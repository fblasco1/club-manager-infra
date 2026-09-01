# Cobranza informe ago 2026 — casos manuales en producción

Referencia local: `backups/prod-to-local/imports/cobranzas_discordantes_v19.xlsx`  
Dry-run objetivo post-pipeline: **28 filas no imputables** por apply automático.

| Código | Cantidad | Acción |
|--------|----------|--------|
| `monto_discordante` | **10** | Corregir factura/categoría/mora en Desk y cobrar manual |
| `socio_no_encontrado` | **17** | Verificar nº padrón vs padrón prod; alta o corrección informe |
| `fecha_invalida` | **1** | Corregir fecha en informe o cobro manual con fecha válida |

El apply automático (`APPLY_PROD`) **no** debe forzar estas filas.

---

## 10 × monto_discordante (manual)

Cuota Social Menor — patrones mora agosto, períodos futuros, montos atípicos.

| Socio | Concepto | Monto informe | Período | Fila Excel |
|-------|----------|---------------|---------|------------|
| 12112 | Cuota Social Menor | $32.275 | 08/2026 | 1483 |
| 11361 | Cuota Social Menor | $32.275 | 08/2026 | 1542 |
| 9126 | Cuota Social Menor | $32.275 | 08/2026 | 1546 |
| 10979 | Cuota Social Menor | $32.295 | 05/2026 | 1568 |
| 11380 | Cuota Social Menor | $28.350 | 08/2026 | 1636 |
| 11930 | Cuota Social Menor | $32.275 | 07/2026 | 1754 |
| 10782 | Cuota Social Menor | $32.275 | 09/2026 | 1818 |
| 10782 | Cuota Social Menor | $32.275 | 10/2026 | 1817 |
| 10782 | Cuota Social Menor | $32.275 | 11/2026 | 1816 |
| 10782 | Cuota Social Menor | $32.275 | 12/2026 | 1811 |

**Notas:**

- **10782:** cuatro líneas son períodos **futuros** (09–12/2026) — validar si corresponde facturar/cobrar antes de imputar.
- **11380:** monto $28.350 (−$480 vs tarifa Menor base) — revisar categoría o error cobrador.
- Resto: revisar mora agosto ($925) vs factura en prod.

---

## 17 × socio_no_encontrado (manual)

El nº de socio del informe no matchea fila en prod (socio nuevo, baja, o typo).

| Socio | Concepto | Monto | Período | Fila |
|-------|----------|-------|---------|------|
| 12132 | Adicional Basquet Escuelita | $24.150 | 07/2026 | 50 |
| 12132 | Adicional Basquet Escuelita | $24.150 | 06/2026 | 51 |
| 12047 | Adicional Patin 1º Nivel | $22.550 | 08/2026 | 85 |
| 12047 | Adicional Patin 1º Nivel | $23.575 | 07/2026 | 86 |
| 12063 | Adicional Voley Escuela | $23.650 | 08/2026 | 124 |
| 11755 | CTO COMP BASQ TIRA A/B/FLEX | $6.000 | 08/2026 | 850 |
| 12047 | CTO COMP PATIN INICIAL | $1.230 | 08/2026 | 1018 |
| 12063 | CTO COMP VOLEY ESC | $4.300 | 08/2026 | 1139 |
| 11755 | Cuota Social Activo | $31.000 | 08/2026 | 1261 |
| 10245 | Cuota Social Adherente | $21.450 | 08/2026 | 1310 |
| 10245 | Cuota Social Adherente | $22.425 | 07/2026 | 1311 |
| 12063 | Cuota Social Menor | $31.350 | 08/2026 | 1523 |
| 12047 | Cuota Social Menor | $31.350 | 08/2026 | 1613 |
| 12047 | Cuota Social Menor | $32.275 | 07/2026 | 1614 |
| 12132 | Cuota Social Menor | $32.275 | 07/2026 | 1792 |
| 12132 | Cuota Social Menor | $32.275 | 06/2026 | 1793 |
| 11755 | SUPERIOR B | $25.000 | 08/2026 | 2452 |

Socios más repetidos: **12132**, **12047**, **12063**, **11755**, **10245**.

---

## 1 × fecha_invalida (manual)

| Socio | Concepto | Monto | Período | Fila |
|-------|----------|-------|---------|------|
| 11678 | Cuota Social Menor | $32.775 | 07/2026 | 1768 |

Revisar `fecha_pago` en el Excel (futura o formato inválido).

---

## Orden operativo prod

1. Deploy código + `apply-cobranza-informe.sh --dry-run`
2. Confirmar ~28 inconsistencias esperadas en `apply_dry_2`
3. `apply-cobranza-informe.sh --apply` (resto del informe)
4. Cierre manual de estas **28 filas** en Desk
