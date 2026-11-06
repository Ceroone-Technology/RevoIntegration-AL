# Registro del paso a producción – Integración Revo BC (GAL)

Nov 5, 2026 · @Omar Carreño

La integración Revo – Business Central (extensión **Revo TPV Integration 1.0.18.0**, Ceroone) se despliega en producción para el centro **GAL (Almudévar)** de GRUPO OLE RESTAURACION, S.L. Cada paso se anota aquí con su fecha, responsable y resultado. Este documento es el registro final del paso a producción.

*Horas en hora de Lima. Las anotadas antes de las 22:52 del 05/11/2026 son aproximadas (±10 min); desde entonces se toman del reloj del sistema.*

## Resumen

| Dato | Valor |
| --- | --- |
| Entorno | Producción, empresa GRUPO OLE RESTAURACION, S.L. |
| Centro | GAL (Almudévar) |
| Versión instalada | 1.0.18.0 |
| Aval de Luis Huapaya | 05/11/2026 |
| Fecha de corte con el Laravel | 04/11/2026 (Laravel detenido para GAL, confirmado por Luis el 05/11/2026) |
| Punto de restauración | 05/11/2026 21:04 hora Lima (06/11/2026 02:04 UTC · 03:04 Madrid) |
| Repositorio | [github.com/Ceroone-Technology/RevoIntegration-AL](https://github.com/Ceroone-Technology/RevoIntegration-AL) |

| Fase | Estado | Inicio | Fin |
| --- | --- | --- | --- |
| A. Antes de empezar | Hecho | 05/11/2026 | 05/11/2026 |
| B. Instalación | Hecho | 05/11/2026 21:18 | 05/11/2026 22:30 |
| C. Configuración inicial | Hecho | 05/11/2026 21:40 | 05/11/2026 22:51 (C11 pendiente del cliente) |
| Fase 0: modo espejo | Pendiente | Prevista 06/11/2026, en sesión con Luis |  |
| Fase 1: solo borradores | Pendiente |  |  |
| Fase 2: registro | Pendiente |  |  |

## A. Antes de empezar

Los seis puntos previos quedaron cerrados el 05/11/2026; ninguno bloquea la instalación.

| # | Paso | Fecha y hora | Responsable | Estado | Notas |
| --- | --- | --- | --- | --- | --- |
| A1 | Fecha de corte con el Laravel para GAL | 05/11/2026 | Luis Huapaya | Hecho | Corte el 04/11/2026. Laravel detenido para GAL (confirmado por Luis el 05/11/2026) |
| A2 | Envío a Hacienda sin duplicar | 05/11/2026 | Luis Huapaya | Hecho | El SII se envía desde BC (DvImpuestos), igual que con el Laravel; las facturas a 0 también se envían. Sin solape gracias al corte y a la detección de preexistentes |
| A3 | Forma de pago CAJA | 05/11/2026 | Luis Huapaya | Hecho | En producción está bien configurada. Las facturas sin cobro usan ALMEFECTIV |
| A4 | Aviso a contabilidad | 05/11/2026 | Omar Carreño | Hecho | No registrarán ni borrarán borradores de Revo durante las pruebas |
| A5 | Cobros contra cliente pasarela | 05/11/2026 | Luis Huapaya | Hecho | Decidido y probado en el sandbox (T17). El cliente creará los clientes pasarela en producción |
| A6 | Punto de restauración | 05/11/2026 21:04 (Lima) | Omar Carreño | Hecho | 06/11/2026 02:04 UTC. Restaurar desde el centro de administración de BC a un momento anterior |

## B. Instalación en producción

La extensión se sube como archivo `.app` desde Administración de extensiones; a producción no se publica desde VS Code.

| # | Paso | Fecha y hora | Responsable | Estado | Notas |
| --- | --- | --- | --- | --- | --- |
| B1 | Cargar `Ceroone_Revo TPV Integration_1.0.18.0.app` (Implementar en: Versión actual) | 05/11/2026 21:18 (Lima) | Omar Carreño | Hecho | Estado de instalación de extensión (Production): Revo TPV Integration · Ceroone · Cargar · Completado · 1.0.18.0 · 5/11/2026 21:18. Modo de esquema: Agregar (primera instalación). Posterior al punto de restauración (21:04) |
| B2 | Asignar el conjunto de permisos Integración Revo (`REVO INTEGRATION`) | 05/11/2026 21:25 (Lima) | Omar Carreño | Hecho | Asignado al usuario Ceroone (ceroone@gruporalsa.com), empresa Grupo Olé. Facturas Revo ya aparece en el buscador. Usuarios de contabilidad: se añadirán cuando se definan |
| B3 | Llamadas externas | 05/11/2026 22:30 (Lima) | Omar Carreño | Hecho | Probar conexión en la ficha GAL: "Conexión correcta. Facturas en la primera página: 100". Producción permite a la extensión llamar a Revo; DvImpuestos no se ha tocado |

## C. Configuración inicial

Se arranca con todo lo que escribe en BC desactivado y se activa por fases.

### C0. Comparación sandbox ↔ producción (antes de aplicar el paquete)

El paquete solo copia la configuración de Revo; lo que referencia debe existir en producción y estar igual. *Validar paquete* detecta los códigos que faltan; lo de abajo se revisa a mano.

| # | Qué comprobar en producción | Fecha y hora | Estado | Resultado |
| --- | --- | --- | --- | --- |
| C0.1 | Secciones COBROS / ALM… con la misma contrapartida (ALMTARJET 4412890, ALMGLOVO 4412896, ALMSTRIPE 4412898, ALMEFECTIV 5700891) | 05/11/2026 22:00 (Lima) | Hecho | Excel de secciones de producción: ALMEFECTIV 5700891, ALMGLOVO 4412896, ALMSTRIPE 4412898 iguales. La de tarjeta en producción es ALMTARJETA (4412890), no ALMTARJET: se corrige en el paquete. ALMBIZUM, ALMCREDITO y ALMTRASNFE sin contrapartida: revisar con Luis |
| C0.2 | Formas de pago ALMEFECTIV, ALMTARJETA… sin cuenta de contrapartida | 05/11/2026 22:45 (Lima) | Hecho | Excel de formas de pago: las 15 ALM… (ALMEFECTIV, ALMTARJETA, ALMGLOVO, ALMSTRIPE…) sin cuenta de contrapartida, sin cartera ni efectos. CAJA mantiene 5700001 (no la usa la integración) |
| C0.3 | Series GALS, GALN, GALR con Nº manuales | 05/11/2026 22:45 (Lima) | Hecho | Existen GALS, GALN y GALR (y GALI, GALL, GALO, GALX), sin líneas de numeración: el nº lo pone Revo y la integración lo asigna como nº de registro |
| C0.4 | Productos 8\_AL, 9\_AL…: grupo IVA, UdM UDS, dimensiones 1S/2A/3C, no inventariable o servicio | 05/11/2026 22:45 (Lima) | Hecho | Los 12 productos \_AL (7\_AL a 17\_AL) existen y son Fuera de inventario: no mueven stock. Grupos IVA validados con el paquete |
| C0.5 | Grupos IVA IVA4, IVA10, IVA21 y 0 % con su % en Configuración registro IVA | 05/11/2026 22:00 (Lima) | Hecho | Excel de Config. grupos registro IVA (NAC): IVA4 4 %, IVA10 10 %, IVA21 21 %, IVA0 0 %, tipo Normal. No existe IVA00: el grupo 0 % del paquete se cambia a IVA0. Confirmar con Luis si el 0 % de Revo va a IVA0 o a NO SUJETO (SII) |
| C0.6 | Cliente genérico X89000000 y clientes por letra | 05/11/2026 22:50 (Lima) | Hecho | Cliente genérico X89000000 en la ficha GAL. Letras: A, O, S factura simplificada; N factura nominal (exige NIF); R abono rectificativo; X abono nominal (exige NIF); I y L excluidas. Ninguna letra tiene cliente propio: sin NIF van al genérico |
| C0.7 | Permitir fecha IVA y Permitir registro cubren noviembre de 2026 | 05/11/2026 22:45 (Lima) | Hecho | Permitir registro 01/01/2026–31/12/2026 y Permitir fecha de IVA 01/07/2026–31/12/2026: cubren noviembre de 2026; Uso fecha IVA habilitado |
| C0.8 | Validar paquete REVO-CONFIG en producción: 0 errores | 05/11/2026 22:08 (Lima) | Hecho | 0 errores en las 5 tablas (1 / 1 / 8 / 12 / 25 registros) tras corregir el grupo IVA 0 % a IVA0 y la sección de las 3 líneas de tarjeta. La primera validación dio 4 errores (ver Incidencias) |

| # | Dónde | Valor | Fecha y hora | Responsable | Estado | Notas |
| --- | --- | --- | --- | --- | --- | --- |
| C1 | Configuración Revo → Registrar automáticamente si cuadra | Desactivado hasta la fase 2 | 05/11/2026 22:25 (Lima) | Omar Carreño | Hecho | Desactivado. Resto de Configuración Revo revisado: URL https://revoxef.works/api/external/v3/, página 100, timeout 120000 ms, 3 reintentos, prefijo IVA, grupo 0 % IVA0, UdM UDS, precio abono = total / cantidad, 1 día atrás, desfase 1, máx. 3 intentos |
| C2 | Configuración Revo → Crear clientes por NIF | Desactivado en fase 0; activar en fase 1 | 05/11/2026 22:25 (Lima) | Omar Carreño | Hecho | Desactivado para la fase 0; plantilla de cliente vacía |
| C3 | Configuración Revo → Días de reintento de errores | 7 | 05/11/2026 22:25 (Lima) | Omar Carreño | Hecho | 7 días |
| C4 | Tarea diaria | No crearla hasta la fase 2 | 05/11/2026 22:48 (Lima) | Omar Carreño | Hecho | Movs. cola trabajo filtrado por Revo: sin tareas. No se crea hasta la fase 2; las pruebas se lanzan con Relanzar día |
| C5 | Paquete de configuración exportado del sandbox | Importar, validar y aplicar | 05/11/2026 21:40 exportado · 22:20 aplicado (Lima) | Omar Carreño | Hecho | Aplicado en producción: 5 tablas, 0 errores, 47 registros insertados, 0 modificados (1 / 1 / 8 / 12 / 25). Excluidos Producto línea de ajuste, Última fecha sincronizada, Última ejecución y Cliente pasarela. Pendiente: sección ALMTARJETA en las 3 líneas de tarjeta (C7) |
| C6 | Ficha del centro GAL | Series GALS / GALN / GALR · dimensiones 3C = 089 y 1S = SRE2 · cliente genérico X89000000 · tokens de Revo | 05/11/2026 22:30 (Lima) | Omar Carreño | Hecho | Serie S cambiada de V-FAC+ (sandbox) a GALS; N GALN, R GALR; 3C = 089, 1S = SRE2; X89000000; CON; precios IVA incluido; activo. Tenant almudevar y tokens introducidos (cifrados, no se registran aquí). Probar conexión correcto |
| C7 | Mapeo métodos de pago | Sección de diario COBROS/ALM… y forma de pago por método | 05/11/2026 22:35 (Lima) | Omar Carreño | Hecho | 25 métodos revisados, todos en plantilla COBROS. Sección ALMTARJETA asignada a Card America Express, Card VISA / Mastercard y Tarjeta. Transferencia cambiada a Omitir (como el Laravel). Omitidos: Crédito, Invitación, Transferencia, Transferencia Bancaria. Bizum se mantiene en ALMBIZUM (sin contrapartida) pendiente de Luis |
| C8 | Configuración de IVA y Configuración contabilidad | Permitir fecha IVA y Permitir registro cubren las fechas a probar | 05/11/2026 22:50 (Lima) | Omar Carreño | Hecho | Ver C0.7: registro e IVA permitidos hasta 31/12/2026 |
| C9 | Productos `_AL` | Dimensiones por defecto 1S, 2A y 3C | 05/11/2026 22:51 (Lima) | Omar Carreño | Hecho | 8_AL: 1S = SRE2 (Carretera), 2A = A2101 (Comida), 3C = 089 (Almudevar R), registro Mismo código |
| C10 | Ficha GAL → Forma de pago sin cobros | ALMEFECTIV | 05/11/2026 22:30 (Lima) | Omar Carreño | Hecho | Sin contrapartida; usada por las facturas sin cobro (a 0) |
| C11 | Clientes pasarela + Mapeo métodos de pago → Cliente pasarela | Uno por pasarela, grupo contable a la 441 |  | Cliente / Omar Carreño | Pendiente | Los crea el cliente; después se asignan a cada método |
| C12 | Ficha GAL → Producto línea de ajuste | Vacío hasta que el cliente lo indique | 05/11/2026 22:30 (Lima) | Luis Huapaya | Hecho | Mientras esté vacío, los tickets a 0 sin líneas quedan en error con aviso y se recuperan reprocesando |

## Fase 0: modo espejo

Se relanzan días anteriores al corte (p. ej. 02/11/2026 y 03/11/2026) que el Laravel ya procesó; la integración solo enlaza lo existente y no crea nada en BC.

| # | Prueba | Resultado esperado | Fecha y hora | Responsable | Estado | Resultado obtenido |
| --- | --- | --- | --- | --- | --- | --- |
| F0.1 | Relanzar día de una fecha ya procesada por el Laravel | Facturas en Creado con Documento preexistente = Sí; ningún borrador nuevo |  | Omar Carreño | Pendiente |  |
| F0.2 | Cobros de esas facturas | Estado Omitido; ninguna línea de diario |  | Omar Carreño | Pendiente |  |
| F0.3 | Registro de sincronizaciones | Una línea por día con el nº de facturas y el importe de Revo |  | Omar Carreño | Pendiente |  |
| F0.4 | Comparar con el Laravel | Mismo nº de facturas e importe del día en BC |  | Omar Carreño | Pendiente |  |
| F0.5 | Ventas → Facturas venta (borradores) | Ningún borrador nuevo |  | Omar Carreño | Pendiente |  |

## Fase 1: solo borradores

Desde la fecha de corte (04/11/2026) la integración crea los borradores y las líneas de cobro sin registrar. Se activa Crear clientes por NIF (C2).

| # | Funcionalidad | Qué comprobar | Fecha y hora | Responsable | Estado | Resultado obtenido |
| --- | --- | --- | --- | --- | --- | --- |
| F1.1 | Borrador de factura | Nº = nº de Revo · cliente genérico o por NIF · líneas con el producto de Revo en la descripción · forma de pago del cobro · Hora Factura · dimensiones |  | Omar Carreño | Pendiente |  |
| F1.2 | Abono (letras R y X) | Se crea como abono con precios positivos |  | Omar Carreño | Pendiente |  |
| F1.3 | Excluidas (I, L) | Estado Excluido: no se crean salvo Forzar subida |  | Omar Carreño | Pendiente |  |
| F1.4 | Cliente por NIF | Cliente nuevo con nº = NIF y Cliente creado = Sí |  | Omar Carreño | Pendiente |  |
| F1.5 | Supergrupo sin mapear | Con error, el mensaje dice cuál |  | Omar Carreño | Pendiente |  |
| F1.6 | Cobros | Línea en la sección ALM… de su método, Liquida a = la factura, sin registrar; con cliente pasarela, segunda línea a la pasarela |  | Omar Carreño | Pendiente |  |
| F1.7 | Las tres diferencias | Dif. pagos, Dif. líneas y Dif. vs BC a 0 en las que cuadran; en rojo las que no |  | Omar Carreño | Pendiente |  |
| F1.8 | Vistas | Pendientes por subir, Con error e Incidencia de pagos muestran los casos esperados |  | Omar Carreño | Pendiente |  |
| F1.9 | Ticket a 0 sin líneas | Con producto de ajuste configurado: se crea con 1 línea a 0; sin él: error con aviso |  | Omar Carreño | Pendiente |  |

## Fase 2: registro

La integración registra las facturas que cuadran con Revo y se envían al SII desde BC. Se activa el registro automático (C1) y la tarea diaria (C4).

| # | Funcionalidad | Qué comprobar | Fecha y hora | Responsable | Estado | Resultado obtenido |
| --- | --- | --- | --- | --- | --- | --- |
| F2.1 | Registrar si cuadra con 3–5 facturas | Pasan a Registrado; Hora Factura visible en el histórico |  | Omar Carreño | Pendiente |  |
| F2.2 | Factura que no cuadra | Queda en borrador con su Motivo sin registrar |  | Omar Carreño | Pendiente |  |
| F2.3 | Forzar registro | Se registra; quedan rellenos Registro forzado, Descuadre ignorado y Forzado por |  | Omar Carreño | Pendiente |  |
| F2.4 | Error de configuración | No se puede forzar; el motivo indica qué falta |  | Omar Carreño | Pendiente |  |
| F2.5 | Abono | Se registra; si sale el aviso del nº de factura corregida, se pulsa Sí |  | Omar Carreño | Pendiente |  |
| F2.6 | Envío al SII | En DvImpuestos la factura sale una sola vez |  | Omar Carreño | Pendiente |  |
| F2.7 | Modo automático | Activar Registrar automáticamente si cuadra → Relanzar día → se registran solas |  | Omar Carreño | Pendiente |  |
| F2.8 | Tarea diaria | Crear tarea diaria y revisar al día siguiente el Registro de sincronizaciones |  | Omar Carreño | Pendiente |  |

## Pendiente de decidir con Luis

Puntos abiertos para la sesión del 06/11/2026; ninguno bloquea la fase 0.

| # | Punto | Situación actual | Decisión de Luis | Estado |
| --- | --- | --- | --- | --- |
| P1 | Producto de la línea de ajuste (tickets a 0 sin líneas) | Campo vacío en GAL: esos tickets quedan en error con aviso hasta configurarlo (C12) |  | Pendiente |
| P2 | Bizum: cuenta de contrapartida | Bizum crea línea en ALMBIZUM, que no tiene contrapartida en producción (C7). ¿Qué cuenta, u omitir? |  | Pendiente |
| P3 | Líneas de Revo al 0 % de IVA | Van al grupo IVA0 (0 %, Normal). ¿IVA0 o NO SUJETO, de cara al SII? (C0.5) |  | Pendiente |
| P4 | Letra O (offline) | Va a la serie S (GALS), como el Laravel; en producción existe la serie GALO. ¿GALO o GALS? |  | Pendiente |
| P5 | Numeración de los cobros (H2) | La serie DIAG-CBRO repite el nº de documento en los cobros de una sección. ¿Renumerar o un nº por cobro? |  | Pendiente |
| P6 | Clientes pasarela | Pendientes de crear por el cliente (C11); hasta entonces el cobro va contra la contrapartida de la sección |  | Pendiente |

## Incidencias y decisiones

| Fecha | Tipo | Descripción | Decisión / acción | Responsable |
| --- | --- | --- | --- | --- |
| 05/11/2026 | Decisión | Versión a instalar | 1.0.18.0, tras probar en el sandbox T21–T25 (borrar borradores sin documento vacío, tickets a 0 sin líneas, forzar subida con línea de ajuste) | Omar Carreño |
| 05/11/2026 | Corrección de la guía | El paso B3 de la guía decía bloquear DvImpuestos | Solo aplica al sandbox; en producción no se toca | Omar Carreño |
| 05/11/2026 | Pendiente | Producto de la línea de ajuste | Luis lo consulta con el cliente | Luis Huapaya |
| 05/11/2026 | Pendiente | H2: la serie DIAG-CBRO repite el nº de documento en los cobros de una sección | Decidir con contabilidad si se renumera o si cada cobro lleva su propio nº | Luis Huapaya |
| 05/11/2026 21:45 | Incidencia | El paquete REVO-CONFIG importado en producción incluía las tablas de configuración de BC (8610–8622…), con 5 registros del sandbox en 8620 Config. Tmpl. Selection Rules, porque en el sandbox Excluir tablas de configuración estaba desactivado | Borrar esas líneas del paquete en producción antes de validar; solo quedan las tablas 50400–50404. Borrar líneas del paquete no toca los datos reales de BC | Omar Carreño |
| 05/11/2026 22:00 | Decisión | Validar paquete en producción: 4 errores. Configuración Revo con grupo IVA 0 % = IVA00 (no existe en producción) y 3 métodos de tarjeta con sección ALMTARJET (en producción se llama ALMTARJETA, misma cuenta 4412890) | Corregir los datos del paquete: IVA00 → IVA0 y ALMTARJET → ALMTARJETA. Revalidar hasta 0 errores antes de aplicar | Omar Carreño |
| 05/11/2026 22:00 | Pendiente | Las secciones ALMBIZUM, ALMCREDITO y ALMTRASNFE no tienen cuenta de contrapartida en producción; y falta confirmar si las líneas de Revo al 0 % van a IVA0 o a NO SUJETO | Revisar con Luis / contabilidad. No bloquea la fase 0 | Luis Huapaya |
| 05/11/2026 22:15 | Incidencia | Al corregir en el paquete la sección de las 3 líneas de tarjeta a ALMTARJETA, el editor de paquetes responde "El valor de Sección diario 'ALMTARJETA' no existe", aunque la sección figura en el Excel de producción. Grupo IVA 0 % ya corregido a IVA0 (50400 sin errores) | Dejar la sección vacía en esas 3 líneas, aplicar el paquete y asignar ALMTARJETA desde Mapeo métodos de pago del centro GAL (lookup filtrado por COBROS). Así se conservan los nombres exactos de los métodos Revo | Omar Carreño |
| 05/11/2026 22:35 | Decisión | En el mapeo importado, el método Transferencia estaba como Crear línea diario (sección ALMTRASNFE, sin contrapartida); el Laravel omitía Transferencia, Transferencia Bancaria y Crédito | Transferencia cambiada a Omitir en producción. Bizum se deja en Crear línea diario (ALMBIZUM) hasta que Luis confirme su contrapartida | Omar Carreño |
| 05/11/2026 22:54 | Decisión | Fases A, B y C terminadas. Desde la fase 0 la integración ya procesa datos reales de Revo en producción | Las fases 0, 1 y 2 se hacen en sesión con Luis supervisando, a partir del 06/11/2026. Se le envía el registro y los puntos pendientes de decidir | Omar Carreño |
