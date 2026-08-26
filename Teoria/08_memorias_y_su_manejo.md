<!--
---
file: Teoria/08_memorias_y_su_manejo.md
description: Memorias RAM (single/dual port), ROM, FIFO, registros de desplazamiento y BRAM
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [memorias, ram, rom, fifo, shift-registers, bram, vhdl]
---
-->

# Memorias y su manejo en VHDL

En VHDL, hablar de “memorias” puede significar varias cosas:

- **Registros (flip-flops):** guardan pocos bits, acceso inmediato, excelente para control.
- **Bancos de registros:** muchos registros agrupados, normalmente seleccionados por un índice.
- **RAM/ROM:** memoria direccionada por una **dirección** (address), con **profundidad** (número de palabras) y **ancho** (bits por palabra).

En FPGA, el sintetizador puede implementar estas memorias con:

- **FF/LUT (memoria distribuida):** buena para memorias pequeñas o con acceso muy particular.
- **BRAM (memoria de bloque):** eficiente para memorias medianas/grandes (p. ej. M9K/M10K según familia), normalmente con lectura/escritura síncronas.

> **Idea clave:** en síntesis no “llamas” a una BRAM con una palabra reservada. El sintetizador **la infiere** (o no) dependiendo del patrón de lectura/escritura, tamaño y opciones de herramienta.

### 8.1 Conceptos base

Una memoria direccionable se describe con parámetros:

- **Ancho de palabra ($W$):** bits por dato.
- **Profundidad ($D$):** cantidad de palabras.
- **Dirección ($A$):** selecciona una palabra.
- **Latencia:** cuántos ciclos tardan los datos en aparecer (típicamente 0 si es lectura combinacional; 1 si es lectura registrada/síncrona).

Si $D$ es potencia de 2, el número de bits de dirección requerido es:

$$N_{addr} = \log_2(D)$$

En VHDL conviene **acotar rangos** para que el sintetizador optimice y para evitar índices fuera de rango:

```vhdl
CONSTANT DATA_W : INTEGER := 8;
CONSTANT DEPTH  : INTEGER := 256;

-- Opción A: dirección como INTEGER acotado
SIGNAL addr_i : INTEGER RANGE 0 TO DEPTH-1 := 0;

-- Opción B: dirección como UNSIGNED (recomendado si viene de un bus)
CONSTANT ADDR_W : INTEGER := 8;  -- 2^8 = 256
SIGNAL addr_u : UNSIGNED(ADDR_W-1 DOWNTO 0) := (OTHERS => '0');
```

> **Uso recomendado:**
> - Direcciones de módulos/buses: `UNSIGNED` + `to_integer(addr_u)`.
> - Contadores internos pequeños: `INTEGER RANGE ...`.

### 8.2 Memorias en FPGA: distribuida vs. BRAM

En una FPGA, la decisión final suele ser automática, pero es útil entender los compromisos:

| Recurso inferido | Se parece a… | Ventajas | Desventajas | Uso típico |
|---|---|---|---|---|
| **Registros (FF)** | Muchos flip-flops | Muy rápido, controlable, fácil de resetear | Consume FFs, no escala bien | Estados, pipelines, pequeños buffers |
| **Distribuida (LUT/FF)** | ROM/RAM pequeña en lógica | Flexible (a veces lectura combinacional) | Puede complicar timing si crece | Tablas pequeñas, memorias con acceso especial |
| **BRAM** | RAM dedicada (bloques) | Gran capacidad y eficiencia | Lectura normalmente síncrona (latencia) | Framebuffers, FIFOs, tablas grandes |

> **Nota (Quartus II 13):** el soporte exacto de inferencia depende de la familia FPGA y de las opciones de síntesis. Para maximizar la probabilidad de inferir BRAM, usa **lectura síncrona** (dato registrado en flanco de reloj) y tamaños razonables.

### 8.3 Modelado con arreglos (arrays) y direccionamiento

La base de una RAM/ROM “casera” es un **array de palabras**. VHDL permite declarar un tipo y luego usarlo como señal.

Ejemplo mínimo de memoria con lectura combinacional (útil para entender el acceso por índice):

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY mem_async IS
    GENERIC (
        DATA_W : INTEGER := 8;
        ADDR_W : INTEGER := 8
    );
    PORT (
        addr  : IN  UNSIGNED(ADDR_W-1 DOWNTO 0);
        dout  : OUT STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF mem_async IS
    CONSTANT DEPTH : INTEGER := 2**ADDR_W;
    TYPE mem_t IS ARRAY (0 TO DEPTH-1) OF STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);
    SIGNAL mem : mem_t := (OTHERS => (OTHERS => '0'));
    SIGNAL idx : INTEGER RANGE 0 TO DEPTH-1;
BEGIN
    idx <= TO_INTEGER(addr);
    dout <= mem(idx);
END ARCHITECTURE;
```

Observa dos detalles importantes:

1. `DEPTH := 2**ADDR_W` asume que la profundidad es potencia de 2.
2. `TO_INTEGER(addr)` requiere `ieee.numeric_std`.

> **Errores típicos:**
> - Usar `STD_LOGIC_VECTOR` como dirección y aplicar `to_integer` sin convertir a `UNSIGNED`.
> - No acotar el rango del índice (`INTEGER` sin `RANGE`) y luego acceder a `mem(i)`.
> - Mezclar librerías no estándar (`std_logic_unsigned`) con `numeric_std`.

### 8.4 ROM sintetizable

Una ROM es una memoria **solo lectura** cuyo contenido es constante. Se puede describir de varias formas.

#### ROM por constante (aggregate)

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY rom_ejemplo IS
    PORT (
        addr : IN  UNSIGNED(3 DOWNTO 0);
        dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF rom_ejemplo IS
    TYPE rom_t IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
    CONSTANT rom_c : rom_t := (
        0  => X"00",
        1  => X"11",
        2  => X"22",
        3  => X"33",
        4  => X"44",
        5  => X"55",
        6  => X"66",
        7  => X"77",
        8  => X"88",
        9  => X"99",
        10 => X"AA",
        11 => X"BB",
        12 => X"CC",
        13 => X"DD",
        14 => X"EE",
        OTHERS => X"FF"
    );
BEGIN
    dout <= rom_c(TO_INTEGER(addr));
END ARCHITECTURE;
```

#### ROM por `CASE` (útil cuando hay pocos valores)

```vhdl
PROCESS(addr)
BEGIN
    CASE addr IS
        WHEN "0000" => dout <= X"00";
        WHEN "0001" => dout <= X"11";
        WHEN "0010" => dout <= X"22";
        WHEN OTHERS => dout <= X"FF";
    END CASE;
END PROCESS;
```

> **Uso recomendado:**
> - ROM pequeña: `CASE` o constante.
> - ROM grande: preferir lectura síncrona y estructuras que favorezcan BRAM (si aplica), o usar el flujo específico de la herramienta.

### 8.5 RAM single-port (1 puerto)

Una RAM single-port típica tiene:

- **1 dirección** (la misma para leer y escribir).
- **Escritura síncrona** (en flanco de reloj).
- Lectura **combinacional** o **síncrona** (según se codifique).

#### RAM con lectura síncrona (patrón común para inferir BRAM)

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ram_1p IS
    GENERIC (
        DATA_W : INTEGER := 8;
        ADDR_W : INTEGER := 8
    );
    PORT (
        clk  : IN  STD_LOGIC;
        we   : IN  STD_LOGIC;
        addr : IN  UNSIGNED(ADDR_W-1 DOWNTO 0);
        din  : IN  STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);
        dout : OUT STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF ram_1p IS
    CONSTANT DEPTH : INTEGER := 2**ADDR_W;
    TYPE ram_t IS ARRAY (0 TO DEPTH-1) OF STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);
    SIGNAL ram    : ram_t := (OTHERS => (OTHERS => '0'));
    SIGNAL dout_r : STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL idx    : INTEGER RANGE 0 TO DEPTH-1;
BEGIN
    idx <= TO_INTEGER(addr);

    PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF we = '1' THEN
                ram(idx) <= din;
            END IF;
            dout_r <= ram(idx);   -- lectura registrada (latencia = 1 ciclo)
        END IF;
    END PROCESS;

    dout <= dout_r;
END ARCHITECTURE;
```

> **Lectura durante escritura (read-during-write):** si `we='1'` y se lee la misma dirección en el mismo ciclo, el valor observado puede ser “viejo”, “nuevo” o “sin cambio” según la inferencia/herramienta. Si tu diseño necesita un comportamiento específico, hazlo explícito (por ejemplo, dando prioridad a `din`).

#### RAM con lectura combinacional (puede dificultar BRAM y empeorar timing)

```vhdl
-- dout cambia en cuanto cambia addr (sin esperar clk)
dout <= ram(idx);
```

> **Uso recomendado:** preferir lectura síncrona en memorias medianas/grandes para reducir caminos combinacionales y favorecer BRAM.

### 8.6 RAM dual-port (2 puertos)

Una RAM dual-port permite dos accesos “en paralelo”. Hay dos casos comunes:

- **Simple dual-port (1 escritura + 1 lectura):** un puerto escribe, el otro lee.
- **True dual-port (2 lecturas/escrituras):** ambos puertos pueden escribir.

#### Simple dual-port (1W/1R) con lecturas síncronas

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY ram_1w1r IS
    GENERIC (
        DATA_W : INTEGER := 8;
        ADDR_W : INTEGER := 8
    );
    PORT (
        clk    : IN  STD_LOGIC;
        we_a   : IN  STD_LOGIC;
        addr_a : IN  UNSIGNED(ADDR_W-1 DOWNTO 0);
        din_a  : IN  STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);

        addr_b : IN  UNSIGNED(ADDR_W-1 DOWNTO 0);
        dout_b : OUT STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF ram_1w1r IS
    CONSTANT DEPTH : INTEGER := 2**ADDR_W;
    TYPE ram_t IS ARRAY (0 TO DEPTH-1) OF STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);
    SIGNAL ram      : ram_t := (OTHERS => (OTHERS => '0'));
    SIGNAL dout_b_r : STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0) := (OTHERS => '0');
BEGIN
    PROCESS(clk)
        VARIABLE ia, ib : INTEGER RANGE 0 TO DEPTH-1;
    BEGIN
        IF RISING_EDGE(clk) THEN
            ia := TO_INTEGER(addr_a);
            ib := TO_INTEGER(addr_b);

            IF we_a = '1' THEN
                ram(ia) <= din_a;
            END IF;
            dout_b_r <= ram(ib);
        END IF;
    END PROCESS;

    dout_b <= dout_b_r;
END ARCHITECTURE;
```

> **Errores típicos:** asumir que dos accesos simultáneos a la misma dirección son “deterministas” sin definir la prioridad. Si necesitas una regla, impleméntala en la lógica de control (por ejemplo, evitar colisiones o definir arbitraje).

### 8.7 Shift registers (registros de desplazamiento)

Un **shift register** es una memoria “lineal” que desplaza su contenido cada ciclo. Es común en:

- Serialización/deserialización.
- Delay lines (retardos programados).
- Filtros y pipelines simples.

#### Shift register de 8 bits (SISO) con concatenación

```vhdl
PROCESS(clk, reset)
BEGIN
    IF reset = '1' THEN
        sreg <= (OTHERS => '0');
    ELSIF RISING_EDGE(clk) THEN
        sreg <= bit_in & sreg(sreg'HIGH DOWNTO 1);
    END IF;
END PROCESS;

bit_out <= sreg(0);
```

#### Shift register de palabras (profundidad N, palabra W)

```vhdl
CONSTANT N : INTEGER := 4;  -- etapas
CONSTANT W : INTEGER := 8;  -- ancho de palabra
TYPE pipe_t IS ARRAY (0 TO N-1) OF STD_LOGIC_VECTOR(W-1 DOWNTO 0);
SIGNAL pipe : pipe_t := (OTHERS => (OTHERS => '0'));

PROCESS(clk, reset)
BEGIN
    IF reset = '1' THEN
        pipe <= (OTHERS => (OTHERS => '0'));
    ELSIF RISING_EDGE(clk) THEN
        pipe(0) <= dato_in;
        FOR i IN 1 TO N-1 LOOP
            pipe(i) <= pipe(i-1);
        END LOOP;
    END IF;
END PROCESS;

dato_out <= pipe(N-1);
```

> **Uso recomendado:** para N pequeño, FFs suelen ser perfectos. Si N es grande y W es ancho, puede convenir una RAM + puntero (buffer circular) en lugar de desplazar todo.

### 8.8 FIFO circular (buffer)

Una **FIFO** (First-In First-Out) es una memoria con dos punteros:

- `wr_ptr`: dónde se escribe el siguiente dato.
- `rd_ptr`: de dónde se lee el siguiente dato.

Se suele acompañar con banderas:

- `empty`: no hay datos para leer.
- `full`: no hay espacio para escribir.

Un enfoque clásico (si $D = 2^{ADDR_W}$) es usar punteros de **ADDR_W+1 bits** (un bit extra para distinguir vuelta completa).

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY fifo_simple IS
    GENERIC (
        DATA_W : INTEGER := 8;
        ADDR_W : INTEGER := 4  -- DEPTH = 16
    );
    PORT (
        clk   : IN  STD_LOGIC;
        reset : IN  STD_LOGIC;

        wr_en : IN  STD_LOGIC;
        din   : IN  STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);
        full  : OUT STD_LOGIC;

        rd_en : IN  STD_LOGIC;
        dout  : OUT STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);
        empty : OUT STD_LOGIC
    );
END ENTITY;

ARCHITECTURE rtl OF fifo_simple IS
    CONSTANT DEPTH : INTEGER := 2**ADDR_W;
    TYPE ram_t IS ARRAY (0 TO DEPTH-1) OF STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);
    SIGNAL ram : ram_t := (OTHERS => (OTHERS => '0'));

    SIGNAL wr_ptr  : UNSIGNED(ADDR_W DOWNTO 0) := (OTHERS => '0');
    SIGNAL rd_ptr  : UNSIGNED(ADDR_W DOWNTO 0) := (OTHERS => '0');
    SIGNAL full_i  : STD_LOGIC := '0';
    SIGNAL empty_i : STD_LOGIC := '1';

    SIGNAL dout_r : STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0) := (OTHERS => '0');
BEGIN
    empty_i <= '1' WHEN wr_ptr = rd_ptr ELSE '0';
    full_i  <= '1' WHEN (wr_ptr(ADDR_W) /= rd_ptr(ADDR_W)) AND
                      (wr_ptr(ADDR_W-1 DOWNTO 0) = rd_ptr(ADDR_W-1 DOWNTO 0))
             ELSE '0';

    empty <= empty_i;
    full  <= full_i;

    PROCESS(clk, reset)
        VARIABLE widx, ridx : INTEGER RANGE 0 TO DEPTH-1;
    BEGIN
        IF reset = '1' THEN
            wr_ptr <= (OTHERS => '0');
            rd_ptr <= (OTHERS => '0');
            dout_r <= (OTHERS => '0');
        ELSIF RISING_EDGE(clk) THEN
            widx := TO_INTEGER(wr_ptr(ADDR_W-1 DOWNTO 0));
            ridx := TO_INTEGER(rd_ptr(ADDR_W-1 DOWNTO 0));

            -- Escritura
            IF (wr_en = '1') AND (full_i = '0') THEN
                ram(widx) <= din;
                wr_ptr <= wr_ptr + 1;
            END IF;

            -- Lectura (síncrona)
            IF (rd_en = '1') AND (empty_i = '0') THEN
                dout_r <= ram(ridx);
                rd_ptr <= rd_ptr + 1;
            END IF;
        END IF;
    END PROCESS;

    dout <= dout_r;
END ARCHITECTURE;
```

> **Errores típicos:**
> - Permitir `wr_en` con `full='1'` o `rd_en` con `empty='1'` sin bloquear → overflow/underflow.
> - No usar el bit extra en los punteros → `full` y `empty` se confunden.
> - Pretender lectura “sin latencia” en FIFO inferida en BRAM → normalmente la lectura es síncrona.

### 8.9 Inicialización y carga desde archivo (síntesis vs simulación)

#### Inicialización en síntesis (hardware real)

En simulación, es común dar valores iniciales con `:=` al declarar señales. En FPGA, **puede** existir inicialización al encender, pero no debes depender de ella para el comportamiento funcional a menos que la guía del dispositivo/herramienta lo garantice.

> **Uso recomendado:** para comportamiento determinista, usa un **reset explícito** para registros y una rutina controlada para limpiar memorias si es estrictamente necesario.

Para memorias grandes, “poner todo a cero en un reset con un `FOR` en un solo ciclo” no siempre representa hardware realista (y puede que la herramienta no lo implemente como esperas). Alternativas típicas:

- Aceptar contenido “indefinido” tras reset y sobre-escribir conforme se use.
- Implementar un **estado de inicialización** que recorra direcciones y escriba ceros durante $D$ ciclos.
- Usar ROM constante (sí es determinista, porque es cableada/literalizada o inicializada por herramienta).

#### Carga desde archivo en simulación (TextIO)

La lectura de archivos con `textio` es **solo simulación** (testbench), no síntesis. Un patrón habitual es cargar una ROM/RAM desde un archivo de texto con palabras en hexadecimal.

Ejemplo típico (testbench) usando `std_logic_textio` para leer hex (una palabra por línea):

```vhdl
-- SOLO SIMULACIÓN (testbench)
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_textio.all;

LIBRARY std;
USE std.textio.all;

-- Asumiendo que ya declaraste:
-- TYPE ram_t IS ARRAY (0 TO DEPTH-1) OF STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);
-- SIGNAL mem : ram_t;

PROCESS
    FILE f : TEXT OPEN READ_MODE IS "mem.hex";
    VARIABLE l : LINE;
    VARIABLE i : INTEGER := 0;
    VARIABLE v : STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);
BEGIN
    WHILE (NOT ENDFILE(f)) AND (i <= mem'HIGH) LOOP
        READLINE(f, l);
        HREAD(l, v);        -- lee un vector en hexadecimal
        mem(i) <= v;
        i := i + 1;
    END LOOP;
    WAIT;
END PROCESS;
```

> **Nota:** si tu archivo está en binario (bits), también puedes usar `READ(l, v)` con `std_logic_textio`.

### 8.10 Errores típicos y depuración

- **Índices fuera de rango:** `mem(TO_INTEGER(addr))` cuando `addr` no está acotada a `0..DEPTH-1`.
- **INTEGER sin rango:** puede hacer que el sintetizador asuma más bits de los necesarios.
- **Lectura asíncrona grande:** `dout <= mem(idx)` en memorias grandes crea un camino combinacional largo (timing difícil).
- **Inicialización engañosa:** valores iniciales que “funcionan” en simulación pero no se respetan igual en hardware.
- **Colisiones dual-port:** dos escrituras a la misma dirección en el mismo ciclo sin arbitraje.
- **Latches accidentales:** procesos combinacionales donde `dout` (u otras señales) no se asignan en todas las ramas.

Técnicas recomendadas de depuración en simulación:

- `ASSERT` para underflow/overflow en FIFOs.
- `ASSERT` para detectar escrituras simultáneas conflictivas.
- Señales internas de observabilidad: punteros, flags y dirección efectiva.

### 8.11 Checklist rápida

- Define **W** (ancho) y **D** (profundidad) y acota rangos.
- Decide el tipo: **registro / shift register / RAM / FIFO**.
- Decide el número de puertos: **1P**, **1W1R**, **2P**.
- Si buscas BRAM: usa **lectura síncrona** y evita lógica combinacional alrededor del array.
- Define el comportamiento ante colisiones (read-during-write y dual-port).
- Separa con claridad qué es **síntesis** y qué es **solo simulación** (TextIO).

---

*[⬆ Volver al Índice](#índice)*

---
