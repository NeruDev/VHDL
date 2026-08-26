<!--
---
file: Teoria/10_verificacion_testbenches_depuracion.md
description: Metodologías de verificación, generación de reloj/reset, assert, testbenches y depuración
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [testbench, verificacion, assert, clock-gen, textio, depuracion, vhdl]
---
-->

# Verificación práctica: testbenches y depuración

La verificación con testbench es donde se detectan la mayoría de errores lógicos antes de llegar a FPGA.

> **Idea clave:** el testbench es “software que prueba hardware”. Puede usar `WAIT`, `TEXTIO`, bucles y asserts libremente, porque **no se sintetiza**.

### 10.1 Estructura canónica de un testbench

Un testbench típico contiene:

- Generación de reloj.
- Generación de reset.
- Instanciación del DUT (*Device Under Test*).
- Drivers de entradas (estímulos).
- Monitores y chequeos (`ASSERT`).

Plantilla mínima:

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY dut_tb IS
END ENTITY;

ARCHITECTURE tb OF dut_tb IS
    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '1';
BEGIN
    -- reloj
    clk <= NOT clk AFTER 10 ns;

    -- reset
    PROCESS
    BEGIN
        rst <= '1';
        WAIT FOR 100 ns;
        rst <= '0';
        WAIT;
    END PROCESS;

    -- DUT: instancia aquí tu entidad
END ARCHITECTURE;
```

### 10.2 Generación de reloj y reset

Buenas prácticas:

- Mantén el reset activo un tiempo suficiente para estabilizar la simulación.
- Si tu DUT usa reset síncrono, suelta `rst` alineado al flanco.

> **Uso recomendado:** centralizar reloj/reset al inicio del testbench y luego solo “programar” estímulos.

### 10.3 Testbench autocheck: ASSERT + scoreboard simple

Un testbench autocheck no solo estimula: también verifica salidas esperadas.

Patrón simple:

1. Generar estímulo.
2. Esperar latencia conocida.
3. `ASSERT` contra el valor esperado.

Ejemplo genérico:

```vhdl
PROCESS
BEGIN
    WAIT UNTIL rst = '0';

    -- Estímulo 1
    a <= X"12";
    b <= X"34";
    WAIT UNTIL RISING_EDGE(clk);

    -- Si el DUT tiene 1 ciclo de latencia
    WAIT UNTIL RISING_EDGE(clk);
    ASSERT y = X"46"
        REPORT "Fallo: y != 0x46" SEVERITY ERROR;

    WAIT;
END PROCESS;
```

> **Errores típicos:**
> - Olvidar la latencia (comparar en el ciclo equivocado).
> - Usar `WAIT FOR ...` sin relación con el reloj (pruebas frágiles).

### 10.4 Estímulos y archivos (TextIO) — solo simulación

Para carga de memorias desde archivo, ver el ejemplo del capítulo 8 (sección 8.9). En general:

- `TEXTIO` sirve para alimentar ROM/RAM/FIFOs en testbench.
- Se recomienda que el formato del archivo sea simple (una palabra hex por línea).

> **Uso recomendado:** si el DUT es sintetizable, evita mezclar lógica de `TEXTIO` dentro del diseño; mantenlo en el testbench.

### 10.5 Checklist de depuración

- Añade `ASSERT` para casos límite (overflow/underflow, índices fuera de rango).
- Expón señales internas clave en simulación (punteros, estados, flags).
- Verifica primero con casos pequeños (profundidad/anchos reducidos) y luego escala.
- Si aparece `'X'`/`'U'`, encuentra el origen: reset faltante, driver múltiple, o señal sin asignación.

### 10.6 Organización de tests (runner y suites)

Cuando el diseño crece, conviene **organizar el testbench en “casos de prueba”** en lugar de escribir un único proceso largo.

Una estructura común en frameworks de verificación VHDL (por ejemplo, VUnit) es:

- **Runner:** punto de entrada que ejecuta un conjunto de pruebas.
- **Suite:** agrupación lógica de pruebas relacionadas.
- **Checks:** aserciones/chequeos que determinan PASS/FAIL.

> **Uso recomendado:** separar por procedimientos ayuda a reutilizar drivers/monitores y a mantener el testbench legible.

Ejemplo esquemático (testbench):

```vhdl
-- SOLO SIMULACIÓN (testbench)
PROCEDURE test_suma IS
BEGIN
    -- 1) aplicar estímulo
    -- 2) esperar latencia
    -- 3) ASSERT de salida
END PROCEDURE;

PROCEDURE test_resta IS
BEGIN
    -- ... otro caso ...
END PROCEDURE;

PROCESS
BEGIN
    -- setup: reset, etc.
    test_suma;
    test_resta;
    WAIT;
END PROCESS;
```

### 10.7 Scoreboard (cola de esperados)

Cuando el DUT produce salidas **con latencia variable**, o cuando hay múltiples transacciones “en vuelo”, un `ASSERT` puntual por ciclo se vuelve frágil. En esos casos se usa un **scoreboard**:

- El generador de estímulos **empuja** resultados esperados (cola FIFO).
- Un monitor de salidas **extrae** y compara resultados reales.

Esta idea aparece de forma central en metodologías de verificación como OSVVM: la verificación se vuelve más robusta si separas *generación de esperados* de *comparación*.

Ejemplo mínimo (testbench) para un DUT con `y_valid`/`y_data`:

```vhdl
-- SOLO SIMULACIÓN (testbench)
TYPE exp_q_t IS ARRAY (0 TO 255) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL exp_q  : exp_q_t := (OTHERS => (OTHERS => '0'));
SIGNAL exp_wr : INTEGER RANGE 0 TO 255 := 0;
SIGNAL exp_rd : INTEGER RANGE 0 TO 255 := 0;

-- Driver: empuja esperados
-- exp_q(exp_wr) <= X"46"; exp_wr <= exp_wr + 1;

-- Monitor: compara reales contra esperados
PROCESS(clk)
BEGIN
    IF RISING_EDGE(clk) THEN
        IF y_valid = '1' THEN
            ASSERT exp_rd < exp_wr
                REPORT "Scoreboard underflow: llegó salida sin esperado" SEVERITY ERROR;
            ASSERT y_data = exp_q(exp_rd)
                REPORT "Mismatch scoreboard" SEVERITY ERROR;
            exp_rd <= exp_rd + 1;
        END IF;
    END IF;
END PROCESS;
```

> **Extensión útil:** algunos scoreboards agregan **etiquetas** (tags) para comparar transacciones fuera de orden. Para un curso, el modelo FIFO “en orden” suele ser suficiente.

### 10.8 Cobertura funcional y logging

**Cobertura funcional** no mide “líneas ejecutadas”: mide si tu testbench ejercitó los **casos funcionales** que importan (rangos de valores, modos, estados y combinaciones). En metodologías como OSVVM esto se formaliza con *bins* y *cross coverage*, pero el concepto puede aplicarse sin usar librerías externas.

**Logging/alertas**: además de `ASSERT`, es útil clasificar mensajes (INFO/WARNING/ERROR) y controlar la verbosidad. Frameworks como OSVVM proporcionan filtrado y reportes, pero en VHDL “puro” puedes apoyarte en `REPORT` y en `ASSERT ... SEVERITY ...`.

Ejemplo (cobertura manual) para un selector de 2 bits:

```vhdl
-- SOLO SIMULACIÓN (testbench)
SIGNAL cov_sel0 : INTEGER := 0;
SIGNAL cov_sel1 : INTEGER := 0;
SIGNAL cov_sel2 : INTEGER := 0;
SIGNAL cov_sel3 : INTEGER := 0;

PROCESS(clk)
BEGIN
    IF RISING_EDGE(clk) THEN
        IF sel = "00" THEN cov_sel0 <= cov_sel0 + 1; END IF;
        IF sel = "01" THEN cov_sel1 <= cov_sel1 + 1; END IF;
        IF sel = "10" THEN cov_sel2 <= cov_sel2 + 1; END IF;
        IF sel = "11" THEN cov_sel3 <= cov_sel3 + 1; END IF;
    END IF;
END PROCESS;

PROCESS
BEGIN
    -- ... correr pruebas ...
    WAIT FOR 1 us;

    ASSERT cov_sel0 > 0 REPORT "Falta cubrir sel=00" SEVERITY WARNING;
    ASSERT cov_sel1 > 0 REPORT "Falta cubrir sel=01" SEVERITY WARNING;
    ASSERT cov_sel2 > 0 REPORT "Falta cubrir sel=10" SEVERITY WARNING;
    ASSERT cov_sel3 > 0 REPORT "Falta cubrir sel=11" SEVERITY WARNING;
    WAIT;
END PROCESS;
```

Recomendaciones prácticas:

- Define qué casos quieres cubrir (rangos, estados, comandos) antes de simular.
- Usa `ASSERT` con mensajes con contexto (ciclo, estado, dirección) para depurar más rápido.
- Si un fallo invalida el resto de pruebas, usa `SEVERITY FAILURE` para detener la simulación.

---

*[⬆ Volver al Índice](#índice)*
