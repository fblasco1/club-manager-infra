---
name: infra-docker
description: >-
  Desarrollo y despliegue Frappe con Docker: bench, compose, migrate, CI.
  Incluye fallback Windows cuando WSL no tiene HTTPS (git push, Drive).
  Usar al tocar infra, bench, o operaciones que requieren salida a Internet.
---

# Infra Docker

## Cuándo usar

- `bench migrate`, `run-tests`, `build`, `restart`.
- Edición de `compose.yaml`, `development/`, `overrides/`, `devcontainer-example/`.
- Nuevo desarrollador u onboarding.
- **Push a GitHub**, sync Drive, o cualquier tarea que requiera **HTTPS** desde el agente.

## Red WSL — HTTPS (obligatorio para agentes)

WSL2 en este proyecto **a menudo no alcanza** `github.com:443` ni Google APIs. **No insistir** con timeouts largos desde bash.

```bash
./scripts/https-preflight.sh
```

| Operación | WSL OK | Si falla preflight |
|-----------|--------|---------------------|
| `git push` (infra o app) | a veces | `./scripts/win/git-push-via-windows.sh` o `scripts/win/git-push.ps1` en PowerShell |
| Sync PM / bitácora | raro | `./scripts/publish-dev-session.sh` (auto-fallback PS) o `sync-pm-ai-to-drive.ps1` |
| SSH Hetzner / deploy | sí | `./scripts/prod/deploy-club-management.sh` |
| `curl` prod / browser QA | sí | MCP cursor-ide-browser |

Documentación: `scripts/win/README.md`, skill **`prod-hetzner-deploy`**.

---

## Repositorio de infra

- Nombre de carpeta recomendado: **`club-manager-infra`** (equivalente lógico a un fork o copia de **[frappe_docker](https://github.com/frappe/frappe_docker)**).
- Si el clone local se llama **`club_manager_infra`**, es el mismo propósito; unificar naming en documentación.

## Comandos típicos

Dentro del servicio que monta el bench (sustituir `<service>` según el compose del proyecto, p. ej. `backend`):

```
docker compose exec <service> bench --site <sitio> migrate
docker compose exec <service> bench --site <sitio> run-tests --app club_management
docker compose exec <service> bench build --app club_management
```

Arranque dev (ajustar ruta al fichero compose del repo):

```
cd club-manager-infra
docker compose -f development/docker-compose.yml up -d
```

## Variables

- Copiar **`example.env`** → **`.env`**; no commitear **`.env`**.

## Tras cambios de DocType

1. `bench migrate`
2. `bench build --app club_management` si cambian assets JS/CSS
3. Verificar Desk (workspaces, reports)

## Producción Hetzner

Deploy SSH + compose: skill **`.cursor/skills/prod-hetzner-deploy/SKILL.md`** y `scripts/prod/deploy-club-management.sh`.

Tras deploy en prod, **verificación obligatoria con MCP cursor-ide-browser** (ver checklist en esa skill); no cerrar el deploy solo con curl/SSH.

## CI (app repo)

- En **frappe-club-management**: tests en push, linters en PR; no saltar **pre-commit**.
- Si preflight HTTPS falla en WSL, push desde Windows (`scripts/win/git-push.ps1`) **antes** de esperar CI.

## Checklist

- [ ] `./scripts/https-preflight.sh` si la tarea incluye push o Drive
- [ ] `.env` fuera de git; `example.env` actualizado si hay vars nuevas
- [ ] migrate ejecutado tras JSON de DocType
- [ ] Pre-commit verde antes de push
