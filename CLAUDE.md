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

## Estado a 06/11/2026

- Versión **1.0.18.0** instalada en **producción** el 05/11/2026 21:18 (hora Lima). Punto de restauración: 05/11/2026 21:04 Lima (06/11 02:04 UTC).
- Centro **GAL (Almudévar)**. Fecha de corte con el Laravel: **04/11/2026** (Laravel detenido para GAL, confirmado por Luis).
- **Fases A, B y C hechas** (antes de empezar, instalación, configuración). Configuración traída del sandbox con el paquete RapidStart `REVO-CONFIG` y ajustada a producción:
  - grupo IVA 0 % = **IVA0** (en el sandbox era IVA00);
  - sección de tarjeta = **ALMTARJETA** (en el sandbox ALMTARJET), misma cuenta 4412890;
  - serie S = **GALS** (en el sandbox V-FAC+); N = GALN; R = GALR;
  - método **Transferencia → Omitir** (como el Laravel);
  - Registrar automáticamente = No · Crear clientes por NIF = No · reintento 7 días · **sin tarea diaria**;
  - Producto línea de ajuste **vacío** (pendiente del cliente); tokens introducidos y *Probar conexión* OK.
- **Siguiente: fase 0 (modo espejo)** en sesión con Luis: relanzar el 03/11/2026 (día ya procesado por el Laravel) → todo debe quedar *Creado* con *Documento preexistente = Sí*, cobros *Omitido*, ningún borrador nuevo. Después fase 1 (borradores desde el 04/11, activar *Crear clientes por NIF*) y fase 2 (registro, auto-registro y tarea diaria).

### Pendiente de decidir con Luis (P1–P6)

1. Producto de la línea de ajuste para tickets a 0 sin líneas.
2. Bizum: la sección ALMBIZUM no tiene contrapartida en producción (¿cuenta u omitir?).
3. Líneas al 0 % de IVA: ¿IVA0 o NO SUJETO (SII)?
4. Letra O (offline): ¿serie GALO o GALS (como el Laravel)?
5. H2: la serie DIAG-CBRO repite el nº de documento en los cobros de una sección.
6. Clientes pasarela: pendientes de que el cliente los cree.

Otros pendientes: regla de ventas de madrugada (día anterior), generador de casos de prueba, recuperación de líneas en otra fecha.

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

- **macOS**: compilador del AL Language en `~/.vscode/extensions/ms-dynamics-smb.al-*/bin/darwin/alc`:
  `alc /project:"$PWD" /packagecachepath:"$PWD/.alpackages" /out:"$PWD/Ceroone_Revo TPV Integration_<versión>.app"`
- **Windows**: `alc.exe` en `%USERPROFILE%\.vscode\extensions\ms-dynamics-smb.al-*\bin\win32\` con las mismas opciones (rutas completas desde PowerShell).
- `.alpackages` no está en el repo: en una máquina nueva, *AL: Download symbols* desde VS Code (sandbox) o `pwsh ./scripts/Get-Symbols.ps1`.

## Decisiones técnicas que conviene recordar

- La integración crea facturas/abonos en borrador con nº = nº de Revo y los registra solo si cuadran con Revo (importe y líneas); si no, *Forzar registro* tras revisión.
- Cobros: líneas de diario sin registrar en COBROS/ALM…; con *Cliente pasarela*, dos líneas con el mismo nº de documento (BC no admite cliente contra cliente en una línea).
- Facturas sin cobros (a 0, invitaciones): forma de pago del centro sin contrapartida (ALMEFECTIV). Forma de pago con contrapartida → cobraría dos veces.
- Borrar un borrador (botón o página de BC) quita antes el nº de registro para que BC no cree el documento vacío (H1); la factura vuelve a Pendiente y se recrea con el mismo nº.
- Tickets a 0 sin líneas: se suben y registran solos con línea de ajuste a 0. Sin líneas con importe: *Forzar subida* con línea de ajuste hasta el total.
- Documentos ya existentes en BC (Laravel o manuales, por nº o *Nº documento externo*) se enlazan como preexistentes y sus cobros se omiten.
- El paquete RapidStart debe exportarse con **Excluir tablas de configuración = Sí**; si no, arrastra tablas 86xx de BC.
