<!--
---
file: Teoria/03_senales_variables_constantes.md
description: Modelo de ejecución delta-cycles, señales, variables, constantes y atributos
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [signal, variable, constant, delta-cycles, atributos, vhdl]
---
-->

# Señales, Variables y Constantes

VHDL dispone de tres clases de **objetos** para almacenar y transferir datos: señales,
variables y constantes. Comprender sus diferencias no es solo saber la sintaxis: es
entender el **modelo de ejecución** que usa VHDL y cómo se traduce en hardware real.

---

### El modelo de ejecución de VHDL: delta-cycles

Para entender por qué las señales y las variables se comportan diferente, es
necesario conocer el **motor de simulación** de VHDL, que es también el modelo que
rige la síntesis.

VHDL simula un **sistema de hardware concurrente**. Cuando múltiples procesos se
activan al mismo tiempo (por ejemplo, al cambiar una señal), todos deben ejecutarse
"simultáneamente". Para lograr esto sin ambigüedad, el simulador utiliza el concepto
de **delta-cycle** (δ):

1. En el instante T, varios procesos se activan.
2. Cada proceso **lee** los valores actuales de las señales y calcula nuevas asignaciones
   con `<=`. Estas asignaciones quedan en una "cola de pendientes", **no se aplican aún**.
3. Al terminar todos los procesos del instante T, el simulador aplica las asignaciones
   pendientes. Esto ocurre en el mismo instante T pero en un **δ posterior**: T + 1δ.
4. Si al aplicar esas asignaciones se activan más procesos, se repite el ciclo (T + 2δ,
   T + 3δ...) hasta que no haya más cambios. Solo entonces avanza el tiempo real.

```
Tiempo real:     T=0                    T=10ns
Delta-cycles:    δ0  δ1  δ2  ...        δ0  δ1  ...
                 |   |   |              |   |
                 procesos calculan      procesos calculan
                 señales en cola        señales en cola
                     |                      |
                     señales se aplican     señales se aplican
```

**Consecuencia práctica:** dentro de un proceso, si asignas una señal con `<=` y
luego la lees en la misma ejecución del proceso, **leerás el valor anterior** al de
la asignación, porque la nueva asignación aún no se ha aplicado (está en la cola).
Las **variables**, en cambio, se actualizan inmediatamente (`δ0`) dentro del proceso.

---

### Comparativa

| Característica | `SIGNAL` | `VARIABLE` | `CONSTANT` |
|:---|:---|:---|:---|
| **Operador de asignación** | `<=` (deferred/scheduled) | `:=` (inmediato) | `:=` (solo al declarar) |
| **Ámbito visible** | Toda la arquitectura | Solo el proceso/subprograma que la contiene | Arquitectura, paquete o subprograma |
| **Cuándo se actualiza** | Al terminar el proceso (siguiente δ) | En la línea donde se ejecuta | Nunca (valor fijo desde elaboración) |
| **Corresponde en hardware** | Alambre (combinacional) o registro (FF) | Nodo interno del proceso; puede mapearse a registro si se preserva entre activaciones | Parámetro literalizado o constante de síntesis |
| **Puede usarse fuera de un proceso** | Sí | No | Sí |
| **Visible entre procesos** | Sí (permite comunicación) | No | Sí |
| **Admite valor inicial** | Sí (`:=` en declaración) | Sí (`:=` en declaración) | Sí (obligatorio) |

---

### Señal

Una **señal** (`SIGNAL`) es el objeto fundamental de VHDL. Modela un **conductor
físico** del circuito: puede ser un alambre (lógica combinacional) o la salida de un
flip-flop (lógica secuencial), según el contexto en que se use.

Características clave:
- Se declara en la **zona de declaraciones de la arquitectura** (antes del `BEGIN`),
  por lo que es visible en todos los procesos y sentencias concurrentes de esa arquitectura.
- La asignación `<=` es **diferida**: el nuevo valor no es visible en el proceso actual,
  sino en el siguiente ciclo de simulación (delta-cycle) o en el siguiente flanco del
  reloj (en síntesis, si está dentro de `RISING_EDGE`).
- Múltiples asignaciones a la misma señal dentro del mismo proceso: **solo tiene efecto
  la última** (las anteriores se sobreescriben antes de que el valor se aplique).
- Permite que dos procesos distintos se comuniquen: proceso A escribe la señal,
  proceso B la lee cuando cambia.

**Señal como alambre (combinacional):**

```vhdl
ARCHITECTURE rtl OF puertas IS
    SIGNAL y_and : STD_LOGIC;
    SIGNAL y_or  : STD_LOGIC;
BEGIN
    -- Asignaciones concurrentes: se evalúan SIEMPRE que cambie a o b
    y_and <= a AND b;
    y_or  <= a OR b;
    -- En hardware: y_and es la salida de una puerta AND, nada más
END ARCHITECTURE rtl;
```

**Señal como registro (secuencial):**

```vhdl
ARCHITECTURE rtl OF registro IS
    SIGNAL q_interno : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"00";
BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            q_interno <= (OTHERS => '0');   -- FF reset a 0
        ELSIF RISING_EDGE(clk) THEN
            q_interno <= d;                 -- FF captura d en cada flanco
        END IF;
    END PROCESS;
    -- q_interno es la salida de 8 flip-flops D en hardware
    q <= q_interno;
END ARCHITECTURE rtl;
```

**Señal con valor inicial:**

```vhdl
-- El valor inicial (:= X"00") solo se aplica en el instante 0 de la simulación.
-- En hardware real (FPGA), el valor inicial puede o no respetarse según el dispositivo.
-- Se recomienda usar reset explícito para garantizar el estado inicial en hardware.
SIGNAL cuenta : INTEGER RANGE 0 TO 9 := 0;
```

**Contador de 0 a 9 con señal:**

```vhdl
ARCHITECTURE rtl OF contador_bcd IS
    SIGNAL cuenta : INTEGER RANGE 0 TO 9 := 0;
BEGIN
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            cuenta <= 0;
        ELSIF RISING_EDGE(clk) THEN
            IF cuenta = 9 THEN
                cuenta <= 0;
            ELSE
                cuenta <= cuenta + 1;
            END IF;
        END IF;
    END PROCESS;
    salida <= STD_LOGIC_VECTOR(TO_UNSIGNED(cuenta, 4));
END ARCHITECTURE rtl;
```

---

### Variable

Una **variable** (`VARIABLE`) es un objeto de **actualización inmediata**. A diferencia
de las señales, no tiene el concepto de "valor anterior vs valor programado": cuando
ejecutas `v := expresion`, el nuevo valor está disponible en la **línea siguiente**.

Características clave:
- Se declara en la **zona de declaraciones del proceso** (entre `PROCESS` y `BEGIN`),
  por lo que es completamente privada a ese proceso. Ningún otro proceso puede leerla.
- La asignación `:=` es **inmediata**: el valor actualizado se puede leer en la
  siguiente instrucción del mismo proceso, en el mismo δ.
- **Persiste entre activaciones del proceso:** si el proceso se activa varias veces,
  la variable recuerda el valor de la última activación. Esto la hace candidata a ser
  sintetizada como un **registro** (flip-flop), al igual que una señal secuencial.
- Son especialmente útiles para **cálculos intermedios encadenados** donde cada paso
  depende del resultado inmediato del paso anterior.

**Diferencia crítica señal vs variable — mismo contador:**

```vhdl
-- CON SEÑAL: la comparación se hace con el valor ANTES del incremento
PROCESS(clk)
BEGIN
    IF RISING_EDGE(clk) THEN
        cuenta_s <= cuenta_s + 1;      -- (A) el nuevo valor aún no existe
        IF cuenta_s = 9 THEN           -- (B) lee el valor ANTERIOR a (A): bug sutil
            cuenta_s <= 0;
        END IF;
    END IF;
END PROCESS;
-- Bug: el contador llega a 10 antes de resetear, porque en (B) cuenta_s
-- todavía vale 9 cuando se llegó a 9, así que en el siguiente ciclo valdrá 10.

-- CON VARIABLE: la comparación se hace con el valor ya incrementado
PROCESS(clk)
    VARIABLE v : INTEGER RANGE 0 TO 10 := 0;
BEGIN
    IF RISING_EDGE(clk) THEN
        v := v + 1;         -- (A) actualización inmediata
        IF v = 10 THEN      -- (B) lee el nuevo valor: correcto
            v := 0;
        END IF;
        cuenta_v <= v;      -- señal recibe el valor final correcto
    END IF;
END PROCESS;
```

**Variable para acumulación en un solo ciclo (pipeline de cálculo):**

```vhdl
PROCESS(datos)
    VARIABLE suma : UNSIGNED(11 DOWNTO 0);  -- 12 bits para sumar 8 valores de 8 bits
BEGIN
    suma := (OTHERS => '0');
    FOR i IN 0 TO 7 LOOP
        suma := suma + UNSIGNED(datos(i));   -- cada suma usa el resultado anterior
    END LOOP;
    -- Si suma fuera SIGNAL, todos los += usarían el valor original (0), no el acumulado
    total <= suma;
END PROCESS;
```

**Cuándo una variable genera un registro (FF):**

```vhdl
-- Una variable que se ESCRIBE en un ciclo y se LEE en el SIGUIENTE
-- (no se inicializa en cada activación) → el sintetizador infiere un FF
PROCESS(clk)
    VARIABLE ff_var : STD_LOGIC;
BEGIN
    IF RISING_EDGE(clk) THEN
        salida <= ff_var;           -- lee el valor de la activación ANTERIOR
        ff_var := entrada;          -- escribe para la PRÓXIMA activación
    END IF;
END PROCESS;
-- ff_var se convierte en un flip-flop exactamente igual que si fuera una señal
```

---

### Constante

Una **constante** (`CONSTANT`) es un objeto de **solo lectura** cuyo valor se fija en
tiempo de **elaboración** (cuando el sintetizador o simulador procesa el diseño,
antes de que comience cualquier ejecución). No consume recursos de hardware propios:
el sintetizador sustituye cada aparición de la constante por su valor literalizado
directamente en el circuito.

Características clave:
- Se puede declarar en la arquitectura, en un proceso, en un subprograma, o en un
  paquete (para compartirla entre archivos).
- El tipo y el valor son inmutables; intentar asignarle un nuevo valor es error de
  compilación.
- Acepta expresiones calculadas en elaboración (sumas, restas, funciones puras).
- Es la forma preferida de nombrar cualquier **número mágico** del diseño.

```vhdl
-- Constantes de proyecto en la zona de declaraciones de arquitectura
CONSTANT CLK_HZ     : INTEGER := 50_000_000;   -- frecuencia de reloj
CONSTANT BAUDRATE   : INTEGER := 9_600;
CONSTANT CLK_DIV    : INTEGER := CLK_HZ / BAUDRATE;  -- 5208 (calculado al elaborar)
CONSTANT HALF_DIV   : INTEGER := CLK_DIV / 2;        -- 2604

-- Constante de tipo vectorial
CONSTANT RESET_VEC  : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"FF";
CONSTANT MASCARA    : UNSIGNED(7 DOWNTO 0) := "00001111";  -- nibble inferior
```

**Divisor de frecuencia con constantes:**

```vhdl
ARCHITECTURE rtl OF divisor IS
    CONSTANT CLK_HZ   : INTEGER := 50_000_000;
    CONSTANT FREQ_OUT : INTEGER := 1;           -- 1 Hz de salida
    CONSTANT MAX_CNT  : INTEGER := (CLK_HZ / FREQ_OUT) - 1;  -- 49_999_999

    SIGNAL contador : INTEGER RANGE 0 TO MAX_CNT := 0;
    SIGNAL toggle   : STD_LOGIC := '0';
BEGIN
    PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF contador = MAX_CNT THEN
                contador <= 0;
                toggle   <= NOT toggle;
            ELSE
                contador <= contador + 1;
            END IF;
        END IF;
    END PROCESS;
    salida <= toggle;
END ARCHITECTURE rtl;
```

**Constante local a un proceso:**

```vhdl
PROCESS(clk)
    CONSTANT UMBRAL : INTEGER := 200;   -- solo visible dentro de este proceso
BEGIN
    IF RISING_EDGE(clk) THEN
        IF sensor > UMBRAL THEN
            alarma <= '1';
        END IF;
    END IF;
END PROCESS;
```

> **Uso recomendado:** declarar todas las constantes de proyecto en un `PACKAGE`
> dedicado. Así, cambiar un valor (por ejemplo la frecuencia del reloj) se hace en
> un único lugar y se propaga automáticamente a todo el diseño.

---

### Atributos de señal

Las señales en VHDL tienen **atributos predefinidos** que permiten interrogar su
historia o sus características. Los más usados en síntesis son `'EVENT` y `'STABLE`.

```vhdl
-- 'EVENT: TRUE si la señal cambió en el delta-cycle actual
IF clk'EVENT AND clk = '1' THEN ...   -- detección de flanco de subida (estilo antiguo)
IF RISING_EDGE(clk) THEN ...           -- equivalente, forma moderna recomendada

-- 'STABLE(tiempo): TRUE si la señal NO ha cambiado en el tiempo especificado
-- Solo útil en simulación y en restricciones de timing, no en síntesis.
ASSERT clk'STABLE(4 ns) REPORT "Glitch detectado en CLK" SEVERITY WARNING;

-- 'LAST_VALUE: valor que tenía la señal antes del último cambio
IF clk = '1' AND clk'LAST_VALUE = '0' THEN ...  -- flanco de subida manual

-- 'LAST_EVENT: tiempo transcurrido desde el último cambio
-- Solo simulación
ASSERT (reset'LAST_EVENT >= 10 ns) REPORT "Reset demasiado corto" SEVERITY ERROR;
```

### Errores típicos con señales y variables

**Error 1 — leer una señal recién asignada dentro del mismo proceso:**

```vhdl
-- INCORRECTO: conta aún tiene el valor anterior en esta iteración
PROCESS(clk)
BEGIN
    IF RISING_EDGE(clk) THEN
        conta <= conta + 1;
        IF conta = 9 THEN      -- se evalúa con el valor ANTES del +1
            conta <= 0;
        END IF;
    END IF;
END PROCESS;

-- CORRECTO: usar variable para leer inmediatamente
PROCESS(clk)
    VARIABLE v : INTEGER RANGE 0 TO 9 := 0;
BEGIN
    IF RISING_EDGE(clk) THEN
        v := v + 1;            -- actualización inmediata
        IF v = 10 THEN
            v := 0;
        END IF;
        conta <= v;            -- señal toma el valor final al terminar
    END IF;
END PROCESS;
```

**Error 2 — asignar múltiples veces la misma señal en un proceso:**

```vhdl
-- Solo tiene efecto la ÚLTIMA asignación (las anteriores se descartan)
PROCESS(a, b)
BEGIN
    salida <= a;   -- esta asignación se cancela
    salida <= b;   -- esta es la que vale
END PROCESS;
```

**Error 3 — variable declarada fuera del proceso (no permitido):**

```vhdl
-- INCORRECTO: VARIABLE no puede ir en la zona de declaraciones de arquitectura
ARCHITECTURE rtl OF ejemplo IS
    VARIABLE v : INTEGER := 0;  -- ERROR de compilación
BEGIN
    ...
```

---

*[⬆ Volver al Índice](#índice)*

---
