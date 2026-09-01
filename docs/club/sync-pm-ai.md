# Sync estado — PM AI (SICLUB / ICDPE Pedro Echagüe)

**Corte:** 2026-09-01  
**Audiencia:** Gemini Spark (PM AI) + Francisco (PO).  
**Publicación:** `./scripts/sync-pm-ai-to-drive.sh` → Google Drive, carpeta **Sistema de Gestion - ERP CLUBES** (antes de 09:00 ART L–V). Config: [`example.sync-pm-ai.env`](example.sync-pm-ai.env).  
**Protocolo:** [`sync-pm-ai-protocol.md`](sync-pm-ai-protocol.md) · Regla Cursor: `.cursor/rules/sync-pm-ai.mdc`  
**Fuentes:** código en `frappe-club-managment` rama `mvp/secretaria-2026-06`, specs SDD, landing Vercel, docs de infra.  
**No es un plan de trabajo nuevo:** refleja lo que el código y las specs dicen hoy.

---

## Flujo de sincronización (referencia)

```text
Cursor AI ──genera sync-pm-ai.md──► Google Drive ──lee──► Gemini Spark (09:00 ART)
     ▲                              + emails Supervielle         │
     └──────── prompt de sesión ◄── briefing + tareas ◄───────────┘
                              Francisco (PO)
```

---

## Cómo leer este documento


| Semáforo          | Significado                                                                                                         |
| ----------------- | ------------------------------------------------------------------------------------------------------------------- |
| **Done (prod)**   | En Hetzner (`gestion.icdpedroechague.com.ar`) y usable por Secretaría / Tesorería.                                  |
| **Done (código)** | Implementado con spec + tests; en `origin/mvp/secretaria-2026-06` o working tree local. **Puede no estar en prod.** |
| **In Progress**   | Código local sucio, untracked o stash; no listo para deploy.                                                        |
| **Backlog**       | Spec existe o está acordada; no hay implementación de producto.                                                     |


**Repos**


| Repo                                  | Rol                          | HEAD relevante (2026-08-28)                  |
| ------------------------------------- | ---------------------------- | -------------------------------------------- |
| `fblasco1/frappe-club-managment`      | App Frappe `club_management` | `mvp/secretaria-2026-06` → `5ca6a85` (01/09, **ahead 3 sin push**) |
| `club-manager-infra`                  | Docker / Compose / Hetzner   | entorno de deploy                            |
| `fblasco1/pedro-echague-landing-page` | Wizard público Vercel        | `main` → `6befe4b`                           |


**URLs**

- Desk / gestión: [https://gestion.icdpedroechague.com.ar](https://gestion.icdpedroechague.com.ar)  
- Alta pública: [https://www.icdpedroechague.com.ar/asociate/inscripcion](https://www.icdpedroechague.com.ar/asociate/inscripcion)

**Gap local → prod (importante)**

- **01/09:** Commit `5ca6a85` — carga masiva cobranzas (informe Excel, mora, scripts). **Push y deploy a Hetzner pendientes** (timeout red desde WSL al cerrar el día).
- Los ajustes de **datos** del informe `Cobranza 01 a 28-08` se validaron solo en **`dev.localhost`** (restore prod). **No** replicar apply masivo en prod sin decisión explícita.
- Go-live portal + Tesorería documentado el **19/08** en commit Frappe `43b226f`.
- Módulo **Spaces** commiteado (`15a22bc`, `8f2d308`); verificar si ya está en Hetzner.

---

## 0. Hilo operativo — carga masiva cobranzas (01/09/2026)

**Contexto:** Tarea operativa que **pausó el backlog planificado** (Spaces SP-1/SP-2, BL-6, etc.) durante el día.

### Hecho hoy (local `dev.localhost`)

| Entregable | Detalle |
| ---------- | ------- |
| Motor apply | `bulk_payments.run` + cruce concepto (`informe_concepto_cobranza.py`) + mora al cobro |
| Tarifas ago 2026 | Activo $31k, Menor $28,5k, Adherente $19,5k, Jubilado $5,5k, hermanos |
| Parche facturas | ~795 líneas cuota impagas + sync PLE (~181) |
| Informe discordantes | **168 → 10** filas (`cobranzas_discordantes_v19.xlsx` en `backups/prod-to-local/imports/`) |
| Refacturas puntuales | Boxeo 3 clases (11844), Gimnasia 2 clases (4 socias), Pre-Mini B U9 → Minibasquet |
| Commit app | `5ca6a85` — `feat(cobranza): carga masiva informe Excel, mora y scripts de ajuste local` |

### Pendiente en producción (datos, manual)

**10 discordantes** de cuota social Menor — corrección **manual en prod** (no apply automático):

- Patrones: mora agosto ($925), socio 10782 (períodos futuros 09–12/2026), casos atípicos (−$480, −$4.425, mezcla Activo/Menor).
- Archivo de referencia local: `backups/prod-to-local/imports/cobranzas_discordantes_v19.xlsx`.

### Deploy código pendiente

```bash
cd development/frappe-bench/apps/club_management
git push -u origin mvp/secretaria-2026-06

cd /ruta/club_manager_infra
./scripts/prod/prepare-ssh-key.sh
./scripts/prod/deploy-club-management.sh
```

Solo migra **código** (+ `bench migrate`); no los PE ni parches de datos del bench local.

---

## 0.1 Agenda mañana (2026-09-02) — ruta PM

Orden sugerido para la sesión con Francisco:

| # | Tema | Objetivo | Referencia |
| - | ---- | -------- | ---------- |
| **1** | **Deploy cobranza a prod** | Push `5ca6a85` + `deploy-club-management.sh`; smoke Desk Secretaría | §0 arriba; skill `prod-hetzner-deploy` |
| **2** | **Informes de la cobradora** | Inventariar qué puede generar el sistema vs. Excel manual del informe | `scripts/informe_cobranzas.py`, `bulk_payments.run`, `_build_discordantes_xlsx.py`, panel Secretaría / listados SI |
| **3** | **Retomar backlog** | Volver al plan pre-operativo (Spaces, portal, pasarela) | `club_management/specs/backlog_implementacion.md`, §2 P0–P4 abajo |
| **4** | **Cierre operativo ago** | Corregir en prod los **10 discordantes** Menor (manual) | `cobranzas_discordantes_v19.xlsx` |

**Prompt sugerido para Cursor (mañana):**

> Revisar informes disponibles para la cobradora (Desk + scripts de informe/apply). Luego retomar backlog según `backlog_implementacion.md` y prioridades §2. Si aún no se hizo: deploy `5ca6a85` a Hetzner.

---



## 1. Avances reales en código (Cursor AI)



### 1.1 Arquitectura base — Done (prod)

Stack operativo: Frappe v16 + ERPNext + PostgreSQL v14 + app `club_management`. Sin parches a `apps/frappe` ni `apps/erpnext` (extensión por `hooks.py` y overrides de métodos).


| Pieza                  | Estado      | Notas                                                                       |
| ---------------------- | ----------- | --------------------------------------------------------------------------- |
| Módulos Frappe         | Done        | `Members`, `Activities`, `Finance`, `Spaces` (este último solo local)       |
| Roles                  | Done        | `Secretaria`, `Tesoreria`, `Socio`; `Coordinacion` sembrado en Spaces local |
| Workspaces Desk        | Done (prod) | Secretaría (KPI + listas), Actividades, Tesorería                           |
| Club Settings (Single) | Done        | Calendario de deuda, cuotas por categoría, flags de facturación             |
| Parches PostgreSQL     | Done        | Payment Ledger / Number Cards (ERPNext asume MariaDB)                       |
| Scheduler diario       | Done        | Generar deuda día 1 · recargo 2.º vencimiento · moroso automático           |
| i18n / marca           | Done        | Login SICLUB, UI Tesorería en español                                       |
| Infra prod             | Done        | Hetzner CX23 (2 vCPU / 4 GB / 40 GB) — margen justito; monitorear RAM/disco |


**In Progress (arquitectura)**

- Cron FeBAMBA 08:00/20:00 ART está en `hooks.py` local (módulo Spaces). No corre en prod hasta migrar Spaces.  
- HRMS declarado en `apps.json` de infra; **no instalado** en el bench. Liquidación nativa de sueldos = fase posterior (GF-HRMS).



### 1.2 Gestión de socios — Done (prod) vs In Progress

**DocTypes Done**

`Socio`, `Tutor No Socio`, `Grupo Familiar` (+ children `Miembro` / `Titular`), `Solicitud Asociacion`, `Solicitud Grupo Familiar`, `Beca Socio`, `Cargo Socio`, `Bonificacion Arancel`, `Club Settings`.


| Flujo                                                                          | Estado                                                  | Evidencia                                        |
| ------------------------------------------------------------------------------ | ------------------------------------------------------- | ------------------------------------------------ |
| Alta / edición Secretaría (menor con tutor, nº socio opcional)                 | **Done (prod)**                                         | `socio_alta_edicion_secretaria.md`               |
| Inscripción Desk (cascada actividad → grupo → equipo) + baja                   | **Done (prod)**                                         | `inscripcion_gestion_desk.md`                    |
| Roster en Equipo Actividad                                                     | **Done (prod)**                                         | `equipo_actividad_form_roster.md`                |
| Dashboard socios + KPI Secretaría                                              | **Done (prod)**                                         | ~1091+ socios en smoke 19/08                     |
| Beca al socio (descuenta al facturar)                                          | **Done (prod)**                                         | BL-1                                             |
| Recibo térmico ESC/POS al cobrar                                               | **Done (prod)**                                         | BL-7                                             |
| Fecha de cobro en diálogo Desk                                                 | **Done (prod)**                                         | BL-8                                             |
| Alta post-baja + cascada de inscripciones                                      | **Done (prod)**                                         | `4dfe560`                                        |
| Adjuntos vigentes (1 File privado por campo; pisa al renovar)                  | **Done (prod)**                                         | `e94ea02`                                        |
| Wizard alta familiar (adulto / menor+tutor / cotitular / Adherente / Jubilado) | **Done (prod)**                                         | Landing `d2cd386`+; Frappe `9385c1b` / `43b226f` |
| Alta pública **sin cobro online**                                              | **Done (prod)**                                         | Secretaría cierra con Activar / Omitir pago      |
| Validación server-side Adherente/Jubilado                                      | **Done (código + prod 19/08)**                          | Edad, whitelist deportes, comprobante haberes    |
| Valores de cuota social publicados en la web                                   | **Done (código** `eb3e4f5` **/ landing** `6befe4b`**)** | Confirmar deploy Hetzner + Vercel Production     |


**In Progress / no cerrado**


| Tema                                                                        | Estado               | Qué falta                                                                     |
| --------------------------------------------------------------------------- | -------------------- | ----------------------------------------------------------------------------- |
| BL-6 Portal socio **inscripción post-alta** (logueado)                      | Backlog              | Distinto del wizard de alta. Spec `portal_socio_inscripcion.md`.              |
| Grupo familiar — reglas Desk avanzadas (hermanos, cotitularidad, descuento) | Parcial              | El alta pública familiar está Done; invariantes Desk + descuento hermanos no. |
| Job **Vitalicio** (25 años desde `fecha_alta`, cuota 0)                     | Backlog              | `socios_categoria_validacion.md`                                              |
| Smoke humano Adherente + Jubilado en prod                                   | Pendiente de negocio | 1 alta de prueba cada uno → Desk (Pendiente, adjuntos privados)               |
| Filtro tendencia KPI / pagos del día / liquidación por inscripción          | Stash `stash@{0}`    | No bloquea operación; no mezclar con post-baja (eso ya está en prod)          |


**Jerarquía de actividades (Done prod)**

`Actividad` → `Grupo Actividad` → `Equipo Actividad` → `Inscripcion Actividad`. Básquet unificado (1 actividad, 6 grupos, CC único `Deportes - Basquet - ICDPE`). Vóley unificado a `VOLEY/ESCUELA` y `VOLEY/FEDERADO`. Panel de gestión + aranceles inline + edición/deshabilitar nodos. Arancel editable en equipo (`3d68c07`) — confirmar si Hetzner tiene este commit.

### 1.3 Motor de tarifas y cobranza — Done (prod)

No hay un “motor” aparte: es **Club Settings + ítems ERPNext (**`ICDPE-`***) + Subscription + jobs**.

**Calendario (defaults ICDPE)**


| Evento                       | Día                                | Comportamiento                                                                          |
| ---------------------------- | ---------------------------------- | --------------------------------------------------------------------------------------- |
| Emisión de deuda             | 1                                  | Job `generar_deuda_mensual` → 1 Sales Invoice / socio / período `MM/YYYY` (idempotente) |
| 1.er vencimiento             | 10                                 | Sin mora si se paga hasta ese día inclusive                                             |
| 2.º vencimiento al **cobro** | **20** (regla vigente de producto) | +10 % sobre cuota/arancel                                                               |
| Después del 2.º vencimiento  | —                                  | +15 % (10+5) sobre el valor del mes de pago; **no** se multiplica por meses de atraso   |
| Job legado 2.º vencimiento   | Último día del mes (Club Settings) | Recargo automático histórico; convive con mora al cobro                                 |


**Qué entra en la factura mensual:** cuota social (por categoría) + aranceles de inscripciones activas + cargos extra recurrentes (si flags). Vitalicio / Baja / Suspendido no facturan cuota.

**Qué no lleva mora al cobro:** cuotas federativas y cargos extra (multas, viajes, etc.). Commit `dd908e4`.

**Otras piezas Done**

- Catálogo canónico de aranceles (`ARANCEL MENSUAL - …`, ítems `ICDPE-BASQUET-*`, `ICDPE-VOLEY-*`, …); legacy `ICDPE-ARANCEL-MENSUAL-*` a retirar.  
- Arancel resoluble en grupo/tira aunque no haya equipo (`wip/catalogo-item-groups`, mergeado en espíritu al MVP).  
- Cargo extra: conceptos por actividad + auto-factura.  
- Bonificación de arancel **al registrar cobro** (DocType `Bonificacion Arancel`, credit note idempotente) — no es Beca.  
- CC: arancel → centro de la actividad; cuota social → CC **Cuotas Sociales** (GF-9, en prod con Tesorería).  
- Cobro multi-factura / medios mixtos y cancelación de SI impaga en PostgreSQL: resueltos en código (bugs B1–B3 cerrados).  
- Tesorería: PI en Borrador (Secretaría) → Submit (Tesorería); P&L + cash flow + liquidez 5 días + factores mora 10/20 en proyección (`b4ed98b`, `fba539e`, `131aec9`).

**In Progress:** inventario de ítems de ingresos (`ops/inventory_ingresos_pillars.py` untracked) — herramienta ops, no producto.

### 1.4 Pasarela de pago — **no operativa en prod**

Decisión de producto **2026-08: SIRO retirado**. Canal online futuro = **Cobrand + Banco Supervielle**.


| Pieza                                       | Estado               | Qué implica                                                                                                          |
| ------------------------------------------- | -------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Alta pública                                | Done                 | **Sin** gateway; Secretaría cobra offline y activa (`alta_sin_pago_online.md`)                                       |
| Wrapper Cobros Plus                         | Código legado (mayo) | `integrations/supervielle_api.py` (hash SHA-256) + `supervielle_webhook.py` (ack + Payment Entry si encuentra la SI) |
| Specs                                       | Existen              | `supervielle_cobros_plus_api.md`, `supervielle_cobros_plus_webhook.md`                                               |
| DocType `Cobros Plus Settings`              | Existe               | No hay flujo de botón “Pagar” en portal de producción                                                                |
| **Payment Log** (IDs inmutables)            | **No existe**        | El webhook busca la SI por `reference`; no persiste ID de gateway en un log dedicado                                 |
| Documentación API Cobrand                   | **No cargada**       | Regla: **no inventar endpoints**                                                                                     |
| Cobro alquiler Spaces (ítems `ICDPE-ALQ-*`) | Backlog              | `spaces_fases_futuras.md` — fase 2 Cobrand                                                                           |


**Conclusión para el PM:** cobranza **operativa = Desk + Payment Entry**. La pasarela es spike técnico incompleto, bloqueada por documentación de API. No planificar go-live de cobro online en el próximo sprint de Spaces.

### 1.5 Gestión de Espacios — Done (código local) / **In Progress de release**

MVP+ de ocupación Desk **cerrado en local el 27/08** (~74 tests en `club_management.spaces.`*). **Working tree untracked; no deployable hasta commit + migrate.**

**Done (código local)**


| ID     | Entregable                                                                                                        |
| ------ | ----------------------------------------------------------------------------------------------------------------- |
| SP-MVP | DocTypes `Espacio`, `Horario Entrenamiento`, `Reserva Espacio`, `Excepcion Horario Dia`, `Suspension Reserva Dia` |
| SP-MVP | Motor de solapes `availability.py`                                                                                |
| SP-MVP | Alquiler externo Temporal / Recurrente (**sin** factura ni cobro online)                                          |
| SP-MVP | Planilla Desk `/desk/ocupacion-espacios` (08:00–04:00, 6 tipos, orden fijo de columnas)                           |
| SP-MVP | Import CSV grilla L–V y sábado + eventos sociales (cenas, vitalicios)                                             |
| SP-MVP | Fixtures FeBAMBA GES (JSON + botón + cron opcional)                                                               |
| SP-MVP | Superposición visible + selector; reubicar/suspender entrenamiento o reserva **solo ese día**                     |
| SP-MVP | Rol `Coordinacion` + workspace Espacios                                                                           |


**In Progress (Spaces, antes de reservas online)**


| ID          | Prioridad      | Qué                                                                              |
| ----------- | -------------- | -------------------------------------------------------------------------------- |
| **Release** | Alta operativa | Commit, migrate, smoke Coordinación, **deploy Hetzner**                          |
| **SP-1**    | Alta           | Sync **FMV (Vóley)** — sin conector; falta definir fuente (API / Excel / export) |
| **SP-2**    | Alta           | Import **Excel de ligas** (preview + upsert idempotente)                         |


---



## 2. Nuevas prioridades de implementación

**Corte 01/09:** La prioridad **P0 del día siguiente** es cerrar deploy de cobranza + informes cobradora + retomar backlog (ver **§0.1**). Lo siguiente resume el plan vigente al 28/08, **reanudable** una vez cerrado el hilo operativo.

Orden acordado al 28/08 (el backlog de julio — “deploy GF primero” — **quedó cerrado**: Tesorería ya está en prod).

### P0 — Mañana 02/09 (post-operativo cobranzas)

1. **Push + deploy** commit `5ca6a85` (carga masiva cobranzas) → Hetzner.
2. **Sesión informes cobradora** — qué reportes existen / faltan vs. Excel mensual.
3. **10 discordantes Menor** en prod (manual).
4. **Retomar** ítem #1 del P0 histórico: verificar HEAD Hetzner y alinear si falta.

### P0 histórico — Cerrar lo que ya opera / no dejar código huérfano

1. **Verificar HEAD real en Hetzner** (`43b226f` vs `3d68c07`) y alinear si falta cuota-en-web / arancel-en-equipo.
2. **Smoke humano** wizard: 1 Adherente + 1 Jubilado de prueba → Desk.
3. **Commit + deploy Spaces MVP** cuando Coordinación valide la planilla en dev (sin esto, 67 archivos se pierden o divergen).



### P1 — Spaces: datos reales (bloquea uso diario de Coordinación)

1. **SP-1 FMV Vóley** (adaptador federativo, mismo contrato que FeBAMBA).
2. **SP-2 Excel ligas** (plantilla acordada con Coordinación).
3. Validación conjunta un viernes “difícil” (cena vitalicios + partido FeBAMBA + superposición).



### P2 — Spaces: operación diaria (sprint `spaces_sprint_gestion.md`)

Orden de épicas ya escrito en la spec (no adelantar cobro online):

1. Épica 3 — carga Excel/CSV (parcialmente hecha vía `import_horarios`).
2. Fixtures partidos (FeBAMBA Done; FMV/Excel = SP-1/SP-2).
3. Épica 2 — disponibilidad incluyendo estados que **bloquean**.
4. Épica 1 — reservas online socio **y** externo + PDF transferencia + cola Coordinación.
5. Épica 4 — PDF/Excel del día por **email a coordinador/es** (ellos replican a WhatsApp de CD; **sin bot WhatsApp**).



### P3 — Portal socio y familia (después de Spaces operativo o en paralelo de frontend)


| Ítem                                                    | Prioridad | Notas                                                              |
| ------------------------------------------------------- | --------- | ------------------------------------------------------------------ |
| BL-6 Inscripción a actividades **después** de ser socio | Media     | Vercel + token; Secretaría sigue asignando tira/equipo             |
| Grupo familiar Desk (hermanos, descuentos)              | Media     | Spec `grupo_familiar_minimo.md` / `socios_categoria_validacion.md` |
| Job Vitalicio                                           | Media     | No bloquea Secretaría hoy                                          |




### P4 — Segundo plano (no subir de prioridad sin decisión de CD)


| Ítem                                                                    | Por qué bajó                                  |
| ----------------------------------------------------------------------- | --------------------------------------------- |
| Cobrand / Supervielle en portal de alta                                 | Alta pública ya opera sin pago; falta doc API |
| Cobro alquiler Spaces (SP-6)                                            | Fase 2 de Spaces; depende del mismo gateway   |
| Portal socio reserva espacios (SP-7)                                    | Después de Épica 1 Desk/token                 |
| GF-HRMS / liquidación sueldos                                           | App no instalada; fuera de fase               |
| BL-14/15/16 (tendencia KPI, pagos del día, liquidación por inscripción) | Stash; no bloquean                            |
| Conciliación bancaria automática                                        | Fuera de GF                                   |
| Integración WhatsApp CD                                                 | Decisión cerrada: **fuera de alcance**        |


**Qué pasó al frente desde julio:** Spaces (ocupación real del club) y cierre del portal de **alta**. Tesorería dejó de ser el cuello de botella.  
**Qué quedó atrás:** pasarela online, BL-6, Vitalicio, HRMS.

---



## 3. Cambios en reglas de negocio o arquitectura



### 3.1 Cobranza y club (cerrados)


| Cambio                  | Antes                                                | Ahora                                                                                                        |
| ----------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Canal online            | Specs/código hablaban de SIRO / Cobros Plus          | **SIRO no forma parte del proyecto.** Online = Cobrand + Banco Supervielle cuando exista doc API.            |
| Alta pública            | Diseño original con pago stub / gateway              | **Sin cobro online** hasta gateway; Secretaría activa en Desk.                                               |
| Mora al cobro           | Recargo lineal o job de fin de mes como única verdad | **Dos tramos al cobro:** 0 % / +10 % (post día 10 hasta día 20) / +15 % después. No se multiplica por meses. |
| Base de mora            | Toda la factura                                      | Solo **cuota social + arancel**. No federativas ni cargos extra.                                             |
| Básquet                 | 3 actividades legacy (Masc/Fem/Escuelita)            | 1 actividad **Basquet**, 6 grupos, 1 Cost Center.                                                            |
| CC de facturación       | Genérico / inconsistente                             | Arancel → CC de la actividad; cuota → **Cuotas Sociales**.                                                   |
| Egresos                 | Se exploró Purchase Order                            | **Solo Purchase Invoice** Borrador → Aprobación Tesorería.                                                   |
| Documentación del socio | Adjuntos acumulables                                 | Un File **privado** vigente por campo; se pisa al renovar; se clona al Socio.                                |
| Categorías portal       | Activo / Menor                                       | + **Adherente** (whitelist Fitness/Funcional/Yoga/Crossfit) y **Jubilado** (comprobante de haberes).         |




### 3.2 Spaces (decisiones de producto 24/08 — implementar en épicas, no en el MVP Desk)


| Tema             | Decisión                                                                                                                                  |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Ocupación online | Al **generar la solicitud** el slot **bloquea**. Queda **firme** solo con confirmación de Coordinación. Rechazo / vencimiento **libera**. |
| Quién reserva    | Socio (portal) **y** externo (token). Tarifas **distintas y configurables** por canal.                                                    |
| Comprobante      | Fase 1: transferencia + PDF. Fase 2: Cobrand.                                                                                             |
| Reporte a CD     | Email a coordinador/es; **replica humana** a WhatsApp. Sin API WhatsApp.                                                                  |
| Retención de PDF | Pendiente de CD/Tesorería: 24 vs 60 meses en reservas Confirmadas.                                                                        |




### 3.3 Interacción Banco Supervielle / Club Pedro Echagüe

- **Hoy:** ninguna transacción online de socio pasa por Supervielle. El club cobra en Desk.  
- **Código:** cliente hash + webhook guest que intenta saldar una Sales Invoice si el `reference` coincide. **No hay Payment Log; no hay mapeo** `cod_trx`**.**  
- **Landing:** Vercel Production apunta `FRAPPE_BASE_URL` a `gestion.icdpedroechague.com.ar` (túnel UAT apagado).  
- **No inventar** URLs ni payloads Cobrand hasta que el equipo cargue la documentación de API.



### 3.4 Modelo de datos Spaces (nuevo, solo local)

Un **Espacio** es un lugar físico (no es `Actividad`). La ocupación sale de: grilla semanal + reservas Confirmadas + excepciones del día + suspensiones del día. Tipos en planilla: Entrenamiento, Preparación física, Alquiler externo, Alquiler socio, Evento club, Bloqueo.

---



## 4. Blockers y decisiones pendientes



### Bloquean avance técnico


| #   | Blocker                                                       | Dueño                     | Impacto                                                                |
| --- | ------------------------------------------------------------- | ------------------------- | ---------------------------------------------------------------------- |
| B1  | **Doc API Cobrand / Supervielle no cargada**                  | Producto / banco          | Impide botón pagar, Payment Log, webhooks reales, cobro de alquileres. |
| B2  | **Spaces sin commit/push**                                    | Ingeniería                | Riesgo de pérdida; prod sigue sin planilla de ocupación.               |
| B3  | **Fuente FMV (vóley) no definida**                            | Coordinación + ingeniería | SP-1 no se puede spec-cerrar (API vs Excel vs scrape).                 |
| B4  | **Excel oficial de Coordinación** (horarios/alquileres/ligas) | Coordinación              | SP-2 y Épica 3; se prometió “esta semana” el 24/08 — validar si llegó. |
| B5  | HEAD Hetzner no verificado en este corte                      | Ingeniería                | Posible gap de 4 commits (cuota web, arancel equipo).                  |




### Decisiones de producto abiertas


| #   | Pregunta                                                                                                    | Default sugerido si no hay respuesta                                                               |
| --- | ----------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| D1  | ¿Retención de PDF de transferencia en reservas Confirmadas: 24 o 60 meses?                                  | 24 meses operativos; 60 si Tesorería lo marca respaldo contable.                                   |
| D2  | ¿El 2.º vencimiento de Club Settings (último día del mes, job) se alinea al **día 20** de la mora al cobro? | Hay rama divergida `fix/funcional-mora-calendario` (ahead 1 / behind 24). No mezclar sin decisión. |
| D3  | ¿Se extrae BL-14/15/16 del stash a un PR chico o se descarta?                                               | Descartar o cherry-pick; no aplicar el stash entero (pisa post-baja ya en prod).                   |
| D4  | ¿Cuándo se hace UAT de Spaces con Coordinación en dev vs. desplegar ya la planilla de solo lectura?         | No desplegar Épica 1 online antes de SP-1/SP-2 si Coordinación no puede cargar FMV/Excel.          |
| D5  | Job Vitalicio: ¿se programa este trimestre?                                                                 | Puede esperar; cuota 0 ya se resuelve si la categoría existe, falta el job de promoción.           |




### Dependencias externas


| Dependencia                              | Estado                                                   |
| ---------------------------------------- | -------------------------------------------------------- |
| FeBAMBA / `formativas_ges` (JSON GitHub) | Integrado en Spaces local                                |
| FMV (federación vóley)                   | Sin conector                                             |
| Google Sheet CM                          | Solo vía export JSON GES; no hay lectura directa en prod |
| Vercel Production (wizard)               | Live; env apunta a Frappe prod                           |
| CX23 4 GB RAM                            | Adecuado para MVP; no holgado                            |




### Riesgos de proceso

- Working tree sucio además de Spaces: cambios en dashboard de actividades, `hooks.py`, `modules.txt`, `patches.txt`, `portal_alta_grupo_familiar.md`. Empaquetar Spaces en commit(s) **separados** del dashboard.  
- Archivos `ops/_tmp_*.py` y `public/node_modules` **no** deben commitearse.  
- Tests: históricamente la suite completa tuvo fallos en solicitud pública; módulos MVP críticos venían verdes. Re-correr `spaces` + cobranza antes de deploy.

---



## 5. Mapa rápido DocType → estado


| DocType                                                               | Módulo          | Release                           |
| --------------------------------------------------------------------- | --------------- | --------------------------------- |
| Socio, Club Settings, Cargo Socio, Beca Socio, Bonificacion Arancel   | Members         | Prod                              |
| Tutor No Socio, Grupo Familiar, Solicitud Asociación / Grupo Familiar | Members         | Prod (wizard 19/08)               |
| Actividad, Grupo Actividad, Equipo Actividad, Inscripcion Actividad   | Activities      | Prod                              |
| Finance Settings + flujos PI/PE                                       | Finance         | Prod                              |
| Cobros Plus Settings                                                  | Club Management | Código; **no usado en operación** |
| Espacio, Reserva Espacio, Excepción / Suspensión                      | Spaces          | **Solo local**                    |
| Payment Log                                                           | —               | **No existe**                     |


---



## 6. Mensaje corto para pegar al PM (5 líneas)

**01/09:** Se cerró en **local** la carga masiva del informe de cobranzas ago (Excel → imputación con mora y tarifas vigentes): discordantes **168→10**; commit `5ca6a85` listo, **deploy prod pendiente**. Mañana: (1) push/deploy código cobranza, (2) revisar **informes que puede usar la cobradora**, (3) **retomar backlog** (Spaces SP-1/SP-2, BL-6, etc.) pausado por esta tarea operativa. Los 10 casos restantes se corrigen **manual en prod**. Supervielle/Cobrand sigue sin API doc; SIRO retirado.

---



## 7. Referencias (para el PM o el agente de implementación)

- **Cobranza masiva (01/09):** `specs/carga_masiva_cobranzas.md`, `specs/informe_concepto_cobranza.md`, scripts `bulk_payments.py`, `informe_cobranzas.py`
- **Discordantes local v19:** `backups/prod-to-local/imports/cobranzas_discordantes_v19.xlsx` (solo infra local; no en git)
- Backlog vivo: `club_management/specs/backlog_implementacion.md`  
- Spaces: `spaces_modulo_resumen.md`, `spaces_sprint_gestion.md`, `spaces_fases_futuras.md`  
- Cobranza online: `docs/club/cobranza-cobrand-supervielle.md` (este repo infra)  
- Alta sin gateway: `specs/alta_sin_pago_online.md`  
- Mora: `specs/recargos_mora_dos_tramos.md`  
- Portal inscripción post-alta: `specs/portal_socio_inscripcion.md` (BL-6)

