# Estructura contable propuesta — Institución Cultural y Deportiva Pedro Echagüe (ICDPE)

> **Documento para revisión del/la contador/a del club.**
> Detalla el plan de cuentas, los centros de costo, las reglas de imputación y las integraciones de cobranza propuestas para el ERP (ERPNext 16) del club.
> **Pedido:** revisar y devolver observaciones o ajustes antes de operar en producción.

---

## 1. Contexto general

- **Razón social / Company en ERP:** *Institución Cultural y Deportiva Pedro Echagüe*
- **Marca / abreviatura interna:** **ICDPE**
- **ERP:** ERPNext 16 (Frappe 16) sobre bench Dockerizado.
- **Base de datos:** PostgreSQL/MariaDB del ERP (toda la contabilidad vive en `tabAccount`, `tabCost Center`, `tabGL Entry`, etc.).
- **Operación:** un único CUIT — toda la actividad del club entra en la **misma persona jurídica/contable**.
- **Bimoneda:**
  - **Moneda base:** **ARS (pesos argentinos)**.
  - **USD:** se opera **solo por alquileres** (algunos contratos cobran en USD).
- **Migración:** **no hay migración de saldos**. Se parte “desde cero” en el ERP; el plan anterior queda como referencia histórica fuera del ERP.

### Origen del rediseño

Se partió del **plan de cuentas histórico** del área contable (8 dígitos, niveles `DISP/INV/DS/OCRED/BUSO/DSOC/PN/CS/EX/EV/PUB/OIE/RF/GADM/GA/GM/RECPAM`). Se detectaron oportunidades de mejora:

- Cuentas mezclando **naturaleza** (qué tipo de gasto/ingreso) con **actividad** (qué deporte): p. ej. `Gastos Fútbol`, `Federación Básquet`, `Insumos Vóley`.
- Cuentas “bolsa” muy agregadas: `Ingresos Varios`, `Gastos Varios`.
- Falta de una cuenta dedicada para **cuota federativa cobrada al socio**.

### Estrategia de la versión 2

Separar **3 ejes** para que el reporte salga “solo”:

1. **Naturaleza contable** → Plan de Cuentas (qué se cobra / paga).
2. **Unidad / actividad** → Centro de Costo (dónde ocurre).
3. **Objeto** → opcional `Project` (eventos, obras, temporadas) si más adelante hace falta.

Resultado: **no se duplican cuentas por deporte**. “Insumos Básquet” deja de ser una cuenta; pasa a ser `**Insumos deportivos` (cuenta) + Centro de Costo `Deportes - Basquet Masculino`**.

---

## 2. Centros de Costo (estructura completa)

Árbol implementado en ERPNext (un único nodo raíz por compañía, los grupos cuelgan de `Main`):

```
Institución Cultural y Deportiva Pedro Echagüe   (raíz, grupo)
└── Main                                          (grupo)
    ├── Administración
    ├── Deportes                                  (grupo)
    │   ├── Deportes - Futbol
    │   ├── Deportes - Basquet Masculino
    │   ├── Deportes - Basquet Femenino
    │   ├── Deportes - Voley
    │   ├── Deportes - Patin
    │   ├── Deportes - Boxeo
    │   ├── Deportes - Gimnasia Artistica
    │   ├── Deportes - Taekwondo
    │   └── Deportes - Shui Lu
    ├── Actividades                               (grupo)
    │   ├── Actividades - Iniciacion Deportiva
    │   ├── Actividades - Danza
    │   ├── Actividades - Yoga
    │   ├── Actividades - CrossFit
    │   ├── Actividades - Funcional
    │   └── Actividades - Ritmos Latinos
    ├── Fitness                                   (grupo)
    │   └── Fitness - Gimnasio de Musculacion
    ├── Gastronomía                               (grupo)
    │   ├── Gastronomía - Buffet
    │   ├── Gastronomía - Peña de Rock
    │   └── Gastronomía - Restaurante
    └── Alquileres                                (grupo)
        ├── Alquileres - Temporal
        └── Alquileres - Recurrente
```

### Regla operativa

- **Toda** transacción de ingreso o gasto debe llevar `Cost Center`.
- “Administración” actúa como “gasto/ingreso institucional” (cuota social, servicios generales si no se prorratean, comisiones bancarias, etc.).
- Los **deportes/actividades/fitness** se imputan al **subcentro** correspondiente (no al grupo).
- Para reportar “toda” el área Deportes, ERPNext suma automáticamente los hijos del grupo `Deportes`.

---

## 3. Plan de Cuentas v2 (estructura con códigos sugeridos)

> Los códigos numéricos son una **convención interna** para ordenar/buscar; ERPNext usa el árbol y el `Account Type` para la operatoria contable.
> Cada cuenta tiene su `Root Type` (`Asset/Liability/Equity/Income/Expense`) y, donde corresponde, su `Account Type` técnico (`Cash`, `Bank`, `Receivable`, `Payable`, `Fixed Asset`, `Accumulated Depreciation`, `Depreciation`).

### 3.1 Activo (1)


| Código | Cuenta                                             | Tipo / Moneda            | Notas                                                        |
| ------ | -------------------------------------------------- | ------------------------ | ------------------------------------------------------------ |
| 1100   | **Activo Corriente** *(grupo)*                     | Asset                    |                                                              |
| 1110   | **Caja y Bancos** *(grupo)*                        | Asset                    |                                                              |
| 1111   | Caja *(grupo)*                                     | Cash                     |                                                              |
| 111101 | Caja ARS                                           | Cash / ARS               | Caja operativa en pesos                                      |
| 111102 | Caja USD                                           | Cash / USD               | Caja en dólares (solo si hay efectivo USD)                   |
| 1112   | Bancos *(grupo)*                                   | Bank                     |                                                              |
| 111201 | Banco ARS                                          | Bank / ARS               | Cuenta operativa principal                                   |
| 111202 | Banco USD                                          | Bank / USD               | Para acreditaciones por alquileres USD                       |
| 1130   | Inversiones temporarias *(grupo)*                  | Asset                    |                                                              |
| 113001 | Plazo fijo / Inversiones ARS                       | Asset / ARS              |                                                              |
| 113002 | FCI / Otras inversiones ARS                        | Asset / ARS              |                                                              |
| 1140   | **Créditos por operaciones** *(grupo, Receivable)* | Receivable               |                                                              |
| 114001 | **Cuotas sociales a cobrar**                       | Receivable               | Default Receivable de la Company                             |
| 114002 | Deudores por ventas                                | Receivable               | Resto de cobranzas no “cuota”                                |
| 114003 | Alquileres a cobrar                                | Receivable               | Opcional para análisis específico                            |
| 1150   | Otros créditos *(grupo)*                           | Asset                    |                                                              |
| 115001 | **Anticipos / gastos pagados por adelantado**      | Asset                    | Clave para prorrateo de cuota federativa pagada al organismo |
| 115002 | **Cobros Plus - a liquidar (ARS)**                 | Asset                    | Cuenta puente de la pasarela bancaria                        |
| 1200   | **Activo No Corriente** *(grupo)*                  | Asset                    |                                                              |
| 1210   | Bienes de Uso *(grupo)*                            | Fixed Asset              |                                                              |
| 121001 | Inmuebles                                          | Fixed Asset              |                                                              |
| 121002 | Instalaciones                                      | Fixed Asset              |                                                              |
| 121003 | Muebles y Útiles                                   | Fixed Asset              |                                                              |
| 121004 | Equipamiento deportivo                             | Fixed Asset              |                                                              |
| 1290   | Amortización acumulada *(grupo)*                   | Accumulated Depreciation |                                                              |
| 129001 | Amort. acum. Inmuebles                             | Accumulated Depreciation |                                                              |
| 129002 | Amort. acum. Instalaciones                         | Accumulated Depreciation |                                                              |
| 129003 | Amort. acum. Muebles y Útiles                      | Accumulated Depreciation |                                                              |
| 129004 | Amort. acum. Equipamiento deportivo                | Accumulated Depreciation |                                                              |


### 3.2 Pasivo (2)


| Código | Cuenta                                    | Tipo      | Notas                                    |
| ------ | ----------------------------------------- | --------- | ---------------------------------------- |
| 2100   | **Pasivo Corriente** *(grupo)*            | Liability |                                          |
| 2110   | Proveedores                               | Payable   | Default Payable de la Company            |
| 2120   | Remuneraciones y cargas a pagar *(grupo)* | Liability |                                          |
| 212001 | Sueldos a pagar                           | Liability |                                          |
| 212002 | Cargas sociales a pagar                   | Liability |                                          |
| 2130   | Impuestos y tasas a pagar                 | Liability |                                          |
| 2140   | Anticipos de clientes                     | Liability | Cobros adelantados (alquileres, eventos) |


### 3.3 Patrimonio Neto (3)


| Código | Cuenta                        | Notas |
| ------ | ----------------------------- | ----- |
| 3000   | **Patrimonio Neto** *(grupo)* |       |
| 3110   | Capital Social                |       |
| 3120   | Ajustes de capital            |       |
| 3210   | Reserva legal                 |       |
| 3310   | Resultados acumulados         |       |
| 3320   | Resultado del ejercicio       |       |


> **Consulta al contador:** ¿Se usa **RECPAM** explícito (resultado por exposición a la inflación) como cuenta separada o se modela vía ajuste de capital + resultado del ejercicio? Hoy no está creada como cuenta dedicada.

### 3.4 Ingresos (4)


| Código     | Cuenta                                            | Moneda  | Notas                                   |
| ---------- | ------------------------------------------------- | ------- | --------------------------------------- |
| 4000       | **Ingresos operativos** *(grupo)*                 | ARS     |                                         |
| 4110       | Cuotas y membresías *(grupo)*                     | ARS     |                                         |
| **411001** | **Cuota social**                                  | ARS     | CC default: **Administración**          |
| 411002     | Inscripciones / matrículas                        | ARS     |                                         |
| 4120       | **Aranceles de actividades y deportes** *(grupo)* | ARS     |                                         |
| **412001** | **Arancel mensual actividad**                     | ARS     | CC = subcentro de la actividad/deporte  |
| **412002** | **Packs CLASES**                                  | ARS     | CC = subcentro de la actividad/deporte  |
| 4130       | Cuotas federativas *(grupo)*                      | ARS     |                                         |
| **413001** | **Cuota federativa**                              | ARS     | CC = subcentro del deporte              |
| 4210       | Alquileres *(grupo)*                              | ARS     |                                         |
| 421001     | Alquiler canchas / espacios (ARS)                 | ARS     | CC = `Alquileres - Temporal/Recurrente` |
| 421002     | Alquiler canchas / espacios (USD)                 | **USD** | CC = `Alquileres - Temporal/Recurrente` |
| 4310       | Actividades (no recurrentes) *(grupo)*            | ARS     |                                         |
| 431002     | Colonias                                          | ARS     | Eventos puntuales                       |
| 431003     | Eventos                                           | ARS     |                                         |
| 4410       | Gastronomía *(grupo)*                             | ARS     |                                         |
| 441001     | **Ventas mostrador (POS)**                        | ARS     | CC = `Gastronomía - <unidad>`           |
| 4510       | Comercial *(grupo)*                               | ARS     |                                         |
| 451001     | Sponsors / Publicidad                             | ARS     |                                         |
| 451002     | Venta indumentaria                                | ARS     |                                         |
| 4900       | Otros ingresos *(grupo)*                          | ARS     |                                         |
| 491001     | Otros ingresos (uso restringido)                  | ARS     | Reclasificar mensualmente               |


> **Importante (federativa cobrada vs paga):** la **cuota federativa cobrada al socio** es **ingreso del club** (`413001`). La **cuota pagada a la federación** es **gasto del club** (ver §3.5), porque “lo cobra el club y después paga a la federación a su nombre”. **No** se modela como recaudación para terceros.

### 3.5 Egresos (5)


| Código     | Cuenta                                                    | Notas                                        |
| ---------- | --------------------------------------------------------- | -------------------------------------------- |
| 5100       | **Personal** *(grupo)*                                    |                                              |
| 511001     | Sueldos                                                   |                                              |
| 512001     | Cargas sociales                                           |                                              |
| 513001     | Honorarios profesionales y servicios                      |                                              |
| 5200       | **Servicios** *(grupo)*                                   |                                              |
| 521001     | Electricidad                                              |                                              |
| 522001     | Agua                                                      |                                              |
| 523001     | Gas                                                       |                                              |
| 524001     | Telecomunicaciones (Internet / Telefonía)                 |                                              |
| 5300       | **Mantenimiento / Operación** *(grupo)*                   |                                              |
| 531001     | Mantenimiento edilicio                                    |                                              |
| 532001     | Limpieza                                                  |                                              |
| 533001     | Seguridad                                                 |                                              |
| 5400       | **Deportes y actividades (naturaleza)** *(grupo)*         | Granularidad va por **Cost Center**          |
| 541001     | Insumos deportivos                                        |                                              |
| 542001     | Arbitrajes / Jueces                                       |                                              |
| 543000     | Afiliaciones / Federaciones *(grupo)*                     |                                              |
| **543001** | **Gastos federativos (afiliaciones / cuotas federación)** | Contracara del cobro `413001`                |
| 544001     | Traslados / Logística                                     |                                              |
| 5500       | **Impuestos y tasas** *(grupo)*                           |                                              |
| 551001     | Impuestos                                                 |                                              |
| 552001     | Tasas / contribuciones                                    |                                              |
| 5600       | **Seguros** *(grupo)*                                     |                                              |
| 561001     | Seguros                                                   |                                              |
| 5700       | **Administración** *(grupo)*                              |                                              |
| 571001     | Librería / Papelería                                      |                                              |
| 572001     | Comisiones bancarias y medios de pago                     |                                              |
| **572002** | **Comisiones Cobros Plus (ARS)**                          | Comisión de la pasarela cuando corresponda   |
| 573001     | Software / Servicios digitales                            |                                              |
| 574001     | Gastos administrativos varios *(evitar)*                  | Solo si no encaja en otro lado; reclasificar |
| 5800       | **Depreciaciones** *(grupo)*                              |                                              |
| 581001     | Amortizaciones                                            |                                              |


> **Consulta al contador:** ¿prefieren mantener la cuenta `574001 Gastos administrativos varios` como “bolsa” o suprimirla y obligar a clasificar?
> Hoy está creada pero con etiqueta “evitar”.

---

## 4. Reglas de imputación (cómo se cargan las transacciones)

### 4.1 Cuotas, aranceles y federativas (vía sede digital del socio)


| Concepto                                | Cuenta de ingreso                   | Centro de costo                                                                                               |
| --------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| **Cuota social**                        | `411001 Cuota social`               | `Administración`                                                                                              |
| **Arancel mensual** (deporte/actividad) | `412001 Arancel mensual actividad`  | Subcentro de la actividad (ej. `Deportes - Voley`, `Actividades - Yoga`, `Fitness - Gimnasio de Musculacion`) |
| **Packs CLASES**                        | `412002 Packs CLASES`               | Subcentro de la actividad                                                                                     |
| **Cuota federativa** (cobrada al socio) | `413001 Cuota federativa`           | Subcentro del deporte                                                                                         |
| **Inscripción / matrícula** (si aplica) | `411002 Inscripciones / matrículas` | `Administración` o subcentro                                                                                  |


- **DocType ERPNext:** `Sales Invoice` (generado por la sede digital).
- **Default Receivable** de la Company: `**Cuotas sociales a cobrar`** (`114001`).
- Cada concepto está mapeado a un **Item** (servicio) en ERPNext, que ya trae cuenta + centro de costo por defecto (`Item Default`).
- **Cost Center obligatorio** en `Sales Invoice` (dimensión mandatoria) para que no se pueda emitir “sin centro de costo”.

### 4.2 Cuota federativa — prorrateo del pago al organismo

Cuando el club **paga a la federación** un monto que cubre varios meses:

1. **Pago inicial** (Ej. paga 12 meses por adelantado):
  - **Débito** `115001 Anticipos / gastos pagados por adelantado`
  - **Crédito** `111201 Banco ARS` (o caja, según medio)
2. **Devengamiento mensual** (asiento contable o `Journal Entry` recurrente):
  - **Débito** `543001 Gastos federativos` (CC = `Deportes - <disciplina>`)
  - **Crédito** `115001 Anticipos / gastos pagados por adelantado`

> **Consulta al contador:** validar si prefieren manejar el devengamiento mensual vía `**Journal Entry` recurrente** (manual periódico) o usar el módulo **Deferred Expense** de ERPNext (devengamiento automático por fecha de inicio/fin del servicio prepago).

### 4.3 Alquileres

- **Cobro por transferencia / efectivo / Cobros Plus (ARS):** `Sales Invoice` con `421001 Alquiler canchas / espacios (ARS)` + CC `Alquileres - Temporal/Recurrente`.
- **Cobro en USD:** `Sales Invoice` en USD con `421002 Alquiler canchas / espacios (USD)` + CC `Alquileres - …`.
- La conversión a ARS para reportes contables se hace con el **Currency Exchange** del ERP (tipo de cambio configurable por fecha).

> **Consulta al contador:** ¿qué tipo de cambio se debe usar (BNA comprador/vendedor, MEP, otro) y con qué frecuencia se cargará? Hoy queda **abierto** para que lo defina contabilidad.

### 4.4 Gastronomía (POS — Buffet / Peña de Rock / Restaurante)

- **DocType ERPNext:** `POS Invoice` (o `Sales Invoice` desde POS Profile).
- **Cuenta de ingreso:** `441001 Ventas mostrador (POS)`.
- **Centro de costo:** subcentro de Gastronomía (`Buffet`, `Peña de Rock`, `Restaurante`).
- **Medios de pago configurados** (`Mode of Payment` → cuenta):
  - Efectivo ARS → `111101 Caja ARS`
  - Transferencia / débito bancario → `111201 Banco ARS`
  - (Tarjeta y/o gateway si se suman después)

### 4.5 Compras y gastos generales

- **DocType ERPNext:** `Purchase Invoice` / `Journal Entry`.
- **Cuenta de pasivo default:** `2110 Proveedores`.
- Cada línea de gasto debe llevar **cuenta de gasto + Cost Center** correcto.
- Servicios generales (luz/agua/gas/internet) por defecto → CC `Administración` (no se prorratea automáticamente; si más adelante hace falta, se usa el módulo **Cost Center Allocation** de ERPNext).

---

## 5. Integración con **Cobros Plus** (Banco Supervielle)

> Cobros Plus reemplaza la propuesta inicial de SIRO. Liquida **solo ARS**. El cobro online dispara un `**Payment Entry`** automático en ERPNext (no se concilia manualmente factura por factura).

### 5.1 Flujo contable

1. **Sede digital** genera `Sales Invoice` (ver §4.1) → queda saldo en `**Cuotas sociales a cobrar`**.
2. **Socio paga online** (Cobros Plus) → webhook crea `**Payment Entry`**:
  - **Débito** `115002 Cobros Plus - a liquidar (ARS)`
  - **Crédito** `Cuotas sociales a cobrar` (cancela el SI)
3. **Si la pasarela informa comisión** en el mismo evento → en el mismo `Payment Entry` se incluye una **deducción**:
  - **Débito** `572002 Comisiones Cobros Plus (ARS)`
  - El neto sigue impactando a `115002`.
4. **Liquidación de Cobros Plus al banco** (acreditación al `Banco ARS`):
  - **Débito** `111201 Banco ARS`
  - **Crédito** `115002 Cobros Plus - a liquidar (ARS)`
  - (Si la comisión recién se ve en el extracto, se asienta acá contra `572002`).

### 5.2 Garantías técnicas

- **Idempotencia:** el ID externo de Cobros Plus se guarda en el `Payment Entry`; si el webhook llega dos veces, no se duplica el asiento.
- **Cost Center**: heredado del `Sales Invoice` original; no debería “romperse” en el camino.
- **Devolución / reverso (si Cobros Plus la informa):** se modelará como `Payment Entry` inverso (a definir cuando aparezca el primer caso real).

> **Consulta al contador:** ¿es deseable separar comisión por tipo (Cobros Plus vs otros medios) en el reporte de PyG? Hoy está separada en `572002` justamente por eso.

---

## 6. Bimoneda (ARS / USD)

- **Moneda base de la Company:** ARS.
- **Cuentas USD declaradas explícitamente:**
  - `111102 Caja USD`
  - `111202 Banco USD`
  - `421002 Alquiler canchas / espacios (USD)`
- Cualquier otra cuenta queda en ARS por defecto.
- En `Sales Invoice` USD, ERPNext:
  - Mantiene importes en USD (moneda del documento).
  - Convierte a ARS para el asiento contable usando el tipo de cambio configurado.
  - El **diferencial cambiario** al cobrar se asienta automáticamente (ERPNext maneja una cuenta de “Exchange Gain/Loss”).

> **Pendiente de definición (contable):**
>
> - Cuenta de **diferencia de cambio** (ganancia/pérdida): hoy ERPNext puede crear una automática, pero conviene definirla explícitamente. Sugerencia: crear en Egresos `5700 Administración → Diferencias de cambio` o en Patrimonio según política. **A confirmar.**

---

## 7. Items (productos / servicios) y mapeo a cuentas

> Se creó un catálogo de **ítems tipo servicio** (no stock, UOM = `Servicio`), cada uno con sus **defaults por compañía** (`Item Default`: `income_account` + `selling_cost_center`).
> Esto hace que la sede digital y la facturación interna **no puedan equivocarse**: al elegir el ítem, ERPNext autocompleta cuenta y centro de costo.

### 7.1 Estructura de Item Groups

- `ICDPE / Cuotas y membresías`
- `ICDPE / Aranceles deportes` · `ICDPE / Packs deportes` · `ICDPE / Federaciones deportes`
- `ICDPE / Aranceles actividades` · `ICDPE / Packs actividades`
- `ICDPE / Aranceles fitness` · `ICDPE / Packs fitness`
- `ICDPE / Gastronomía POS`
- `ICDPE / Alquileres`
- `ICDPE / Comercial`
- `ICDPE / Actividades puntuales` (Colonias / Eventos)

### 7.2 Catálogo creado (resumen)


| Bloque                                                  | Cant.    | Cuenta ingreso (nro.)                  | Centro de costo                                 |
| ------------------------------------------------------- | -------- | -------------------------------------- | ----------------------------------------------- |
| Institucional (cuota social + inscripción)              | 2        | `411001`, `411002`                     | `Administración - ICDPE`                        |
| Deportes (arancel + packs + federativo) × 9 disciplinas | 27       | `412001`, `412002`, `413001`           | `Deportes - … - ICDPE`                          |
| Actividades (arancel + packs) × 6                       | 12       | `412001`, `412002`                     | `Actividades - … - ICDPE`                       |
| Fitness — Gimnasio de musculación                       | 2        | `412001`, `412002`                     | `Fitness - Gimnasio de Musculacion - ICDPE`     |
| Gastronomía POS × 3 unidades                            | 3        | `441001`                               | `Gastronomía - Buffet/Peña/Restaurante - ICDPE` |
| Alquileres ARS/USD × Temporal/Recurrente                | 4        | `421001`, `421002`                     | `Alquileres - Temporal/Recurrente - ICDPE`      |
| Comercial + Colonias/Eventos                            | 4        | `451001`, `451002`, `431002`, `431003` | varios                                          |
| **Total**                                               | **≈ 54** |                                        |                                                 |


> **Consulta al contador:** ¿la **cuota social** debería discriminarse por **categoría de socio** (activo / vitalicio / cadete / etc.) o alcanza con un único ítem `Cuota social` + el detalle por categoría dentro del padrón de socios?
> Hoy está modelada como **un único ítem** y la categoría queda en el socio (no en la cuenta).

---

## 8. Defaults configurados en ERPNext (resumen para validación)

### 8.1 Company `Institución Cultural y Deportiva Pedro Echagüe`

- **Default Receivable:** `Cuotas sociales a cobrar` (`114001`).
- **Default Payable:** `Proveedores` (`2110`).
- **Default Bank (ARS):** `Banco ARS` (`111201`).
- **Default Cash (ARS):** `Caja ARS` (`111101`).
- **Default Currency:** `ARS`.

### 8.2 Mode of Payment → Cuenta


| Medio                           | Cuenta                                      |
| ------------------------------- | ------------------------------------------- |
| Efectivo ARS                    | `111101 Caja ARS`                           |
| Efectivo USD *(si se usa)*      | `111102 Caja USD`                           |
| Transferencia ARS               | `111201 Banco ARS`                          |
| Transferencia USD *(si se usa)* | `111202 Banco USD`                          |
| **Cobros Plus (ARS)**           | `**115002 Cobros Plus - a liquidar (ARS)`** |


### 8.3 POS Profile — Gastronomía

- Default Income Account: `441001 Ventas mostrador (POS)`
- Default Cost Center: `Gastronomía` (o subcentro por sucursal/punto, según se decida).
- Modos de pago aceptados: efectivo + transferencia.

### 8.4 Dimensión obligatoria

- **Cost Center: obligatorio** en `Sales Invoice`, `POS Invoice`, `Purchase Invoice`, `Journal Entry`.
- Esto previene asientos sin segmentación.

---

## 9. Puntos abiertos para el contador

Por favor revisar y devolver decisión sobre:

1. **RECPAM / ajuste por inflación**: ¿se crea cuenta separada o se mantiene vía `Resultados acumulados` + `Ajustes de capital`?
2. **Diferencias de cambio** (alquileres USD): ¿cuenta dedicada en Egresos o en otra ubicación? ¿qué cotización aplica?
3. **Cuota social por categoría de socio**: ¿una sola cuenta `411001` o subcuentas por categoría (`411001.01 Activo`, `411001.02 Vitalicio`, etc.)?
4. **Cuota federativa**: confirmar tratamiento como **ingreso/gasto del club** (no “tercero / fondo de la federación”).
5. **Prorrateo de federativa pagada por adelantado**: ¿`Journal Entry` recurrente manual o uso de **Deferred Expense** automático de ERPNext?
6. **“Otros ingresos” y “Gastos administrativos varios”**: ¿se mantienen como “bolsa” con política de reclasificación mensual o se eliminan?
7. **Bienes de uso y amortizaciones**: ¿se cargan altas históricas como saldos iniciales (apertura) o se reconstruye sólo desde el ejercicio en curso? *(impacto en informes patrimoniales)*
8. **Cuentas de impuestos** (`213X`): hoy solo hay `Impuestos y tasas a pagar` agrupada. ¿Conviene desdoblar por tipo (IVA si aplica, IIBB, Tasa municipal)?
9. **Reportes oficiales**: ¿necesitan algún reporte particular además de Balance General y Estado de Resultados estándar de ERPNext (p. ej., presentación a inspección general de justicia o asamblea)?
10. **Numeración de comprobantes** (no es plan de cuentas pero impacta): definir series para `Sales Invoice` / `POS Invoice` / `Payment Entry` según normativa AFIP (electrónica) cuando se active.

---

## 10. Archivos de referencia (en el repositorio del proyecto)

- **Plan de cuentas (importer ERPNext):** `Chart of Accounts Importer - ICDPE.csv`
- **Centros de costo:**
  - Pasada 1 (grupos): `Centro de costos - ICDPE (1 - grupos).csv`
  - Pasada 2 (subcentros): `Centro de costos - ICDPE (2 - subcentros).csv`
- **Script de items servicio (Python / Frappe API):** `scripts/icdpe_create_service_items.py`
- **Este documento:** `docs/Accounting - ICDPE - Revision Contable.md`

---

## 11. Resumen ejecutivo (1 página para el contador)

- **Compañía única (un CUIT)**, ERPNext 16, moneda base ARS, con USD habilitado solo en **Caja USD**, **Banco USD** y **Alquiler USD**.
- **Plan de cuentas reorganizado por naturaleza** (qué se cobra/paga). Lo que antes eran cuentas por deporte (`Gastos Fútbol`, `Federación Básquet`, etc.) **ahora se reporta vía Centro de Costo**, no como cuenta nueva.
- **Nuevas cuentas clave incorporadas:**
  - `4120 Aranceles` (`412001` y `412002` packs).
  - `4130 Cuota federativa` (ingreso del club).
  - `543001 Gastos federativos` (contracara del pago a la federación).
  - `115001 Anticipos / gastos pagados por adelantado` (para prorrateo de federativa).
  - `115002 Cobros Plus - a liquidar (ARS)` + `572002 Comisiones Cobros Plus`.
- **Cobranza online** vía **Cobros Plus**, con `Payment Entry` automático e idempotente.
- **Sede digital** del socio = origen único de Sales Invoice para cuotas/aranceles/federativas/packs.
- **Gastronomía** opera con **POS** propio (cuentas y CC dedicados).
- **Reportes** salen automáticamente cruzando *cuenta × centro de costo* → no hace falta inventar reportes manuales por deporte.

Quedamos atentos a los comentarios y correcciones para dejarlo cerrado antes de operar en producción.