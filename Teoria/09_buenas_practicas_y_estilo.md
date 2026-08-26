<!--
---
file: Teoria/09_buenas_practicas_y_estilo.md
description: Buenas prácticas de diseño hardware, estilo sintetizable, interfaces y sincronización
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [buenas-practicas, estilo-sintetizable, cdc, handshake, dry, vhdl]
---
-->

# Buenas prácticas de diseño y estilo en VHDL

Este capítulo reúne criterios de “programación” (legibilidad, modularidad, pruebas) pero aterrizados a lo que **realmente ocurre en hardware**: concurrencia, latencia, recursos y timing.

### 9.1 Mentalidad hardware vs. software

En software, una función se ejecuta “de arriba hacia abajo”. En VHDL:

- **Las sentencias concurrentes ocurren en paralelo.**
- Un `PROCESS` describe un bloque secuencial, pero el proceso como tal sigue siendo parte de un sistema concurrente.
- **El tiempo importa:** lo que en C es “una asignación”, en hardware puede ser un registro (1 ciclo) o una red combinacional (sin ciclo pero con retardo).

Tres métricas prácticas al diseñar:

- **Latencia:** cuántos ciclos tardan los datos en aparecer.
- **Throughput:** cuántos datos por ciclo puede aceptar/producir el bloque.
- **Recursos:** FFs, LUTs y BRAM (ver capítulo 8).

> **Uso recomendado:** antes de escribir VHDL, define claramente qué señales deben ser **registradas** (estado) y qué señales son **combinacionales** (cálculo instantáneo dentro del ciclo).

### 9.2 Estilo sintetizable: combinacional vs secuencial

Un patrón que evita muchos bugs: separar explícitamente lo combinacional y lo secuencial.

**Combinacional (sin memoria):**

- Asignar **valores por defecto** al inicio del proceso.
- Cubrir todas las ramas (`IF/CASE`) para evitar inferencia de latch.

```vhdl
PROCESS(a, b, sel)
BEGIN
    y <= (OTHERS => '0');
    CASE sel IS
        WHEN "00" => y <= a;
        WHEN "01" => y <= b;
        WHEN OTHERS => y <= (OTHERS => '0');
    END CASE;
END PROCESS;
```

**Secuencial (registro / estado):**

```vhdl
PROCESS(clk, rst)
BEGIN
    IF rst = '1' THEN
        q <= (OTHERS => '0');
    ELSIF RISING_EDGE(clk) THEN
        q <= d;
    END IF;
END PROCESS;
```

> **Errores típicos:**
> - Mezclar lógica combinacional grande dentro del `RISING_EDGE` sin necesidad (empeora timing).
> - Olvidar asignación por defecto en combinacional (aparecen latches).

### 9.3 Tipos, rangos y conversiones seguras

Reglas prácticas que simplifican el diseño:

- Para direcciones, contadores y tamaños, **acota rangos** (`INTEGER RANGE ...`) o usa `UNSIGNED` con ancho explícito.
- Evita `STD_LOGIC_VECTOR` para aritmética: usa `UNSIGNED`/`SIGNED`.
- Al indexar memorias, asegura que el índice esté en rango.

Ejemplo seguro de índice (con `UNSIGNED`):

```vhdl
-- addr tiene N bits y DEPTH=2^N
idx <= TO_INTEGER(addr);
-- Si DEPTH no es potencia de 2 o addr puede exceder, usa ASSERT en simulación
```

> **Uso recomendado:** si `DEPTH` no es potencia de 2, usa `INTEGER RANGE 0 TO DEPTH-1` para el índice o valida con `ASSERT` en testbench.

### 9.4 Modularidad y reutilización (DRY)

DRY (*Don’t Repeat Yourself*) en hardware no significa “llamar una función y listo”: significa **evitar duplicar lógica** y mejorar mantenibilidad.

Herramientas típicas en VHDL:

- `GENERIC` para parametrizar anchos/profundidad.
- `PACKAGE` para constantes, tipos y funciones comunes.
- `RECORD` para agrupar interfaces y configuración.

Ejemplo: constantes y tipos en un paquete (reutilizable):

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;

PACKAGE cfg_pkg IS
    CONSTANT DATA_W : POSITIVE := 8;
    CONSTANT DEPTH  : POSITIVE := 16;
    SUBTYPE dato_t IS STD_LOGIC_VECTOR(DATA_W-1 DOWNTO 0);
    TYPE ram_t IS ARRAY (0 TO DEPTH-1) OF dato_t;
END PACKAGE cfg_pkg;
```

> **Nota (compatibilidad):** este estilo es VHDL-93 y funciona bien en flujos conservadores.

### 9.5 Interfaces y handshakes (valid/ready, req/ack)

Cuando conectas bloques “pipelineados” o productores/consumidores, necesitas un protocolo para evitar pérdida de datos.

Dos familias comunes:

- **req/ack (petición/ack):** clásico; útil en control.
- **valid/ready:** típico en streaming; permite throughput de 1 dato/ciclo.

#### Ejemplo: registro de etapa con `valid/ready` (1 palabra)

Este bloque actúa como una “etapa de pipeline” que almacena un dato cuando hay transferencia.

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY reg_slice IS
    GENERIC (W : POSITIVE := 8);
    PORT (
        clk : IN  STD_LOGIC;
        rst : IN  STD_LOGIC;

        in_valid : IN  STD_LOGIC;
        in_ready : OUT STD_LOGIC;
        in_data  : IN  STD_LOGIC_VECTOR(W-1 DOWNTO 0);

        out_valid : OUT STD_LOGIC;
        out_ready : IN  STD_LOGIC;
        out_data  : OUT STD_LOGIC_VECTOR(W-1 DOWNTO 0)
    );
END ENTITY;

ARCHITECTURE rtl OF reg_slice IS
    SIGNAL v_reg : STD_LOGIC := '0';
    SIGNAL d_reg : STD_LOGIC_VECTOR(W-1 DOWNTO 0) := (OTHERS => '0');
BEGIN
    -- Se puede aceptar dato si el registro está vacío o el downstream acepta este ciclo
    in_ready <= (NOT v_reg) OR out_ready;

    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            v_reg <= '0';
            d_reg <= (OTHERS => '0');
        ELSIF RISING_EDGE(clk) THEN
            IF in_ready = '1' THEN
                v_reg <= in_valid;
                IF in_valid = '1' THEN
                    d_reg <= in_data;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    out_valid <= v_reg;
    out_data  <= d_reg;
END ARCHITECTURE;
```

Idea clave: una transferencia ocurre cuando `valid='1' AND ready='1'`.

> **Errores típicos:**
> - Tratar `valid` como “pulso” sin respetar el backpressure (cuando `ready='0'`).
> - No registrar `valid` junto con el dato (se desalinean).

### 9.6 Cruce de dominios de reloj (CDC) básico

Si una señal se genera en un reloj y se consume en otro, hay riesgo de **metastabilidad**.

Regla mínima (para señales de 1 bit, tipo *flag*): usar un **sincronizador de 2 FF** en el dominio de destino.

```vhdl
PROCESS(clk_dst, rst)
    VARIABLE ff1 : STD_LOGIC := '0';
    VARIABLE ff2 : STD_LOGIC := '0';
BEGIN
    IF rst = '1' THEN
        ff1 := '0';
        ff2 := '0';
    ELSIF RISING_EDGE(clk_dst) THEN
        ff1 := sig_async;
        ff2 := ff1;
    END IF;
    sig_sync <= ff2;
END PROCESS;
```

> **Nota:** para **buses** (varios bits) no basta con dos FF por bit: normalmente se requiere un protocolo (handshake) o una FIFO CDC.

---

*[⬆ Volver al Índice](README.md)*

---
