---
name: club-domain
description: Aplica el dominio de gestión de club/socios en Frappe: memberships, Subscription, familias y hermanos (parent_id/Family), Cost Centers multi-unidad (Sports, Gym, Restaurant, Rentals) e integración SIRO con Payment Log. Usar al diseñar DocTypes, reportes, flujos de pago o de socios/familias.
---

# Dominio club / socios

## Cuándo aplicar

- Al diseñar o extender DocTypes relacionados con socios, membresías, pagos o ingresos.
- Al implementar reportes por unidad (deportes, gimnasio, restaurante, alquileres).
- Al tocar lógica de familias, hermanos o suscripciones.

## Bench y nomenclatura

- DocType de socio en este producto: **`Socio`**. Donde la skill dice **Member** se refiere al concepto de negocio, no a renombrar el DocType sin un sprint dedicado.
- Código bajo el paquete `club_management/<módulo>/` del bench (`apps/club_management/club_management/` relativo al bench). En este repo la copia editable está en **`development/frappe-bench/apps/club_management/`**. Ver **`AGENTS.md`** y **`REPO_LAYOUT.md`**.

---

## Conceptos del dominio

### Socios y membresías

- **Socio** (concepto Member): entidad que tiene suscripciones y puede pertenecer a una familia.
- **Membership:** vinculada a **Subscription**; la lógica de negocio debe usar Subscription como referencia cuando corresponda.
- **Familia / hermanos:** la relación entre hermanos se modela con `parent_id` o un enlace custom a un DocType **Family**. Cualquier regla de “hermanos” debe comprobar este vínculo, no solo coincidencia de apellidos u otros criterios ad hoc.

### Multi-unidad (Cost Centers)

Los ingresos y costes se diferencian por **Cost Center** según la unidad:

- **Sports** (deportes)
- **Gym** (gimnasio)
- **Restaurant** (restaurante)
- **Rentals** (alquileres)

Al crear o enlazar transacciones, reportes o listados por unidad, usar el Cost Center correcto.

### Pagos e integración SIRO

- **Payment Log (o equivalente):** almacenar siempre los IDs de transacción de SIRO para idempotencia y trazabilidad.
- La lógica de pagos debe ser **idempotente**: comprobar si ya existe una transacción con el mismo ID antes de crear o actualizar. Ver también la skill **siro-payments** (y **security-auditor** para inmutabilidad de IDs).

---

## DocTypes y nombres estándar

Usar de forma consistente (ajustar si el proyecto tiene nombres distintos):

- **Socio** – miembro del club (este proyecto ya lo usa como DocType; **Member** es el término de dominio en inglés)
- **Subscription** – suscripción (vinculada a membresías)
- **Family** – familia (para agrupar hermanos)
- **Payment Log** (o el DocType que guarde IDs de transacción SIRO)
- **Cost Center** – estándar Frappe/ERPNext; usar los valores Sports, Gym, Restaurant, Rentals según la unidad

Al proponer nuevos DocTypes, usar PascalCase y **no duplicar** el mismo concepto (en este repo ya existe **Socio**; no añadir un **Member** paralelo salvo migración planificada).

---

## Reglas rápidas

- Hermanos → validar por `parent_id` o link a **Family**.
- Ingresos por unidad → asignar **Cost Center** (Sports, Gym, Restaurant, Rentals).
- Pagos SIRO → guardar ID de transacción en Payment Log; lógica idempotente.
- No exponer datos de un socio a otro; las consultas deben filtrar por el socio/usuario actual (ver **security-auditor**).

---

## Checklist al diseñar una feature de club

- [ ] Memberships enlazadas a Subscription donde corresponda.
- [ ] Lógica de hermanos usa Family o parent_id, no criterios ad hoc.
- [ ] Cost Center correcto en transacciones/reportes por unidad.
- [ ] Pagos SIRO registrados en Payment Log con ID de transacción.
- [ ] Nombres de DocTypes alineados con el resto del proyecto.
