# Tabla de estados

| Op Code | Estado | Edo Equiv | Acción |
| :--- | :--- | :--- | :--- |
| | RESET0 | S00 | Reset |
| | FETCH0 | S01 | RI <- M(PC) |
| | FETCH1 | S02 | PC <- PC + 1 |
| **70h** | **LOAD dir** | | **R1 <- M(dirH dirL)** |
| | LOAD0 | S03 | L <- M(PC) |
| | LOAD1 | S04 | PC <- PC + 1 |
| | LOAD2 | S05 | H <- M(PC) |
| | LOAD3 | S06 | PC <- PC + 1 |
| | LOAD4 | S07 | R1 <- M(HL) |
| **71h** | **STORE dir** | | **M(dirH dirL) <- R1** |
| | STORE0 | S03 | L <- M(PC) |
| | STORE1 | S04 | PC <- PC + 1 |
| | STORE2 | S05 | H <- M(PC) |
| | STORE3 | S06 | PC <- PC + 1 |
| | STORE5 | S08 | SalA <- R1; M(HL) <- ALU(A) |
| **40h** | **NOT R1** | | **R1 <- not R1** |
| | NOT0 | S15 | SalA <- R1; R1 <- ALU(notA) |
| **41h** | **AND R1** | | **R1 <- R0 and R1** |
| | AND0 | S16 | SalA <- R0; SalB <- R1; R1 <- ALU(AandB) |
| **42h** | **DEC R1** | | **R1 <- R1 - 1** |
| | DEC0 | S17 | SalA <- R1; R1 <- ALU(A - 1) |
| **43h** | **INC R1** | | **R1 <- R1 + 1** |
| | INC0 | S18 | SalA <- R1; R1 <- ALU(A + 1) |
| **44h** | **SUB R1** | | **R1 <- R0 - R1** |
| | SUB0 | S19 | SalA <- R0; SalB <- R1; R1 <- ALU(A - B) |
| **45h** | **ADD R1** | | **R1 <- R0 + R1** |
| | ADD0 | S09 | SalA <- R0; SalB <- R1; R1 <- ALU(A + B) |
| **46h** | **MOV R0** | | **R0 <- R1** |
| | MOV0 | S10 | SalA <- R1; R0 <- ALU(A) |
| **47h** | **MOVI K** | | **R1 <- K** |
| | MOVI0 | S12 | R1 <- M(PC) |
| | MOVI1 | S13 | PC <- PC + 1 |
| **80h** | **JMP dir** | | **PC <- dirH dirL** |
| | STORE0 | S03 | L <- M(PC) |
| | STORE1 | S04 | PC <- PC + 1 |
| | STORE2 | S05 | H <- M(PC) |
| | STORE3 | S06 | PC <- PC + 1 |
| | STORE5 | S14 | PC <- HL |
| **81h** | **JZ dir** | | **Si FZ=1: PC <- dirH dirL** |
| | STORE0 | S03 | L <- M(PC) |
| | STORE1 | S04 | PC <- PC + 1 |
| | STORE2 | S05 | H <- M(PC) |
| | STORE3 | S06 | PC <- PC + 1 |
| | STORE5 | S14 | Si FZ=1: PC <- HL |
| **82h** | **JC dir** | | **Si FC=1: PC <- dirH dirL** |
| | STORE0 | S03 | L <- M(PC) |
| | STORE1 | S04 | PC <- PC + 1 |
| | STORE2 | S05 | H <- M(PC) |
| | STORE3 | S06 | PC <- PC + 1 |
| | STORE5 | S14 | Si FC=1: PC <- HL |
| **83h** | **JS dir** | | **Si FS=1: PC <- dirH dirL** |
| | STORE0 | S03 | L <- M(PC) |
| | STORE1 | S04 | PC <- PC + 1 |
| | STORE2 | S05 | H <- M(PC) |
| | STORE3 | S06 | PC <- PC + 1 |
| | STORE5 | S14 | Si FS=1: PC <- HL |
| **FFh** | **FIN** | | **Fin** |
| | FIN0 | S11 | Fin |



### 1. Fase de Búsqueda (Fetch) y Control Básico

Esta tabla contiene los estados de inicialización, la lectura de la memoria para traer el Código de Operación, y las instrucciones cortas de control o carga inmediata.

| Op Code | Instrucción / Fase | Estado | Acción | Pines Modificados |
| :--- | :--- | :--- | :--- | :--- |
| | **RESET** | | **Reset** | |
| | RESET0 | S00 | Reset | `[Clear, H]` `[inicia, H]` |
| | **FETCH** | | **Búsqueda de Instrucción**| |
| | FETCH0 | S01 | RI <- M(PC) | `[cs', L], [oe', L], [Lri, H]` |
| | FETCH1 | S02 | PC <- PC + 1 | `[Ipc, H]` |
| **47h** | **MOVI K** | | **R1 <- K** | |
| | MOVI0 | S12 | R1 <- M(PC) | `[cs', L], [oe', L], [SelRegW, 001], [wr, H]` |
| | MOVI1 | S13 | PC <- PC + 1 | `[Ipc, H]` |
| **FFh** | **FIN** | | **Fin** | |
| | FIN0 | S11 | Fin | `[Fin, H]` |
---

### 2. Fase de Ejecución: Operaciones Rápidas (ALU y Registros)

Estas instrucciones se ejecutan en un solo ciclo de reloj. Aquí es donde los multiplexores de los registros y de la ALU hacen todo el trabajo pesado. Nota cómo cambian las direcciones: **R0 se asume como `000**` y **R1 como `001**`.

| Op Code | Instrucción / Fase | Estado | Acción | SelRegW | SelRegRA | SelRegRB | ope | wr |SalAlu|LF|
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **40h** | **NOT R1** | | **R1 <- not R1** | | | | | |
| | NOT0 | S15 | SalA <- R1; R1 <- ALU(notA) | 001 | 001 | | 011 | H | H | H |
| **41h** | **AND R1** | | **R1 <- R0 and R1** | | | | | |
| | AND0 | S16 | SalA <- R0; SalB <- R1; R1 <- ALU(AandB) | 001 | 000 | 001 | 010 | H | H | H |
| **42h** | **DEC R1** | | **R1 <- R1 - 1** | | | | | |
| | DEC0 | S17 | SalA <- R1; R1 <- ALU(A - 1) | 001 | 001 | | 100 | H | H | H |
| **43h** | **INC R1** | | **R1 <- R1 + 1** | | | | | |
| | INC0 | S18 | SalA <- R1; R1 <- ALU(A + 1) | 001 | 001 | | 111 | H | H | H |
| **44h** | **SUB R1** | | **R1 <- R0 - R1** | | | | | |
| | SUB0 | S19 | SalA <- R0; SalB <- R1; R1 <- ALU(A - B) | 001 | 000 | 001 | 110 | H | H | H |
| **45h** | **ADD R1** | | **R1 <- R0 + R1** | | | | | |
| | ADD0 | S09 | SalA <- R0; SalB <- R1; R1 <- ALU(A + B) | 001 | 000 | 001 | 101 | H | H | H |
| **46h** | **MOV R0** | | **R0 <- R1** | | | | | |
| | MOV0 | S10 | SalA <- R1; R0 <- ALU(A) | 000 | 001 | | 000 | H | H |  |

*(Nota técnica: En el estado S10 (MOV), `ope = 000` actúa como un "pasa-bajas" o *bypass* transparente en la ALU para mover el dato sin alterarlo).*

---

### 3. Fase de Ejecución: Operaciones Complejas (Memoria y Saltos)

Esta sección evidencia la reutilización del hardware. Las instrucciones de carga, almacenamiento y salto comparten la misma secuencia de estados para ensamblar la dirección de 16 bits, pero luego divergen en la acción final dependiendo del OpCode. Esto es un diseño clásico de microprogramación, donde una rutina común de "fetch operand" se utiliza para múltiples instrucciones.

| Op Code | Instrucción / Fase | Estado | Acción | Pines Modificados |
| :--- | :--- | :--- | :--- | :--- |
| **70h** | **LOAD dir** | | **R1 <- M(dirH dirL)** | |
| | LOAD0 | S03 | L <- M(PC) | `[cs', L], [oe', L], [LL, H]` |
| | LOAD1 | S04 | PC <- PC + 1 | `[Ipc, H]` |
| | LOAD2 | S05 | H <- M(PC) | `[cs', L], [oe', L], [LH, H]` |
| | LOAD3 | S06 | PC <- PC + 1 | `[Ipc, H]` |
| | LOAD4 | S07 | R1 <- M(HL) | `[SelDir, H], [cs', L], [oe', L], [SelRegW, 001], [wr, H]` |
| **71h** | **STORE dir** | | **M(dirH dirL) <- R1** | |
| | STORE0 | S03 | L <- M(PC) | `[cs', L], [oe', L], [LL, H]` |
| | STORE1 | S04 | PC <- PC + 1 | `[Ipc, H]` |
| | STORE2 | S05 | H <- M(PC) | `[cs', L], [oe', L], [LH, H]` |
| | STORE3 | S06 | PC <- PC + 1 | `[Ipc, H]` |
| | STORE5 | S08 | SalA <- R1; M(HL) <- ALU(A) | `[SelDir, H], [cs', L],  [we, L], [SelRegRA, 001], [ope, 000], [SalAlu, H]` |
| **80h** | **JMP dir** | | **PC <- dirH dirL** | |
| | STORE0 | S03 | L <- M(PC) | `[cs', L], [oe', L], [LL, H]` |
| | STORE1 | S04 | PC <- PC + 1 | `[Ipc, H]` |
| | STORE2 | S05 | H <- M(PC) | `[cs', L], [oe', L], [LH, H]` |
| | STORE3 | S06 | PC <- PC + 1 | `[Ipc, H]` |
| | STORE5 | S14 | PC <- HL | `[Lpc, H]` |
| **81h** | **JZ dir** | | **Si FZ=1: PC <- dirH dirL** | |
| | STORE0 | S03 | L <- M(PC) | `[cs', L], [oe', L], [LL, H]` |
| | STORE1 | S04 | PC <- PC + 1 | `[Ipc, H]` |
| | STORE2 | S05 | H <- M(PC) | `[cs', L], [oe', L], [LH, H]` |
| | STORE3 | S06 | PC <- PC + 1 | `[Ipc, H]` |
| | STORE5 | S14 | Si FZ=1: PC <- HL | `[Lpc, H]` *(Condicionado)* |
| **82h** | **JC dir** | | **Si FC=1: PC <- dirH dirL** | |
| | STORE0 | S03 | L <- M(PC) | `[cs', L], [oe', L], [LL, H]` |
| | STORE1 | S04 | PC <- PC + 1 | `[Ipc, H]` |
| | STORE2 | S05 | H <- M(PC) | `[cs', L], [oe', L], [LH, H]` |
| | STORE3 | S06 | PC <- PC + 1 | `[Ipc, H]` |
| | STORE5 | S14 | Si FC=1: PC <- HL | `[Lpc, H]` *(Condicionado)* |
| **83h** | **JS dir** | | **Si FS=1: PC <- dirH dirL** | |
| | STORE0 | S03 | L <- M(PC) | `[cs', L], [oe', L], [LL, H]` |
| | STORE1 | S04 | PC <- PC + 1 | `[Ipc, H]` |
| | STORE2 | S05 | H <- M(PC) | `[cs', L], [oe', L], [LH, H]` |
| | STORE3 | S06 | PC <- PC + 1 | `[Ipc, H]` |
| | STORE5 | S14 | Si FS=1: PC <- HL | `[Lpc, H]` *(Condicionado)* |

A nivel arquitectónico, estas tres tablas describen exactamente cómo la **Unidad de Control** (la máquina de estados finitos o FSM) orquesta la **Ruta de Datos (Datapath)** del procesador. Cada estado representa un ciclo de reloj, y los "pines modificados" o "señales" son las líneas de control físicas que abren y cierran registros, conmutan multiplexores y le indican a la Memoria o a la ALU qué hacer.

Aquí tienes la descripción técnica de cómo opera la lógica de hardware en cada categoría:

### 1. Lógica de Búsqueda (Fetch) y Control Básico

Esta sección maneja el ciclo fundamental de vida del procesador: traer la instrucción de la memoria para saber qué ejecutar.

* **El bus de direcciones y la Memoria:** Durante el estado `S01` (FETCH0), la Unidad de Control necesita leer el Código de Operación (OpCode). Para ello, asume que el Contador de Programa ($PC$) está conectado al bus de direcciones de la memoria.
* **Activación de lectura:** La señal `oe'` (Output Enable, típicamente activa en bajo) se pone en estado `L` para habilitar los buffers triestado de la memoria de programa, permitiendo que el dato fluya hacia el bus de datos interno.
* **Captura de la instrucción:** Simultáneamente, la señal `Lri` (Load Register Instruction) en `H` habilita la escritura del Registro de Instrucción ($RI$), atrapando el OpCode en el flanco del reloj.
* **Alineación del PC:** En `S02` (FETCH1), la señal `Ipc` (Increment PC) le indica al hardware del Contador de Programa que sume 1 a su valor actual ($PC \leftarrow PC + 1$), dejándolo listo para apuntar al siguiente byte (que podría ser el operando de la instrucción actual o el OpCode de la siguiente).
* **Cargas Inmediatas (`MOVI`):** Opera bajo el mismo principio de lectura de memoria, pero en lugar de activar `Lri`, direcciona un registro de propósito general usando `SelRegW = 001` (Registro $R1$) y enciende el pin de escritura del banco de registros (`wr = H`).

### 2. Lógica de Ejecución Rápida (ALU y Registros)

Esta tabla describe un datapath clásico de **Registro-ALU-Registro** de un solo ciclo. No hay acceso a memoria externa aquí, por lo que todo ocurre a la velocidad máxima del reloj.

* **Multiplexación de Entradas (Source):** Los buses de entrada de la ALU ($SalA$ y $SalB$) están conectados a la salida de un multiplexor gigante (el banco de registros). Las señales `SelRegRA` y `SelRegRB` actúan como los selectores de estos multiplexores. Por ejemplo, si `SelRegRA = 000`, enruta físicamente el contenido de $R0$ hacia la entrada A de la ALU.
* **Operación Combinacional:** La señal `ope` (de 3 bits) entra directamente al decodificador interno de la Unidad Lógico Aritmética (ALU). Esto configura las compuertas lógicas internas para que el resultado en el bus de salida de la ALU sea una suma (`101`), una resta (`110`), un AND (`010`), etc.
* **Escritura (Destination):** El resultado de la ALU viaja de vuelta al banco de registros. La señal `SelRegW` le dice al demultiplexor de entrada qué registro debe recibir el dato, y el pin `wr = H` (Write Enable) abre el *latch* del flip-flop de ese registro para guardar el resultado en ese exacto ciclo de reloj.

### 3. Lógica de Ejecución Compleja (Memoria de Datos y Saltos)

Esta es la sección mecánicamente más compleja porque revela un "cuello de botella" intencional en el diseño: **El procesador maneja direcciones de 16 bits, pero su memoria y bus de datos son de 8 bits.** * **Ensamblaje del Puntero ($HL$):** Para acceder a una dirección específica o saltar hacia ella, el procesador no puede leer los 16 bits de golpe. Utiliza la subrutina de los estados `S03` al `S06`. Lee el byte "bajo" (dirL) de la memoria y usa la señal `LL = H` para guardarlo en el registro interno $L$. Luego incrementa el $PC$, lee el byte "alto" (dirH) y usa `LH = H` para guardarlo en el registro $H$. Ahora, el par de registros $HL$ contiene la dirección completa de 16 bits.

* **Multiplexación del Bus de Direcciones (`SelDir`):** Por defecto, la memoria apunta a donde diga el $PC$. Pero en instrucciones como `LOAD` y `STORE`, necesitamos leer/escribir en la variable a la que apunta $HL$. La señal `SelDir = H` actúa como el conmutador de un multiplexor en el bus de direcciones: desconecta temporalmente al $PC$ de la memoria y conecta en su lugar a los registros $HL$.
* Una vez hecho el cambio de vía, se usa `oe'` (lectura) para cargar un registro, o `we` (Write Enable, escritura) para guardar un dato en la RAM.


* **Control de Flujo (Saltos condicionales e incondicionales):** En lugar de interactuar con la RAM, las instrucciones de salto modifican directamente el Contador de Programa. La señal clave aquí es `Lpc` (Load PC).
* Para un salto incondicional (`JMP`), `Lpc = H` fuerza físicamente a que el valor que estaba ensamblado en $HL$ sobrescriba al $PC$ ($PC \leftarrow HL$).
* Para saltos condicionales (`JZ`, `JC`, `JS`), la señal `Lpc` pasa por una compuerta AND junto con la bandera de la ALU correspondiente ($FZ$, $FC$, $FS$). Si la compuerta no recibe un `1` de la bandera (condición no cumplida), `Lpc` se queda en `L`, el salto se ignora, y el procesador vuelve a Fetch para ejecutar la siguiente línea de código secuencial.