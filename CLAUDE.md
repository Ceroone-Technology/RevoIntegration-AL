# Contexto del proyecto para Claude Code

Extensión AL **Revo TPV Integration** (publisher Ceroone) para **Grupo Olé**: integra el TPV Revo con Business Central y
sustituye al Laravel `RevoBusinessCentralGrupoOle`. Responsable técnico: Omar Carreño (Ceroone). Interlocutor con el
cliente: **Luis Huapaya** (Ceroone). Detalle técnico y estructura: [README.md](README.md).

## Reglas de trabajo (acordadas con el usuario)

- **El usuario publica él mismo.** Claude compila y deja el `.app`; no publica ni escribe en BC. Lecturas de BC solo con su permiso.
- **Confirmar antes de cada commit/push** al repo `github.com/Ceroone-Technology/RevoIntegration-AL`: resumir archivos y mensaje y esperar OK.
- **Paso a paso y con evidencias**: en el despliegue se avanza un paso cada vez, con capturas del usuario, y cada paso se anota en el registro (ver abajo) con la **hora real del sistema** (no estimada).
- **Registro del despliegue: actualizar SIEMPRE Word y HTML** a la vez tras cada cambio (ver «Registro del paso a producción»).
- Subir versión en `app.json` en cada entrega. Probar siempre primero en el sandbox; producción solo por el paso a paso.
- **Credenciales**: el Excel de mapeos del cliente (`MapeoRevoToBusinessCentral.xlsx`, hoja SOCIEDADES) contiene tokens de Revo en claro. Nunca copiarlos a código, docs, chat ni commits. En BC se guardan cifrados (IsolatedStorage) y el usuario los teclea.
- Tono: español, directo, con recomendación clara.

## Entornos

| Entorno | Uso |
|---|---|
| Tenant `28bc6d77-52ea-4888-ac5e-1eacec3be425`, empresa «Grupo Olé» (GRUPO OLE RESTAURACION, S.L.) | Mismo tenant para todo |
| Sandbox **Development_20260421** (copia de producción del 18/04/2026) | Pruebas y publicación con Ctrl+F5 (`.vscode/launch.json`) |
| **Production** | Solo instalación por `.app` (Administración de extensiones) y el paso a paso |

## Estado a 13/11/2026

- Versión **1.0.25.0** en **producción** (PTE, instalada el 13/11 por la mañana). Historial: 1.0.18.0 el 05/11 · 1.0.19.0–1.0.23.0 el 07/11 · 1.0.24.0 el 12/11 23:54 Lima · 1.0.25.0 el 13/11.
- **12 centros en 7 empresas** (los que procesaba el Laravel, ya detenido): Grupo Olé (GAL, GOL, GVI), Duffy (DBU), La Candelaria (CCF), Cebrian (CCA), Ibérica Stadium (SCA), Zurolé (ZCA, ZSM), Rosviple (RLA, ROL, ROZ). Fase 0 (espejo) y fase 1 (borradores) hechas en todos; facturas creadas en borrador y cobros en el diario sin registrar.
- **Tareas diarias** a la hora del Laravel, escalonadas 5 min (hora Madrid = Lima + 6 h): Grupo Olé 05:55 · Duffy 06:00 · La Candelaria 06:05 · Cebrian 06:10 · Ibérica 06:15 · Zurolé 06:20 · Rosviple 06:25. **Nunca dos relanzamientos a la vez** con secciones compartidas (H4).
- **Clientes pasarela** (reuniones con Luis del 12/11): por centro y método con cuenta en TESORERIAS (VISA, RESTAURANTE, SODEXO, GOURMET, MARCHANDO, UBER, GLOVO, VOLVEREMOS, COVER, IMPAGADO) un grupo registro cliente y un cliente `PAS-<centro>-<método>` (Cta. clientes = Cta. efectos = 4412xxN / 4415xx1, NAC/NAC, CON, forma de pago **EFECTO**) y su mapeo. 120 en total, aplicados con `config/REVO-PAS-<EMPRESA>.rapidstart` (generados con `scripts/build_rapidstart_gateways.py`). Sin pasarela: Transferencia, Crédito, Bizum (Omitir), Efectivo y Glovo efectivo (pendiente de Luis) y Propinas (sin cuenta).
- **1.0.25.0**: la línea de la pasarela es de tipo **Efecto** (lo pidió Luis; la 1.0.24.0 la hacía Factura), Nº efecto = orden del cobro en la factura, queda en Cartera. Probado en el sandbox con GALS-000224819 (efecto en Cartera, 4412890 debe). Botón **Rehacer cobros** (Facturas Revo): rehace los cobros sin registrar con la configuración actual.
- **Siguiente**: prueba con Luis en producción (2 facturas: Rehacer cobros → registrar factura → registrar sus 2 líneas filtrando por *Nº documento externo*, porque el Nº documento se repite en la sección, H2); 5 más para los usuarios; Rehacer cobros del 05 al 12/11 en los 12 centros; fase 2 (registro automático) con el OK de Luis.
- Reglas aprendidas: no vaciar días con documentos creados por la integración; en el sandbox la app está publicada como **Dev** (publicar con VS Code: cargar el `.app` da AVS0109); en producción es PTE (cargar el `.app`). En Duffy la serie de contactos CONT estaba desfasada (corregido a CONT11281 el 13/11).

## Acceso de Claude a BC (MCP, solo lectura)

- Servidores MCP oficiales de BC en [.mcp.json](.mcp.json), configuración **CLAUDE-LECTURA**: uno por empresa de producción (`bc-grupoole`, `bc-duffy`, `bc-lacandelaria`, `bc-cebrian`, `bc-iberica`, `bc-zurole`, `bc-rosviple`) y `bc-sandbox` (Development_20260421, Grupo Olé).
- App de Entra «BC MCP - Claude (Ceroone)» en el inquilino RALSA98 SL (= tenant de BC), Id. de cliente `e908fd12-4885-4e50-8e8e-a6e9e03ded81`, redirect `http://localhost:33418/callback`, permiso delegado Financials.ReadWrite.All con consentimiento de administrador, sin secreto.
- En BC (página 8350, en cada empresa y en el sandbox) CLAUDE-LECTURA está activa, no predeterminada, con **Desbloquear herramientas de edición = No**, modo dinámico y *Data Query Tools*. Herramientas útiles: `bc_data_find_tables`, `bc_data_get_table_schema`, `bc_data_query` (consultas AL de solo lectura; tablas Revo 50400–50415).
- En una máquina nueva: abrir Claude Code en el repo, aprobar los servidores `bc-*` y `/mcp` → Authenticate (en cada uno) con **ceroone@gruporalsa.com**. El token queda en cada máquina, no en el repo.
- Aunque el acceso es de solo lectura, las lecturas de BC siguen siendo **con permiso del usuario**. Nunca escribir en BC.

### Pendiente de decidir con Luis

1. Producto de la línea de ajuste para tickets a 0 sin líneas (P1).
2. Líneas al 0 % de IVA: ¿IVA0 o NO SUJETO (SII)?; letra O (offline): ¿serie propia o la S?
3. H2: la serie DIAG-CBRO repite el nº de documento en los cobros de una sección.
4. Efectivo con pasarela o no; Propinas sin cuenta.
5. Cuentas de Cartera de los grupos pasarela (descontados, en gestión de cobro, impagados): vacías; solo hacen falta si los efectos se remesan o descuentan.
6. Activar registro automático (fase 2).

Ver la lista completa (P1–P10) en el registro.

## Registro del paso a producción

- Documento vivo (Claude Docs): https://claude.ai/artifact/Nw4bHHyDGupC4jCQ6XyriL — tablas por fase con fecha/hora, responsable, estado (Pendiente / En curso / Hecho / No aplica) y resultado; secciones «Pendiente de decidir con Luis» e «Incidencias y decisiones».
- Copia local: `docs/registro/registro.md` (fuente, se mantiene igual que el documento) → `docs/Registro del paso a produccion - Integracion Revo BC (GAL).html` y `.docx`.
- Al marcar un paso: actualizar el documento de Claude Docs **y** `registro.md` con el mismo texto, y regenerar:
  - macOS: `sh docs/registro/exportar.sh` (python3 + `textutil`)
  - Windows: `.\docs\registro\exportar.ps1` (python + Word)

## Otros documentos

| Documento | Dónde |
|---|---|
| Guía «Pruebas en producción» (paso a paso por fases) | Claude Docs https://claude.ai/artifact/TnFit47uye7NpkzTZH8DmH · `docs/Pruebas en produccion - Integracion Revo BC.*` |
| Resultados de pruebas en el sandbox (T1–T25, hallazgos H1/H2) | Pestaña del doc anterior · `docs/Resultados de pruebas Sambox - Integracion Revo BC.*` |
| Manual de usuario | Claude Docs https://claude.ai/artifact/LMKYJvndW46vmxe1hNMju1 · `docs/manual-usuario-revo-bc.html` |

## Compilar

- **macOS**: la extensión AL 18.x ya no trae `alc` para darwin. Compilar desde VS Code con **AL: Package** (Cmd+Shift+P), que deja el `.app` en la raíz del repo. Sandbox: **Ejecutar → Ejecutar sin depuración** (publica como Dev). Producción: el usuario carga el `.app` en Administración de extensiones.
- **Windows**: `alc.exe` en `%USERPROFILE%\.vscode\extensions\ms-dynamics-smb.al-*\bin\win32\`:
  `alc /project:"$PWD" /packagecachepath:"$PWD/.alpackages" /out:"$PWD/Ceroone_Revo TPV Integration_<versión>.app"`
- `.alpackages` no está en el repo: en una máquina nueva, *AL: Download symbols* desde VS Code (sandbox) o `pwsh ./scripts/Get-Symbols.ps1`.

## Decisiones técnicas que conviene recordar

- La integración crea facturas/abonos en borrador con nº = nº de Revo y los registra solo si cuadran con Revo (importe y líneas); si no, *Forzar registro* tras revisión.
- Cobros: líneas de diario sin registrar en COBROS/ALM…; con *Cliente pasarela*, dos líneas con el mismo nº de documento (BC no admite cliente contra cliente en una línea): Pago al cliente que liquida la factura y **Efecto** al cliente pasarela (Nº efecto 1, 2…, forma de pago del cliente pasarela, que debe crear efectos; BC España lo lleva a la *Cta. efectos* del grupo). Devoluciones: Abono a la pasarela.
- Cobro negativo en una factura (cambio devuelto con otro método, H5): línea positiva sin tipo ni liquidación.
- Facturas sin cobros (a 0, invitaciones): forma de pago del centro sin contrapartida (ALMEFECTIV). Forma de pago con contrapartida → cobraría dos veces.
- Borrar un borrador (botón o página de BC) quita antes el nº de registro para que BC no cree el documento vacío (H1); la factura vuelve a Pendiente y se recrea con el mismo nº.
- Tickets a 0 sin líneas: se suben y registran solos con línea de ajuste a 0. Sin líneas con importe: *Forzar subida* con línea de ajuste hasta el total.
- Documentos ya existentes en BC (Laravel o manuales, por nº o *Nº documento externo*) se enlazan como preexistentes y sus cobros se omiten.
- El paquete RapidStart debe exportarse con **Excluir tablas de configuración = Sí**; si no, arrastra tablas 86xx de BC.
