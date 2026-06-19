# Subagent Topology — Club Management

Use this file to **decide delegation**. Cursor may not load it automatically; treat it as team documentation.

## When to delegate

- Domain-heavy backend vs Desk UI vs tests vs security vs infra.
- Large changes that would bloat the main thread with file listings and Bench paths.

---

## BackendSubagent

**Scope:** Python under **`apps/club_management/club_management/`** — DocType `*.py`, **`@frappe.whitelist()`**, `hooks.py`, scheduled jobs, `get_doc`/`get_all` queries.

**Delegate when:** new/changed DocType controller, `validar_socio`, Vitalicio scheduling, cuota resolution, hooks.

**Must read:** `.cursor/skills/frappe-developer/SKILL.md`, `.cursor/skills/spec-first-tdd/SKILL.md`, `.cursor/skills/no-core-hacks/SKILL.md`.

**Constraints:** PostgreSQL-compatible SQL; type hints; **never** edit `frappe`/`erpnext` apps.

**Cursor (skill):** `.cursor/skills/club-backend-subagent/SKILL.md` — mencionar `@club-backend-subagent` o abrir la skill al delegar tareas de este alcance.

**Cursor (subagent):** `.cursor/agents/club-backend-subagent.md` — invocar con “usa el subagente club-backend-subagent para …”.

---

## FrontendSubagent

**Scope:** `*.js` en carpetas de DocType, **Workspace** JSON, **Web Form** JSON, definición de **Report** (columnas/filtros).

**Delegate when:** `frappe.ui.form.on`, workspace Secretaría / Club Management, informes “pendientes de validación”.

**Must read:** `.cursor/rules/security.mdc` (XSS), `.cursor/skills/frappe-developer/SKILL.md` para naming de DocType en JS.

**Constraints:** sin `innerHTML` con datos de usuario sin escape; assets versionados en la app, no “solo en Desk” sin JSON en repo.

**Cursor (skill):** `.cursor/skills/club-frontend-subagent/SKILL.md` — mencionar `@club-frontend-subagent` o abrir la skill al delegar tareas de este alcance.

**Cursor (subagent):** `.cursor/agents/club-frontend-subagent.md` — invocar con “usa el subagente club-frontend-subagent para …”.

---

## TestingSubagent

**Scope:** `specs/` y `**/test_*.py` —Given/When/Then, `FrappeTestCase`, fixtures.

**Delegate when:** nuevo spec, tests de permisos, tests `allow_guest`, aislamiento entre Socios.

**Must read:** `.cursor/skills/spec-first-tdd/SKILL.md`, `.cursor/skills/frappe-testing/SKILL.md`.

**Paths (paquete de la app en el bench):**

- `apps/club_management/club_management/<module>/doctype/<name>/test_<name>.py`
- `apps/club_management/club_management/tests/test_<area>.py`

---

## SecuritySubagent

**Scope:** revisión de whitelist, invitados, SIRO, XSS, fugas entre socios.

**Delegate when:** nueva API, pagos, carnet HTML, antes de cerrar sprint sensible.

**Must read:** `.cursor/skills/security-auditor/SKILL.md`, `.cursor/skills/siro-payments/SKILL.md`.

**Output:** informe con secciones Whitelist, Aislamiento, SIRO, XSS (ver skill).

---

## InfraSubagent

**Scope:** repo **club-manager-infra** / **club_manager_infra** — compose, overrides, devcontainer, `example.env`, GitHub Actions de despliegue.

**Delegate when:** compose, variables de entorno, `bench migrate` en CI, troubleshooting contenedores.

**Must read:** `.cursor/skills/infra-docker/SKILL.md`, **`AGENTS.md`**, **`REPO_LAYOUT.md`**. Código de app: `development/frappe-bench/apps/club_management/`.

---

## Parallelización

**Secuencial (mismo feature):** Spec + tests rojos → implementación backend/frontend → migrate/build → auditoría.

**Paralelo (distintos frentes):**

- SecuritySubagent sobre código **ya mergeado** mientras FrontendSubagent trabaja en otra pantalla.
- InfraSubagent ajustando compose mientras TestingSubagent redacta **siguiente** spec (no el mismo ticket sin spec cerrado).

**No paralelizar:** implementación de lógica de negocio antes de existir el test rojo acordado (rompe TDD).
