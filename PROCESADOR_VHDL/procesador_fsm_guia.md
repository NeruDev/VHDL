# Guía del procesador de 8 bits con FSM (VHDL + Logisim)

Documento basado en `unidad_control_comentada.vhd` y en el esquema de la ruta de datos en Logisim Evolution. Se divide en tres partes:

1. Principios de funcionamiento del procesador.
2. Explicación del código, parte por parte.
3. Cómo modificar el código: operaciones de la ALU, nuevos estados, nuevos opcodes y cambios en el uso de `H`/`L`.

> **Nota sobre las deducciones.** Lo que se afirma sobre la ruta de datos sale del esquema y del código. Los mnemónicos `JZ`/`JC`/`JS` y los códigos de `ope` (000 = pasa A, 010 = AND, 011 = NOT, 100 = DEC, 101 = ADD, 110 = SUB, 111 = INC) se deducen del uso en cada estado. Conviene verificarlos contra tus módulos `ALU`, `FLAGS` y `BR`.

---

## Índice

- [1. Principios de funcionamiento](#1-principios-de-funcionamiento)
- [2. El código explicado por partes](#2-el-código-explicado-por-partes)
- [3. Cómo modificar el código](#3-cómo-modificar-el-código)

---

## 1. Principios de funcionamiento

### 1.1 Visión general

El procesador se divide en dos bloques que trabajan juntos:

| Bloque | Qué hace | Dónde vive |
|---|---|---|
| **Ruta de datos** | Guarda y transforma los datos (registros, ALU, memoria, buses) | Esquema de Logisim |
| **Unidad de control** | Decide, en cada ciclo de reloj, qué componentes de la ruta de datos se activan | `unidad_control` (VHDL) |

La unidad de control es una **máquina de estados finitos (FSM)**. No toca los datos: solo genera señales (`Lpc`, `oe`, `wr`, `ope`...) que abren o cierran los caminos de la ruta de datos.

Es una arquitectura tipo **von Neumann**: instrucciones y datos conviven en la misma RAM de $256 \times 8$ bits, es decir $2^8 = 256$ direcciones de un byte cada una.

### 1.2 Componentes de la ruta de datos

| Bloque | Función | Entradas de control | Salida principal |
|---|---|---|---|
| **PC** | Contador de programa: dirección de la siguiente instrucción o byte a leer | `Lpc` (cargar), `Ipc` (incrementar) | `SalidaPC` → `MUXPCHL` |
| **HL** | Par de registros de dirección: `L` (byte bajo) y `H` (byte alto). Se cargan desde `BusDatos` | `LL`, `LH` | `SalidaHL` → `MUXPCHL` y `entradaPC` |
| **MUXPCHL** | Elige quién direcciona la memoria | `SelDir` (0 = PC, 1 = HL) | `dir` → `MEMORIA` |
| **MEMORIA** | RAM de $256 \times 8$ | `oe` (leer), `we` (escribir) | `datos` → `BusDatos` |
| **RI** | Registro de instrucción: guarda el opcode | `Lri` | `CO` → unidad de control |
| **BR** | Banco de registros (R0, R1...) | `SelRegRA`, `SelRegRB`, `SelRegW`, `wr` | `SalA`, `SalB` (la entrada de escritura `entDat` viene de `BusDatos`) |
| **ALU** | Opera sobre `SalA` y `SalB` | `ope` | `SalidaALU`, `SalidaFlags` |
| **FLAGS** | Registro de banderas Z, C y S | `LF` | `FLGS` → unidad de control |
| **BUFFERALU** | Buffer triestado que pone el resultado de la ALU en el bus | `SalAlu` | `BusDatos` |

### 1.3 El `BusDatos` y la regla del único emisor

`BusDatos` es un bus compartido. Dos componentes pueden **escribir** en él y varios pueden **leerlo**:

| Emisores (uno a la vez) | Receptores |
|---|---|
| `MEMORIA` (cuando `oe = 1`) | `RI`, `HL`, `BR` (por `entDat`) y `MEMORIA` (cuando `we = 1`) |
| `BUFFERALU` (cuando `SalAlu = 1`) | |

**Regla de oro:** en un mismo estado nunca deben estar activos `oe` y `SalAlu` a la vez, porque dos emisores en el mismo bus producen un conflicto. El código la respeta: LOAD usa `oe`, STORE usa `SalAlu`, y las operaciones de ALU usan `SalAlu` con `oe = 0`.

### 1.4 El ciclo de instrucción

Toda instrucción pasa por las mismas tres fases:

```text
        +-------------+     +-------------+     +----------------+
 ----> | S01_FETCH0  | --> | S02_FETCH1  | --> |   EJECUCION    | ---+
 |     | lee M[PC]   |     | PC+1        |     | estados propios|    |
 |     | RI <- byte  |     | decodifica  |     | de cada opcode |    |
 |     +-------------+     +-------------+     +----------------+    |
 +--------------------------------------------------------------------+
```

1. **Fetch** (S01 y S02): se lee el opcode de `M[PC]` y se guarda en `RI`.
2. **Decode** (S02): la FSM mira `CO` (salida de `RI`) y elige el siguiente estado.
3. **Execute**: uno o varios estados propios de la instrucción. Al terminar se vuelve a S01.

### 1.5 Temporización: qué pasa en cada ciclo

Cada estado dura un ciclo de reloj. Las salidas de la FSM son combinacionales: se mantienen estables durante todo el estado. Los registros destino (`RI`, `HL`, `PC`, `BR`, `FLAGS`) **capturan su valor en el flanco de subida** que cierra ese estado.

> **Consecuencia práctica:** lo que activas en el estado *N* se ve reflejado en el estado *N+1*.

Ejemplo: en S01 se activa `Lri`, el opcode se captura en `RI` al final del ciclo, y por eso `CO` ya es válido en S02, donde se decodifica.

El tiempo total de un programa es $T = N_{ciclos} \cdot T_{clk}$, donde $N_{ciclos}$ es la suma de los ciclos de cada instrucción ejecutada.

### 1.6 Registros de programación

El banco `BR` tiene selectores de 3 bits ($2^3 = 8$ registros posibles), pero esta FSM solo usa dos:

| Selector | Registro | Uso en la FSM |
|---|---|---|
| `"000"` | R0 | Operando A de las operaciones de dos operandos |
| `"001"` | R1 | Operando B, destino de casi todas las operaciones, y registro de LOAD/STORE/MOVI |

R1 funciona como un acumulador implícito: casi todas las instrucciones escriben su resultado en R1.

### 1.7 Formato de instrucciones y juego de instrucciones

Hay tres formatos según cuántos bytes ocupa la instrucción en memoria:

| Formato | Bytes | Contenido | Instrucciones |
|---|---|---|---|
| Sin operando | 1 | `[opcode]` | NOT, AND, DEC, INC, SUB, ADD, MOV, FIN |
| Con inmediato | 2 | `[opcode][dato]` | MOVI |
| Con dirección | 3 | `[opcode][L][H]` | LOAD, STORE, JMP, JZ, JC, JS |

En las instrucciones de 3 bytes el **primer byte tras el opcode es L (byte bajo)** y el segundo es H (byte alto).

| CO | Instrucción | Efecto | Ciclos |
|---|---|---|---|
| 40h | NOT | R1 ← NOT R1 | 3 |
| 41h | AND | R1 ← R0 AND R1 | 3 |
| 42h | DEC | R1 ← R1 − 1 | 3 |
| 43h | INC | R1 ← R1 + 1 | 3 |
| 44h | SUB | R1 ← R0 − R1 | 3 |
| 45h | ADD | R1 ← R0 + R1 | 3 |
| 46h | MOV | R0 ← R1 | 3 |
| 47h | MOVI | R1 ← byte inmediato | 4 |
| 70h | LOAD | R1 ← M[HL] | 7 |
| 71h | STORE | M[HL] ← R1 | 7 |
| 80h | JMP | PC ← HL | 7 |
| 81h | JZ | PC ← HL si FZ = 1 | 7 (6 si no salta) |
| 82h | JC | PC ← HL si FC = 1 | 7 (6 si no salta) |
| 83h | JS | PC ← HL si FS = 1 | 7 (6 si no salta) |
| FFh | FIN | Detiene el procesador | — |

**Regla de contabilidad del PC:** cada byte de la instrucción consume exactamente un incremento (`Ipc`). El opcode lo consume S02; los operandos los consumen los estados siguientes. Al terminar una instrucción el PC debe apuntar al primer byte de la siguiente. Si agregas estados, esta cuenta tiene que seguir cuadrando.

### 1.8 Traza de una instrucción: `LOAD 0010h`

Memoria en `0000h`: `70 10 00` (opcode, L = 10h, H = 00h). Supón `M[0010h] = 2Ah`.

| Ciclo | Estado | PC | Señales activas | Qué ocurre |
|---|---|---|---|---|
| 1 | S01_FETCH0 | 0 | `oe`, `Lri` | Se lee `M[0]` = 70h y se guarda en RI |
| 2 | S02_FETCH1 | 0 | `Ipc` | PC pasa a 1; `CO` = 70h → va a S03 |
| 3 | S03_LOAD0_STORE0 | 1 | `oe`, `LL` | L ← `M[1]` = 10h |
| 4 | S04_LOAD1_STORE1 | 1 | `Ipc` | PC pasa a 2 |
| 5 | S05_LOAD2_STORE2 | 2 | `oe`, `LH` | H ← `M[2]` = 00h |
| 6 | S06_LOAD3_STORE3 | 2 | `Ipc` | PC pasa a 3; `CO` = 70h → va a S07 |
| 7 | S07_LOAD4 | 3 | `SelDir`, `oe`, `wr` (`SelRegW` = 001) | R1 ← `M[HL]` = `M[0010h]` = 2Ah |
| 8 | S01_FETCH0 | 3 | `oe`, `Lri` | Empieza la siguiente instrucción |

### 1.9 Programa de ejemplo: cuenta regresiva

Objetivo: cargar 5 en R1 y restar 1 hasta llegar a 0.

| Dirección | Byte | Significado |
|---|---|---|
| 00h | `47` | MOVI |
| 01h | `05` | dato inmediato = 5 |
| 02h | `42` | DEC |
| 03h | `81` | JZ |
| 04h | `09` | L del destino |
| 05h | `00` | H del destino |
| 06h | `80` | JMP |
| 07h | `02` | L del destino |
| 08h | `00` | H del destino |
| 09h | `FF` | FIN |

Funcionamiento (suponiendo que la ALU activa Z cuando el resultado es 0): R1 baja 5 → 4 → 3 → 2 → 1 → 0. Mientras R1 ≠ 0, `JZ` no salta y `JMP 0002h` repite el `DEC`. Cuando R1 = 0 se activa FZ, `JZ` salta a `0009h` y la FSM llega a `FIN`.

Cuenta de ciclos hasta que `Fin = 1`:

$$N = 4 + 4\,(3 + 6 + 7) + (3 + 7) + 3 = 81$$

(MOVI; cuatro vueltas completas de DEC + JZ sin salto + JMP; la última pasada con DEC + JZ con salto; y los tres ciclos de FIN.)

---

## 2. El código explicado por partes

### 2.1 Encabezado y librerías

```vhdl
-- Librerias estandar de IEEE
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;  -- STD_LOGIC y STD_LOGIC_VECTOR
USE IEEE.NUMERIC_STD.ALL;     -- aritmetica sobre vectores (no se usa directamente)
```

- El bloque de comentarios inicial documenta el problema (integrar el bus `FLGS`) y la solución con alias.
- `STD_LOGIC_1164` es la única librería realmente necesaria: define los tipos de las señales.

### 2.2 La entidad: la caja negra

La entidad define solo los pines. En Logisim es el bloque `unidad_control` con sus conexiones.

| Grupo | Puertos | Tipo | Descripción |
|---|---|---|---|
| Globales | `clk`, `rst` | entrada | Reloj y reset (activo en alto, asíncrono) |
| Estado de la ruta | `CO` (8 bits) | entrada | Opcode guardado en RI |
| | `FLGS` (8 bits) | entrada | Bus de banderas; solo se usan los bits 0, 1 y 2 |
| Control del PC | `Lpc`, `Ipc` | salida | Cargar / incrementar el PC |
| Control de direcciones | `SelDir`, `LH`, `LL` | salida | Selector del MUX y carga de H y L |
| Instrucción | `Lri` | salida | Cargar RI |
| Banco de registros | `SelRegW`, `SelRegRA`, `SelRegRB` (3 bits), `wr` | salida | Destino, orígenes A y B, habilitar escritura |
| ALU | `ope` (3 bits), `SalAlu`, `LF` | salida | Operación, habilitar buffer de salida, cargar banderas |
| Memoria | `oe`, `we` | salida | Lectura y escritura (activos en alto) |
| Estado | `Fin` | salida | Indica fin de programa |
| Depuración | `estado_out` (5 bits) | salida | Estado actual para sondas |

### 2.3 Los alias de las banderas

```vhdl
ALIAS FZ : STD_LOGIC IS FLGS(0); -- Zero  en el bit 0
ALIAS FC : STD_LOGIC IS FLGS(1); -- Carry en el bit 1
ALIAS FS : STD_LOGIC IS FLGS(2); -- Sign  en el bit 2
```

Un `ALIAS` no crea hardware: es otro nombre para el mismo bit. Permite escribir `IF FZ = '1'` en lugar de `IF FLGS(0) = '1'`. Si el módulo `FLAGS` cambia el orden de los bits, solo se modifican estas tres líneas.

### 2.4 El tipo de estados y las señales

```vhdl
TYPE estado_t IS ( S00_RESET, S01_FETCH0, S02_FETCH1, ... S19_SUB0 );
SIGNAL estado_actual, estado_siguiente : estado_t;
```

- `estado_t` es un tipo enumerado: una lista de nombres. El sintetizador elige la codificación binaria.
- `estado_actual` es la memoria de la FSM (se guarda en flip-flops).
- `estado_siguiente` es lo que la lógica combinacional decide para el próximo flanco.

| Grupo | Estados | Función |
|---|---|---|
| Inicio | S00 | Estado tras el reset |
| Fetch | S01, S02 | Buscar y decodificar |
| Lectura de dirección | S03 a S06 | Compartidos por LOAD, STORE y saltos |
| Memoria | S07 (LOAD), S08 (STORE) | Acceso a M[HL] |
| ALU | S09 (ADD), S15 (NOT), S16 (AND), S17 (DEC), S18 (INC), S19 (SUB) | Un estado por operación |
| Transferencia | S10 (MOV), S12 y S13 (MOVI) | Copiar datos |
| Control | S11 (FIN), S14 (ejecutar salto) | Detener / saltar |

### 2.5 La salida `estado_out`

```vhdl
WITH estado_actual SELECT
    estado_out <= "00000" WHEN S00_RESET,
                  "00001" WHEN S01_FETCH0,
                  ...
                  "11111" WHEN OTHERS;
```

- Es una asignación concurrente que convierte el nombre del estado en un número de 5 bits.
- Sirve solo para depurar: conecta `estado_out` a una sonda en Logisim y verás en qué estado está la FSM.
- Con 5 bits caben $2^5 = 32$ códigos. `"11111"` queda reservado para `OTHERS`, así que los estados útiles van del 0 al 30.

### 2.6 El proceso secuencial

```vhdl
PROCESS(clk, rst)
BEGIN
    IF rst = '1' THEN
        estado_actual <= S00_RESET;           -- reset asincrono
    ELSIF rising_edge(clk) THEN
        estado_actual <= estado_siguiente;    -- avanza en cada flanco
    END IF;
END PROCESS;
```

- Es la única parte del código con reloj: aquí se "guarda" el estado.
- `rst = '1'` fuerza S00 de inmediato, sin esperar al reloj.
- Este reset solo afecta a la FSM. PC, HL, RI, BR y FLAGS se limpian con la señal `CLEAR` de la ruta de datos.

### 2.7 El proceso combinacional

Calcula dos cosas en cada estado: las **salidas** y el **estado siguiente**.

```vhdl
PROCESS(estado_actual, CO, FLGS)
```

La lista sensible incluye `FLGS` porque los saltos condicionales dependen de las banderas. Si falta alguna señal que se lee dentro del proceso, la simulación puede no reaccionar a sus cambios.

#### 2.7.1 Valores por defecto

Al inicio del proceso se apagan todas las salidas:

```vhdl
Lpc <= '0';  Ipc <= '0';  SelDir <= '0';  LH <= '0';  LL <= '0';  Lri <= '0';
wr <= '0';   SalAlu <= '0';  LF <= '0';   Fin <= '0'; oe <= '0';  we <= '0';
SelRegW <= "000";  SelRegRA <= "000";  SelRegRB <= "000";  ope <= "000";
estado_siguiente <= estado_actual;   -- por defecto, retener el estado
```

Esto simplifica todo lo demás:

- Cada estado solo escribe las señales que necesita encender.
- Se evitan latches no deseados (una salida sin asignar en alguna rama).
- Nada queda activo "por accidente" de un estado al siguiente.

#### 2.7.2 Estados S00 a S02: arranque, fetch y decodificación

| Estado | Salidas activas | Siguiente |
|---|---|---|
| S00_RESET | ninguna | S01 |
| S01_FETCH0 | `oe`, `Lri` | S02 |
| S02_FETCH1 | `Ipc` | según `CO` |

S02 contiene el **decodificador central**:

```vhdl
CASE CO IS
    WHEN x"40" => estado_siguiente <= S15_NOT0;
    ...
    WHEN x"70" => estado_siguiente <= S03_LOAD0_STORE0;
    WHEN x"80" => estado_siguiente <= S03_LOAD0_STORE0;
    WHEN x"FF" => estado_siguiente <= S11_FIN0;
    WHEN OTHERS => estado_siguiente <= S01_FETCH0;  -- opcode desconocido
END CASE;
```

- Es el único lugar donde un opcode se asocia a un camino de ejecución.
- Un opcode desconocido vuelve a S01. Como S02 ya incrementó el PC, ese byte simplemente se ignora.

#### 2.7.3 Estados S03 a S06: lectura de la dirección de 2 bytes

Los usan LOAD, STORE y los cuatro saltos, porque todos llevan `[L][H]` tras el opcode.

| Estado | Salidas activas | Efecto | Siguiente |
|---|---|---|---|
| S03 | `oe`, `LL` | L ← `M[PC]` | S04 |
| S04 | `Ipc` | PC avanza al segundo byte | S05 |
| S05 | `oe`, `LH` | H ← `M[PC]` | S06 |
| S06 | `Ipc` | PC apunta a la siguiente instrucción; bifurca | ver abajo |

En estos estados `SelDir = 0`, así que la memoria sigue direccionada por el PC. S04 existe solo para mover el contador: el PC solo puede hacer una cosa por ciclo.

S06 es el punto de bifurcación:

```vhdl
IF CO = x"70" THEN     estado_siguiente <= S07_LOAD4;
ELSIF CO = x"71" THEN  estado_siguiente <= S08_STORE5;
ELSIF CO = x"80" THEN  estado_siguiente <= S14_JMP_COND;       -- salto incondicional
ELSIF CO = x"81" THEN
    IF FZ = '1' THEN estado_siguiente <= S14_JMP_COND;         -- salta si Z = 1
    ELSE             estado_siguiente <= S01_FETCH0;           -- si no, sigue
    END IF;
...
```

La decisión de saltar o no se toma aquí, con las banderas del momento. Si no se salta, el PC ya apunta a la siguiente instrucción y la ejecución continúa en secuencia.

#### 2.7.4 Acceso a memoria: S07 (LOAD) y S08 (STORE)

| Estado | Señales | Qué hace |
|---|---|---|
| S07_LOAD4 | `SelDir`=1, `oe`=1, `SelRegW`="001", `wr`=1 | El MUX direcciona con HL; el dato de la memoria baja por `BusDatos` y se escribe en R1 |
| S08_STORE5 | `SelDir`=1, `we`=1, `SelRegRA`="001", `ope`="000", `SalAlu`=1 | R1 pasa por la ALU sin cambios, el buffer lo pone en el bus y la memoria lo escribe en HL |

Fíjate en que STORE tiene `oe = 0` y LOAD tiene `SalAlu = 0`: así se respeta la regla del único emisor.

#### 2.7.5 La familia ALU

Todas las operaciones de ALU siguen la misma receta de un estado:

1. Elegir los registros origen (`SelRegRA`, `SelRegRB`).
2. Elegir la operación (`ope`).
3. Habilitar el buffer (`SalAlu = 1`) para que el resultado llegue al bus.
4. Elegir el destino (`SelRegW`) y escribir (`wr = 1`).
5. Guardar las banderas (`LF = 1`).

| Estado | Instrucción | `SelRegRA` | `SelRegRB` | `SelRegW` | `ope` |
|---|---|---|---|---|---|
| S09_ADD0 | ADD | 000 | 001 | 001 | 101 |
| S15_NOT0 | NOT | 001 | — | 001 | 011 |
| S16_AND0 | AND | 000 | 001 | 001 | 010 |
| S17_DEC0 | DEC | 001 | — | 001 | 100 |
| S18_INC0 | INC | 001 | — | 001 | 111 |
| S19_SUB0 | SUB | 000 | 001 | 001 | 110 |

Las operaciones de un solo operando (NOT, DEC, INC) no usan `SelRegRB`, que queda en su valor por defecto.

#### 2.7.6 MOV y MOVI

| Estado | Señales | Qué hace |
|---|---|---|
| S10_MOV0 | `SelRegRA`="001", `ope`="000", `SalAlu`=1, `SelRegW`="000", `wr`=1 | R0 ← R1 (pasa por la ALU sin cambios). No activa `LF`: conserva las banderas |
| S12_MOVI0 | `oe`=1, `SelRegW`="001", `wr`=1 | R1 ← `M[PC]` (el PC ya apunta al byte inmediato) |
| S13_MOVI1 | `Ipc`=1 | Salta el byte inmediato para que no se ejecute como opcode |

#### 2.7.7 El salto: S14

```vhdl
WHEN S14_JMP_COND =>
    SelDir <= '1';   -- el MUX elige HL
    Lpc    <= '1';   -- el PC se carga con HL
    estado_siguiente <= S01_FETCH0;
```

Este estado **no revisa banderas**: la decisión ya se tomó en S06. Si se llegó aquí, se salta. Según el esquema, `entradaPC` se toma directamente de `SalidaHL`, así que `SelDir = 1` parece redundante aunque inofensivo.

#### 2.7.8 FIN y `OTHERS`

```vhdl
WHEN S11_FIN0 =>
    Fin <= '1';
    estado_siguiente <= S11_FIN0;     -- se queda aqui hasta un reset

WHEN OTHERS =>
    estado_siguiente <= S01_FETCH0;   -- red de seguridad
```

### 2.8 Tabla resumen de señales por estado

Solo se listan las señales distintas de su valor por defecto.

| Estado | Señales en '1' | Buses | Siguiente |
|---|---|---|---|
| S00_RESET | — | — | S01 |
| S01_FETCH0 | `oe`, `Lri` | — | S02 |
| S02_FETCH1 | `Ipc` | — | según `CO` |
| S03_LOAD0_STORE0 | `oe`, `LL` | — | S04 |
| S04_LOAD1_STORE1 | `Ipc` | — | S05 |
| S05_LOAD2_STORE2 | `oe`, `LH` | — | S06 |
| S06_LOAD3_STORE3 | `Ipc` | — | S07 / S08 / S14 / S01 |
| S07_LOAD4 | `SelDir`, `oe`, `wr` | W=001 | S01 |
| S08_STORE5 | `SelDir`, `we`, `SalAlu` | RA=001, ope=000 | S01 |
| S09_ADD0 | `SalAlu`, `LF`, `wr` | RA=000, RB=001, W=001, ope=101 | S01 |
| S10_MOV0 | `SalAlu`, `wr` | RA=001, W=000, ope=000 | S01 |
| S11_FIN0 | `Fin` | — | S11 |
| S12_MOVI0 | `oe`, `wr` | W=001 | S13 |
| S13_MOVI1 | `Ipc` | — | S01 |
| S14_JMP_COND | `SelDir`, `Lpc` | — | S01 |
| S15_NOT0 | `SalAlu`, `LF`, `wr` | RA=001, W=001, ope=011 | S01 |
| S16_AND0 | `SalAlu`, `LF`, `wr` | RA=000, RB=001, W=001, ope=010 | S01 |
| S17_DEC0 | `SalAlu`, `LF`, `wr` | RA=001, W=001, ope=100 | S01 |
| S18_INC0 | `SalAlu`, `LF`, `wr` | RA=001, W=001, ope=111 | S01 |
| S19_SUB0 | `SalAlu`, `LF`, `wr` | RA=000, RB=001, W=001, ope=110 | S01 |

---

## 3. Cómo modificar el código

### 3.1 Quién decide qué

Antes de modificar nada conviene separar responsabilidades:

| Pregunta | Quién la decide | Dónde se cambia |
|---|---|---|
| ¿Qué hace la ALU con cada código `ope`? | El módulo `ALU` | Esquema de Logisim |
| ¿Qué código `ope` pide cada instrucción? | La FSM | `ope <= "xxx"` en el estado |
| ¿Qué opcode lanza cada instrucción? | El decodificador de S02 | `CASE CO` en S02 |
| ¿Qué pasos sigue cada instrucción? | Los estados | Un `WHEN` por estado |

Por eso, cambiar el comportamiento de una operación puede implicar tocar la ALU, la FSM o ambas.

### 3.2 Cambiar qué hace una instrucción existente

**Caso A: la ALU ya implementa la operación deseada.** Basta con cambiar `ope` en el estado. Por ejemplo, si INC debe pasar a hacer SUB:

```vhdl
-- Antes: INC usa ope = "111"
WHEN S18_INC0 =>
    SelRegRA <= "001";
    SelRegW  <= "001";
    ope      <= "111";    -- cambiar por el codigo de la operacion deseada
```

**Caso B: cambiar los registros involucrados.** Se modifican `SelRegRA`, `SelRegRB` o `SelRegW`. Por ejemplo, un ADD que guarde el resultado en R0 en lugar de R1:

```vhdl
WHEN S09_ADD0 =>
    SelRegRA <= "000";
    SelRegRB <= "001";
    SelRegW  <= "000";    -- destino: R0 en lugar de R1
    ope      <= "101";
    SalAlu   <= '1';
    LF       <= '1';
    wr       <= '1';
    estado_siguiente <= S01_FETCH0;
```

### 3.3 Agregar una operación nueva de la ALU (ejemplo: OR)

Con `ope` de 3 bits hay $2^3 = 8$ códigos posibles. La FSM usa siete (000, 010, 011, 100, 101, 110, 111), así que el código `001` queda libre.

**Paso 1. Implementar la operación en la ALU de Logisim.** Haz que el código `001` produzca `SalA OR SalB` y que la ALU siga calculando las banderas. Este paso es obligatorio: la FSM solo *pide* la operación.

**Paso 2. Declarar el nuevo estado** en `estado_t`:

```vhdl
TYPE estado_t IS (
    S00_RESET, ... S19_SUB0,
    S20_OR0                      -- nuevo estado
);
```

**Paso 3. Asignarle un código de depuración** en `estado_out`:

```vhdl
"10100" WHEN S20_OR0,            -- 20 en binario
```

**Paso 4. Asignarle un opcode** en el decodificador de S02. Elige uno libre; conviene mantener la familia 4x para las operaciones de registros:

```vhdl
WHEN x"48" => estado_siguiente <= S20_OR0;   -- OR
```

**Paso 5. Escribir el estado** copiando la plantilla de la familia ALU:

```vhdl
-- OR (48h): R1 <- R0 OR R1
WHEN S20_OR0 =>
    SelRegRA <= "000";   -- operando A = R0
    SelRegRB <= "001";   -- operando B = R1
    SelRegW  <= "001";   -- destino = R1
    ope      <= "001";   -- codigo de OR (debe existir en la ALU)
    SalAlu   <= '1';     -- el resultado llega al bus
    LF       <= '1';     -- actualiza banderas
    wr       <= '1';     -- escribe en el banco de registros
    estado_siguiente <= S01_FETCH0;
```

La instrucción ocupa un byte, así que no necesita más cambios: S02 ya incrementó el PC y el estado vuelve a S01.

### 3.4 Más de 8 operaciones: ensanchar `ope`

Si necesitas más de ocho operaciones hay que pasar `ope` a 4 bits ($2^4 = 16$ códigos). Cambios necesarios:

```vhdl
-- 1) Entidad: ensanchar el puerto
ope : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

-- 2) Valor por defecto del proceso combinacional
ope <= "0000";

-- 3) Cada asignacion existente gana un cero a la izquierda
ope <= "0101";   -- antes "101" (ADD)
ope <= "1000";   -- ejemplo de operacion nueva (codigo 8)
```

Y en Logisim: ensanchar el pin `ope` de la ALU, el pin de salida de `unidad_control` y los cables o etiquetas que los unen (data bits = 4). Si olvidas alguno, Logisim marca el cable con error de ancho.

### 3.5 Una instrucción nueva que reutiliza estados (ejemplo: MOVI a R0)

Hoy MOVI carga el inmediato en R1. Para una variante que cargue R0 puedes reutilizar el estado `S13_MOVI1` (el que salta el byte inmediato):

```vhdl
-- Nuevo estado (declarar en estado_t y en estado_out, como en 3.3)
-- Opcode: WHEN x"49" => estado_siguiente <= S21_MOVI_R0;

WHEN S21_MOVI_R0 =>
    oe      <= '1';      -- lee el byte inmediato M[PC]
    SelRegW <= "000";    -- destino = R0
    wr      <= '1';
    estado_siguiente <= S13_MOVI1;   -- reutiliza: Ipc salta el inmediato
```

Fíjate en que solo se escribe un estado nuevo: lo demás ya existía. Es la forma más económica de crecer.

### 3.6 Modificaciones relacionadas con H y L

El par `HL` se carga desde `BusDatos` con `LL` y `LH`, y su salida alimenta el MUX y el PC. Eso permite varias ideas útiles.

#### a) Cargar H o L con un byte inmediato (ejemplo: LDH, opcode 74h)

Permite construir direcciones por software, sin una instrucción de 3 bytes:

```vhdl
-- Opcode: WHEN x"74" => estado_siguiente <= S23_LDH0;

WHEN S23_LDH0 =>
    oe <= '1';           -- lee el byte inmediato M[PC]
    LH <= '1';           -- lo guarda en H
    estado_siguiente <= S13_MOVI1;   -- reutiliza: Ipc salta el inmediato
```

Para `LDL` basta repetir el estado con `LL <= '1'` en lugar de `LH`.

#### b) Copiar un registro a L (ejemplo: MOV L,R1, opcode 4Ah)

Como `HL` lee `BusDatos` y el buffer de la ALU puede escribir en él, se puede mover R1 a L sin pasar por memoria:

```vhdl
-- Opcode: WHEN x"4A" => estado_siguiente <= S22_MOVL0;

WHEN S22_MOVL0 =>
    SelRegRA <= "001";   -- lee R1
    ope      <= "000";   -- la ALU deja pasar A sin cambios
    SalAlu   <= '1';     -- R1 llega al BusDatos
    LL       <= '1';     -- L captura el valor del bus
    estado_siguiente <= S01_FETCH0;
```

Aquí no se activa `oe` ni `wr`. Combinado con INC o ADD, permite recorrer vectores en memoria: incrementar un registro, copiarlo a L y hacer LOAD.

#### c) Salto indirecto: JMP HL (opcode 84h)

Si HL ya contiene la dirección, no hace falta leerla de memoria. El decodificador puede mandar el opcode directamente a S14:

```vhdl
WHEN x"84" => estado_siguiente <= S14_JMP_COND;   -- 3 ciclos: S01, S02, S14
```

Ahorra cuatro ciclos frente a JMP normal, pero exige haber cargado HL antes (por ejemplo con LDH y LDL).

#### d) LOAD y STORE con dirección de 1 byte

Con una RAM de $256 \times 8$ solo se necesita el byte bajo; según tu esquema, la memoria recibe únicamente `dirL`. Se pueden crear opcodes cortos que omitan la lectura de H:

```vhdl
-- En S02: WHEN x"72" => S03...; WHEN x"73" => S03...;  (LOADD / STORED)

-- Se modifica S04 para que bifurque segun el opcode
WHEN S04_LOAD1_STORE1 =>
    Ipc <= '1';
    IF CO = x"72" THEN      estado_siguiente <= S07_LOAD4;    -- LOAD corto
    ELSIF CO = x"73" THEN   estado_siguiente <= S08_STORE5;   -- STORE corto
    ELSE                    estado_siguiente <= S05_LOAD2_STORE2;
    END IF;
```

La instrucción pasa de 7 a 5 ciclos y de 3 a 2 bytes. Contabilidad del PC: el opcode lo consume S02 y el byte L lo consume el `Ipc` de S04, así que el PC termina apuntando a la siguiente instrucción. H conserva un valor anterior, pero la memoria no lo usa.

> Verifica en tu esquema que la memoria use solo `dirL`. Si algún módulo usara `dirH`, esta variante no sería válida.

### 3.7 Agregar una bandera nueva

Si la ALU y el registro `FLAGS` producen un bit adicional (por ejemplo, desbordamiento en `FLGS(3)`):

```vhdl
-- 1) Alias nuevo en la parte declarativa
ALIAS FV : STD_LOGIC IS FLGS(3);   -- Bandera Overflow

-- 2) Opcode nuevo en S02 (comparte la lectura de direccion)
WHEN x"85" => estado_siguiente <= S03_LOAD0_STORE0;   -- JV

-- 3) Rama nueva en S06
ELSIF CO = x"85" THEN
    IF FV = '1' THEN estado_siguiente <= S14_JMP_COND;
    ELSE             estado_siguiente <= S01_FETCH0;
    END IF;
```

No hace falta tocar la lista sensible del proceso: ya incluye `FLGS` completo.

### 3.8 Plantillas listas para copiar

**Instrucción ALU de un byte:**

```vhdl
WHEN S2x_NUEVA0 =>
    SelRegRA <= "000";  -- operando A
    SelRegRB <= "001";  -- operando B (omitir si usa un solo operando)
    SelRegW  <= "001";  -- destino
    ope      <= "xxx";  -- codigo de la operacion en la ALU
    SalAlu   <= '1';
    LF       <= '1';
    wr       <= '1';
    estado_siguiente <= S01_FETCH0;
```

**Instrucción con byte inmediato** (lee `M[PC]` y luego salta el byte con S13):

```vhdl
WHEN S2x_NUEVA0 =>
    oe      <= '1';
    -- aqui el destino: SelRegW + wr, o LH / LL
    estado_siguiente <= S13_MOVI1;
```

### 3.9 Lista de verificación al agregar un estado u opcode

| Paso | Dónde | Qué comprobar |
|---|---|---|
| 1 | `estado_t` | El estado está declarado |
| 2 | `estado_out` | Tiene un código único (0 a 30) y no choca con `"11111"` |
| 3 | S02 (`CASE CO`) | El opcode apunta al estado nuevo y no repite uno existente |
| 4 | S06 | Si usa dirección de 2 bytes, tiene su rama de bifurcación |
| 5 | El estado nuevo | Solo enciende lo necesario y termina con `estado_siguiente` |
| 6 | Bus | Nunca hay `oe` y `SalAlu` en el mismo estado |
| 7 | PC | Cada byte de la instrucción consume exactamente un `Ipc` |
| 8 | ALU / Logisim | Si usa un `ope` nuevo, la ALU lo implementa |
| 9 | Simulación | Probar con un programa corto y mirar `estado_out` |

Errores frecuentes:

- **El PC queda desalineado:** al terminar la instrucción el PC apunta a un operando y se ejecuta como si fuera un opcode. Revisa el conteo de `Ipc`.
- **Opcode sin `WHEN`:** cae en `OTHERS` de S02 y se ignora silenciosamente.
- **Estado sin `estado_siguiente`:** la FSM se queda en ese estado (el valor por defecto retiene el estado actual).
- **Más de 31 estados:** `estado_out` deja de poder representarlos con 5 bits; hay que ensancharlo y cambiar el pin en Logisim.
- **Operación de ALU que no existe:** la FSM pide un `ope` que la ALU no implementa y el resultado es incorrecto, sin ningún error de VHDL.

### 3.10 Propuesta de mapa de opcodes ampliado

| CO | Instrucción | Estado | Nota |
|---|---|---|---|
| 48h | OR | S20_OR0 | Requiere `ope` = 001 en la ALU |
| 49h | MOVI R0 | S21_MOVI_R0 | Reutiliza S13 |
| 4Ah | MOV L,R1 | S22_MOVL0 | Usa `SalAlu` + `LL` |
| 72h | LOADD (dirección corta) | S04 modificado | Reutiliza S07 |
| 73h | STORED (dirección corta) | S04 modificado | Reutiliza S08 |
| 74h | LDH (H ← inmediato) | S23_LDH0 | Reutiliza S13 |
| 84h | JMP HL | S14 | Sin estado nuevo |
| 85h | JV (salta si overflow) | S03 a S06 + S14 | Requiere `FLGS(3)` |

Con estos cuatro estados nuevos (S20 a S23), `estado_out` usaría los códigos `10100`, `10101`, `10110` y `10111`.