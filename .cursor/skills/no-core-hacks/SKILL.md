---
name: no-core-hacks
description: Refuerza la prohibición de modificar apps/frappe y apps/erpnext; toda customización debe vivir en la app del proyecto. Incluye uso de PostgreSQL v14 y extensión vía hooks y overrides. Usar cuando se proponga cambiar core, escribir SQL o parches, o al revisar dónde colocar código nuevo.
---

# Sin tocar core (No Core Hacks)

## Cuándo aplicar

- Cuando se proponga modificar archivos en `apps/frappe` o `apps/erpnext`.
- Al decidir dónde colocar código nuevo (controladores, hooks, APIs).
- Al escribir raw SQL o revisar migraciones.
- Cuando se mencione “parche”, “override” o “customización de ERPNext/Frappe”.

---

## Regla principal

**No modificar nunca `apps/frappe` ni `apps/erpnext`.** Toda la customización del proyecto debe residir en la **app custom** (p. ej. `apps/club_management`).

---

## Dónde va el código custom

- **DocTypes nuevos:** bajo el **paquete** `apps/club_management/club_management/<módulo>/doctype/` (p. ej. `members/doctype/socio/`). No es obligatorio usar un único `doctype/` en la raíz del paquete.
- **Lógica de negocio:** en controladores (`.py`) de la app custom.
- **Eventos (before_save, on_update, etc.):** implementados en la app custom y **registrados en `hooks.py`** de esa app.
- **Client scripts:** en los `.js` de los DocTypes de la app custom; usar `frappe.ui.form.on('DocType', { ... })`.
- **Overrides de comportamiento:** mediante hooks de Frappe (doc_events, override_doctype_class, etc.) en la app custom, no editando archivos del core.

Rutas: usar siempre `/` (p. ej. `apps/club_management/...`).

---

## Base de datos: PostgreSQL

- El proyecto usa **PostgreSQL v14**.
- Cualquier **raw SQL** (si se usa) debe ser sintaxis **Postgres**, no MariaDB/MySQL.
- Preferir `frappe.get_doc`, `frappe.get_all`, `frappe.db.get_value` antes que SQL directo.
- No usar `frappe.db.commit()` en el flujo normal de una petición; el ciclo de request lo maneja.

---

## Si “hace falta” cambiar core

- **No editar core.** En su lugar:
  - Crear un DocType o módulo en la app custom que extienda o use el estándar.
  - Usar **hooks** (override_doctype_class, doc_events, etc.) para inyectar comportamiento desde la app custom.
  - Si existe un punto de extensión oficial (API, evento), usarlo desde la app custom.
- Si no hay forma de lograr algo sin tocar core, documentar la limitación y proponer una alternativa dentro de la app custom (o un patch documentado y versionado en la app, nunca en el repo de frappe/erpnext).

---

## Checklist antes de añadir código

- [ ] El código nuevo está en la app del proyecto (p. ej. `apps/club_management/`), no en `apps/frappe` ni `apps/erpnext`.
- [ ] Los eventos usados están registrados en `hooks.py` de la app custom.
- [ ] No se ha editado ningún archivo bajo `apps/frappe` o `apps/erpnext`.
- [ ] Cualquier SQL raw usa sintaxis PostgreSQL v14.
- [ ] No se usa `frappe.db.commit()` salvo en tareas largas donde se indique explícitamente.
