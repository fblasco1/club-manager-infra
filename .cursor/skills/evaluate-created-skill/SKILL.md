---
name: evaluate-created-skill
description: Evalúa skills de agente ya creadas: estructura, calidad de la descripción y buenas prácticas de la guía de autoría. Usar cuando el usuario pida evaluar una skill, auditar una skill, revisar la calidad de una skill o comprobar si sigue las mejores prácticas.
---

# Evaluar skill creada

## Cuándo aplicar

Usar esta skill cuando el usuario pida:
- Evaluar, auditar o revisar una skill
- Comprobar si una skill sigue buenas prácticas
- Validar la estructura o la descripción de una skill

## Flujo de evaluación

1. **Obtener la skill a evaluar**: Leer el `SKILL.md` (y opcionalmente `reference.md`, `examples.md`) de la skill indicada por el usuario o por ruta.
2. **Aplicar los criterios** de las secciones siguientes.
3. **Emitir el informe** con el formato indicado en "Formato del informe".

---

## Criterios de calidad

### 1. Frontmatter y descripción

- **Campo `name`**: Solo minúsculas, números y guiones; máx. 64 caracteres.
- **Campo `description`**:
  - En tercera persona (no "Yo puedo..." ni "Puedes usar...").
  - Incluye QUÉ hace la skill (capacidades concretas).
  - Incluye CUÁNDO usarla (escenarios o términos que la disparan).
  - Máx. 1024 caracteres, no vacía.

**Ejemplos de descripción:**

- ✅ "Extrae texto y tablas de PDFs, rellena formularios, fusiona documentos. Usar con archivos PDF o cuando se mencionen PDFs, formularios o extracción de documentos."
- ❌ "Ayuda con documentos" (vago).
- ❌ "Puedo ayudarte a procesar PDFs" (primera persona).

### 2. Estructura y tamaño

- **SKILL.md** tiene menos de 500 líneas (recomendado para rendimiento).
- Referencias a otros archivos son **solo un nivel**: desde SKILL.md a `reference.md`, `examples.md`, etc.; no cadenas profundas de enlaces.
- Si hay contenido muy largo o detallado, está en archivos separados (progressive disclosure).

### 3. Contenido y estilo

- **Terminología consistente**: Un solo término para el mismo concepto (p. ej. "API endpoint" o "campo", no mezclar con "ruta", "caja", "elemento").
- **Instrucciones concretas**: Pasos claros, no párrafos genéricos que el agente ya conoce.
- **Sin rutas tipo Windows** en instrucciones: usar `scripts/helper.py`, no `scripts\helper.py`.
- **Sin información sensible al tiempo** del tipo "antes de agosto de 2025 usa la API antigua"; si hace falta, ponerla en una sección "Patrones antiguos (deprecados)".

### 4. Patrones a evitar

- Demasiadas alternativas sin un criterio claro: preferir un método por defecto y una alternativa explícita (p. ej. "Para PDFs escaneados con OCR, usar...").
- Nombres de skill vagos: preferir `processing-pdfs`, `analyzing-spreadsheets` frente a `helper`, `utils`, `tools`.
- Scripts que no se indica si deben **ejecutarse** o solo **leerse** como referencia.

### 5. Si incluye scripts

- Paquetes necesarios documentados.
- Manejo de errores claro y útil.
- En el SKILL.md debe quedar claro si el agente debe ejecutar el script o solo usarlo como referencia.

---

## Formato del informe

Al terminar la evaluación, devolver un informe con esta estructura:

```markdown
# Evaluación: [nombre de la skill]

## Resumen
[Una o dos frases: estado general y si cumple los criterios principales.]

## 🔴 Crítico
[Items que deben corregirse antes de considerar la skill bien formada. Si no hay ninguno, escribir "Ninguno."]

## 🟡 Sugerencia
[Mejoras recomendadas. Si no hay ninguna, escribir "Ninguna."]

## 🟢 Opcional
[Mejoras opcionales o buenas prácticas adicionales. Si no hay ninguna, escribir "Ninguna."]

## Checklist rápido
- [ ] Descripción en tercera persona, con QUÉ y CUÁNDO
- [ ] SKILL.md con menos de 500 líneas
- [ ] Terminología consistente
- [ ] Referencias a archivos de un solo nivel
- [ ] Sin rutas estilo Windows en instrucciones
- [ ] Nombre de skill específico (no vago)
```

---

## Resumen de criterios (checklist interno)

Antes de cerrar el informe, comprobar:

**Calidad básica**
- Descripción específica con términos clave y escenarios de uso.
- QUÉ y CUÁNDO en la descripción.
- Tercera persona en la descripción.
- SKILL.md por debajo de 500 líneas.
- Terminología consistente.
- Ejemplos concretos cuando los haya.

**Estructura**
- Referencias a archivos solo a un nivel.
- Progressive disclosure usado cuando el contenido es largo.
- Pasos de flujos claros.
- Sin información sensible al tiempo sin marcar como deprecada.

**Si hay scripts**
- Paquetes documentados.
- Errores manejados de forma explícita y útil.
- Rutas en estilo Unix (no Windows).
