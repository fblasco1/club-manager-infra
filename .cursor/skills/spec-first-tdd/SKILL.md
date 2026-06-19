---
name: spec-first-tdd
description: SDD y TDD en Frappe: specs Given/When/Then en club_management/specs/, tests antes de código, Red-Green-Refactor. Usar al cambiar comportamiento o añadir features en la app custom.
---

# Spec-first y TDD

## Cuándo aplicar

- Antes de nuevos DocTypes, APIs, hooks o JS de formulario.
- Cuando el usuario pida TDD o especificación formal.

## Regla de oro

**No añadir lógica de producción en `.py` o `.js` sin un test que falle primero.**

## Orden

1. **Spec** — `club_management/specs/<tema>.md` en el paquete de la app (en este repo: bajo `development/frappe-bench/apps/club_management/`).
2. **Red** — test que refleja el escenario.
3. **Green** — mínimo código.
4. **Refactor** — mantener verde.

## Ubicación de tests

- Por DocType: `apps/club_management/club_management/<modulo>/doctype/<nombre>/test_<nombre>.py`
- Integración: `apps/club_management/club_management/tests/test_<area>.py`

Ver guías de testing del framework para **`FrappeTestCase`** y rollback entre tests.

## Contexto

- **PostgreSQL v14** si hay SQL crudo.
- **Sin tocar** `frappe` / `erpnext` en el árbol de apps.

## Checklist

- [ ] Spec Given/When/Then actualizado
- [ ] Test existía y fallaba antes del código nuevo
- [ ] Sin campos o hooks “por si acaso”
- [ ] Eventos relevantes coherentes con **`hooks.py`**
