# Guía del microprocesador de 8 bits con FSM (VHDL + Logisim Evolution)

Este documento reúne y unifica todo lo visto hasta ahora:

- el código `control.vhd` (la unidad de control),
- la guía previa basada en `unidad_control_comentada.vhd` y en el esquema de Logisim,
- las tablas de estados y el texto de la guía del profesor,
- las notas de comparación y las limitaciones detectadas.

Está organizado así: primero cada parte del microprocesador por separado, luego las tablas de estados, el juego de instrucciones, el funcionamiento general unificado, el contraste entre fuentes y, al final, las guías para modificar instrucciones, opcodes y operaciones de la ALU.

---

## Índice

- [0. Fuentes, convenciones y notación](#0-fuentes-convenciones-y-notación)
- [1. Visión general](#1-visión-general)
- [2. Las partes del microprocesador](#2-las-partes-del-microprocesador)
- [3. El código VHDL por secciones](#3-el-código-vhdl-por-secciones)
- [4. Tablas de estados y señales](#4-tablas-de-estados-y-señales)
- [5. Juego de instrucciones](#5-juego-de-instrucciones)
- [6. Funcionamiento general unificado](#6-funcionamiento-general-unificado)
- [7. Contraste de fuentes y puntos por verificar](#7-contraste-de-fuentes-y-puntos-por-verificar)
- [8. Limitaciones del juego de instrucciones](#8-limitaciones-del-juego-de-instrucciones)
- [9. Guías para modificar el procesador](#9-guías-para-modificar-el-procesador)
- [Apéndice A. Glosario de señales](#apéndice-a-glosario-de-señales)

---

## 0. Fuentes, convenciones y notación

### 0.1 Fuentes y su grado de confianza

| Etiqueta | Fuente | Qué aporta | Confianza |
|---|---|---|---|
| **[Código]** | `control.vhd` | Lo que realmente hace la FSM: estados, transiciones, salidas | Máxima (es lo que se simula) |
| **[Profesor]** | Tablas y texto del profesor | Comportamiento esperado, pines modificados por estado | Alta, con erratas de nomenclatura (ver sección 7) |
| **[Guía previa]** | `unidad_control_comentada.vhd` + esquema de Logisim | Componentes de la ruta de datos, bits de banderas, tamaño de memoria | Media: describe otra versión del archivo |
| **[Deducción]** | Inferencias propias | Lo que no está escrito en ningún lado pero se desprende de la lógica | A verificar en el esquema |

### 0.2 Notación de señales

- `X=H` significa que la señal `X` vale `'1'` (nivel alto). `X=L` significa `'0'` (nivel bajo).
- Una prima (`cs'`, `oe'`) indica **señal activa en bajo**: se activa cuando vale `L`.
- `SelRegW=001` indica el valor binario del selector de 3 bits.
- `R0` = selector `"000"`, `R1` = selector `"001"`.
- VHDL no distingue mayúsculas de minúsculas: `lF` y `LF` son la misma señal.

### 0.3 Polaridad de las señales de memoria

| Señal | Activa en | Para leer | Para escribir | Por defecto |
|---|---|---|---|---|
| `cs` | **bajo** (`'0'`) | `cs='0'` | `cs='0'` | `'1'` (memoria no seleccionada) |
| `oe` | **bajo** (`'0'`) | `oe='0'` | `oe='1'` | `'1'` (salida deshabilitada) |
| `we` | **alto** (`'1'`) | `we='0'` | `we='1'` | `'0'` |

> **Advertencia.** La guía previa escribía `oe <= '1'` para leer memoria. En este código eso **deshabilita** la lectura. Toda lectura se escribe `cs <= '0'; oe <= '0';`. Las tablas del profesor (`[cs', L], [oe', L]`) coinciden con el código.

---

## 1. Visión general

### 1.1 Dos bloques que trabajan juntos

| Bloque | Qué hace | Dónde vive |
|---|---|---|
| **Ruta de datos (datapath)** | Guarda y transforma datos: registros, ALU, memoria, buses | Esquema de Logisim |
| **Unidad de control** | En cada ciclo de reloj decide qué componentes de la ruta de datos se activan | `control` (VHDL) |

La unidad de control es una **máquina de estados finitos (FSM) tipo Moore**: no toca los datos, solo genera señales (`Lpc`, `oe`, `wr`, `ope`…) que abren o cierran caminos en la ruta de datos. Sus salidas dependen únicamente del estado presente.

La arquitectura es **von Neumann**: instrucciones y datos conviven en la misma memoria.

### 1.2 Esquema de bloques (simplificado)

```text
                         +------------------------+
   CO (desde RI) ------->|                        |-----> Lpc, Ipc, SelDir
   Flags (desde FLAGS) ->|   UNIDAD DE CONTROL    |-----> cs, oe, we
   clk, rst ------------>|        (FSM)           |-----> Lri, LL, LH
                         |                        |-----> SelRegW/RA/RB, wr
                         |                        |-----> ope, SalAlu, LF
                         +------------------------+-----> clear, inicia, fin, idEstado

   PC ----+
          +--> MUX (SelDir) --> dirección --> MEMORIA <----+
   HL ----+                                     |           |
    ^                                           v           |
    |                                      BusDatos <-------+-------- BUFFERALU <-- ALU <-- BR (SalA, SalB)
    +-- LL, LH (cargan desde BusDatos)         |  |  |                              |
                                               |  |  +--> BR (entrada de escritura) +--> FLAGS --> Flags
                                               |  +-----> HL
                                               +--------> RI --> CO
```

### 1.3 Componentes de la ruta de datos

| Bloque | Función | Entradas de control | Salida principal |
|---|---|---|---|
| **PC** | Contador de programa: dirección del siguiente byte a leer | `Lpc`, `Ipc` | Dirección (hacia el MUX) |
| **RI** | Registro de instrucción: guarda el opcode | `Lri` | `CO` (hacia la unidad de control) |
| **HL** | Par de registros de dirección (`L` byte bajo, `H` byte alto) | `LL`, `LH` | `SalidaHL` (hacia el MUX y hacia la carga del PC) |
| **MUX de dirección** | Elige quién direcciona la memoria | `SelDir` | Dirección de memoria |
| **Memoria** | Almacena programa y datos | `cs`, `oe`, `we` | Dato (hacia `BusDatos`) |
| **BR** | Banco de registros (R0, R1…) | `SelRegW`, `SelRegRA`, `SelRegRB`, `wr` | `SalA`, `SalB` |
| **ALU** | Opera sobre `SalA` y `SalB` | `ope` | Resultado y banderas |
| **BUFFERALU** | Buffer triestado: pone el resultado de la ALU en el bus | `SalAlu` | `BusDatos` |
| **FLAGS** | Registro de banderas | `LF` | `Flags` (hacia la unidad de control) |

---

## 2. Las partes del microprocesador

Cada subsección describe una parte: qué hace, qué señales la gobiernan, en qué estados se activa y qué conviene saber para modificarla.

### 2.1 Unidad de control (FSM)

**Función.** Ejecuta indefinidamente el ciclo *buscar → decodificar → ejecutar*, generando en cada estado las señales de control correspondientes.

**Estructura en el código [Código].** Tres procesos VHDL:

| Proceso | Tipo | Qué hace |
|---|---|---|
| 1. Registro de estado | Secuencial (`clk`, `rst`) | Guarda `edo_pre`; reset asíncrono a `S00` |
| 2. Estado siguiente | Combinacional (`edo_pre`, `CO`, `Flags`) | Decide `edo_sig` (decodificador de instrucciones) |
| 3. Salidas | Combinacional (`edo_pre`) | Genera todas las señales de control (Moore) |

**Estados.** El tipo `ESTADOS` tiene 20 valores (`S00`…`S19`):

| Grupo | Estados | Función |
|---|---|---|
| Inicio | S00 | Reset |
| Búsqueda | S01, S02 | Traer y decodificar el opcode |
| Lectura de dirección | S03 a S06 | Compartidos por LOAD, STORE y los 4 saltos |
| Memoria | S07 (LOAD), S08 (STORE) | Acceso a `M(HL)` |
| ALU | S09 (ADD), S15 (NOT), S16 (AND), S17 (DEC), S18 (INC), S19 (SUB) | Una operación por estado |
| Transferencia | S10 (MOV), S12 y S13 (MOVI) | Copiar datos |
| Control | S11 (FIN), S14 (salto) | Detener / saltar |

**Valores por defecto.** Al inicio del proceso 3 todas las salidas se ponen en su valor inactivo y cada estado solo cambia las que necesita. Así no queda nada activo por accidente y se evitan *latches*. Del mismo modo, `edo_sig <= edo_pre` al inicio del proceso 2 hace que, si ninguna rama asigna, la FSM retenga el estado.

**Estado ilegal.** `when others` del proceso 2 envía a `S00` (reinicia la CPU y vuelve a activar `clear`). Con los 20 estados cubiertos, solo se alcanzaría con un valor inválido de `edo_pre`.

### 2.2 PC (Contador de Programa)

- **Función.** Guarda la dirección del siguiente byte a leer (opcode, operando o dato inmediato).
- **Señales.** `Lpc` (cargar con `HL`), `Ipc` (incrementar en 1).
- **Se activa en:**

| Señal | Estados | Efecto |
|---|---|---|
| `Ipc` | S02, S04, S06, S13 | `PC ← PC + 1` |
| `Lpc` | S14 | `PC ← HL` |

- **Regla de contabilidad del PC.** Cada byte de la instrucción consume exactamente un `Ipc`: el opcode en S02, el byte `L` en S04, el byte `H` en S06 y el dato inmediato en S13. Al volver a S01, el PC debe apuntar al primer byte de la instrucción siguiente. Si agregas estados, esta cuenta debe seguir cuadrando.
- **Carga de salto.** Según el esquema, la entrada de carga del PC sale **directamente** de la salida de `HL`; por eso S14 no activa `SelDir` [Código + Guía previa].

### 2.3 RI (Registro de Instrucción)

- **Función.** Retiene el opcode durante toda la instrucción. Su salida es `CO`.
- **Señal.** `Lri` (solo en S01).
- **Detalle de temporización.** `Lri` se activa en S01 y el opcode se captura al final de ese ciclo; por eso `CO` ya es válido en S02, donde se decodifica. `CO` sigue válido en S06, porque `RI` no se vuelve a cargar hasta el siguiente S01.

### 2.4 Registros H y L (par HL)

- **Función.** Forman la dirección `HL` (`H` parte alta, `L` parte baja), usada como dirección de datos en LOAD/STORE o como destino en los saltos.
- **Señales.** `LL` (cargar L, estado S03), `LH` (cargar H, estado S05). Ambos se cargan desde `BusDatos`.
- **Orden en memoria.** En una instrucción de 3 bytes, el primer byte tras el opcode es **L** y el segundo es **H**: `[opcode][L][H]`.
- **Cómo se llena [Profesor].** El procesador no lee 16 bits de golpe: usa los estados S03 a S06 para leer primero el byte bajo, incrementar el PC, leer el byte alto e incrementar de nuevo.
- **Ancho de la dirección: punto por verificar.** El profesor habla de direcciones de 16 bits sobre una memoria y un bus de datos de 8 bits. La guía previa indica una RAM de $256 \times 8$ que solo recibe `dirL`. Ver sección 7.

### 2.5 Multiplexor de dirección (`SelDir`)

- **Función.** Elige quién direcciona la memoria.
- **Señal.** `SelDir`.

| `SelDir` | Dirección de memoria | Estados |
|---|---|---|
| `L` (por defecto) | Salida del PC | S01, S03, S05, S12 (lecturas del flujo de instrucciones) |
| `H` | Salida de HL | S07 (LOAD), S08 (STORE) |

- En S14 (salto) `SelDir` **no** se activa: el PC se carga directo de `HL`.

### 2.6 Memoria

- **Función.** Almacena programa y datos en una sola memoria (von Neumann).
- **Señales.** `cs'`, `oe'`, `we` (ver polaridades en 0.3).

| Operación | Estados | Señales |
|---|---|---|
| Leer (opcode, operandos, inmediato) | S01, S03, S05, S12 | `cs'=L`, `oe'=L` (dirección = PC) |
| Leer dato | S07 | `cs'=L`, `oe'=L`, `SelDir=H` (dirección = HL) |
| Escribir dato | S08 | `cs'=L`, `we=H`, `SelDir=H` (el dato lo pone la ALU en el bus) |
| Inactiva | resto de estados | `cs'=H`, `oe'=H`, `we=L` |

- En STORE `oe'` queda en `H` (la memoria no emite) y `SalAlu=H` (emite la ALU): así no hay dos emisores en el bus.

### 2.7 BusDatos y la regla del único emisor

`BusDatos` es el bus compartido de 8 bits. En cada estado **como máximo un componente puede escribir en él**.

| Emisor | Condición | Estados |
|---|---|---|
| Memoria | `cs'=L` y `oe'=L` | S01, S03, S05, S07, S12 |
| BUFFERALU | `SalAlu=H` | S08, S09, S10, S15, S16, S17, S18, S19 |
| Ninguno (bus libre) | — | S00, S02, S04, S06, S11, S13, S14 |

| Receptor | Estados |
|---|---|
| RI | S01 |
| L | S03 |
| H | S05 |
| BR (registro `SelRegW`) | S07, S12 (dato de memoria); S09, S10, S15 a S19 (resultado de la ALU) |
| Memoria (escritura) | S08 |

**Regla de oro:** nunca `SalAlu=H` junto con `oe'=L`. Verificado en el código: ningún estado activa ambos.

### 2.8 Banco de registros (BR)

- **Función.** Almacena los registros de propósito general. Con selectores de 3 bits cabrían hasta 8 ($2^3 = 8$); **este código solo usa R0 y R1**.
- **Señales.**

| Señal | Función |
|---|---|
| `SelRegRA` | Registro que sale por el puerto A (`SalA`, hacia la ALU) |
| `SelRegRB` | Registro que sale por el puerto B (`SalB`, hacia la ALU) |
| `SelRegW` | Registro destino de escritura |
| `wr` | Habilita la escritura; el registro captura en el flanco que cierra el estado |

- La entrada de escritura del BR viene de `BusDatos` [Guía previa].
- **Roles de los registros en esta FSM:**

| Registro | Selector | Uso |
|---|---|---|
| R0 | `"000"` | Operando A de las operaciones de dos operandos; destino solo de MOV |
| R1 | `"001"` | Operando B, destino de casi todo, y registro de LOAD/STORE/MOVI (acumulador implícito) |

- **Valor por defecto.** `SelRegRB` vale `"000"` si un estado no lo asigna: el puerto B lee R0 aunque la ALU no lo use (NOT, DEC, INC).

### 2.9 ALU y BUFFERALU

- **Función.** La ALU calcula una operación sobre `SalA` y `SalB`; el BUFFERALU (triestado) pone el resultado en `BusDatos` cuando `SalAlu=H`.
- **Señal de operación.** `ope` (3 bits). La FSM solo *pide* la operación; qué hace cada código lo decide el módulo `ALU` del esquema.

| `ope` | Operación | Estados que la usan |
|---|---|---|
| `000` | Paso directo: salida = A | S08 (STORE), S10 (MOV) |
| `001` | **Libre** (no usado) | — |
| `010` | A AND B | S16 |
| `011` | NOT A | S15 |
| `100` | A − 1 | S17 |
| `101` | A + B | S09 |
| `110` | A − B | S19 |
| `111` | A + 1 | S18 |

- **Receta de un estado de ALU:** elegir orígenes (`SelRegRA`, `SelRegRB`), elegir operación (`ope`), habilitar el buffer (`SalAlu=H`), elegir destino (`SelRegW`) y escribir (`wr=H`), y guardar banderas (`LF=H`).
- **Paso directo.** `ope=000` actúa como *bypass*: mueve un dato sin alterarlo (se usa en STORE y MOV).

### 2.10 Registro de banderas (FLAGS)

- **Función.** Guarda las banderas del resultado de la última operación que activó `LF`.
- **Señal.** `LF` (carga las banderas con el resultado actual de la ALU).
- **Bits usados** [Guía previa y Profesor]:

| Bit | Bandera | Usada por |
|---|---|---|
| `Flags(0)` | FZ (cero) | JZ (81h) |
| `Flags(1)` | FC (acarreo) | JC (82h) |
| `Flags(2)` | FS (signo) | JS (83h) |

- **Quién las actualiza (`LF=H`):** ADD (S09), NOT (S15), AND (S16), DEC (S17), INC (S18), SUB (S19).
- **Quién NO las actualiza:** LOAD (S07), STORE (S08), MOV (S10), MOVI (S12). Por tanto un valor recién cargado no puede probarse con un salto sin una operación de ALU intermedia.
- El puerto `Flags` es de 8 bits, pero solo los bits 0 a 2 se usan.

### 2.11 Señales de supervisión

| Señal | Qué hace | Estados |
|---|---|---|
| `clear` | Limpia la ruta de datos (PC, HL, RI, BR y FLAGS, según la guía previa) | S00 |
| `inicia` | Señal de arranque; su destino exacto no se deduce del código ni de las guías | S00 |
| `fin` | Indica que el procesador se detuvo | S11 |
| `idEstado` (5 bits) | Número binario del estado actual, para sondas/displays en Logisim | todos |

**Arranque.** `rst='1'` fuerza `edo_pre = S00` de forma asíncrona. Mientras la FSM está en S00, `clear=H` e `inicia=H`. La ruta de datos se limpia con `clear`, que **genera la unidad de control**: `rst` no llega directamente a PC, HL, RI, BR ni FLAGS. S00 dura hasta el primer flanco de reloj con `rst='0'`, cuando pasa a S01.

---

## 3. El código VHDL por secciones

El archivo `control_comentado.vhd` contiene los comentarios operativos. Esta tabla resume su estructura:

| Sección | Contenido | Qué conviene saber |
|---|---|---|
| [0] Librerías | `std_logic_1164` y `numeric_std` | `numeric_std` no se usa directamente |
| [1] Entidad | Puertos de la unidad de control | Ver glosario (apéndice A) |
| [2] Arquitectura | Tipo `ESTADOS`, señales `edo_pre` y `edo_sig` | Para agregar estados, ampliar el tipo |
| [3] Proceso 1 | Registro de estado (reset asíncrono) | Es lo único con reloj |
| [4] Proceso 2 | Estado siguiente | Decodificación en `S02` (`if/elsif`) y en `S06`; `others → S00` |
| [5] Proceso 3 | Salidas por estado | `idEstado` se asigna dentro de cada estado |

Detalles del proceso 2:

- **S02** es el decodificador central: es el único lugar donde un opcode se asocia a su camino de ejecución. Un opcode desconocido cae en el `else` y vuelve a S01 (NOP de 1 byte; S02 ya incrementó el PC).
- **S06** es el segundo bifurcador y decide el salto: `70 → S07`, `71 → S08`, `80 → S14`, y `81/82/83 → S14` solo si la bandera vale `'1'`; si vale `'0'` vuelve a S01. No tiene `else` final: si `CO` no coincidiera, se quedaría en S06 por el valor por defecto (no ocurre, porque solo se llega con esos seis códigos).

---

## 4. Tablas de estados y señales

### 4.1 Tabla maestra: estado, acción y salidas

Solo se listan las salidas distintas de su valor por defecto. Los estados `S03` a `S06` son compartidos por LOAD, STORE y los saltos (el profesor los rotula `LOAD0–3` y `STORE0–3` por reutilización).

| Estado | `idEstado` | Nombre (profesor) | Acción | Salidas activas | Siguiente |
|---|---|---|---|---|---|
| S00 | `00000` | RESET0 | Reset | `clear=H`, `inicia=H` | S01 |
| S01 | `00001` | FETCH0 | `RI ← M(PC)` | `cs'=L`, `oe'=L`, `Lri=H` | S02 |
| S02 | `00010` | FETCH1 | `PC ← PC + 1` | `Ipc=H` | según `CO` |
| S03 | `00011` | LOAD0 / STORE0 | `L ← M(PC)` | `cs'=L`, `oe'=L`, `LL=H` | S04 |
| S04 | `00100` | LOAD1 / STORE1 | `PC ← PC + 1` | `Ipc=H` | S05 |
| S05 | `00101` | LOAD2 / STORE2 | `H ← M(PC)` | `cs'=L`, `oe'=L`, `LH=H` | S06 |
| S06 | `00110` | LOAD3 / STORE3 | `PC ← PC + 1` | `Ipc=H` | S07 / S08 / S14 / S01 |
| S07 | `00111` | LOAD4 | `R1 ← M(HL)` | `SelDir=H`, `cs'=L`, `oe'=L`, `SelRegW=001`, `wr=H` | S01 |
| S08 | `01000` | STORE5 | `M(HL) ← R1` | `SelDir=H`, `cs'=L`, `we=H`, `SelRegRA=001`, `ope=000`, `SalAlu=H` | S01 |
| S09 | `01001` | ADD0 | `R1 ← R0 + R1` | ver 4.2 | S01 |
| S10 | `01010` | MOV0 | `R0 ← R1` | ver 4.2 | S01 |
| S11 | `01011` | FIN0 | Fin | `fin=H` | S11 |
| S12 | `01100` | MOVI0 | `R1 ← M(PC)` | `cs'=L`, `oe'=L`, `SelRegW=001`, `wr=H` | S13 |
| S13 | `01101` | MOVI1 | `PC ← PC + 1` | `Ipc=H` | S01 |
| S14 | `01110` | JMP/JZ/JC/JS (final) | `PC ← HL` | `Lpc=H` | S01 |
| S15 | `01111` | NOT0 | `R1 ← not R1` | ver 4.2 | S01 |
| S16 | `10000` | AND0 | `R1 ← R0 and R1` | ver 4.2 | S01 |
| S17 | `10001` | DEC0 | `R1 ← R1 − 1` | ver 4.2 | S01 |
| S18 | `10010` | INC0 | `R1 ← R1 + 1` | ver 4.2 | S01 |
| S19 | `10011` | SUB0 | `R1 ← R0 − R1` | ver 4.2 | S01 |
| otro | `11111` | — | Estado ilegal | (solo `idEstado`) | S00 |

### 4.2 Estados de ALU y transferencia entre registros

Todos tienen `wr=H` y `SalAlu=H`. La columna `LF` indica si actualizan banderas. Una celda vacía en `SelRegRB` significa que el estado no lo asigna (queda en `"000"`, pero la ALU no lo usa).

| Estado | Instrucción | Acción | `SelRegW` | `SelRegRA` | `SelRegRB` | `ope` | `LF` |
|---|---|---|---|---|---|---|---|
| S15 | NOT | `SalA ← R1; R1 ← ALU(not A)` | 001 | 001 |  | 011 | H |
| S16 | AND | `SalA ← R0; SalB ← R1; R1 ← ALU(A and B)` | 001 | 000 | 001 | 010 | H |
| S17 | DEC | `SalA ← R1; R1 ← ALU(A − 1)` | 001 | 001 |  | 100 | H |
| S18 | INC | `SalA ← R1; R1 ← ALU(A + 1)` | 001 | 001 |  | 111 | H |
| S19 | SUB | `SalA ← R0; SalB ← R1; R1 ← ALU(A − B)` | 001 | 000 | 001 | 110 | H |
| S09 | ADD | `SalA ← R0; SalB ← R1; R1 ← ALU(A + B)` | 001 | 000 | 001 | 101 | H |
| S10 | MOV | `SalA ← R1; R0 ← ALU(A)` | 000 | 001 |  | 000 | **L** |

### 4.3 Resumen de señales por estado

| Señal | Estados donde está activa |
|---|---|
| `clear`, `inicia` | S00 |
| `Lri` | S01 |
| `Ipc` | S02, S04, S06, S13 |
| `LL` | S03 |
| `LH` | S05 |
| `Lpc` | S14 |
| `fin` | S11 |
| `cs'=L` | S01, S03, S05, S07, S08, S12 |
| `oe'=L` | S01, S03, S05, S07, S12 |
| `we=H` | S08 |
| `SelDir=H` | S07, S08 |
| `wr=H` | S07, S09, S10, S12, S15 a S19 |
| `SalAlu=H` | S08, S09, S10, S15 a S19 |
| `LF=H` | S09, S15 a S19 |
| `SelRegW=000` | S10 |
| `SelRegW=001` | S07, S09, S12, S15 a S19 |

---

## 5. Juego de instrucciones

### 5.1 Formatos

| Formato | Bytes | Contenido | Instrucciones |
|---|---|---|---|
| Sin operando | 1 | `[opcode]` | NOT, AND, DEC, INC, SUB, ADD, MOV, FIN |
| Con inmediato | 2 | `[opcode][dato]` | MOVI |
| Con dirección | 3 | `[opcode][L][H]` | LOAD, STORE, JMP, JZ, JC, JS |

### 5.2 Tabla de instrucciones

| CO | Instrucción | Efecto | Estados | Ciclos |
|---|---|---|---|---|
| 40h | NOT | `R1 ← not R1` | S15 | 3 |
| 41h | AND | `R1 ← R0 and R1` | S16 | 3 |
| 42h | DEC | `R1 ← R1 − 1` | S17 | 3 |
| 43h | INC | `R1 ← R1 + 1` | S18 | 3 |
| 44h | SUB | `R1 ← R0 − R1` | S19 | 3 |
| 45h | ADD | `R1 ← R0 + R1` | S09 | 3 |
| 46h | MOV | `R0 ← R1` | S10 | 3 |
| 47h | MOVI K | `R1 ← K` | S12, S13 | 4 |
| 70h | LOAD dir | `R1 ← M(dirH dirL)` | S03 a S07 | 7 |
| 71h | STORE dir | `M(dirH dirL) ← R1` | S03 a S06, S08 | 7 |
| 80h | JMP dir | `PC ← dirH dirL` | S03 a S06, S14 | 7 |
| 81h | JZ dir | si FZ=1: `PC ← dirH dirL` | S03 a S06, S14 | 7 (6 si no salta) |
| 82h | JC dir | si FC=1: `PC ← dirH dirL` | S03 a S06, S14 | 7 (6 si no salta) |
| 83h | JS dir | si FS=1: `PC ← dirH dirL` | S03 a S06, S14 | 7 (6 si no salta) |
| FFh | FIN | Detiene el procesador | S11 | 3 y se queda |
| otro | (NOP implícito) | No hace nada | S02 → S01 | 2 |

### 5.3 Cálculo de ciclos

Toda instrucción gasta 2 ciclos de búsqueda (S01 y S02) más los estados de ejecución:

$$N_{instr} = 2 + N_{ejec}$$

El tiempo total de un programa es:

$$T = N_{ciclos} \cdot T_{clk}$$

Capacidad de direccionamiento según el ancho de dirección:

$$2^8 = 256 \text{ direcciones} \qquad 2^{16} = 65\,536 \text{ direcciones}$$

### 5.4 Traza de `LOAD 0010h`

Memoria desde `0000h`: `70 10 00` (opcode, L = 10h, H = 00h). Supón `M[0010h] = 2Ah`.

| Ciclo | Estado | PC | Señales activas | Qué ocurre |
|---|---|---|---|---|
| 1 | S01 | 0 | `cs'`, `oe'`, `Lri` | Se lee `M[0]` = 70h y se guarda en RI |
| 2 | S02 | 0 | `Ipc` | PC pasa a 1; `CO` = 70h → va a S03 |
| 3 | S03 | 1 | `cs'`, `oe'`, `LL` | L ← `M[1]` = 10h |
| 4 | S04 | 1 | `Ipc` | PC pasa a 2 |
| 5 | S05 | 2 | `cs'`, `oe'`, `LH` | H ← `M[2]` = 00h |
| 6 | S06 | 2 | `Ipc` | PC pasa a 3; `CO` = 70h → va a S07 |
| 7 | S07 | 3 | `SelDir`, `cs'`, `oe'`, `wr` (`SelRegW=001`) | R1 ← `M[HL]` = `M[0010h]` = 2Ah |
| 8 | S01 | 3 | `cs'`, `oe'`, `Lri` | Empieza la instrucción siguiente |

### 5.5 Comportamiento de un salto condicional

Para `JZ dir` con las banderas ya cargadas:

- **FZ = 1:** `S01 → S02 → S03 → S04 → S05 → S06 → S14 → S01` (7 ciclos). En S14 `Lpc=H` carga `PC ← HL`.
- **FZ = 0:** `S01 → S02 → S03 → S04 → S05 → S06 → S01` (6 ciclos). S14 no se visita; el PC ya apunta a la instrucción siguiente.

### 5.6 Programa de ejemplo: cuenta regresiva

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

R1 baja 5 → 4 → 3 → 2 → 1 → 0. Mientras R1 ≠ 0, `JZ` no salta y `JMP 0002h` repite el `DEC`. Cuando R1 = 0 se activa FZ, `JZ` salta a `0009h` y la FSM llega a FIN. Esto depende de que la ALU active Z cuando el resultado sea 0 y de que `DEC` actualice banderas (`LF=H` en S17, lo cual se cumple).

Ciclos hasta que `fin = 1`:

$$N = 4 + 4\,(3 + 6 + 7) + (3 + 7) + 3 = 81$$

(MOVI; cuatro vueltas completas de DEC + JZ sin salto + JMP; la última pasada con DEC + JZ con salto; y los tres ciclos de FIN.)

---

## 6. Funcionamiento general unificado

### 6.1 El ciclo de instrucción

Toda instrucción pasa por tres fases:

```text
        +-----------+     +-----------+     +--------------------+
 ---->  |   S01     | --> |   S02     | --> |     EJECUCIÓN      | ---+
 |      | RI<-M(PC) |     | PC<-PC+1  |     | estados propios    |    |
 |      |           |     | decodifica|     | de cada opcode     |    |
 |      +-----------+     +-----------+     +--------------------+    |
 +--------------------------------------------------------------------+
```

1. **Fetch (S01 y S02).** Se lee el opcode de `M(PC)` y se guarda en `RI`; luego el PC avanza.
2. **Decode (S02).** Con `CO` ya válido, la FSM elige el camino siguiente.
3. **Execute.** Uno o varios estados propios; al terminar se regresa a S01.

### 6.2 Diagrama de transiciones

```text
S00 ──► S01 ──► S02 ──(según CO)──┬─ 40 ─► S15 ─► S01        NOT
                                  ├─ 41 ─► S16 ─► S01        AND
                                  ├─ 42 ─► S17 ─► S01        DEC
                                  ├─ 43 ─► S18 ─► S01        INC
                                  ├─ 44 ─► S19 ─► S01        SUB
                                  ├─ 45 ─► S09 ─► S01        ADD
                                  ├─ 46 ─► S10 ─► S01        MOV
                                  ├─ 47 ─► S12 ─► S13 ─► S01 MOVI
                                  ├─ FF ─► S11 ─► S11 ...    FIN (permanente)
                                  ├─ otro ─► S01             NOP implícito
                                  └─ 70,71,80,81,82,83 ─► S03 ─► S04 ─► S05 ─► S06
                                                                                  │
                          ┌───────────────────────────────────────────────────────┘
                          │  (según CO en S06)
                          ├─ 70 ─► S07 ─► S01                          LOAD
                          ├─ 71 ─► S08 ─► S01                          STORE
                          ├─ 80 ─► S14 ─► S01                          JMP
                          └─ 81/82/83 ─┬─ bandera=1 ─► S14 ─► S01     JZ/JC/JS
                                       └─ bandera=0 ─► S01
```

### 6.3 Temporización

- Cada estado dura **un ciclo de reloj**.
- Las salidas de la FSM (Moore) se mantienen estables durante todo el estado.
- Los registros destino (`RI`, `HL`, `PC`, `BR`, `FLAGS`) capturan su valor en el **flanco de subida que cierra el estado**.

> **Consecuencia práctica:** lo que activas en el estado *N* se refleja en el estado *N+1*. Por eso `Lri` en S01 deja `CO` válido en S02.

### 6.4 Reglas que mantienen coherente el procesador

1. **Un solo emisor en el bus** (sección 2.7).
2. **Un `Ipc` por cada byte de la instrucción** (sección 2.2).
3. **Las banderas solo cambian con operaciones de ALU que activan `LF`** (sección 2.10); el salto decide en S06 con las banderas vigentes.
4. **Valores por defecto inactivos**: cada estado solo escribe lo que necesita (sección 2.1).
5. **Las instrucciones de 3 bytes comparten S03 a S06**: lo que las distingue es la bifurcación de S06.

### 6.5 Explicación del profesor por categoría, con precisiones

**Búsqueda y control básico.**
- En S01 el PC es el que direcciona la memoria (`SelDir=L`). `cs'=L` y `oe'=L` habilitan la salida de la memoria y `Lri=H` hace que el RI atrape el opcode en el flanco de reloj.
- En S02, `Ipc=H` suma 1 al PC, dejándolo apuntando al siguiente byte (operando o siguiente opcode).
- MOVI lee igual que el fetch pero, en lugar de `Lri`, escribe en el banco de registros (`SelRegW=001`, `wr=H`).

**Ejecución de operaciones rápidas (ALU y registros).**
- Es un camino **registro → ALU → registro** sin acceso a memoria. `SelRegRA` y `SelRegRB` son selectores de los multiplexores del banco de registros; `ope` entra al decodificador interno de la ALU; `SelRegW` y `wr` eligen y habilitan el registro destino.
- *Precisión:* el estado de ejecución dura un ciclo, pero la instrucción completa dura 3 (S01, S02 y el estado de ejecución).

**Ejecución de operaciones complejas (memoria y saltos).**
- La rutina compartida S03 a S06 ensambla la dirección de 16 bits en `HL` leyendo `L` y luego `H`.
- `SelDir=H` desconecta el PC de la memoria y conecta `HL`; después `oe'` lee o `we` escribe.
- En JMP, `Lpc=H` hace que `PC ← HL`.
- *Precisión 1 (salto condicional):* el profesor describe que `Lpc` pasa por una compuerta AND con la bandera. En **este código la condición se resuelve en la FSM**: el estado S06 decide ir a S14 (y entonces `Lpc=H` sin condición) o volver a S01. Funcionalmente es equivalente (el PC solo se carga si la bandera está en 1) y no hace falta compuerta AND en la ruta de datos, porque `Flags` entra a la unidad de control.
- *Precisión 2 (microprogramación):* compartir la rutina S03 a S06 es reutilización de estados en una FSM cableada. No hay una memoria de microcódigo.

### 6.6 Resumen en pocas líneas

Al arrancar, `rst` lleva la FSM a S00, que limpia la ruta de datos. Después la FSM repite sin parar: S01 lee el opcode de `M(PC)` hacia `RI`; S02 avanza el PC y decodifica `CO`. Las instrucciones de 1 byte ejecutan en un estado y regresan a S01. MOVI lee un byte inmediato en S12 y avanza el PC en S13. Las instrucciones de 3 bytes cargan `L` y `H` (S03 a S06), y luego LOAD/STORE acceden a `M(HL)` (S07/S08), mientras los saltos cargan `PC ← HL` en S14 si la condición se cumple. Las operaciones aritmético-lógicas siempre toman operandos de R0/R1, calculan en la ALU, escriben en R1 y actualizan banderas. FIN deja la FSM en S11 hasta un reset.

---

## 7. Contraste de fuentes y puntos por verificar

### 7.1 Guía previa frente a este código

| Concepto | Guía previa | Este código |
|---|---|---|
| Nombre de entidad | `unidad_control` | `control` |
| Banderas | `FLGS` con alias `FZ/FC/FS` | `Flags` (sin alias): `Flags(0)=Z`, `(1)=C`, `(2)=S` |
| Fin / depuración | `Fin` / `estado_out` | `fin` / `idEstado` |
| Estados | `S01_FETCH0`, `S03_LOAD0_STORE0`… | `S00` a `S19` |
| Estado presente / siguiente | `estado_actual` / `estado_siguiente` | `edo_pre` / `edo_sig` |
| Estructura | Un proceso combinacional | Dos procesos combinacionales + uno secuencial |
| Salida de `idEstado` | `WITH … SELECT` | Dentro del proceso de salidas |
| Memoria | `oe` y `we` activos en alto, sin `cs` | `cs'` y `oe'` activos en bajo, `we` en alto |
| Puertos `clear`/`inicia` | No aparecen | Existen; S00 los activa |
| S00 | Sin salidas | `clear=H`, `inicia=H` |
| S14 | `SelDir='1'` y `Lpc='1'` | Solo `Lpc='1'` |
| `when others` (siguiente) | → S01 | → S00 |

**Coinciden:** opcodes, formatos, códigos de `ope`, registros usados, estados compartidos S03 a S06, decisión del salto en S06, conteo de ciclos y los ejemplos de traza.

### 7.2 Profesor frente a este código

| Punto | Profesor | Código | Resultado |
|---|---|---|---|
| `cs'`, `oe'` activos en bajo | Sí | Sí | Coincide |
| Pines de S00, S01, S02, S03 a S07, S12, S13, S14 | Tablas | Idénticos | Coincide |
| Tabla de ALU (`SelRegW`, `RA`, `RB`, `ope`, `wr`, `SalAlu`, `LF`) | Tabla 2 | Idéntica, incluido MOV sin `LF` | Coincide |
| S14 sin `SelDir` | `[Lpc, H]` | Solo `Lpc` | Coincide |
| `we` en S08 | `[we, L]` | `we <= '1'` | **Discrepancia (ver 7.3)** |
| Condición del salto | AND de `Lpc` con la bandera | Resuelta en S06 | Equivalente, mecanismo distinto |

### 7.3 Puntos por verificar en Logisim

1. **Polaridad de `we` en S08.** La tabla del profesor muestra `[we, L]` mientras el código escribe `we <= '1'` (activo en alto, por defecto `'0'`). Puede ser una errata de la tabla (debería ser `we, H`) o una RAM con `we` activo en bajo. Si la RAM fuera activa en bajo, con este código STORE no escribiría. Conviene comprobar con una simulación de STORE.
2. **Ancho de dirección de la memoria.** El profesor habla de 16 bits (`dirH dirL`); la guía previa afirma una RAM de $256 \times 8$ que solo usa `dirL`. Compruébalo en el esquema (qué pines del par HL llegan a la RAM). Afecta al diseño de LOAD/STORE cortos (sección 9.7).
3. **Función de `inicia`.** No se deduce del código ni de las guías; verificar a qué módulo llega.
4. **Semántica de las banderas.** Que `FZ`, `FC` y `FS` se calculen como se espera para NOT, AND, INC, DEC, ADD y SUB depende del módulo `ALU`/`FLAGS`.

### 7.4 Erratas de nomenclatura en la tabla del profesor

- Las filas de JMP, JZ, JC y JS están rotuladas `STORE0` a `STORE5` (copiadas de la fila de STORE). En realidad usan los mismos estados S03 a S06 y terminan en S14.
- La numeración salta de `STORE3` a `STORE5` (no hay `STORE4`); corresponde a S08.
- La tabla pone la condición en S14 (`Si FZ=1: PC ← HL`), pero en el código S14 se ejecuta **solo** cuando la condición ya se cumplió.

---

## 8. Limitaciones del juego de instrucciones

Consecuencias del diseño; no son errores de sintaxis.

| # | Limitación | Rodeo |
|---|---|---|
| 1 | R0 solo se escribe con MOV (`R0 ← R1`). No existe `R1 ← R0` | `MOVI 00h` y luego `ADD` deja `R1 = R0` (destruye R1) |
| 2 | LOAD, MOVI y STORE solo usan R1 | Pasar el dato por R1 |
| 3 | NOT, DEC, INC solo operan sobre R1; las de dos operandos son siempre `R0 op R1 → R1` | `SUB` es `R0 − R1`; el orden no se invierte |
| 4 | LOAD, MOVI y MOV no actualizan banderas | Pasar por una operación de ALU (por ejemplo INC y luego DEC) antes de un salto |
| 5 | No hay comparación no destructiva (CMP) | Copiar con MOV antes de restar |
| 6 | Sin OR, XOR, desplazamientos ni rotaciones | Agregarlos (sección 9.4); `ope="001"` está libre |
| 7 | Saltos solo absolutos con 2 bytes de dirección; sin CALL/RET ni pila | Convención de software |
| 8 | HL solo se carga con bytes de la instrucción; no hay punteros ni indexado | Código automodificable (STORE sobre el byte `L`/`H` de una instrucción posterior), o agregar LDH/LDL/MOV L (sección 9.7) |
| 9 | Sin acarreo de entrada (ADC/SBB) | Manejar el acarreo a mano con JC |
| 10 | Opcode desconocido = NOP de 1 byte | — |
| 11 | FIN es permanente | Solo `rst` lo saca de S11 |

---

## 9. Guías para modificar el procesador

### 9.1 Quién decide qué

| Pregunta | Quién la decide | Dónde se cambia |
|---|---|---|
| ¿Qué hace la ALU con cada código `ope`? | El módulo `ALU` | Esquema de Logisim |
| ¿Qué `ope` pide cada instrucción? | La FSM | `ope <= "xxx"` en el estado (proceso 3) |
| ¿Qué opcode lanza cada instrucción? | El decodificador | `elsif CO = x"xx"` en S02 (y en S06 si lleva dirección) |
| ¿Qué pasos sigue cada instrucción? | Los estados | `when Sxx` en el proceso 2 (transición) y en el proceso 3 (salidas) |

Cambiar el comportamiento de una operación puede requerir tocar la ALU, la FSM o ambas.

### 9.2 Lista de verificación para agregar un estado u opcode

Para un estado nuevo `S20` hay que tocar, **en este orden**:

| Paso | Dónde | Qué comprobar |
|---|---|---|
| 1 | `type ESTADOS` | Declarar `S20` |
| 2 | Proceso 2 | Agregar `when S20 => edo_sig <= …;`. Si se olvida, `when others` envía a `S00` y la CPU se **reinicia** (no se queda trabada) |
| 3 | S02 (proceso 2) | Agregar `elsif CO = x"xx" then edo_sig <= S20;` antes del `else`. Si lleva dirección, enviarlo a S03 y agregar su rama en S06 |
| 4 | Proceso 3 | Agregar `when S20 =>` con `idEstado` único (`"10100"`) y las señales necesarias |
| 5 | Memoria | Leer = `cs <= '0'; oe <= '0';` (nunca `oe <= '1'` para leer) |
| 6 | Bus | Nunca `SalAlu='1'` junto con `oe='0'` |
| 7 | PC | Un `Ipc` por cada byte de la instrucción |
| 8 | ALU | Si usa un `ope` nuevo, la ALU lo implementa en Logisim |
| 9 | `idEstado` | Máximo 31 estados (5 bits; `"11111"` reservado) |
| 10 | Simulación | Probar con un programa corto y observar `idEstado` |

### 9.3 Modificar una instrucción existente

**Caso A: cambiar la operación que usa un estado.** Se cambia `ope` en el proceso 3 (la ALU ya debe implementar el nuevo código). **Cuidado con los operandos:** los estados de un solo operando (NOT, DEC, INC) no asignan `SelRegRB`, que queda en `"000"` (R0).

Ejemplo: cambiar solo `ope` de INC a `"110"` calcularía `R1 − R0`, **no** `R0 − R1` como SUB. Para igualar a SUB hay que ajustar también los selectores:

```vhdl
when S18 =>            -- INC convertido en SUB (R0 - R1)
  idEstado <= "10010";
  SelRegW <= "001";
  wr <= '1';
  SelRegRA <= "000";   -- A = R0 (antes "001")
  SelRegRB <= "001";   -- B = R1 (antes sin asignar)
  ope <= "110";        -- A - B (antes "111")
  SalAlu <= '1';
  lF <= '1';
```

**Caso B: cambiar los registros involucrados.** Se modifican `SelRegRA`, `SelRegRB` o `SelRegW`. Por ejemplo, un ADD cuyo resultado se guarde en R0 en lugar de R1 solo cambia `SelRegW <= "000"` en S09.

**Caso C: cambiar si una instrucción actualiza banderas.** Se agrega o quita `lF <= '1';` en su estado (por ejemplo, para que MOV actualice banderas, se agrega en S10).

### 9.4 Agregar una operación nueva de la ALU (ejemplo: OR)

Con `ope` de 3 bits hay $2^3 = 8$ códigos; el código `001` está libre.

**Paso 1. Implementar la operación en Logisim.** Haz que `ope = 001` produzca `SalA OR SalB` y que la ALU siga calculando las banderas. Es obligatorio: la FSM solo *pide* la operación.

**Paso 2. Declarar el estado:**

```vhdl
-- Tipo de estados: agregar S20 al final de la lista
type ESTADOS is (S00, S01, S02, S03, S04, S05, S06, S07,
            S08, S09, S10, S11, S12, S13, S14, S15,
            S16, S17, S18, S19, S20);
```

**Paso 3. Asignar un opcode** en S02 (proceso 2), antes del `else` final:

```vhdl
-- OR (48h): se agrega al if/elsif de S02
elsif CO = x"48" then
  edo_sig <= S20;
```

**Paso 4. Definir la transición** del estado nuevo (proceso 2):

```vhdl
when S20 =>            -- Fin de OR
  edo_sig <= S01;
```

**Paso 5. Escribir las salidas** (proceso 3), copiando la receta de la familia ALU:

```vhdl
when S20 =>            -- SalA <- R0; SalB <- R1; R1 <- ALU(A or B)
  idEstado <= "10100"; -- 20 en binario
  SelRegW <= "001";    -- destino = R1
  wr <= '1';
  SelRegRA <= "000";   -- operando A = R0
  SelRegRB <= "001";   -- operando B = R1
  ope <= "001";        -- codigo de OR (debe existir en la ALU)
  SalAlu <= '1';
  lF <= '1';
```

La instrucción ocupa un byte, así que no necesita más cambios: S02 ya incrementó el PC.

### 9.5 Más de 8 operaciones: ensanchar `ope`

Con $2^4 = 16$ códigos, `ope` pasa a 4 bits. Cambios necesarios:

```vhdl
-- 1) Entidad: ensanchar el puerto
ope: out std_logic_vector (3 downto 0);

-- 2) Proceso 3, valores por defecto
ope <= "0000";

-- 3) Cada asignacion existente gana un cero a la izquierda
ope <= "0101";   -- antes "101" (ADD)
ope <= "1000";   -- ejemplo de operacion nueva (codigo 8)
```

En Logisim hay que ensanchar el pin `ope` de la ALU, el pin de salida de `control` y los cables o etiquetas que los unen (*data bits* = 4). VHDL exige la misma longitud en cada asignación: si olvidas una, no compila.

### 9.6 Cambiar el valor de un opcode

El valor hexadecimal de cada opcode aparece **solo** en el proceso 2:

- Instrucciones de 1 o 2 bytes: se edita `CO = x"40"` (u otro) en la rama correspondiente de S02.
- Instrucciones de 3 bytes (70h, 71h, 80h a 83h): se edita **tanto** la lista de S02 (la condición que lleva a S03) **como** la rama de S06.

Antes de reasignar, comprueba que el nuevo valor no esté ya usado. Los opcodes libres no ocupados incluyen, por ejemplo, `48h`, `49h`, `4Ah`, `72h`, `73h`, `74h`, `84h` y `85h`.

### 9.7 Modificaciones relacionadas con H y L

Mapa de estados nuevos propuestos (continuación de `S20`):

| Estado | `idEstado` | Instrucción | Opcode |
|---|---|---|---|
| S20 | `10100` | OR | 48h |
| S21 | `10101` | MOVI R0 | 49h |
| S22 | `10110` | MOV L,R1 | 4Ah |
| S23 | `10111` | LDH (H ← inmediato) | 74h |

**a) MOVI a R0 (opcode 49h).** Reutiliza S13 para saltar el byte inmediato:

```vhdl
-- Proceso 2, en S02:   elsif CO = x"49" then edo_sig <= S21;
-- Proceso 2, estado:
when S21 =>
  edo_sig <= S13;      -- reutiliza S13: Ipc salta el inmediato
-- Proceso 3:
when S21 =>            -- R0 <- M(PC)
  idEstado <= "10101";
  cs <= '0';
  oe <= '0';           -- lee el byte inmediato
  SelRegW <= "000";    -- destino = R0
  wr <= '1';
```

**b) Cargar H con un inmediato (LDH, opcode 74h).** Permite construir direcciones por software:

```vhdl
-- Proceso 2, en S02:   elsif CO = x"74" then edo_sig <= S23;
-- Proceso 2, estado:
when S23 =>
  edo_sig <= S13;      -- reutiliza S13
-- Proceso 3:
when S23 =>            -- H <- M(PC)
  idEstado <= "10111";
  cs <= '0';
  oe <= '0';
  LH <= '1';
```

Para `LDL` basta repetir el estado con `LL <= '1'`.

**c) Copiar R1 a L (MOV L,R1, opcode 4Ah).** `HL` lee de `BusDatos` y el buffer de la ALU puede escribir en él; no hace falta memoria:

```vhdl
-- Proceso 2, en S02:   elsif CO = x"4A" then edo_sig <= S22;
-- Proceso 2, estado:
when S22 =>
  edo_sig <= S01;
-- Proceso 3:
when S22 =>            -- L <- R1 (via ALU, paso directo)
  idEstado <= "10110";
  SelRegRA <= "001";   -- lee R1
  ope <= "000";        -- paso directo
  SalAlu <= '1';       -- R1 llega al BusDatos
  LL <= '1';           -- L captura el bus
```

No se activan `cs` ni `oe` (memoria sin emitir), por lo que no hay conflicto de bus. Combinado con INC o ADD permite recorrer vectores: incrementar un registro, copiarlo a L y hacer LOAD.

**d) Salto indirecto JMP HL (opcode 84h).** Si HL ya contiene la dirección, no hace falta leerla de memoria:

```vhdl
-- Proceso 2, en S02:
elsif CO = x"84" then
  edo_sig <= S14;      -- S01, S02, S14: 3 ciclos (ahorra 4 frente a JMP)
```

Exige haber cargado `HL` antes (por ejemplo con LDH y MOV L).

**e) LOAD y STORE cortos (opcodes 72h y 73h).** Solo válidos si la memoria usa únicamente `dirL` (punto 2 de la sección 7.3). En ese caso se omite la lectura de `H`:

```vhdl
-- Proceso 2, S02: agregar 72h y 73h a la condicion que lleva a S03:
if (CO = x"70") or (CO = x"71") or (CO = x"72") or (CO = x"73") or
   (CO = x"80") or (CO = x"81") or (CO = x"82") or (CO = x"83") then
  edo_sig <= S03;

-- Proceso 2: S04 deja de ser lineal
when S04 =>
  if CO = x"72" then
    edo_sig <= S07;    -- LOAD corto (reutiliza S07)
  elsif CO = x"73" then
    edo_sig <= S08;    -- STORE corto (reutiliza S08)
  else
    edo_sig <= S05;
  end if;
```

La instrucción pasa de 7 a 5 ciclos y de 3 a 2 bytes. Contabilidad del PC: el opcode lo consume S02 y el byte `L` lo consume el `Ipc` de S04, así que el PC termina apuntando a la siguiente instrucción. `H` conserva un valor anterior pero la memoria no lo usa. Si la memoria sí usa `H`, esta variante no es válida.

### 9.8 Agregar una bandera nueva (ejemplo: overflow en `Flags(3)`)

Si la ALU y `FLAGS` producen un bit adicional:

```vhdl
-- Proceso 2, en S02: agregar 85h (JV) a la condicion que lleva a S03
(CO = x"85") or

-- Proceso 2, en S06: nueva rama
elsif CO = x"85" and Flags(3) = '1' then
  edo_sig <= S14;      -- JV salta: overflow activo
elsif CO = x"85" and Flags(3) = '0' then
  edo_sig <= S01;      -- JV no salta
```

No hace falta tocar la lista de sensibilidad: ya incluye `Flags` completo.

### 9.9 Plantillas listas para copiar

**Instrucción ALU de un byte** (proceso 3; recuerda agregar su transición en el proceso 2 y su rama en S02):

```vhdl
when S2x =>
  idEstado <= "xxxxx";  -- numero de estado, unico
  SelRegW <= "001";     -- destino
  wr <= '1';
  SelRegRA <= "000";    -- operando A
  SelRegRB <= "001";    -- operando B (omitir si usa un solo operando)
  ope <= "xxx";         -- codigo de la operacion en la ALU
  SalAlu <= '1';
  lF <= '1';            -- quitar si no debe cambiar banderas
```

**Instrucción con byte inmediato** (lee `M(PC)` y salta el byte con S13):

```vhdl
-- Proceso 2:
when S2x =>
  edo_sig <= S13;

-- Proceso 3:
when S2x =>
  idEstado <= "xxxxx";
  cs <= '0';
  oe <= '0';
  -- aqui el destino: SelRegW + wr, o LH / LL
```

### 9.10 Errores frecuentes

| Síntoma | Causa probable |
|---|---|
| El PC queda desalineado y se ejecuta un operando como si fuera opcode | Falta o sobra un `Ipc`; revisar la contabilidad del PC |
| La instrucción nueva no hace nada | Falta la rama en S02: el opcode cae en el `else` y se ignora como NOP |
| La CPU se reinicia al llegar al estado nuevo | Falta su `when` en el proceso 2: `when others` envía a S00 |
| La FSM se queda en el estado nuevo | Su `when` existe pero no asigna `edo_sig` (se retiene por el valor por defecto) |
| La memoria no entrega el dato | Se escribió `oe <= '1'` (inactivo) en lugar de `cs <= '0'; oe <= '0'` |
| Resultado incorrecto sin error de VHDL | El `ope` pedido no existe o hace otra cosa en la ALU |
| Error de compilación al ensanchar `ope` | Alguna asignación conserva 3 bits |
| `idEstado` no puede representar el estado | Más de 31 estados con 5 bits |
| STORE no escribe | Polaridad de `we` de la RAM distinta (ver 7.3, punto 1) |

---

## Apéndice A. Glosario de señales

| Señal | Dirección | Activa en | Descripción |
|---|---|---|---|
| `clk` | entrada | flanco de subida | Reloj de la FSM |
| `rst` | entrada | alto | Reset asíncrono; fuerza `S00` |
| `CO` (8 bits) | entrada | — | Opcode guardado en RI |
| `Flags` (8 bits) | entrada | — | Banderas; solo bits 0 (Z), 1 (C), 2 (S) |
| `clear` | salida | alto | Limpia la ruta de datos (en S00) |
| `inicia` | salida | alto | Señal de arranque (en S00) |
| `Lpc` | salida | alto | Carga el PC con HL |
| `Ipc` | salida | alto | Incrementa el PC |
| `SelDir` | salida | — | 0 = dirección del PC; 1 = dirección de HL |
| `cs` | salida | **bajo** | Selección de la memoria |
| `oe` | salida | **bajo** | Salida de la memoria hacia el bus |
| `we` | salida | alto (a verificar) | Escritura en la memoria |
| `Lri` | salida | alto | Carga el registro de instrucción |
| `LL`, `LH` | salida | alto | Cargan L y H desde el bus |
| `SelRegW` (3 bits) | salida | — | Registro destino del BR |
| `SelRegRA`, `SelRegRB` (3 bits) | salida | — | Registros que salen por los puertos A y B |
| `wr` | salida | alto | Habilita la escritura en el BR |
| `ope` (3 bits) | salida | — | Operación de la ALU |
| `SalAlu` | salida | alto | Habilita el buffer de la ALU hacia el bus |
| `LF` | salida | alto | Carga el registro de banderas |
| `fin` | salida | alto | Procesador detenido (S11) |
| `idEstado` (5 bits) | salida | — | Número del estado actual |
