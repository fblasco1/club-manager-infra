---
name: sync-pm-ai
description: >-
  Genera el corte diario sync-pm-ai.md para Gemini Spark (PM AI): releva git,
  clasifica Done/In Progress/Backlog, documenta blockers y prioridades. Usar cuando
  pidan "sync para PM", "generar sync", sincronizar estado con PM AI, o al cerrar
  un hito de deploy/sprint.
---

# Sync PM AI (Gemini Spark)

## Flujo

Cursor AI → `docs/club/sync-pm-ai.md` → Google Drive (*Sistema de Gestion - ERP CLUBES*) → Gemini Spark (09:00 ART) → Francisco → prompt de sesión en Cursor.

Detalle: **`docs/club/sync-pm-ai-protocol.md`**.

## Checklist de generación

### 1. Git (todos los repos relevantes)

```bash
# App Frappe
cd development/frappe-bench/apps/club_management
git status -sb && git log -1 --oneline && git stash list

# Landing (si existe)
cd ../../../pedro-echague-landing-page && git status -sb && git log -1 --oneline
```

Anotar: rama, HEAD, commits ahead/behind origin, archivos M/??, stashes.

### 2. Clasificación por semáforo

| Nivel | Criterio |
|-------|----------|
| Done (prod) | Verificado o documentado en Hetzner / Vercel Production |
| Done (código) | En origin o commit local con spec; deploy pendiente |
| In Progress | Working tree dirty, untracked, stash, WIP sin tests |
| Backlog | Spec en `club_management/specs/` sin producto |

Fuentes: `specs/backlog_implementacion.md`, specs del módulo (p. ej. `spaces_*`), `docs/club/cobranza-cobrand-supervielle.md`.

### 3. Ejes obligatorios

- **Arquitectura base** — módulos, roles, scheduler, PostgreSQL patches.
- **Gestión de socios** — portal alta, Desk, grupo familiar, BL-6.
- **Motor de tarifas** — Club Settings, jobs, mora, catálogo ICDPE.
- **Pasarela** — Cobrand/Supervielle (código vs prod); Payment Log; SIRO no aplica.
- **Módulo activo** — p. ej. Spaces: entregado local vs pendiente SP-1/SP-2.

### 4. Blockers

- APIs sin documentación.
- Datos de terceros (FMV, Excel Coordinación).
- Gap local→prod no verificado en SSH.
- Decisiones de producto abiertas (retención PDF, calendario mora día 20 vs fin de mes).

### 5. Escribir `docs/club/sync-pm-ai.md`

Actualizar **fecha de corte** y secciones §0–§7 según plantilla en el protocolo. Incluir **mensaje corto de 5 líneas** para Gemini.

### 6. Entrega

```bash
./scripts/publish-dev-session.sh
# Actualiza bitácora + sube sync-pm-ai.md y Bitacora de desarrollo.md a Drive
# Si WSL no tiene HTTPS → fallback automático a PowerShell (sync-pm-ai-to-drive.ps1)
```

Primera vez: `cp docs/club/example.sync-pm-ai.env .env.sync-pm-ai`

Si el agente ve timeout a `google.com` / `googleapis.com` desde WSL, **no reintentar rclone en bash** — usar directamente:

```powershell
cd \\wsl.localhost\Ubuntu\home\francisco\ERSport\club_manager_infra
.\scripts\sync-pm-ai-to-drive.ps1
```

Briefing Gemini Spark **09:00 ART L–V**.

## Comandos útiles

```bash
# Listar DocTypes de la app
find club_management -path '*/doctype/*/*.json' ! -name '*_dashboard.json' | wc -l

# Tests de un módulo (ej. Spaces)
bench --site dev.localhost run-tests --app club_management --module club_management.spaces.tests
```

## No hacer

- No inventar estado de Cobrand/Supervielle ni endpoints.
- No marcar Done (prod) sin evidencia (commit deploy, smoke, backlog).
- No commitear el sync salvo que el usuario lo pida.
