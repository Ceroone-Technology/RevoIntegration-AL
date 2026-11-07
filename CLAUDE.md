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

## Estado a 07/11/2026

- Versión **1.0.23.0** en **producción** (07/11/2026). Historial: 1.0.18.0 el 05/11 21:18 Lima · 1.0.19.0 el 07/11 13:40 · 1.0.20.0–1.0.23.0 el 07/11 hacia las 15:00. Punto de restauración: 05/11/2026 21:04 Lima (06/11 02:04 UTC).
- Centro **GAL (Almudévar)**. El Laravel está detenido para GAL (confirmado por Luis). Fecha de corte real: **05/11/2026** (el Laravel procesó el 04/11 completo; P7 resuelto).
- **Fase 0 hecha**: 01–04/11 enlazadas como preexistentes y *Registrado* (01/11: 208 · 02/11: 265 · 03/11: 257 · 04/11: 290).
- **Fase 1 en curso**: 05/11 con 289 borradores + 11 registradas (creados con la marca *Creado por integración Revo*); además hay **250 borradores del 06/11** (pendiente de confirmar quién lo procesó).
- **Fase 2 empezada**: primera factura registrada GALS-000242392 (Revo 4453, 3,40 €, ALMEFECTIV, libro DvImpuestos DV-FV293397). **P8 bloqueante**: salió con Tipo de factura SII **F1**; para simplificadas lo habitual es F2. Comparar con una GALS del Laravel (p. ej. GALS-000241831) antes de registrar más; si el Laravel usaba F2, corregir la integración (S/A/O → F2, R → R5).
- Zona horaria del usuario Ceroone en BC cambiada a Madrid (los campos de fecha/hora se guardan en UTC).
- Regla aprendida: **no vaciar días con documentos creados por la integración** (al reimportar se enlazan como preexistentes y pierden la marca y los cobros). Si hace falta: Borrar borrador → borrar sus líneas de cobro → Vaciar → Relanzar.

### Situación previa (06/11/2026)

- Centro **GAL (Almudévar)**. Fecha de corte inicial con el Laravel: **04/11/2026**.
- **Fases A, B y C hechas** (antes de empezar, instalación, configuración). Configuración traída del sandbox con el paquete RapidStart `REVO-CONFIG` y ajustada a producción:
  - grupo IVA 0 % = **IVA0** (en el sandbox era IVA00);
  - sección de tarjeta = **ALMTARJETA** (en el sandbox ALMTARJET), misma cuenta 4412890;
  - serie S = **GALS** (en el sandbox V-FAC+); N = GALN; R = GALR;
  - método **Transferencia → Omitir** (como el Laravel);
  - Registrar automáticamente = No · Crear clientes por NIF = No · reintento 7 días · **sin tarea diaria**;
  - Producto línea de ajuste **vacío** (pendiente del cliente); tokens introducidos y *Probar conexión* OK.
- **Siguiente (a 07/11)**: resolver P8; revisar las 11 registradas del 05/11 y los borradores del 06/11; completar F1.2–F1.9 y F2.2–F2.8 del registro; activar *Crear clientes por NIF*, auto-registro y tarea diaria solo tras el visto bueno de Luis.

## Acceso de Claude a BC (MCP, solo lectura)

- Servidor MCP oficial de BC configurado en [.mcp.json](.mcp.json) (servidor `bc-grupoole`): Production, empresa Grupo Olé, configuración **CLAUDE-LECTURA**.
- App de Entra «BC MCP - Claude (Ceroone)» en el inquilino RALSA98 SL (= tenant de BC), Id. de cliente `e908fd12-4885-4e50-8e8e-a6e9e03ded81`, redirect `http://localhost:33418/callback`, permiso delegado Financials.ReadWrite.All con consentimiento de administrador, sin secreto.
- En BC (página 8350) CLAUDE-LECTURA está activa, no predeterminada, con **Desbloquear herramientas de edición = No**, modo dinámico y *Data Query Tools*. Herramientas útiles: `bc_data_find_tables`, `bc_data_get_table_schema`, `bc_data_query` (consultas AL de solo lectura; tablas Revo 50400–50415).
- En una máquina nueva: abrir Claude Code en el repo, aprobar el servidor `bc-grupoole` y `/mcp` → Authenticate con **ceroone@gruporalsa.com**. El token queda en cada máquina, no en el repo.
- Aunque el acceso es de solo lectura, las lecturas de BC siguen siendo **con permiso del usuario**. Nunca escribir en BC.

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
