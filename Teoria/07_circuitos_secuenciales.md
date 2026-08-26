<!--
---
file: Teoria/07_circuitos_secuenciales.md
description: Flip-Flops, Latches, contadores, registros y Máquinas de Estados Finitos (FSM Moore y Mealy)
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [fsm, moore, mealy, flip-flop, latch, secuenciales, vhdl]
---
-->

# Circuitos Secuenciales

A diferencia de los circuitos combinacionales, donde la salida depende únicamente de las entradas actuales, en los **circuitos secuenciales** la salida depende de las entradas actuales y de la **historia pasada** (estado). Esto implica la necesidad de elementos de **memoria**.

### 7.1 Tipos de memoria: Latch vs. Flip-Flop

La memoria básica en electrónica digital se basa en la realimentación.

*   **Latch (Cerrojo):** Es sensible al **nivel** de la señal de control (habilitación). Mientras la señal de control esté activa, la salida cambia si cambia la entrada (transparencia). Es propenso a *glitches* y difícil de controlar en diseños complejos.
    *   *En VHDL:* Se infiere cuando un proceso no asigna valor a una señal en todas las ramas posibles (ej. falta un `ELSE`). Generalmente es indeseado en diseño síncrono.

*   **Flip-Flop (Biestable):** Es sensible al **flanco** (transición) de la señal de reloj (`CLK`). Solo actualiza su salida en el instante preciso del cambio de 0 a 1 (flanco de subida) o 1 a 0.
    *   *En VHDL:* Se infiere usando `RISING_EDGE(clk)` o `clk'EVENT AND clk='1'`. Es el bloque constructivo fundamental de las FPGAs.

```vhdl
-- Flip-Flop D con Reset Asíncrono (Estándar en FPGAs)
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY dff_async_rst IS
    PORT (
        clk   : IN  STD_LOGIC;
        reset : IN  STD_LOGIC;
        d     : IN  STD_LOGIC;
        q     : OUT STD_LOGIC
    );
END ENTITY dff_async_rst;

ARCHITECTURE rtl OF dff_async_rst IS
BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            q <= '0';
        ELSIF RISING_EDGE(clk) THEN
            q <= d;
        END IF;
    END PROCESS;
END ARCHITECTURE rtl;
```

### 7.2 Tipos de circuitos secuenciales

1.  **Asíncronos:** Los cambios de estado ocurren en cuanto cambian las entradas, sin una señal de reloj global que sincronice todo. Son rápidos pero difíciles de diseñar y propensos a condiciones de carrera.
2.  **Síncronos:** Todos los cambios de estado están sincronizados por una señal de reloj global (`CLK`). El sistema avanza paso a paso. Son más fáciles de diseñar y verificar, y son el estándar en diseño FPGA/ASIC.

### 7.3 Máquinas de Estados Finitos (FSM)

Una FSM es un modelo matemático de computación usado para diseñar lógica secuencial. Se compone de estados, transiciones y salidas.

#### 7.3.1 Modelo de Moore

*   **Definición:** Las salidas dependen **únicamente del estado actual**.
*   **Características:**
    *   La salida es síncrona con el reloj (si se registra el estado) o estable durante el periodo del estado.
    *   Suele requerir más estados que Mealy.
    *   Es más segura frente a *glitches* de entrada.

**Diagrama de bloques:**

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#e3f2fd','primaryTextColor':'#1565c0','primaryBorderColor':'#64b5f6','lineColor':'#42a5f5','secondaryColor':'#fff3e0','tertiaryColor':'#f1f8e9'}}}%%
graph LR
    A[Entrada] --> B[Lógica de<br/>Estado Siguiente]
    B --> C[Registro de<br/>Estado]
    C --> D[Lógica de<br/>Salida]
    D --> E[Salida]
    C -.Estado actual.-> B
    F[CLK] --> C
    
    style C fill:#bbdefb,stroke:#1976d2,stroke-width:2px,color:#0d47a1
    style D fill:#ffccbc,stroke:#d84315,stroke-width:2px,color:#bf360c
    style B fill:#c8e6c9,stroke:#388e3c,stroke-width:2px,color:#1b5e20
```

**Ejemplo 1: Detector de Secuencia "01" (Moore)**

Ejemplo simple: detectar cuando llega un `0` seguido de un `1`.

En Moore, necesitamos **3 estados** porque la salida solo depende del estado:

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#e8eaf6','primaryTextColor':'#3f51b5','primaryBorderColor':'#7986cb','lineColor':'#5c6bc0','noteBkgColor':'#f3e5f5','noteTextColor':'#333'}}}%%
stateDiagram-v2
    RESET --> E_Inicial
    
    E_Inicial --> E_Inicial: entrada=1
    E_Inicial --> CERO: entrada=0
    CERO --> CERO: entrada=0
    CERO --> DETECTADO: entrada=1
    DETECTADO --> CERO: entrada=0
    DETECTADO --> E_Inicial: entrada=1
    
    note right of E_Inicial
        Salida: 0
        Esperando primer 0
    end note
    
    note right of CERO
        Salida: 0
        Ya recibió 0,
        esperando 1
    end note
    
    note right of DETECTADO
        Salida: 1
        Secuencia "01"
        completada ✓
    end note
```

**Estados Moore:**
- **E_Inicial**: Estado inicial, esperando el primer `0`. Salida = `0`
  - Si entrada = `1`: permanece en E_Inicial
  - Si entrada = `0`: va a CERO
- **CERO**: Se recibió un `0`, esperando el `1`. Salida = `0`
  - Si entrada = `0`: permanece en CERO (reinicia detección)
  - Si entrada = `1`: va a DETECTADO
- **DETECTADO**: Secuencia `01` completa. **Salida = `1`**
  - Si entrada = `0`: va a CERO (nueva secuencia posible)
  - Si entrada = `1`: va a E_Inicial (resetea)

**Implementación VHDL (Estándar de 2 procesos):**

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY fsm_moore_01 IS
    PORT (
        clk     : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        entrada : IN  STD_LOGIC;
        salida  : OUT STD_LOGIC
    );
END ENTITY fsm_moore_01;

ARCHITECTURE rtl OF fsm_moore_01 IS
    -- Declaración de tipo enumerado para los estados
    TYPE estado_t IS (E_Inicial, CERO, DETECTADO);
    SIGNAL estado_actual, estado_siguiente : estado_t;
BEGIN
    -- 1. Proceso síncrono: Registro de estado
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            estado_actual <= E_Inicial;
        ELSIF RISING_EDGE(clk) THEN
            estado_actual <= estado_siguiente;
        END IF;
    END PROCESS;

    -- 2. Proceso combinacional: Lógica de estado siguiente y salidas (Moore)
    PROCESS(estado_actual, entrada)
    BEGIN
        -- Valores por defecto para evitar latches
        estado_siguiente <= estado_actual;
        salida <= '0';

        CASE estado_actual IS
            WHEN E_Inicial =>
                salida <= '0';
                IF entrada = '0' THEN
                    estado_siguiente <= CERO;
                ELSE
                    estado_siguiente <= E_Inicial;
                END IF;

            WHEN CERO =>
                salida <= '0';
                IF entrada = '1' THEN
                    estado_siguiente <= DETECTADO;
                ELSE
                    estado_siguiente <= CERO;
                END IF;

            WHEN DETECTADO =>
                salida <= '1'; -- Salida depende exclusivamente del estado
                IF entrada = '0' THEN
                    estado_siguiente <= CERO;
                ELSE
                    estado_siguiente <= E_Inicial;
                END IF;
        END CASE;
    END PROCESS;
END ARCHITECTURE rtl;
```

**Ejemplo 2: Detector de Secuencia "101" (Moore)**

Detecta la secuencia 101 en una entrada serial. La salida se activa un ciclo después de completarse la secuencia.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#e8f5e9','primaryTextColor':'#2e7d32','primaryBorderColor':'#66bb6a','lineColor':'#81c784','secondaryColor':'#fff9c4','tertiaryColor':'#e1f5fe','noteBkgColor':'#fffde7','noteTextColor':'#333'}}}%%
stateDiagram-v2
    RESET --> E_Inicial
    E_Inicial --> E_Inicial: entrada=0
    E_Inicial --> S1: entrada=1
    S1 --> S2: entrada=0
    S1 --> S1: entrada=1
    S2 --> E_Inicial: entrada=0
    S2 --> S3: entrada=1
    S3 --> S2: entrada=0
    S3 --> S1: entrada=1
    
    note right of E_Inicial
        Salida: 0
        Estado inicial
    end note
    
    note right of S1
        Salida: 0
        Detectado "1"
    end note
    
    note right of S2
        Salida: 0
        Detectado "10"
    end note
    
    note right of S3
        Salida: 1
        Detectado "101" ✓
    end note
```

**Estados en FSM Moore:**
- **E_Inicial**: No se ha detectado nada o reinicio. Salida = `0`
  - `0`: permanece en E_Inicial
  - `1`: va a S1
- **S1**: Se detectó un `1`. Salida = `0`
  - `0`: va a S2
  - `1`: permanece en S1
- **S2**: Se detectó `10`. Salida = `0`
  - `0`: vuelve a E_Inicial
  - `1`: va a S3
- **S3**: Se detectó `101` completo. **Salida = `1`**
  - `0`: va a S2 (puede empezar nueva secuencia "101")
  - `1`: va a S1

**Ejemplo 3: Detector de Secuencia "001" (Moore)**

Detecta la secuencia 001 en una entrada serial. Se necesitan **4 estados**.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#fff3e0','primaryTextColor':'#e65100','primaryBorderColor':'#ff9800','lineColor':'#fb8c00','secondaryColor':'#fce4ec','tertiaryColor':'#e8f5e9','noteBkgColor':'#fffde7','noteTextColor':'#333'}}}%%
stateDiagram-v2
    RESET --> E_Inicial
    E_Inicial --> S1: entrada=0
    E_Inicial --> E_Inicial: entrada=1
    S1 --> S2: entrada=0
    S1 --> E_Inicial: entrada=1
    S2 --> S2: entrada=0
    S2 --> DETECTADO: entrada=1
    DETECTADO --> S1: entrada=0
    DETECTADO --> E_Inicial: entrada=1
    
    note right of E_Inicial
        Salida: 0
        Esperando primer 0
    end note
    
    note right of S1
        Salida: 0
        Detectado "0"
    end note
    
    note right of S2
        Salida: 0
        Detectado "00"
    end note
    
    note right of DETECTADO
        Salida: 1
        Detectado "001" ✓
    end note
```

**Estados en FSM Moore:**
- **E_Inicial**: Estado inicial. Salida = `0`
  - `0`: va a S1
  - `1`: permanece en E_Inicial
- **S1**: Se detectó primer `0`. Salida = `0`
  - `0`: va a S2
  - `1`: vuelve a E_Inicial
- **S2**: Se detectó `00`. Salida = `0`
  - `0`: permanece en S2
  - `1`: va a DETECTADO
- **DETECTADO**: Secuencia `001` completa. **Salida = `1`**
  - `0`: va a S1 (nueva secuencia posible)
  - `1`: vuelve a E_Inicial

#### 7.3.2 Modelo de Mealy

*   **Definición:** Las salidas dependen del **estado actual Y de las entradas actuales**.
*   **Características:**
    *   La salida puede cambiar en cuanto cambia la entrada (asíncrona respecto al reloj dentro del ciclo).
    *   Suele requerir menos estados.
    *   Puede propagar ruido de las entradas a las salidas.

**Diagrama de bloques:**

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#e3f2fd','primaryTextColor':'#1565c0','primaryBorderColor':'#64b5f6','lineColor':'#42a5f5','secondaryColor':'#fff3e0','tertiaryColor':'#f1f8e9'}}}%%
graph LR
    A[Entrada] --> B[Lógica de<br/>Estado Siguiente]
    A --> D[Lógica de<br/>Salida]
    B --> C[Registro de<br/>Estado]
    C --> B
    C --> D
    D --> E[Salida]
    F[CLK] --> C
    
    style C fill:#bbdefb,stroke:#1976d2,stroke-width:2px,color:#0d47a1
    style D fill:#ffccbc,stroke:#d84315,stroke-width:2px,color:#bf360c
    style B fill:#c8e6c9,stroke:#388e3c,stroke-width:2px,color:#1b5e20
```

**Ejemplo 1: Detector de Secuencia "01" (Mealy)**

En Mealy, solo necesitamos **2 estados** porque la salida depende del estado Y la entrada:

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#e0f2f1','primaryTextColor':'#00695c','primaryBorderColor':'#4db6ac','lineColor':'#26a69a','noteBkgColor':'#fff8e1','noteTextColor':'#333'}}}%%
stateDiagram-v2
    RESET --> E_Inicial
    
    E_Inicial --> E_Inicial: 1/0
    E_Inicial --> CERO: 0/0
    CERO --> CERO: 0/0
    CERO --> E_Inicial: 1/1
    
    note right of E_Inicial
        Estado inicial
        Esperando 0
        Transiciones: entrada/salida
    end note
    
    note right of CERO
        Ya recibió 0
        Si recibe 1 → salida=1 ✓
        Si recibe 0 → sigue esperando
    end note
```

**Estados Mealy (formato `entrada/salida`):**
- **E_Inicial**: Estado inicial
  - `1/0`: permanece en E_Inicial, salida = `0`
  - `0/0`: va a CERO, salida = `0`
- **CERO**: Se recibió un `0`
  - `0/0`: permanece en CERO, salida = `0`
  - **`1/1`**: va a E_Inicial, **salida = `1`** (secuencia detectada en este ciclo)

**Implementación VHDL (Estándar de 2 procesos):**

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY fsm_mealy_01 IS
    PORT (
        clk     : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        entrada : IN  STD_LOGIC;
        salida  : OUT STD_LOGIC
    );
END ENTITY fsm_mealy_01;

ARCHITECTURE rtl OF fsm_mealy_01 IS
    -- Declaración de tipo enumerado para los estados
    TYPE estado_t IS (E_Inicial, CERO);
    SIGNAL estado_actual, estado_siguiente : estado_t;
BEGIN
    -- 1. Proceso síncrono: Registro de estado
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            estado_actual <= E_Inicial;
        ELSIF RISING_EDGE(clk) THEN
            estado_actual <= estado_siguiente;
        END IF;
    END PROCESS;

    -- 2. Proceso combinacional: Lógica de estado siguiente y salida Mealy (depende de entrada)
    PROCESS(estado_actual, entrada)
    BEGIN
        -- Valores por defecto
        estado_siguiente <= estado_actual;
        salida <= '0';

        CASE estado_actual IS
            WHEN E_Inicial =>
                IF entrada = '0' THEN
                    estado_siguiente <= CERO;
                    salida <= '0';
                ELSE
                    estado_siguiente <= E_Inicial;
                    salida <= '0';
                END IF;

            WHEN CERO =>
                IF entrada = '1' THEN
                    estado_siguiente <= E_Inicial;
                    salida <= '1'; -- Secuencia 01 detectada en el ciclo actual
                ELSE
                    estado_siguiente <= CERO;
                    salida <= '0';
                END IF;
        END CASE;
    END PROCESS;
END ARCHITECTURE rtl;
```

**Comparación para este ejemplo:**
- Moore: 3 estados, salida estable durante todo el ciclo
- Mealy: 2 estados, salida se activa inmediatamente con la entrada

**Ejemplo 2: Detector de Secuencia "101" (Mealy)**

La misma funcionalidad, pero con menos estados. La salida se activa **en el mismo ciclo** que llega el último bit.

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#fce4ec','primaryTextColor':'#c2185b','primaryBorderColor':'#f06292','lineColor':'#ec407a','secondaryColor':'#fff9c4','tertiaryColor':'#e1f5fe','noteBkgColor':'#fffde7','noteTextColor':'#333'}}}%%
stateDiagram-v2
    RESET --> E_Inicial
    E_Inicial --> E_Inicial: 0/0
    E_Inicial --> S1: 1/0
    S1 --> S2: 0/0
    S1 --> S1: 1/0
    S2 --> E_Inicial: 0/0
    S2 --> S1: 1/1
    
    note right of E_Inicial
        Estado IDLE
        Transiciones: entrada/salida
    end note
    
    note right of S1
        Detectado "1"
        Si llega 0 → S2
    end note
    
    note right of S2
        Detectado "10"
        Si llega 1 → salida=1 ✓
    end note
```

**Estados en FSM Mealy (formato `entrada/salida`):**
- **E_Inicial**: Estado inicial
  - `0/0`: permanece en E_Inicial
  - `1/0`: va a S1
- **S1**: Detectado `1`
  - `0/0`: va a S2
  - `1/0`: permanece en S1
- **S2**: Detectado `10`
  - `0/0`: vuelve a E_Inicial
  - **`1/1`**: vuelve a S1 y **activa salida** (secuencia detectada)

**Ejemplo 3: Detector de Secuencia "001" (Mealy)**

Detecta la secuencia 001. Con Mealy solo necesitamos **3 estados** (vs 4 en Moore).

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#f3e5f5','primaryTextColor':'#6a1b9a','primaryBorderColor':'#ba68c8','lineColor':'#ab47bc','noteBkgColor':'#fff9c4','noteTextColor':'#333'}}}%%
stateDiagram-v2
    RESET --> E_Inicial
    E_Inicial --> E_Inicial: 1/0
    E_Inicial --> S1: 0/0
    S1 --> S2: 0/0
    S1 --> E_Inicial: 1/0
    S2 --> S2: 0/0
    S2 --> E_Inicial: 1/1
    
    note right of E_Inicial
        Estado inicial
        Esperando primer 0
        Formato: entrada/salida
    end note
    
    note right of S1
        Detectado "0"
        Esperando segundo 0
    end note
    
    note right of S2
        Detectado "00"
        Si llega 1 → salida=1 ✓
    end note
```

**Estados en FSM Mealy (formato `entrada/salida`):**
- **E_Inicial**: Estado inicial
  - `0/0`: va a S1, salida = `0`
  - `1/0`: permanece en E_Inicial, salida = `0`
- **S1**: Se detectó primer `0`
  - `0/0`: va a S2, salida = `0`
  - `1/0`: vuelve a E_Inicial, salida = `0`
- **S2**: Se detectó `00`
  - `0/0`: permanece en S2, salida = `0`
  - **`1/1`**: vuelve a E_Inicial, **salida = `1`** (secuencia detectada)

**Comparación para este ejemplo:**
- Moore: 4 estados, salida registrada
- Mealy: 3 estados, salida inmediata

#### 7.3.3 Resumen: Comparación Moore vs. Mealy

| Aspecto | Moore | Mealy |
|---------|-------|-------|
| **Salida depende de** | Solo estado actual | Estado actual + Entradas |
| **Número de estados** | Generalmente más | Generalmente menos |
| **Sincronización de salida** | Con el reloj (registrada) | Puede ser asíncrona |
| **Inmunidad al ruido** | Mayor (salida estable) | Menor (entrada afecta salida) |
| **Velocidad de respuesta** | Un ciclo de retardo | Más rápida (mismo ciclo) |
| **Uso típico** | Control, decodificación | Protocolos, detección de patrones |
---

*[⬆ Volver al Índice](README.md)*


---
