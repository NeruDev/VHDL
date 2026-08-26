<!--
---
file: Teoria/05_operadores.md
description: Operadores lógicos, relacionales, aritméticos, concatenación, desplazamiento y precedencia
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [operadores, logicos, aritmeticos, precedencia, vhdl]
---
-->

# Operadores

### 5.1 Lógicos
Aplicables a `STD_LOGIC`, `STD_LOGIC_VECTOR`, `BIT` y `BOOLEAN`.

| Operador | Descripción | Ejemplo |
|----------|-------------|---------|
| `AND`  | Y lógico | `s <= a AND b;` |
| `OR`   | O lógico | `s <= a OR b;` |
| `NAND` | Y negado | `s <= a NAND b;` |
| `NOR`  | O negado | `s <= a NOR b;` |
| `XOR`  | O exclusivo | `s <= a XOR b;` |
| `XNOR` | O exclusivo negado | `s <= a XNOR b;` |
| `NOT`  | Negación | `s <= NOT a;` |

```vhdl
SIGNAL a, b, c, y : STD_LOGIC;
y <= (a AND b) OR (NOT c);
```

### 5.2 Relacionales
Devuelven `BOOLEAN`. Se usan en condiciones `IF` y `WHEN`.

| Operador | Significado |
|----------|-------------|
| `=`  | Igual |
| `/=` | Distinto |
| `<`  | Menor que |
| `<=` | Menor o igual |
| `>`  | Mayor que |
| `>=` | Mayor o igual |

```vhdl
IF (contador >= MAX_CUENTA) THEN ...
IF (estado /= ERROR) THEN ...
```

> `<=` se usa también como operador de asignación de señal. El contexto determina
> si es comparación o asignación.

### 5.3 Aritméticos
Requieren `ieee.numeric_std` con tipos `UNSIGNED` o `SIGNED`.

| Operador | Descripción |
|----------|-------------|
| `+` | Suma |
| `-` | Resta |
| `*` | Multiplicación |
| `/` | División (solo potencias de 2 en síntesis) |
| `MOD` | Módulo |
| `REM` | Resto |
| `ABS` | Valor absoluto |

```vhdl
SIGNAL a, b, suma : UNSIGNED(7 DOWNTO 0);
suma <= a + b;
suma <= a - b;
suma <= a * b;  -- el resultado puede necesitar más bits
```

### 5.4 Concatenación y desplazamiento

```vhdl
-- Concatenación con &
SIGNAL hi    : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"AB";
SIGNAL lo    : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"CD";
SIGNAL bytes : STD_LOGIC_VECTOR(15 DOWNTO 0);
bytes <= hi & lo;   -- resultado: X"ABCD"

-- Insertar un bit en la posición más significativa (shift-in)
SIGNAL sreg : STD_LOGIC_VECTOR(7 DOWNTO 0);
sreg <= bit_entrada & sreg(7 DOWNTO 1);  -- desplaza derecha e inserta

-- Desplazamiento con operadores nativos
SIGNAL vec : STD_LOGIC_VECTOR(7 DOWNTO 0);
vec <= vec SLL 1;  -- desplazamiento lógico izquierda (rellena con '0')
vec <= vec SRL 1;  -- desplazamiento lógico derecha  (rellena con '0')
vec <= vec SLA 1;  -- desplazamiento aritmético izq. (rellena con bit[0])
vec <= vec SRA 1;  -- desplazamiento aritmético der. (rellena con MSB)
vec <= vec ROL 1;  -- rotación circular izquierda
vec <= vec ROR 1;  -- rotación circular derecha
```

> **Nota:** los operadores `SLL`/`SRL`/`SLA`/`SRA`/`ROL`/`ROR` tienen soporte
> irregular en herramientas de síntesis. Para máxima compatibilidad (Quartus II 13),
> preferir la concatenación explícita con `&` y slices.

### 5.5 Precedencia de operadores

De mayor a menor prioridad (los de mayor prioridad se evalúan primero):

| Prioridad | Operadores |
|-----------|------------|
| 1 (máxima) | `NOT`, `ABS`, `**` |
| 2 | `*`, `/`, `MOD`, `REM` |
| 3 | `+`, `-` (unarios) |
| 4 | `+`, `-`, `&` |
| 5 | `SLL`, `SRL`, `SLA`, `SRA`, `ROL`, `ROR` |
| 6 | `=`, `/=`, `<`, `<=`, `>`, `>=` |
| 7 | `AND`, `OR`, `NAND`, `NOR`, `XOR`, `XNOR` |

> **Regla práctica:** `AND`, `OR`, `XOR`, etc. tienen la **misma** prioridad en VHDL
> (a diferencia de C o Python). Usar paréntesis siempre que se mezclen:

```vhdl
-- INCORRECTO (ambigüedad, comportamiento inesperado):
y <= a AND b OR c;

-- CORRECTO (explícito):
y <= (a AND b) OR c;
```

---

*[⬆ Volver al Índice](README.md)*

---
