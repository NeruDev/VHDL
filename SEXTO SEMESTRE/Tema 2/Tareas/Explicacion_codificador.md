# ¿Cómo funciona el Codificador Binario ↔ Gray? (Guía Didáctica)

Esta guía explica (con el nivel de detalle de un curso intermedio) cómo se obtiene el "cerebro" lógico del codificador serial Binario↔Gray en Logisim.

Se basa en el documento técnico `codificadorBG_Logisim.md`, pero aquí se incluye el camino completo:

1) definición del problema, 2) estados, 3) tabla de transiciones completa (16 casos), 4) tabla de excitación JK, 5) mapas de Karnaugh y 6) verificación paso a paso.

---

## 1. Notación y convención de operación (serial + Moore)

### 1.1 Señales (nombres técnicos ↔ nombres "amigables")

| Nombre técnico | Nombre amigable | Significado |
| :--- | :--- | :--- |
| `SYS` | `MODO` | 0 = Gray→Binario, 1 = Binario→Gray |
| `N_bit` (o `N`) | `DATO_ENTRANTE` | Bit serial que llega en el ciclo actual |
| `Q1` | `BIT_BIN_GUARDADO` | Bit binario previo almacenado (memoria interna) |
| `Q0` | `SALIDA_ACTUAL` | Bit de salida almacenado (lo que se ve en la salida) |
| `C_BIT` | `SALIDA` | Bit de salida del sistema (Moore) |

### 1.2 Convención temporal (muy importante)

- El circuito procesa **1 bit por flanco de subida** de `CLK`.
- Usaremos la convención:
  - $Q$ = valor actual almacenado.
  - $Q^+$ = valor que quedará almacenado **después** del próximo flanco de reloj.
- En una **FSM Moore**, la salida observable es el estado actual: $$C_{BIT} = Q_0$$
- En la práctica, si alimentas un número de 4 bits, debes ingresar los bits **desde MSB a LSB** (ej.: `1101` significa 1, luego 1, luego 0, luego 1).

---

## 2. Fundamentos: ¿qué es Gray y cómo se convierte?

### 2.1 Propiedad clave del código Gray

Entre dos valores consecutivos en Gray, **solo cambia un bit**. Por eso es muy usado cuando no quieres que varias líneas cambien a la vez (reduce errores por "rebotes" o desalineación temporal).

### 2.2 Tabla de referencia (0–15)

| Decimal | Binario (B3 B2 B1 B0) | Gray (G3 G2 G1 G0) |
| :---: | :---: | :---: |
| 0 | `0000` | `0000` |
| 1 | `0001` | `0001` |
| 2 | `0010` | `0011` |
| 3 | `0011` | `0010` |
| 4 | `0100` | `0110` |
| 5 | `0101` | `0111` |
| 6 | `0110` | `0101` |
| 7 | `0111` | `0100` |
| 8 | `1000` | `1100` |
| 9 | `1001` | `1101` |
| 10 | `1010` | `1111` |
| 11 | `1011` | `1110` |
| 12 | `1100` | `1010` |
| 13 | `1101` | `1011` |
| 14 | `1110` | `1001` |
| 15 | `1111` | `1000` |

### 2.3 Reglas matemáticas estándar (paralelas)

Estas ecuaciones son la referencia "ideal" cuando conviertes los 4 bits a la vez:

**Binario → Gray:**

$$G_3 = B_3$$

$$G_i = B_{i+1} \oplus B_i \quad \text{para } i = 2,1,0$$

**Gray → Binario:**

$$B_3 = G_3$$

$$B_i = B_{i+1} \oplus G_i \quad \text{para } i = 2,1,0$$

> En esta guía implementamos la conversión **serial**, así que necesitaremos memoria para ir "arrastrando" información de un ciclo al siguiente.

---

## 3. ¿Por qué necesitamos memoria? (y por qué hay 4 estados)

### 3.1 La regla de oro: XOR como "detector de diferencia"

La operación XOR ($\oplus$) vale 1 cuando los bits son distintos y 0 cuando son iguales.

En el codificador serial, el bit convertido del ciclo actual siempre se calcula como:

$$v\_{curr\_out} = N\_{bit} \oplus Q_1$$

Intuición: comparamos lo que entra ahora con el "bit binario previo" guardado.

### 3.2 ¿Qué guardamos para el siguiente ciclo? (depende del modo)

- Si `SYS=1` (Binario→Gray), el binario "previo" del próximo ciclo debe ser el **binario actual**, o sea: $$v\_{curr\_bin} = N\_{bit}$$
- Si `SYS=0` (Gray→Binario), el binario "previo" del próximo ciclo es el **binario que acabas de calcular**, o sea: $$v\_{curr\_bin} = v\_{curr\_out}$$

Esto se resume como un multiplexor:

$$v\_{curr\_bin} = SYS\cdot N\_{bit} + \overline{SYS}\cdot (N\_{bit} \oplus Q_1)$$

### 3.3 Los 4 estados (codificación)

Tenemos dos bits de memoria: $Q_1$ y $Q_0$. Por lo tanto hay $2^2=4$ estados posibles.

| Estado (conceptual) | $Q_1$ (binario previo) | $Q_0$ (salida almacenada) | Significado |
| :--- | :---: | :---: | :--- |
| `S_BIN0_OUT0` | 0 | 0 | binario previo 0, salida 0 |
| `S_BIN0_OUT1` | 0 | 1 | binario previo 0, salida 1 |
| `S_BIN1_OUT0` | 1 | 0 | binario previo 1, salida 0 |
| `S_BIN1_OUT1` | 1 | 1 | binario previo 1, salida 1 |

**Estado inicial (RESET):** $Q_1=0$, $Q_0=0$.

---

## 4. La receta por ciclo (estado siguiente)

En cada ciclo, calculamos dos cosas:

1) **Salida a registrar (próximo $Q_0$):**

$$Q_0^+ = v\_{curr\_out} = N\_{bit} \oplus Q_1$$

2) **Bit binario a registrar (próximo $Q_1$):**

$$Q_1^+ = v\_{curr\_bin} = SYS\cdot N\_{bit} + \overline{SYS}\cdot (N\_{bit} \oplus Q_1)$$

Y la salida Moore visible siempre es:

$$C_{BIT} = Q_0$$

---

## 5. Tabla de transiciones completa (16 combinaciones)

La tabla siguiente muestra **todas** las combinaciones posibles de estado actual ($Q_1$, $Q_0$), modo (`SYS`) y entrada (`N_bit`), y el estado siguiente ($Q_1^+$, $Q_0^+$).

Columnas intermedias:

- $v\_{prev\_bin} = Q_1$
- $v\_{curr\_out} = N\_{bit} \oplus Q_1$
- $v\_{curr\_bin} = N\_{bit}$ si `SYS=1`, o $v\_{curr\_out}$ si `SYS=0`

| # | $Q_1$ | $Q_0$ | `SYS` | $N\_{bit}$ | $v\_{prev\_bin}$ | $v\_{curr\_out}$ | $v\_{curr\_bin}$ | $Q_1^+$ | $Q_0^+$ |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 0  | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 1  | 0 | 0 | 0 | 1 | 0 | 1 | 1 | 1 | 1 |
| 2  | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| 3  | 0 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 1 |
| 4  | 0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 5  | 0 | 1 | 0 | 1 | 0 | 1 | 1 | 1 | 1 |
| 6  | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| 7  | 0 | 1 | 1 | 1 | 0 | 1 | 1 | 1 | 1 |
| 8  | 1 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 |
| 9  | 1 | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 |
| 10 | 1 | 0 | 1 | 0 | 1 | 1 | 0 | 0 | 1 |
| 11 | 1 | 0 | 1 | 1 | 1 | 0 | 1 | 1 | 0 |
| 12 | 1 | 1 | 0 | 0 | 1 | 1 | 1 | 1 | 1 |
| 13 | 1 | 1 | 0 | 1 | 1 | 0 | 0 | 0 | 0 |
| 14 | 1 | 1 | 1 | 0 | 1 | 1 | 0 | 0 | 1 |
| 15 | 1 | 1 | 1 | 1 | 1 | 0 | 1 | 1 | 0 |

### 5.1 Observación clave: $Q_0$ no afecta el estado siguiente

Fíjate que si comparas los pares (0,4), (1,5), (2,6), (3,7), etc., el resultado $Q_1^+$ y $Q_0^+$ es idéntico aunque cambie $Q_0$.

Eso pasa porque $Q_0$ es **solo la salida Moore registrada**. La lógica de "estado siguiente" depende de $Q_1$, `SYS` y `N_bit`.

---

## 6. De transiciones a Flip-Flops JK (tabla de excitación)

Vamos a implementar los dos bits de estado ($Q_1$ y $Q_0$) con Flip-Flops JK.

### 6.1 Tabla genérica de excitación JK

| Transición $Q \rightarrow Q^+$ | $J$ | $K$ |
| :---: | :---: | :---: |
| $0 \rightarrow 0$ | 0 | X |
| $0 \rightarrow 1$ | 1 | X |
| $1 \rightarrow 0$ | X | 1 |
| $1 \rightarrow 1$ | X | 0 |

### 6.2 Tabla específica para este diseño (16 combinaciones)

Aquí aplicamos la tabla anterior a $Q_1 \rightarrow Q_1^+$ y $Q_0 \rightarrow Q_0^+$.

| $Q_1$ | $Q_0$ | `SYS` | $N\_{bit}$ | $J_1$ | $K_1$ | $J_0$ | $K_0$ |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 0 | 0 | 0 | 0 | 0 | X | 0 | X |
| 0 | 0 | 0 | 1 | 1 | X | 1 | X |
| 0 | 0 | 1 | 0 | 0 | X | 0 | X |
| 0 | 0 | 1 | 1 | 1 | X | 1 | X |
| 0 | 1 | 0 | 0 | 0 | X | X | 1 |
| 0 | 1 | 0 | 1 | 1 | X | X | 0 |
| 0 | 1 | 1 | 0 | 0 | X | X | 1 |
| 0 | 1 | 1 | 1 | 1 | X | X | 0 |
| 1 | 0 | 0 | 0 | X | 0 | 1 | X |
| 1 | 0 | 0 | 1 | X | 1 | 0 | X |
| 1 | 0 | 1 | 0 | X | 1 | 1 | X |
| 1 | 0 | 1 | 1 | X | 0 | 0 | X |
| 1 | 1 | 0 | 0 | X | 0 | X | 0 |
| 1 | 1 | 0 | 1 | X | 1 | X | 1 |
| 1 | 1 | 1 | 0 | X | 1 | X | 0 |
| 1 | 1 | 1 | 1 | X | 0 | X | 1 |

> Las X (*don't care*) son el espacio donde "elegimos" 0 o 1 para simplificar compuertas (sin romper el comportamiento).

---

## 7. Mapas de Karnaugh y ecuaciones finales

En esta sección simplificamos $J_1$, $K_1$, $J_0$ y $K_0$ usando mapas de Karnaugh de 4 variables.

**Convención del mapa:**

- Filas: $(Q_1 Q_0)$ en orden Gray: `00`, `01`, `11`, `10`.
- Columnas: `(SYS N)` en orden Gray: `00`, `01`, `11`, `10`.

### 7.1 Mapa de Karnaugh de $J_1$

| $J_1$ | `SYS N=00` | `01` | `11` | `10` |
| :---: | :---: | :---: | :---: | :---: |
| $Q_1Q_0=00$ | 0 | 1 | 1 | 0 |
| $Q_1Q_0=01$ | 0 | 1 | 1 | 0 |
| $Q_1Q_0=11$ | X | X | X | X |
| $Q_1Q_0=10$ | X | X | X | X |

Agrupando con las X, se obtiene:

$$J_1 = N\_{bit}$$

### 7.2 Mapa de Karnaugh de $K_1$

| $K_1$ | `SYS N=00` | `01` | `11` | `10` |
| :---: | :---: | :---: | :---: | :---: |
| $Q_1Q_0=00$ | X | X | X | X |
| $Q_1Q_0=01$ | X | X | X | X |
| $Q_1Q_0=11$ | 0 | 1 | 0 | 1 |
| $Q_1Q_0=10$ | 0 | 1 | 0 | 1 |

Una forma SOP (suma de productos) es:

$$K_1 = \overline{SYS}\,N\_{bit} + SYS\,\overline{N\_{bit}}$$

Que es exactamente un XOR:

$$K_1 = SYS \oplus N\_{bit}$$

### 7.3 Mapa de Karnaugh de $J_0$

| $J_0$ | `SYS N=00` | `01` | `11` | `10` |
| :---: | :---: | :---: | :---: | :---: |
| $Q_1Q_0=00$ | 0 | 1 | 1 | 0 |
| $Q_1Q_0=01$ | X | X | X | X |
| $Q_1Q_0=11$ | X | X | X | X |
| $Q_1Q_0=10$ | 1 | 0 | 0 | 1 |

Agrupando (y usando las X para cerrar grupos), resulta:

$$J_0 = \overline{Q_1}\,N\_{bit} + Q_1\,\overline{N\_{bit}} = Q_1 \oplus N\_{bit}$$

### 7.4 Mapa de Karnaugh de $K_0$

| $K_0$ | `SYS N=00` | `01` | `11` | `10` |
| :---: | :---: | :---: | :---: | :---: |
| $Q_1Q_0=00$ | X | X | X | X |
| $Q_1Q_0=01$ | 1 | 0 | 0 | 1 |
| $Q_1Q_0=11$ | 0 | 1 | 1 | 0 |
| $Q_1Q_0=10$ | X | X | X | X |

Agrupando:

$$K_0 = \overline{Q_1}\,\overline{N\_{bit}} + Q_1\,N\_{bit} = Q_1 \odot N\_{bit} = \overline{Q_1 \oplus N\_{bit}}$$

> Observación útil: con estas elecciones de X, queda $K_0 = \overline{J_0}$. Esto permite implementar ambos con una XOR y un NOT (o con una XNOR directa).

---

## 8. Resumen de ecuaciones (lo que se cablea en Logisim)

La lógica combinacional (módulo de estado siguiente) queda:

$$J_1 = N\_{bit}$$
$$K_1 = SYS \oplus N\_{bit}$$
$$J_0 = Q_1 \oplus N\_{bit}$$
$$K_0 = \overline{Q_1 \oplus N\_{bit}}$$

Y la salida Moore es directa:

$$C_{BIT} = Q_0$$

**Interpretación de compuertas:**

- $J_1$: cable directo desde `N_bit`.
- $K_1$: una XOR (`SYS` con `N_bit`).
- $J_0$: una XOR (`Q1` con `N_bit`).
- $K_0$: una XNOR (`Q1` con `N_bit`) o XOR + NOT.

---

## 9. Verificación paso a paso (end-to-end)

### 9.1 Ejemplo 1: Gray `1101` → Binario (poner `SYS=0`)

Según la tabla 0–15, Gray `1101` corresponde a Binario `1001` (decimal 9).

Condición inicial: aplicar `RST` para dejar $Q_1=0$, $Q_0=0$.

Procesamos MSB→LSB:

| Ciclo | $N\_{bit}$ (Gray) | $Q_1$ antes | $Q_0$ antes | $Q_0^+=N\oplus Q_1$ | $Q_1^+$ (porque `SYS=0`) | Salida observable ($C_{BIT}=Q_0$ después del flanco) |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| 1 | 1 | 0 | 0 | 1 | 1 | 1 |
| 2 | 1 | 1 | 1 | 0 | 0 | 0 |
| 3 | 0 | 0 | 0 | 0 | 0 | 0 |
| 4 | 1 | 0 | 0 | 1 | 1 | 1 |

Salida serial: `1001` ✔

### 9.2 Ejemplo 2: Binario `1001` → Gray (poner `SYS=1`)

Según la tabla 0–15, Binario `1001` corresponde a Gray `1101`.

Reset: $Q_1=0$, $Q_0=0$.

| Ciclo | $N\_{bit}$ (Bin) | $Q_1$ antes | $Q_0$ antes | $Q_0^+=N\oplus Q_1$ | $Q_1^+$ (porque `SYS=1`) | Salida observable ($C_{BIT}=Q_0$ después del flanco) |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| 1 | 1 | 0 | 0 | 1 | 1 | 1 |
| 2 | 0 | 1 | 1 | 1 | 0 | 1 |
| 3 | 0 | 0 | 1 | 0 | 0 | 0 |
| 4 | 1 | 0 | 0 | 1 | 1 | 1 |

Salida serial: `1101` ✔

---

*Este documento es una guía pedagógica diseñada para el curso de VHDL. Para la guía de construcción modular en Logisim y tablas técnicas, consulta `codificadorBG_Logisim.md`.*
