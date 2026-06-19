---
name: infra-docker
description: Desarrollo y despliegue Frappe con Docker: bench dentro del contenedor, compose tipo frappe_docker, migrate tras DocType, variables en example.env, CI. Usar al tocar infra o al ejecutar bench en club-manager-infra.
---

# Infra Docker

## Cuándo usar

- `bench migrate`, `run-tests`, `build`, `restart`.
- Edición de `compose.yaml`, `development/`, `overrides/`, `devcontainer-example/`.
- Nuevo desarrollador u onboarding.

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

## CI (app repo)

- En **frappe-club-management** (GitHub puede listar el remoto como *frappe-club-managment*): tests en push, linters en PR; no saltar **pre-commit**.

## Checklist

- [ ] `.env` fuera de git; `example.env` actualizado si hay vars nuevas
- [ ] migrate ejecutado tras JSON de DocType
- [ ] Pre-commit verde antes de push
