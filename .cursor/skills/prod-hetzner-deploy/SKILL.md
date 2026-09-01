---
name: prod-hetzner-deploy
description: >-
  SSH y despliegue de club_management en producción Hetzner (gestion.icdpedroechague.com.ar):
  clave SSH local, compose en el servidor, bench build, docker commit, sync assets frontend.
  Usar cuando el usuario pida deploy a producción, Hetzner, SSH al servidor, o verificar el sitio en prod.
---

# Deploy producción Hetzner (ICDPE)

## Local vs producción (obligatorio entender)

| Entorno | Qué es | Dónde corre | Sitio Frappe | URL típica |
|---------|--------|-------------|--------------|------------|
| **Local** | **Docker Desktop** en esta computadora (WSL2 + devcontainer) | Contenedor `devcontainer-frappe-1`, Postgres en volumen `devcontainer_postgresql-data` | `dev.localhost` (con **datos restaurados** desde prod) | `http://dev.localhost:8000` |
| **Producción** | **Servidor Hetzner** (`157.90.164.162`) | Compose en `/root/club_manager_infra`, imagen `icdpe-frappe:v16-mvp` | `gestion.icdpedroechague.com.ar` | `https://gestion.icdpedroechague.com.ar` |

- **Nunca** confundir comandos: `scripts/local/*` → **Docker Desktop local**; `scripts/prod/*` → **SSH Hetzner**.
- Probar imports, migraciones e inscripciones **siempre en local primero**; deploy a prod solo con OK explícito del usuario.
- El restore de prod **no crea** el sitio `gestion.icdpedroechague.com.ar` en local: sobrescribe **`dev.localhost`** con la base de producción (mismos socios/datos).

### Entorno local — levantar y clonar datos de prod

Requisitos: **Docker Desktop encendido**, integración WSL activa, entrada en hosts:

```text
127.0.0.1 dev.localhost
```

```bash
# Desde la raíz de club_manager_infra
docker compose -p devcontainer -f .devcontainer/docker-compose.yml up -d

./scripts/prod/prepare-ssh-key.sh          # solo la primera vez
./scripts/local/sync-prod-db-to-local.sh pull
./scripts/local/sync-prod-db-to-local.sh restore   # prod → dev.localhost
./scripts/local/sync-prod-db-to-local.sh migrate
./scripts/local/sync-prod-db-to-local.sh verify    # ej. ~1166 socios

# bench start (terminal aparte)
docker exec -it devcontainer-frappe-1 bash -lc \
  'cd /workspace/development/frappe-bench && bench start'
```

Abrir: **http://dev.localhost:8000** (login Desk con credenciales de prod tras restore).

| Script local | Uso |
|--------------|-----|
| `scripts/local/sync-prod-db-to-local.sh pull` | Backup Hetzner → `./backups/prod-to-local/` |
| `scripts/local/sync-prod-db-to-local.sh restore` | Restaurar prod en `dev.localhost` |
| `scripts/local/sync-prod-db-to-local.sh migrate` | `bench migrate` + build |
| `scripts/local/sync-prod-db-to-local.sh verify` | Contar socios post-restore |
| `scripts/local/sync-prod-db-to-local.sh test-import` | Import padrón (dry_run / `--apply`) |

Contenedor local: `devcontainer-frappe-1`. Bench: `/workspace/development/frappe-bench`. Sitio: **`dev.localhost`**.

Probar import de inscripciones (local):

```bash
./scripts/local/sync-prod-db-to-local.sh test-import
./scripts/local/sync-prod-db-to-local.sh test-import --apply
```

---

## Seguridad (obligatorio)

- **Nunca** commitear claves privadas SSH, `DB_PASSWORD`, ni `/root/.icdpe-secrets.env`.
- La clave vive en la máquina del desarrollador; el repo solo documenta **rutas** y **comandos**.
- Secretos de prod: solo en el servidor (`/root/.icdpe-secrets.env`), fuera de git.

## Red WSL vs Windows (HTTPS) — leer antes de push/deploy

En este entorno **WSL2 suele perder salida HTTPS** a GitHub y Google Drive (timeout en `:443`). **SSH a Hetzner (`157.90.164.162:22`) normalmente sí funciona** desde WSL.

| Destino | Puerto | WSL bash | Fallback Windows |
|---------|--------|----------|------------------|
| `github.com` (git push) | 443 | ❌ frecuente | `scripts/win/git-push.ps1` |
| Google Drive (sync PM / bitácora) | 443 | ❌ frecuente | `scripts/sync-pm-ai-to-drive.ps1` |
| Hetzner SSH | 22 | ✅ habitual | — |
| `gestion.icdpedroechague.com.ar` | 443 | ✅ habitual | — |

### Preflight (ejecutar al inicio de deploy o push)

```bash
./scripts/https-preflight.sh
```

Exit **0** → podés usar `git push` y rclone desde WSL.  
Exit **1** → usar PowerShell para GitHub/Drive; deploy SSH puede seguir en WSL.

### Git push sin tocar `git config --global`

**Opción A — desde WSL** (invoca PowerShell):

```bash
# Infra
./scripts/win/git-push-via-windows.sh

# App club_management
cd development/frappe-bench/apps/club_management
../../../../scripts/win/git-push-via-windows.sh --remote upstream --branch mvp/secretaria-2026-06
```

**Opción B — PowerShell directo** (recomendado si A falla):

```powershell
cd \\wsl.localhost\Ubuntu\home\francisco\ERSport\club_manager_infra
.\scripts\win\git-push.ps1

cd development\frappe-bench\apps\club_management
..\..\..\..\..\scripts\win\git-push.ps1 -Remote upstream -Branch mvp/secretaria-2026-06
```

Usa `git -c safe.directory=...` **por invocación** (no modifica config global). Detalle: `scripts/win/README.md`.

### Sync PM / bitácora a Drive

```bash
./scripts/publish-dev-session.sh   # intenta WSL; si no hay HTTPS → PowerShell automático
```

Manual Windows: `.\scripts\sync-pm-ai-to-drive.ps1` (primera vez: `-CopyConfigFromWsl`).

### Flujo deploy completo (WSL sin HTTPS a GitHub)

1. `./scripts/https-preflight.sh`
2. **Push app** vía Windows (`git-push.ps1` con `-Remote upstream`).
3. **Push infra** (si hubo cambios en `club_manager_infra`).
4. **Deploy** desde WSL (solo SSH): `./scripts/prod/deploy-club-management.sh`
5. Verificación browser (checklist abajo).

No reintentar `git push` en loop desde WSL si el preflight falló — ir directo al fallback Windows.

Referencia red WSL: `docs/club/rclone-oauth-wsl-fix.md` (OAuth rclone, `networkingMode=mirrored`).

---

| Dato | Valor |
|------|--------|
| Host | `157.90.164.162` |
| Usuario | `root` |
| Destino SSH | `root@157.90.164.162` |
| Directorio compose | `/root/club_manager_infra` |
| Sitio Frappe | `gestion.icdpedroechague.com.ar` |
| Imagen Docker | `icdpe-frappe:v16-mvp` |
| Rama app (habitual) | `mvp/secretaria-2026-06` |
| Remoto git en contenedor | `upstream` (no `origin`) |

### Clave en WSL / Linux (desarrollo local)

Ruta habitual en Windows montada en WSL:

```text
/mnt/c/Users/USUARIO/.ssh/id_ed25519
```

Preparar copia usable por scripts (permisos 600):

```bash
./scripts/prod/prepare-ssh-key.sh
# o manual:
cp /mnt/c/Users/USUARIO/.ssh/id_ed25519 /tmp/hetzner_key && chmod 600 /tmp/hetzner_key
```

Variable opcional: `HETZNER_SSH_KEY=/ruta/a/clave` (default: `/tmp/hetzner_key`).

Probar conexión:

```bash
ssh -i /tmp/hetzner_key -o StrictHostKeyChecking=no root@157.90.164.162 'hostname'
```

## Despliegue rápido (solo código + assets)

Desde la raíz de **club_manager_infra**:

```bash
./scripts/https-preflight.sh          # si falla GitHub → push Windows antes
./scripts/prod/prepare-ssh-key.sh     # si hace falta
./scripts/prod/deploy-club-management.sh
```

**Antes del deploy:** la app debe estar en GitHub (`upstream`). Si WSL no tiene HTTPS:

```bash
cd development/frappe-bench/apps/club_management
../../../../scripts/win/git-push-via-windows.sh --remote upstream --branch mvp/secretaria-2026-06
```

Variables útiles:

| Variable | Default |
|----------|---------|
| `APP_BRANCH` | `mvp/secretaria-2026-06` |
| `PROD_HOST` | `root@157.90.164.162` |
| `HETZNER_SSH_KEY` | `/tmp/hetzner_key` |
| `PROD_SITE` | `gestion.icdpedroechague.com.ar` |

## Qué hace el deploy estándar

1. `git fetch upstream` + `reset --hard` en `apps/club_management` (contenedor backend).
2. `bench migrate --skip-failing` (opcional, flag `SKIP_MIGRATE=1` para saltar).
3. `bench build --app club_management`.
4. `docker commit` backend → `icdpe-frappe:v16-mvp`.
5. `docker compose up -d --force-recreate --no-deps frontend websocket`.
6. **Sync `assets.json`** del backend al frontend (volúmenes `sites/assets` separados).

## Verificación post-deploy

**Obligatorio tras cada deploy a producción:** comprobar en el navegador (MCP **cursor-ide-browser**; en WSL no usar Playwright headed local) que el sitio carga y que el cambio desplegado funciona. No dar el deploy por cerrado solo con `curl` o `git log`.

### Checklist mínimo (Secretaría / panel socios)

1. Abrir `https://gestion.icdpedroechague.com.ar/desk/secretaría` (login si hace falta).
2. Confirmar que **no** aparece error de servidor al cargar el panel (p. ej. fallo en `get_panel_lists`).
3. Verificar el área afectada por el deploy (KPIs, gráficos, informes, cobro, etc.).
4. Si el deploy tocó solo Actividades u otro workspace, repetir la verificación allí.

### Comandos auxiliares (no sustituyen el browser)

```bash
# assets públicos
curl -s "https://gestion.icdpedroechague.com.ar/assets/assets.json" | grep club_management

# commit en servidor
ssh -i /tmp/hetzner_key root@157.90.164.162 \
  'docker compose -f /root/club_manager_infra/compose.yaml exec -T backend \
   bash -lc "cd apps/club_management && git log -1 --oneline"'

# import Python sin error de sintaxis (panel Secretaría)
ssh -i /tmp/hetzner_key root@157.90.164.162 \
  'docker compose -f /root/club_manager_infra/compose.yaml -f /root/club_manager_infra/overrides/compose.postgres.yaml exec -T backend \
   bench --site gestion.icdpedroechague.com.ar execute club_management.members.api.secretaria_workspace.get_panel_lists'
```

Desk: hard refresh (`Ctrl+Shift+R`) en `/desk/secretaría` si el browser ya tenía la pestaña abierta.

## Otros scripts

| Script | Uso |
|--------|-----|
| `scripts/prod/deploy-club-management.sh` | Deploy código + build + frontend |
| `scripts/prod/prepare-ssh-key.sh` | Copiar clave Windows → `/tmp/hetzner_key` |
| `scripts/prod/restart-bench.sh remote` | Reinicio bench + build sin pull |
| `scripts/prod/migrate-socios-dashboard.sh` | Backup/restore masivo de datos |

## Referencia extendida

Ver [reference.md](reference.md) (compose exacto, secretos en servidor, troubleshooting assets 404).
