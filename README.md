# Revo TPV Integration (extensión AL para Business Central)

Extensión PTE de **Ceroone** para **Grupo Olé** que integra el TPV **Revo** con **Dynamics 365 Business Central**.
Sustituye al Laravel `RevoBusinessCentralGrupoOle`: corre dentro de BC (cola de proyectos), sin servidor intermedio.

- **Versión:** 1.0.16.0. Estado a 05/11/2026: probada en el sandbox `Development_20260421` (centro GAL, Almudévar) y pendiente del paso a producción.
- **Destino:** BC Online (Cloud), aplicación 26+, runtime 15, localización ES. IDs 50400–50449.

## Qué hace

1. **Importa** de la API de Revo, por centro y día, las facturas con sus pagos y las líneas de pedido. Las guarda en tablas staging con upsert, así que relanzar un día no duplica nada.
2. **Crea en BC las facturas y abonos de venta en borrador**:
   - el nº de registro es el nº fiscal de Revo;
   - el cliente se identifica por NIF y, si no existe, se da de alta;
   - productos por supergrupo y % de IVA, con la descripción real del artículo de Revo;
   - descuento global, hora del ticket, dimensiones del centro y forma de pago.
3. **Registra automáticamente** los borradores que cuadran con Revo en importe y líneas, si está activado. Los que no cuadran se quedan en borrador con el motivo, para revisarlos y forzar su registro.
4. **Crea los cobros como líneas de diario sin registrar**, liquidando la factura. Si el método de pago tiene *cliente pasarela* (Dojo, Glovo, Stripe…), genera dos líneas con el mismo nº de documento: el cobro salda al cliente y el importe queda pendiente en la pasarela.
5. **Seguimiento**: estados por factura, comprobaciones de cobros, líneas e importe BC, log de errores, registro de sincronizaciones y relanzamiento de días o rangos.

Nunca modifica documentos que ya existen en BC, tanto si los creó el Laravel como si se crearon a mano (los reconoce por el nº o por el *Nº documento externo*).

## Estructura

```
RevoIntegration-AL/
├── app.json
├── config/REVO-GAL.rapidstart      paquete de configuración del centro GAL
├── scripts/
│   ├── Get-Symbols.ps1             descarga símbolos BC 26 ES del feed público (compilar sin sandbox)
│   └── build_rapidstart_gal.py     genera el paquete RapidStart
└── src/
    ├── Enums/          50400-50407 estado doc/pago, tipo doc, serie, área log, acción método pago, tipo/resultado sync
    ├── Setup/
    │   ├── RevoSetup.Table.al               50400 parámetros globales (URL, IVA, UDS, días, intentos, auto-registro)
    │   ├── RevoCenter.Table.al              50401 centro: tenant, cliente genérico, dimensiones, series S/N/R,
    │   │                                          forma de pago sin cobros, supergrupo por defecto, producto de ajuste
    │   ├── RevoDocLetterSetup.Table.al      50402 letra de prefijo -> tipo doc / serie / cliente / exigir NIF
    │   ├── RevoSuperGroupMapping.Table.al   50403 supergrupo (+% IVA) -> producto
    │   └── RevoPayMethodMapping.Table.al    50404 método de pago -> plantilla/sección, forma de pago, cliente pasarela u omitir
    ├── Staging/
    │   ├── RevoInvoiceHeader.Table.al       50410 factura Revo: estado, comprobaciones, subida/registro forzados
    │   ├── RevoInvoiceLine.Table.al         50411
    │   ├── RevoPayment.Table.al             50412
    │   ├── RevoErrorLog.Table.al            50413
    │   ├── RevoInvoiceContentLink.Table.al  50414
    │   └── RevoSyncLog.Table.al             50415 resumen por centro y día de cada sincronización
    ├── Integration/
    │   ├── RevoCredentialMgt.Codeunit.al    50400 credenciales Revo en IsolatedStorage (SecretText)
    │   ├── RevoAPIClient.Codeunit.al        50401 llamadas a Revo, paginación, reintentos 429/5xx
    │   ├── RevoJsonHelper.Codeunit.al       50402
    │   ├── RevoImport.Codeunit.al           50403
    │   ├── RevoDocumentBuilder.Codeunit.al  50404 borrador de factura/abono
    │   ├── RevoPaymentBuilder.Codeunit.al   50405 líneas de diario de cobro
    │   ├── RevoDimensionHelper.Codeunit.al  50406
    │   ├── RevoErrorLogger.Codeunit.al      50407
    │   ├── RevoSyncOrchestrator.Codeunit.al 50408 flujo, aislamiento de errores, cola, relanzar, acciones masivas
    │   ├── RevoSyncJob.Codeunit.al          50409 entrada de la cola de proyectos
    │   ├── RevoPostingSubscribers.Codeunit.al 50410 al registrar: estado Registrado y hora en el documento registrado
    │   ├── RevoNifHelper.Codeunit.al        50411 validación de NIF/CIF/NIE
    │   ├── RevoDocPoster.Codeunit.al        50412 registro de borradores
    │   ├── RevoSyncLogger.Codeunit.al       50413
    │   └── RevoDraftSubscribers.Codeunit.al 50414 borrar borradores sin documento vacío de numeración
    ├── Pages/          50400-50419 configuración, centros, mapeos, Facturas Revo (lista y ficha), pagos, logs, relanzar
    │                   + extensiones de factura y abono registrados
    └── Permissions/    permissionset 50400 "REVO INTEGRATION"
```

## Flujo diario (tarea de la cola, 00:30)

1. **Importación** de los últimos `Sync Days Back` días hasta ayer: `reports/invoices?withPayments=true` y `reports/orderContents?fullPrecision=true&withItem=true`, en páginas de 100 con commit por página.
2. **Reintento**: los errores de los últimos `Error Retry Days` días vuelven a intentarse. Los más antiguos se reprocesan a mano.
3. **Documentos**: cada factura *Pendiente/Error* (con menos de `Max Processing Attempts` intentos) se procesa en su propio `Codeunit.Run`. Si falla, solo se revierte esa factura.
4. **Estados**: detecta los borradores que se registraron o se borraron en BC.
5. **Auto-registro** de los borradores que cuadran (si `Auto-Post Matching Docs` está activado).
6. **Cobros** de las facturas ya creadas, cada uno en su propio `Codeunit.Run`.

**Relanzar día/rango** (desde Facturas Revo o el registro de sincronizaciones): encola una ejecución con `CENTER=X;DATE=AAAA-MM-DD[;TO=AAAA-MM-DD]`, de hasta 31 días, procesados de uno en uno. Reimporta, reinicia los intentos y reprocesa.

## Reglas principales

| Caso | Comportamiento |
|---|---|
| Letras I/L (invitaciones, albaranes) | Excluidas. **Forzar subida** las crea como factura si se decide subirlas. |
| Cliente | NIF existente → alta automática si el NIF es válido y hay nombre → cliente de la letra → genérico del centro. N y X exigen NIF. |
| Línea sin supergrupo | Toma el supergrupo por defecto del centro (8, como el Laravel). |
| Factura sin cobros (a 0, invitación) | Forma de pago sin cobros del centro, que no puede tener contrapartida (p. ej. ALMEFECTIV). |
| Ticket vacío (sin líneas, a 0) | Se sube solo con una línea a 0 del *producto línea de ajuste* del centro. Así no quedan huecos en la numeración. |
| Faltan líneas de Revo | Queda en error. **Forzar subida** la crea con una línea de ajuste hasta el total de Revo y después hay que forzar su registro. |
| Ya existe en BC (Laravel o manual) | Se enlaza como *preexistente*; no se crean cobros, para no duplicarlos. |
| Borrar un borrador | Con el botón **Borrar borrador** o desde la página de BC, sin crear el documento vacío de numeración. La factura vuelve a Pendiente y se crea de nuevo con el mismo nº. |
| Propina | No forma parte del cobro (el `total` del pago de Revo ya la excluye). |
| Hora del ticket | Se copia al campo "Hora Factura" de la extensión Ceroone si está instalada. Se busca por nombre, sin dependencia. |

## Compilar y desplegar

```powershell
# Símbolos (si no hay sandbox a mano)
./scripts/Get-Symbols.ps1

# Compilar
$alc = (Get-ChildItem "$env:USERPROFILE\.vscode\extensions\ms-dynamics-smb.al-*\bin" -Recurse -Filter alc.exe | Select-Object -First 1).FullName
& $alc /project:"<ruta>\RevoIntegration-AL" /packagecachepath:"<ruta>\RevoIntegration-AL\.alpackages" /out:"<ruta>\Ceroone_Revo TPV Integration_<versión>.app"
```

- En el sandbox se publica desde VS Code (Ctrl+F5, `launch.json`). En producción se sube el `.app` desde *Administración de extensiones*.
- Hay que subir la versión en `app.json` en cada entrega.
- **Requisitos por entorno:**
  - permitir peticiones HTTP a la extensión: *Administración de extensiones → Configurar → Permitir solicitudes HttpClient*;
  - asignar el conjunto de permisos `REVO INTEGRATION`.
- **Configuración por empresa**, en este orden:
  1. Configuración Revo.
  2. Centros: credenciales, letras por defecto, series S/N/R con *Nº manuales*, dimensiones, forma de pago sin cobros y producto de ajuste.
  3. Mapeos de supergrupos y de métodos de pago, con sus plantillas y secciones `COBROS/ALM*` y clientes pasarela.
  4. *Crear tarea diaria*.

La guía paso a paso de despliegue y pruebas en producción, los resultados de las pruebas y el manual de usuario están en `../docs`, fuera de este repositorio.

## Pendiente a 05/11/2026

- **Producto de la línea de ajuste**: el cliente tiene que confirmar producto o cuenta y el IVA.
- **Pruebas en el sandbox de la 1.0.16.0**:
  - borrar un borrador (botón y página de BC);
  - ticket vacío;
  - forzar subida con líneas incompletas.
- Pruebas T11–T13: errores de configuración (supergrupo sin mapear, método sin sección, serie N eliminada).
- **H2**: la serie `DIAG-CBRO` asigna el mismo nº de documento a todos los cobros de la sección. Hay que decidir con contabilidad si se renumeran o si cada cobro lleva su propio nº.
- Fecha de corte del Laravel y confirmación de que el SII no recibe dos veces las facturas.
- Regla de la madrugada (tickets después de medianoche) y generador de casos de prueba.
