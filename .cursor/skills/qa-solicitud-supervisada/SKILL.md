---
name: qa-solicitud-supervisada
description: QA flujo Solicitud de Asociación. En WSL la UI supervisada va por Browser MCP de Cursor; bench/Playwright headless para lógica.
---

# QA supervisado — Solicitud de Asociación

**Skill canónica (guion Browser MCP + bench):**

`development/frappe-bench/apps/club_management/.cursor/skills/qa-solicitud-supervisada/SKILL.md`

## Resumen WSL

- **No** `playwright --headed` en consola WSL (sin ventana).
- **Sí** pedir al agente que use **cursor-ide-browser** con `http://dev.localhost:8000`.
- **Sí** `bench execute club_management.members.qa.run_supervised.run` para API supervisada con Enter.

Cuando el usuario pida «ejecutar QA supervisado», leer la skill canónica y usar Browser MCP.
