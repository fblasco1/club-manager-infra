# Bitácora de Desarrollo y Sincronización — ERP Clubes

Este documento actúa como el canal principal de comunicación y alineación técnica entre **Cursor AI** (Desarrollo) y **Gemini Spark** (PM AI). Su propósito es asegurar la trazabilidad del progreso, la gestión de la arquitectura y el cumplimiento de las reglas de negocio establecidas para el sistema.

**Publicación en Drive:** subir `docs/club/bitacora-de-desarrollo.md` a la carpeta [Sistema de Gestion - ERP CLUBES](https://drive.google.com/drive/folders/1KAvGKTnyjkZ_RDjwyxe_c6E3teS0RWtQ) (manual o vía el método acordado con el PO).  
**Skill agente:** `.cursor/skills/bitacora-desarrollo/SKILL.md`  
**Corte operativo complementario:** `docs/club/sync-pm-ai.md` (opcional; semáforo Done/prod y gap local→prod).

---

## Resumen de Arquitectura y Referencias de Negocio

La solución se construye sobre una base tecnológica robusta diseñada para la escalabilidad y la integración financiera de entidades deportivas.

### Stack tecnológico

| Capa | Tecnología |
|------|------------|
| Framework | Frappe Framework / ERPNext |
| Infraestructura | Docker para despliegue y entornos aislados |
| Base de datos | PostgreSQL v14 |

### Contexto de negocio e integraciones

| Tema | Detalle |
|------|---------|
| Entidad de referencia | Club Pedro Echagüe (ICDPE) |
| Pasarela de pagos | Integración con **Banco Supervielle Cobros+** / **Cobrand** (SIRO retirado) |
| App custom | `club_management` en `development/frappe-bench/apps/club_management/` |
| Producción | https://gestion.icdpedroechague.com.ar |

---

## Backlog maestro sincronizado (Cursor AI ↔ PM AI)

Listado de tareas críticas clasificadas por épicas de desarrollo para el ERP Clubes.

### Épica 1: Arquitectura base e infraestructura

| ID | Tarea | Prioridad | Estado | Dependencias |
|----|-------|-----------|--------|--------------|
| 1.1 | Configuración Docker y PostgreSQL | Crítica | Done | — |
| 1.2 | Frappe Site multi-tenant | Alta | To Do | Docker |
| 1.3 | Scheduler Frappe + PostgreSQL (`last_execution` tz) | Alta | Done (prod hotfix 01/09) | Docker |

### Épica 2: Núcleo de gestión de socios y ciclo de vida

| ID | Tarea | Prioridad | Estado | Dependencias |
|----|-------|-----------|--------|--------------|
| 2.1 | DocType Socio y máquina de estados | Alta | Done (prod) | Arquitectura base |
| 2.2 | Generación carné QR | Media | To Do | DocType Socio |

### Épica 3: Motor de facturación y grupo familiar

| ID | Tarea | Prioridad | Estado | Dependencias |
|----|-------|-----------|--------|--------------|
| 3.1 | Esquema tarifario (Activo $31.000, Menor $28.500, Adherente $19.500, Jubilado $5.500) | Alta | Done (prod) | DocType Socio |
| 3.2 | Matriz de descuentos y regla 18–21 años | Media | To Do | Esquema tarifario |
| 3.3 | Migración / conciliación cobranzas históricas agosto 2026 (CSV→PE, cutoff 31/08) | Alta | Done (prod 04/09) | Motor cobranza + mora |

### Épica 4: Integración bancaria Supervielle / Cobrand

| ID | Tarea | Prioridad | Estado | Dependencias |
|----|-------|-----------|--------|--------------|
| 4.1 | DocType Configuración e integración API Checkout | Crítica | In Progress | Motor facturación |
| 4.2 | Webhooks/Polling de cobros y conciliación | Alta | To Do | API Checkout |

### Épica 5: Portal de autogestión y operatoria de Secretaría

| ID | Tarea | Prioridad | Estado | Dependencias |
|----|-------|-----------|--------|--------------|
| 5.1 | Caja diaria y rendición actividades (Club Echagüe) | Media | To Do | Conciliación bancaria |

> **Nota técnica (repo):** el backlog detallado con specs SDD vive en `club_management/specs/backlog_implementacion.md`. Esta sección es la vista ejecutiva para el PM AI; Cursor debe mantener coherencia entre ambos al actualizar estados.

---

## Estructura estándar del DevLog diario

**Cursor AI** debe completar una entrada al finalizar cada sesión de código para mantener la sincronización con el PM AI.

| Campo | Detalle / registro |
|-------|-------------------|
| **Fecha** | YYYY-MM-DD |
| **Módulo / DocType** | Especificar el componente afectado |
| **Tareas completadas** | Listado de funcionalidades implementadas o bugs resueltos |
| **Cambios de schema / API** | Nuevos campos en DocTypes o endpoints modificados |
| **Blockers / dudas** | Impedimentos técnicos o consultas para el PM AI |
| **Próximo backlog sugerido** | Tareas recomendadas para la siguiente sesión |

### Entradas DevLog

<!-- Cursor AI: agregar nuevas entradas arriba de esta línea (más reciente primero) -->

#### 2026-09-04 — Outliers cerrados + commit/deploy + skill carga masiva

| Campo | Contenido |
|-------|-----------|
| **Fecha** | 2026-09-04 |
| **Módulo / DocType** | Cobranza / conciliación agosto · skill `carga-masiva-meses` |
| **Tareas completadas** | Outliers: BOXEO 12275 `resuelto_manual`; PATIN 8770 `ignorado_error_cobrador`; CTO COMP VOLEY ESC 12235 `liquidado_a_4000` (SI/PE $4.000 Paid). Limpieza `tmp_*` / `diag_*` / `_tmp_*`. Skill base `.cursor/skills/carga-masiva-meses` para cargar meses con pipeline informe. Commit + push + deploy limpio del paquete pendiente. |
| **Cambios de schema / API** | Sin schema nuevo en este corte (Payment Log puede ir en commit aparte si se incluye). |
| **Blockers / dudas** | Opcional: alias/alta socio **12062**. Supervielle/Cobrand sin doc API. |
| **Próximo backlog sugerido** | 1) Spaces SP-1/SP-2. 2) BL-6 portal. 3) Cobrand/Supervielle con doc. 4) Re-publicar bitácora en Drive. |

#### 2026-09-04 — Cierre migración histórica agosto 2026 (prod)

| Campo | Contenido |
|-------|-----------|
| **Fecha** | 2026-09-04 |
| **Módulo / DocType** | Cobranza / migración (`purge_historical_data_pre_september`, `cobranzas_bulk_importer`, `conciliacion_migracion_agosto`, `reparar_cierre_migracion_agosto`, `alinear_pe_monto_distinto`) · Desk Secretaría · Pagos por equipo · Mora |
| **Tareas completadas** | **Migración histórica pre-septiembre dada por cerrada en prod.** Purga + reimputación CSV `cobranzas_bulk_erp_agosto_2026.csv` (2562 filas / **$52.115.308**). Hotfix Desk Secretaría (sidebar + `scheduler_postgres` + assets). Alineación **Pagos por equipo** (incl. Superior B / Basquet Amarillo). Conciliación CSV↔PE INF: faltantes reales bajaron a **1** (`socio_no_encontrado` **12062** Adherente $19.500, sin alias). Alias padrón **12009→9484**, **11755→3838** reimputados. Adelantos **09/2026** facturados/aplicados. Limpieza **52** moras residuales huérfanas (~$242k) vía CN. Alineación **414→3** `pe_monto_distinto`: 410 `ok_con_mora` (INF base + PE mora del origen), 1 C FED split indebido marcado `ok_exento` (C FED/CTO COMP **no** aplican mora). Outliers cerrados en entrada DevLog posterior del mismo día. Specs: `purga_migracion_historica_pre_septiembre.md`, `conciliacion_migracion_agosto.md`, `reparacion_cierre_migracion_agosto.md`. |
| **Cambios de schema / API** | Sin cambios de DocType. Scripts ops/migración + ajuste `liquidacion_equipo` / mapeo Superior B / expand aranceles. |
| **Blockers / dudas** | **Pendiente opcional:** alta/alias de socio **12062**. **Supervielle/Cobrand:** sin doc API. |
| **Próximo backlog sugerido** | 1) Spaces SP-1/SP-2. 2) BL-6 portal post-alta. 3) Publicar bitácora en Drive. |

#### 2026-09-01 — Prod: apply cobranza agosto + deuda septiembre + fix scheduler

| Campo | Contenido |
|-------|-----------|
| **Fecha** | 2026-09-01 |
| **Módulo / DocType** | Cobranza (`bulk_payments`, pipeline `APPLY_PROD`) · `Club Settings` · Scheduler Frappe · `Sales Invoice` / `Socio` |
| **Tareas completadas** | **Apply prod** informe `Cobranza 01 a 28-08.xlsx`: prep-only real (477 cargos CTO, ~489 facturas, 6 refacturas) + **apply** **1.458** Payment Entries; **~26 filas manuales** pendientes (8 discordantes + 17 socio no encontrado + 1 fecha inválida). **Deuda septiembre 2026** emitida manualmente en prod: **936** facturas mensuales + **1** complemento aranceles; 20 socios omitidos. **Diagnóstico scheduler:** jobs diarios congelados desde **19/06/2026** (`TypeError`: comparación datetime naive vs aware en `ScheduledJobType.is_event_due` por `last_execution` `timestamptz` en PostgreSQL). **Fix prod:** `ALTER` columna a `timestamp without time zone` + hotfix `scheduler_postgres.py` + hooks. Commits app: `e09ee1f` (pipeline APPLY_PROD), `6187e92`, `5b0152b` (refactura PE skip). |
| **Cambios de schema / API** | **DB prod (ops):** `tabScheduled Job Type.last_execution` → `timestamp without time zone`. **Código (sin deploy formal aún):** `club_management/integrations/scheduler_postgres.py`, hooks `before_job`/`before_request`. Sin cambios de DocType. |
| **Blockers / dudas** | **Cierre manual ~26 filas** cobranza agosto — ver `docs/club/cobranza-informe-manual-prod.md`. **Deploy git limpio** del parche scheduler + pipeline (hoy hotfix vía `docker cp`). **Supervielle/Cobrand:** sin doc API. Confirmar en Desk que scheduler encola jobs tras reinicio (monitorizar `Scheduled Job Log` el 02/09). |
| **Próximo backlog sugerido** | 1) Commit + push + deploy `scheduler_postgres.py`. 2) Cierre manual filas cobranza agosto en Desk. 3) Verificar 20 socios omitidos deuda 09/2026. 4) Spaces SP-1/SP-2. 5) BL-6 portal post-alta. |

#### 2026-09-01 — Bitácora + canal PM + carga masiva cobranzas (local)

| Campo | Contenido |
|-------|-----------|
| **Fecha** | 2026-09-01 |
| **Módulo / DocType** | `docs/club/bitacora-de-desarrollo.md` · Cobranza (`bulk_payments`, `Club Settings`, `Socio`) · Módulo Spaces |
| **Tareas completadas** | Estructura de **Bitácora de Desarrollo** y skill `bitacora-desarrollo` como canal Cursor ↔ Gemini Spark. Protocolo bidireccional (Pasos 1–3) documentado. **MVP Secretaría + Tesorería + portal alta familiar** operativos en prod (go-live 19/08). Motor cobranza mensual/manual, mora 10/20, bonificaciones y alta sin pago online. **Sesión operativa 01/09:** apply masivo informe Excel cobranzas en `dev.localhost` (restore prod); discordantes **168 → 10**; commit app `5ca6a85` (carga masiva, mora, scripts). Módulo **Spaces** commiteado (planilla Desk, FeBAMBA); deploy prod a verificar. |
| **Cambios de schema / API** | Sin cambios de schema en esta sesión de bitácora. Cobranza: servicios `bulk_payments.run`, cruce `informe_concepto_cobranza.py`, parches facturas cuota impagas (~795 líneas) + sync PLE (~181). Landing: cuotas publicadas en web (`6befe4b`). |
| **Blockers / dudas** | **Supervielle/Cobrand:** wrapper legacy; sin Payment Log ni doc API — checkout online no operativo (SIRO retirado). **Prod datos:** 10 filas discordantes cuota Menor — corrección **manual en prod** (no apply automático); ver `cobranzas_discordantes_v19.xlsx`. **Deploy:** `5ca6a85` ahead 3 sin push; validar HEAD Hetzner. **PM:** confirmar si webhook vs polling para 4.2 cuando llegue doc banco. |
| **Próximo backlog sugerido** | 1) Push + deploy `5ca6a85` tras smoke. 2) Cierre manual 10 discordantes en prod. 3) Spaces SP-1 (FMV) + SP-2 (Excel ligas) + smoke Coordinación. 4) BL-6 portal inscripción post-alta. 5) Publicar esta bitácora en Drive (carpeta ERP Clubes) para rutina Gemini 09:00 ART. |

---

---

## Directivas de PM AI (Gemini Spark)

Esta sección contiene las definiciones estratégicas que guían el desarrollo.

### Prioridades actuales

1. ~~Cierre migración / cobranza histórica agosto 2026~~ — **Done prod 04/09** (quedan opcionales: socio 12062 + 3 outliers manuales).
2. Commit + push + deploy limpio del paquete scripts migración/conciliación/mora (+ `scheduler_postgres` si aún no está en git limpio).
3. Spaces: sync FMV + import Excel ligas (SP-1 / SP-2) y validación Coordinación.
4. Estabilización núcleo socios (BL-6 inscripción portal post-alta).
5. Revisar socios omitidos de deuda septiembre 2026 (si el club aún lo pide).
6. Integración Supervielle/Cobrand cuando exista documentación de API.

### Reglas de negocio

- Todos los movimientos financieros deben estar vinculados a un socio.
- La validación de cobros mediante la API de Supervielle/Cobrand es mandatoria **antes de emitir recibos automáticos online**; cobranza Desk manual sigue operativa.
- SIRO no forma parte del proyecto.

### Criterios de aceptación técnicos

- El código debe seguir las convenciones de Frappe Framework (hooks, controllers, patches).
- Toda nueva funcionalidad debe ser compatible con la arquitectura basada en Docker.
- Los esquemas de base de datos deben ser optimizados para PostgreSQL.

---

## Ejemplo de entrada DevLog (referencia)

A continuación, se presenta un ejemplo de cómo debe lucir un registro completo:

### Registro de sesión

| Campo | Contenido |
|-------|-----------|
| **Fecha** | 24 de Mayo de 2024 |
| **Módulo / DocType** | Club Member / Payment Integration |
| **Tareas completadas** | Creación del script de conexión inicial con el endpoint de Cobros+ de Banco Supervielle. Ajuste en el controlador de Member para validar estados de deuda. |
| **Cambios de schema / API** | Añadido campo `supervielle_token` al DocType de configuración. Nuevo endpoint `api/method/club_erp.integrations.supervielle.sync_payments`. |
| **Blockers / dudas** | Se requiere confirmación sobre la frecuencia de sincronización (webhook vs. polling) permitida por el Banco. |
| **Próximo backlog sugerido** | Mapeo de respuestas de error de la API del banco a mensajes de usuario en ERPNext. |

---

## Protocolo de sincronización bidireccional

| Paso | Actor | Acción |
|------|-------|--------|
| **1** | Cursor AI | Al **iniciar** sesión: leer prioridades del Backlog y directivas del PM en este documento (y `sync-pm-ai.md` si existe corte reciente). |
| **2** | Cursor AI | Al **finalizar** sesión: registrar en el DevLog diario las tareas completadas, cambios de schema/API, blockers y dudas; actualizar estados del Backlog maestro si corresponde. |
| **3** | PM AI (Gemini Spark) | En la rutina diaria automatizada (09:00 ART L–V): procesar el DevLog, actualizar estados en el Backlog y formular las especificaciones técnicas del siguiente sprint diario. |

**Publicación en Drive:** subir `docs/club/bitacora-de-desarrollo.md` a la [carpeta ERP Clubes](https://drive.google.com/drive/folders/1KAvGKTnyjkZ_RDjwyxe_c6E3teS0RWtQ) antes del briefing **09:00 ART L–V** (manual desde el explorador de Drive o el método que acuerde el PO con Gemini).

Ver también: `docs/club/sync-pm-ai-protocol.md` (corte operativo complementario en `sync-pm-ai.md`).
