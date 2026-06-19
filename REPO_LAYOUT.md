# Layout del repositorio (club-manager-infra)

Este documento describe **cómo está organizado el disco**, **qué sube a GitHub** el repo de infra y **cómo convive** con el repo de la app Frappe.

## Dos repositorios en GitHub

| Repo remoto | Rol |
|-------------|-----|
| **club-manager-infra** | Docker, Compose, imágenes, CI, documentación de despliegue, reglas Cursor (`.cursor/`), datos de referencia (p. ej. CSV contables) en la raíz si los versionas aquí. |
| **frappe-club-managment** | Código de la app `club_management` (DocTypes, hooks, tests, `specs/`). |

En desarrollo local, la app suele estar clonada **dentro** del bench:

`development/frappe-bench/apps/club_management/`

Ese directorio es **otro clon Git** (segundo remoto). El `.gitignore` del infra **no versiona** casi nada bajo `development/*` salvo excepciones puntuales; el bench y las apps clonadas son **tuyos en la máquina** (o del contenedor), no el contenido típico de cada PR del infra.

## Raíz del workspace (este repo)

Convención: abrir Cursor en la **raíz del clone** del infra (`club-manager-infra` o `club_manager_infra` — mismo rol).

Árbol conceptual (no exhaustivo):

```text
.
├── compose.yaml / pwd.yml / docker-bake.hcl   # Orquestación / build
├── images/ overrides/ scripts/ tests/          # Docker e infra
├── docs/                                      # Guías (fork / extensión de frappe_docker + tuyas)
├── .cursor/                                   # Reglas y skills del equipo (opcional compartir)
├── AGENTS.md / REPO_LAYOUT.md                 # Convenciones para agentes y humanos
├── apps.json                                  # Apps a instalar en bench (URLs GitHub + rama)
├── example.env                                # Plantilla de variables
├── *.csv                                      # Datos ICDPE / importación (si los mantienes aquí)
└── development/
    ├── installer.py, apps-example.json, …    # Sí suelen ir al remoto del infra
    └── frappe-bench/                          # Bench local — mayormente ignorado por Git del infra
        └── apps/
            ├── frappe/
            ├── erpnext/
            └── club_management/               # ← repo Git separado (app)
```

## ¿Tiene sentido esta configuración?

**Sí**, para un equipo que:

- Despliega con **Docker** siguiendo **frappe_docker**.
- Quiere **un solo clone** para abrir el editor: infra + docs + convenciones.
- Mantiene la **app Frappe en su propio repo** (historial limpio, permisos, releases de app aparte).

Ventajas:

- No mezclas commits de Docker con commits de DocTypes.
- `apps.json` documenta de dónde sale la app en un bench nuevo.
- `.cursor/` en el infra alinea a todos los contribuyentes del **entorno y despliegue**; la app sigue teniendo su propio árbol bajo `apps/club_management/`.

## Alternativas si crece el proyecto

| Necesidad | Opción |
|-----------|--------|
| Fijar en cada commit del infra **qué revisión** de la app usas | [Git submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) en `development/frappe-bench/apps/club_management` (o dejar de ignorar esa ruta y tratarla como submódulo). Trade-off: más fricción en `git submodule update`. |
| CSV grandes o datos sensibles | Carpeta `resources/samples/` o `import-templates/` + `.gitignore` parcial, o **Git LFS** / almacén externo. |
| Mucha doc **solo del club** mezclada con doc genérica frappe_docker | `docs/club/` o repo `club-management-docs` aparte y enlace desde README. |
| Reglas Cursor solo personales | `.cursor/` local en `.gitignore` y un `.cursor/` “oficial” mínimo en repo — hoy tener todo `.cursor/` en el repo es válido para equipos pequeños. |

## Rutas que usan agentes y reglas

- Paquete Python de la app (specs, DocTypes):  
  `development/frappe-bench/apps/club_management/club_management/`
- Bench (comandos): desde `development/frappe-bench/` según README / devcontainer del proyecto.

Reglas detalladas de producto y proceso: **`AGENTS.md`**.
