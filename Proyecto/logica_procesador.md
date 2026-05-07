# Lógica del Procesador RISC de 8 bits

Este documento describe la arquitectura interna y la lógica de funcionamiento del procesador diseñado en VHDL. El sistema sigue una arquitectura de Harvard simplificada con un bus de datos compartido para memoria y periféricos.

## 1. Parámetros de Arquitectura

| Parámetro | Valor | Descripción |
| :--- | :--- | :--- |
| **Ancho de Datos** | 8 bits | Tamaño de palabra procesada por la ALU y registros. |
| **Ancho de Direcciones** | 16 bits | Capacidad de direccionamiento de 64 KB (0x0000 a 0xFFFF). |
| **Registros** | 8 | Banco de registros de propósito general (R0 a R7). |
| **Frecuencia Base** | 50 MHz | Reloj de entrada en FPGA (Divisible a 1 Hz). |

## 2. Formato de Instrucción

Las instrucciones son de longitud variable (1 a 3 bytes). El primer byte siempre contiene el **Código de Operación (Opcode)** y, en instrucciones de registro, el índice del registro destino.

**Estructura del Opcode (8 bits):**
`[ Opcode (5 bits) | Registro Destino (3 bits) ]`

---

## 3. Unidades Lógicas

### 3.1 Unidad de Control (UC)
Es el cerebro del sistema. Implementa una Máquina de Estados Finitos (FSM) que orquesta el ciclo de instrucción: **Fetch -> Decode -> Execute**.

```mermaid
graph LR
    subgraph UC [Unidad de Control - FSM]
        Direction[Lógica de Decodificación]
        States[Controlador de Estados]
    end

    %% Entradas
    CLK(Reloj) --> States
    RST(Reset) --> States
    INICIA(Inicia) --> States
    CO[Opcode 8-bit] --> Direction
    FZ(Flag Zero) --> States
    FC(Flag Carry) --> States
    FS(Flag Sign) --> States

    %% Salidas
    Direction --> SelReg[Selectores de Registro]
    States --> MemCtrl[cs, oe, we]
    States --> ALUCtrl[ope, SalAlu, LF]
    States --> PCCtrl[Ipc, Lpc, SelDir]
    States --> RegCtrl[LH, LL, Lri, wr]

    style UC fill:#f9f,stroke:#333,stroke-width:2px
```

### 3.2 Unidad Aritmético Lógica (ALU)
Realiza las operaciones matemáticas y lógicas fundamentales. Genera señales de estado (banderas) basadas en el resultado.

```mermaid
graph TD
    subgraph ALU [Unidad Aritmético Lógica]
        Op[Selector de Operación]
        Calc[Núcleo de Cálculo 8-bit]
        Flags[Generador de Banderas]
    end

    SalA[Operando A] --> Calc
    SalB[Operando B] --> Calc
    ope[Opcode ALU] --> Op
    Op --> Calc
    Calc --> Salida[Resultado 8-bit]
    Calc --> Flags
    Flags --> FZ(Zero)
    Flags --> FC(Carry)
    Flags --> FS(Sign)

    style ALU fill:#bbf,stroke:#333,stroke-width:2px
```

### 3.3 Banco de Registros (BR)
Contiene 8 registros de 8 bits. Permite leer dos operandos simultáneamente (A y B) y escribir un resultado en un tercer registro en el flanco de reloj.

```mermaid
graph LR
    subgraph BR [Banco de Registros 8x8]
        Regs[(R0...R7)]
    end

    entDat[Dato Entrada] -- wr --> Regs
    SelRegW[Sel Reg W] --> Regs
    Regs -- RA --> SalA[Puerto A]
    SelRegRA[Sel Reg A] --> Regs
    Regs -- RB --> SalB[Puerto B]
    SelRegRB[Sel Reg B] --> Regs

    style BR fill:#dfd,stroke:#333,stroke-width:2px
```

### 3.4 Contador de Programa (PC) y Puntero HL
El **PC** gestiona la ejecución secuencial, mientras que el registro **HL** actúa como un puntero de 16 bits para saltos y acceso a memoria RAM.

```mermaid
graph TD
    subgraph Direccionamiento
        PC[Program Counter 16-bit]
        HL[Registro H|L 16-bit]
        MUX{Mux Dir}
    end

    Ipc(Incremento) --> PC
    Lpc(Carga) --> PC
    BusDat[Bus de Datos 8-bit] --> HL
    HL --> PC
    PC --> MUX
    HL --> MUX
    SelDir[Selector UC] --> MUX
    MUX --> DirMem[Bus Direcciones 16-bit]

    style Direccionamiento fill:#ffd,stroke:#333,stroke-width:2px
```

### 3.5 Memoria RAM (64Kx8)
Almacena tanto el programa (instrucciones) como los datos de usuario. Utiliza un bus bidireccional controlado por buffers tri-estado.

```mermaid
graph LR
    subgraph RAM [Memoria 64KB]
        Storage[[Celdas de Memoria]]
    end

    Dir[Dirección 16-bit] --> Storage
    cs(Chip Select) --> Storage
    oe(Output Enable) --> Storage
    we(Write Enable) --> Storage
    Bus[Bus de Datos 8-bit] <--> Storage

    style RAM fill:#ddd,stroke:#333,stroke-width:2px
```

---

## 4. Diagrama de Bloques Completo del Procesador

Este diagrama muestra la interconexión global entre la Unidad de Control, la Ruta de Datos y la Memoria.

```mermaid
graph TD
    %% Bloques Principales
    subgraph CPU [Procesador RISC 8-bit]
        UC[Unidad de Control]
        
        subgraph RD [Ruta de Datos - Datapath]
            ALU[ALU]
            BR[Banco de Registros]
            REGS[PC / HL / RI / Flags]
        end
    end

    MEM[Memoria RAM 64KB]

    %% Conexiones de Control
    UC -- "Señales de Control (RA, RB, wr, ope, etc.)" --> RD
    UC -- "cs, oe, we" --> MEM

    %% Conexiones de Datos y Direcciones
    RD -- "Bus de Direcciones (16-bit)" --> MEM
    MEM <== "Bus de Datos (8-bit)" ==> RD
    RD -- "Opcode (RI)" --> UC
    RD -- "FZ, FC, FS" --> UC

    %% I/O Externo
    RST((RESET)) --> UC
    CLK((CLOCK)) --> UC
    START((INICIA)) --> UC
    RD -- "Salida" --> LEDs[LEDs / 7-Seg]

    %% Estilos
    style CPU fill:#fff,stroke:#333,stroke-width:4px
    style UC fill:#f9f,stroke:#333
    style RD fill:#bbf,stroke:#333
    style MEM fill:#eee,stroke:#333
```
