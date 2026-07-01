---
name: prod-hetzner-deploy
description: >-
  SSH y despliegue de club_management en producción Hetzner (gestion.icdpedroechague.com.ar):
  clave SSH local, compose en el servidor, bench build, docker commit, sync assets frontend.
  Usar cuando el usuario pida deploy a producción, Hetzner, SSH al servidor, o verificar el sitio en prod.
---

# Deploy producción Hetzner (ICDPE)

## Seguridad (obligatorio)

- **Nunca** commitear claves privadas SSH, `DB_PASSWORD`, ni `/root/.icdpe-secrets.env`.
- La clave vive en la máquina del desarrollador; el repo solo documenta **rutas** y **comandos**.
- Secretos de prod: solo en el servidor (`/root/.icdpe-secrets.env`), fuera de git.

## Acceso SSH

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

Desde la raíz de **club_manager_infra** (tras `git push` de `club_management`):

```bash
./scripts/prod/prepare-ssh-key.sh   # si hace falta
./scripts/prod/deploy-club-management.sh
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

```bash
# assets públicos
curl -s "https://gestion.icdpedroechague.com.ar/assets/assets.json" | grep club_management

# commit en servidor
ssh -i /tmp/hetzner_key root@157.90.164.162 \
  'docker compose -f /root/club_manager_infra/compose.yaml exec -T backend \
   bash -lc "cd apps/club_management && git log -1 --oneline"'
```

Desk: hard refresh (`Ctrl+Shift+R`) en `/desk/secretaría`.

## Otros scripts

| Script | Uso |
|--------|-----|
| `scripts/prod/deploy-club-management.sh` | Deploy código + build + frontend |
| `scripts/prod/prepare-ssh-key.sh` | Copiar clave Windows → `/tmp/hetzner_key` |
| `scripts/prod/restart-bench.sh remote` | Reinicio bench + build sin pull |
| `scripts/prod/migrate-socios-dashboard.sh` | Backup/restore masivo de datos |

## Referencia extendida

Ver [reference.md](reference.md) (compose exacto, secretos en servidor, troubleshooting assets 404).
