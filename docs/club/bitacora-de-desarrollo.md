# Bitácora de desarrollo — SICLUB / ICDPE Pedro Echagüe

Se genera desde [`sync-pm-ai.md`](sync-pm-ai.md) al cerrar sesión.
Publicada en Google Drive (misma carpeta que el sync PM).

---

## 2026-09-01

### 0. Hilo operativo — carga masiva cobranzas (01/09/2026)

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

### 0.1 Agenda mañana (2026-09-02) — ruta PM

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

### Mensaje PM (§6)

**01/09:** Se cerró en **local** la carga masiva del informe de cobranzas ago (Excel → imputación con mora y tarifas vigentes): discordantes **168→10**; commit `5ca6a85` listo, **deploy prod pendiente**. Mañana: (1) push/deploy código cobranza, (2) revisar **informes que puede usar la cobradora**, (3) **retomar backlog** (Spaces SP-1/SP-2, BL-6, etc.) pausado por esta tarea operativa. Los 10 casos restantes se corrigen **manual en prod**. Supervielle/Cobrand sigue sin API doc; SIRO retirado.

_Actualizado: 2026-09-01 12:27 ART_

---

