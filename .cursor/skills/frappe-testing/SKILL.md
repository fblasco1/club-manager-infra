---
name: frappe-testing
description: Tests Frappe: FrappeTestCase, rutas bajo club_management/<modulo>/doctype y tests/, permisos en whitelist, allow_guest con token, aislamiento entre Socios. Usar al escribir o revisar tests.
---

# Tests en Frappe

## Rutas (Bench)

- Cerca del DocType: `apps/club_management/club_management/<modulo>/doctype/<nombre>/test_<nombre>.py`
- Centralizado: `apps/club_management/club_management/tests/test_<area>.py`
- Usar **`/`** en rutas.

## Base de test

```python
import frappe
from frappe.tests.utils import FrappeTestCase

class TestEjemplo(FrappeTestCase):
    def test_comportamiento_spec(self):
        ...
```

## Qué cubrir

1. **validate / hooks** — datos inválidos → `frappe.throw` / ValidationError.
2. **`@frappe.whitelist()`** — con usuario sin permiso → PermissionError o fallo controlado; con usuario adecuado → éxito. Usar **`frappe.set_user()`** y restaurar.
3. **`allow_guest=True`** — token u otro mecanismo documentado en spec; tests negativos (token malo, documento ajeno).
4. **Aislamiento** — dos **Socio** / usuarios; no filas cruzadas.
5. **Hooks en `hooks.py`** — comportamiento observable desde el test.

## Fixtures

- Insertar con `frappe.get_doc(...).insert()`; confiar en rollback del caso de test cuando aplique.

## Checklist

- [ ] Cobertura alineada al spec
- [ ] Whitelist autenticada + invitados según diseño
- [ ] Aislamiento si la feature es por socio
- [ ] Nada de modificaciones en core
