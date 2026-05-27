# Club Management (dev) — levantar entorno como venimos trabajando

Esta guía documenta el flujo “rápido” que usamos para desarrollar y hacer QA del
flujo **Solicitud de Asociación** en `dev.localhost`.

## Requisitos

- Docker + Docker Compose v2
- Este repo clonado

## 1) Levantar la stack devcontainer-example

Desde la **raíz** del repo:

```bash
docker compose -p devcontainer-example -f .devcontainer/docker-compose.yml up -d
docker ps --format '{{.Names}}' | grep devcontainer-example
```

El contenedor principal de trabajo suele ser:

- `devcontainer-example-frappe-1`

## 2) Iniciar Frappe (bench start)

Entrar al contenedor y levantar el servidor:

```bash
docker exec -it devcontainer-example-frappe-1 bash
cd /workspace/development/frappe-bench
bench start
```

## 3) URLs (sitio de prueba)

- **Base URL**: `http://dev.localhost:8000`
- **Formulario público**: `http://dev.localhost:8000/solicitud-asociacion`
- **Login Desk**: `http://dev.localhost:8000/login`

Si `dev.localhost` no resuelve en tu host, agregar entrada en hosts:

- Windows: `C:\Windows\System32\drivers\etc\hosts` → `127.0.0.1 dev.localhost`

## 4) QA del flujo Solicitud de Asociación

### Nivel 1 — CI (sin UI)

Dentro del contenedor:

```bash
cd /workspace/development/frappe-bench
bench --site dev.localhost run-tests --module club_management.members.tests.test_flujo_solicitud_completo
```

### Nivel 2 — runner supervisado (terminal)

```bash
bench --site dev.localhost execute club_management.members.qa.run_supervised.run
```

Solo alta (deja la solicitud en `Pendiente` para validar desde Desk):

```bash
bench --site dev.localhost execute club_management.members.qa.run_supervised.run_alta_only \
  --kwargs '{"dni":"83999999","email":"qa@example.com"}'
```

### Nivel 3 — UI supervisada en WSL

En WSL no usar Playwright headed. Para ver UI, usar el Browser integrado de Cursor
con base `http://dev.localhost:8000`.

Guion completo: `development/frappe-bench/apps/club_management/.cursor/skills/qa-solicitud-supervisada/SKILL.md`

