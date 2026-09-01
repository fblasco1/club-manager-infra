# Referencia — producción Hetzner ICDPE

## Arquitectura en servidor

```text
/root/club_manager_infra/          # clone club-manager-infra (compose)
/root/.icdpe-secrets.env           # DB_PASSWORD, etc. (NO en git)
/home/frappe/frappe-bench/         # dentro del contenedor backend
  apps/club_management/            # git → github fblasco1/frappe-club-managment
  sites/gestion.icdpedroechague.com.ar/
```

Compose habitual:

```bash
cd /root/club_manager_infra
source /root/.icdpe-secrets.env
DC="docker compose -f compose.yaml \
  -f overrides/compose.postgres.yaml \
  -f overrides/compose.redis.yaml \
  -f overrides/compose.https.yaml"
```

## Git de la app en el contenedor

```bash
$DC exec -T backend bash -lc '
  cd apps/club_management
  git fetch upstream mvp/secretaria-2026-06
  git reset --hard upstream/mvp/secretaria-2026-06
  git log -1 --oneline
'
```

## Build + imagen + frontend

```bash
$DC exec -T backend bench build --app club_management
docker commit $(docker ps -qf name=backend) icdpe-frappe:v16-mvp
$DC up -d --force-recreate --no-deps frontend websocket
```

## Problema conocido: assets.json desincronizado

Backend y frontend montan **volúmenes distintos** en `/home/frappe/frappe-bench/sites/assets`.
Tras `bench build` en backend, el frontend puede seguir sirviendo hashes viejos (404 en JS/CSS).

Sincronizar manualmente:

```bash
$DC exec -T backend cat /home/frappe/frappe-bench/sites/assets/assets.json > /tmp/assets.json
$DC exec -T backend cat /home/frappe/frappe-bench/sites/assets/assets-rtl.json > /tmp/assets-rtl.json
$DC exec -T frontend bash -lc 'cat > /home/frappe/frappe-bench/sites/assets/assets.json' < /tmp/assets.json
$DC exec -T frontend bash -lc 'cat > /home/frappe/frappe-bench/sites/assets/assets-rtl.json' < /tmp/assets-rtl.json
```

Verificar:

```bash
curl -s https://gestion.icdpedroechague.com.ar/assets/assets.json | grep club_management
```

## Usuarios Desk (referencia operativa)

| Rol | Email |
|-----|--------|
| Secretaria | `ariela@icdpedroechague.com.ar`, `miranda@icdpedroechague.com.ar` |

Contraseñas: en `/root/.icdpe-secrets.env` del servidor (`ARIELA_PASSWORD`, `MIRANDA_PASSWORD`). No copiar al repo.

## Dominio y TLS

- URL: `https://gestion.icdpedroechague.com.ar`
- Workspace: `/desk/secretaría`
- Plantilla env: `docs/club/example.prod.env` (actualizar `SITES_RULE` / `FRAPPE_SITE_NAME_HEADER` si cambia el dominio)

## Troubleshooting

| Síntoma | Causa probable | Acción |
|---------|----------------|--------|
| `git push` timeout / `Could not connect to github.com` en WSL | WSL sin HTTPS | `./scripts/https-preflight.sh`; luego `scripts/win/git-push.ps1` desde PowerShell |
| rclone / Drive timeout desde WSL | Misma red WSL | `./scripts/publish-dev-session.sh` o `sync-pm-ai-to-drive.ps1` en Windows |
| 404 en `club_management.bundle.*.js` | Frontend con `assets.json` viejo | Sync assets.json (arriba) + recrear frontend |
| Dashboard sin estilos nuevos | CSS no en bundle SCSS | `bench build`; verificar `public/scss/club_management.bundle.scss` importa parciales |
| Sidebar vacía | boot sin ítems Secretaría | `bench execute club_management.members.setup.secretaria_workspace_sidebar.sync_secretaria_workspace_sidebar` |
| `bench migrate` falla en patches ICDPE | Cost Center / datos legacy | `migrate --skip-failing` si no bloquea la feature |
