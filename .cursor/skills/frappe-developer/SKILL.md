---
name: frappe-developer
description: Crea y modifica DocTypes en Frappe/ERPNext siguiendo el layout de Bench: paquete apps/<app>/<app>/, módulos bajo members/ activities/, JSON+PY+JS para formularios estándar, JSON+PY para child tables. Usar al definir DocTypes, permisos o scripts de formulario en club_management.
---

# Frappe Developer

## Layout Bench (documentación Frappe)

- Carpeta del bench: `apps/club_management/`
- **Paquete Python:** `apps/club_management/club_management/` (`hooks.py`, `modules.txt`, carpetas de módulo).
- DocTypes: **`club_management/<modulo>/doctype/<nombre_snake>/`** (p. ej. `members/doctype/socio/`), alineado con el **Module** en Frappe.

Rutas siempre con **`/`**.

## Archivos por tipo de DocType

### DocType estándar (formulario Desk)

1. **`<nombre>.json`** — metadatos, campos, **`permissions`**
2. **`<nombre>.py`** — `class NombreDocType(Document):`
3. **`<nombre>.js`** — `frappe.ui.form.on('Nombre DocType', { ... })` cuando haya lógica de formulario

### Child DocType (`istable`: 1)

1. **`<nombre>.json`**
2. **`<nombre>.py`**
3. **No** crear **`.js`** esperando formulario propio del child; el marco no lo usa como DocType de escritorio independiente.

### Single, etc.

Igual que estándar si hay form Desk con cliente; si no, basta JSON + PY.

## JSON

- Incluir **`permissions`** mínimo razonable (p. ej. System Manager escritura, **All** lectura si aplica).
- **`module`:** debe existir en **Module Def** / **`modules.txt`**.
- DocType name en JSON = nombre en **PascalCase** / espacios según convención Frappe.

## Python

```python
import frappe
from frappe.model.document import Document

class MiDocType(Document):
    pass
```

Eventos que requieran registro central van también en **`hooks.py`** si procede.

## JavaScript (solo DocTypes con form)

```javascript
frappe.ui.form.on('Mi DocType', {
	refresh(frm) {},
});
```

## Checklist

- [ ] Ruta bajo **`club_management/<modulo>/doctype/...`**, no mezclar con `apps/frappe`.
- [ ] **Child table:** solo `.json` + `.py`
- [ ] **DocPerm** presente y roles de negocio (Secretaria, Socio, …) revisados
- [ ] Nombre en JS = nombre del DocType en Desk
- [ ] `bench migrate` tras cambiar JSON
