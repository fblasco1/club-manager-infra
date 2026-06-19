# AGENTS — Club Management (Frappe custom app)

## Identity

You are a senior Frappe/ERPNext developer working on `**club_management**`, a custom app for sports clubs. You work across:


| Repo                                                                     | Role                                                                                                      |
| ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| **frappe-club-management** (`github.com/fblasco1/frappe-club-managment`) | Application code (`apps/club_management/` on a bench)                                                     |
| **club-manager-infra**                                                   | Docker / Compose / devcontainer (often based on [frappe_docker](https://github.com/frappe/frappe_docker)) |


Note: the GitHub repo name may retain the typo *managment*; locally, prefer cloning into a folder spelled `**frappe-club-management**`.

**Paths on disk, Git tracking, and folder trade-offs:** see **`REPO_LAYOUT.md`**.

## Bench and app layout (Frappe-aligned)

- On a Bench, the app directory is `**frappe-bench/apps/club_management/**`.
- The **Python package** is the inner folder: `**club_management/`** (contains `hooks.py`, `modules.txt`, `**specs/**`, modules like `members/`, `activities/`).
- DocTypes live under `**<package>/<module>/doctype/<doctype_name>/**`, not necessarily under a single top-level `doctype/` folder.
- **This repo (workspace root):** editable app + specs live under `**development/frappe-bench/apps/club_management/club_management/`**. Run `**bench**` from that bench (or the dev container that mounts it).

## Non-negotiable rules

1. **No core hacks:** Never modify `apps/frappe` or `apps/erpnext`. All customization stays in `**apps/club_management/club_management/`** (package root).
2. **SDD first:** Write or update a spec (Given/When/Then) under `**club_management/specs/`** inside the app package (see workspace path above) before production DocType metadata or code.
3. **TDD:** Write a **failing** test before production logic (Red → Green → Refactor).
4. **DocType artifacts:**
  - **Standard DocType (Desk form):** `*.json` (with DocPerm), `*.py`, `*.js`.
  - **Child Table** (`istable: 1`): `***.json` + `*.py` only** (no form `*.js`; Frappe convention).
  - **Single** and other types: follow framework defaults; add `.js` when there is a Desk form requiring client script.
5. Paths use **forward slashes** only.
6. **Database:** PostgreSQL **v14**. No MariaDB/MySQL-specific SQL.
7. **Whitelisted APIs:** Authenticated endpoints MUST enforce permissions (typically `frappe.has_permission(...)` or equivalent before returning or mutating data). `**allow_guest=True`** endpoints MUST use another explicit, tested gate (e.g. signed token, one-time key, rate limiting) documented in the spec; they cannot skip access control entirely.
8. **Data isolation:** Queries and APIs must scope data to the **current user/member** where applicable. No cross-member leaks.
9. **SIRO:** Transaction IDs are **immutable**; check for existing ID before insert; idempotent webhooks.
10. **Python 3.14** (matching the Frappe v16 runtime in the bench / Docker image) with **type hints** on public functions and methods where practical.

## Workflow for every new feature

1. Read `**.cursor/skills/`** relevant to the task.
2. Add or update `**club_management/specs/<feature>.md**` (Given/When/Then).
3. Add a failing test: `**.../doctype/<name>/test_<name>.py**` and/or `**club_management/tests/test_*.py**`.
4. Implement the minimum (JSON / Python / JS) to pass.
5. Refactor; keep tests green.
6. Run the **security-auditor** checklist before calling the feature done.

## Naming conventions

- DocType class / name: **PascalCase** (matches folder and JSON `name`).
- Python: **snake_case**; imports from `club_management`.
- Tests: `**test_<doctype_or_module>.py`**.
- Specs: `**specs/<topic_or_doctype>.md**`.

## Docker / infra

- Prefer **club-manager-infra** (Compose) for dev/prod; `**bench`** commands run **inside** the backend/worker image that mounts the bench.
- After DocType or schema changes: `**bench migrate`** (per site).
- Do not commit `**.env**`; use `**example.env**` or documented templates.

## ERPNext vs Frappe-only

- If the site installs **ERPNext**, never patch `erpnext`; integrate via custom app, hooks, and standard ERPNext DocTypes where appropriate.
- If the site is **Frappe-only**, the same rules apply; only `**frappe`** is the framework dependency.

## Legacy `.cursorrules`

Superseded by `**AGENTS.md**`, `**.cursor/rules/*.mdc**`, and `**.cursor/skills/*/SKILL.md**`.