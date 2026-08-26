<!--
---
file: Teoria/04_palabras_clave_principales.md
description: Sentencias secuenciales y concurrentes: process, if, case, loop, generate, component, packages
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [process, if-else, case, generate, component, functions, packages, vhdl]
---
-->

# Palabras clave principales

---

### 4.1 `PROCESS`

Un proceso es el bloque fundamental de la descripción **secuencial** en VHDL. Su
contenido se ejecuta línea por línea, pero el proceso en sí es una sentencia
concurrente (puede haber varios procesos activos en paralelo dentro de una
arquitectura).

**Sintaxis:**

```vhdl
[etiqueta:] PROCESS [(lista_de_sensibilidad)]
    -- declaraciones locales (variables, constantes, subprogramas)
BEGIN
    -- sentencias secuenciales
END PROCESS [etiqueta];
```

**Proceso combinacional** — todas las señales leídas deben estar en la lista de
sensibilidad; si falta alguna se infieren latches no deseados:

```vhdl
-- Mux 4:1 de 1 bit
PROCESS(a, b, c, d, sel)   -- todas las entradas deben estar aquí
BEGIN
    CASE sel IS
        WHEN "00"   => y <= a;
        WHEN "01"   => y <= b;
        WHEN "10"   => y <= c;
        WHEN OTHERS => y <= d;
    END CASE;
END PROCESS;
```

**Proceso secuencial (registro con reset síncrono):**

```vhdl
PROCESS(clk)
BEGIN
    IF RISING_EDGE(clk) THEN
        IF reset = '1' THEN
            q <= (OTHERS => '0');
        ELSE
            q <= d;
        END IF;
    END IF;
END PROCESS;
```

**Proceso secuencial (registro con reset asíncrono):**

```vhdl
-- reset asíncrono: va en la lista de sensibilidad Y es el primer IF
PROCESS(clk, reset)
BEGIN
    IF reset = '1' THEN            -- evaluado en cualquier flanco de reset
        q <= (OTHERS => '0');
    ELSIF RISING_EDGE(clk) THEN
        q <= d;
    END IF;
END PROCESS;
```

> **Uso recomendado:**
> - Lógica combinacional: lista de sensibilidad completa o usar `PROCESS(ALL)` (VHDL-2008).
> - Lógica secuencial: solo `clk` (sin reset) o `clk` + `reset` (con reset asíncrono).
> - Nombrar siempre los procesos para facilitar la depuración.

> **Errores típicos:**
> - Omitir señales de la lista de sensibilidad → latches no intencionales.
> - Usar `FALLING_EDGE` cuando el diseño mezcla flancos → violaciones de setup/hold.
> - Asignar la misma señal en dos procesos distintos → driver múltiple, error de síntesis.

---

### 4.2 `IF / ELSIF / ELSE`

Controla el flujo dentro de un proceso. En hardware, cada rama `IF` se convierte en
un **multiplexor con prioridad**: la primera condición verdadera tiene mayor prioridad.

**Sintaxis:**

```vhdl
IF condicion THEN
    ...
ELSIF condicion THEN
    ...
ELSE
    ...
END IF;
```

**Ejemplo — codificador de prioridad de 4 bits:**

```vhdl
PROCESS(req)
BEGIN
    IF    req(3) = '1' THEN salida <= "11";
    ELSIF req(2) = '1' THEN salida <= "10";
    ELSIF req(1) = '1' THEN salida <= "01";
    ELSIF req(0) = '1' THEN salida <= "00";
    ELSE                    salida <= "XX";
    END IF;
END PROCESS;
```

**Ejemplo — detección de rango (imposible con CASE):**

```vhdl
PROCESS(temperatura)
BEGIN
    IF temperatura > 80 THEN
        alarma <= '1';
        ventilador <= '1';
    ELSIF temperatura > 60 THEN
        alarma <= '0';
        ventilador <= '1';
    ELSE
        alarma <= '0';
        ventilador <= '0';
    END IF;
END PROCESS;
```

> **Uso recomendado:**
> - Cuando existe jerarquía de prioridad real en el diseño.
> - Para condiciones de rango (mayor que, menor que).
> - Preferir `CASE` si todas las ramas son mutuamente excluyentes sin prioridad.

> **Errores típicos:**
> - No cubrir todos los casos y no asignar un valor por defecto → latch inferido.
> - Confundir lógica de prioridad con selección paralela (usar `CASE` en ese caso).

---

### 4.3 `CASE`

Selección múltiple **sin prioridad**: todas las ramas son mutuamente excluyentes y se
evalúan en paralelo (hardware de multiplexor). Requiere cubrir **todos** los valores
posibles del selector.

**Sintaxis:**

```vhdl
CASE expresion IS
    WHEN valor1         => ...;
    WHEN valor2 | valor3 => ...;    -- varios valores con |
    WHEN OTHERS         => ...;     -- obligatorio si no se cubren todos los casos
END CASE;
```

**Ejemplo — decodificador BCD a 7 segmentos:**

```vhdl
PROCESS(bcd)
BEGIN
    CASE bcd IS
        -- segmentos: gfedcba
        WHEN "0000" => seg <= "0111111";  -- 0
        WHEN "0001" => seg <= "0000110";  -- 1
        WHEN "0010" => seg <= "1011011";  -- 2
        WHEN "0011" => seg <= "1001111";  -- 3
        WHEN "0100" => seg <= "1100110";  -- 4
        WHEN "0101" => seg <= "1101101";  -- 5
        WHEN "0110" => seg <= "1111101";  -- 6
        WHEN "0111" => seg <= "0000111";  -- 7
        WHEN "1000" => seg <= "1111111";  -- 8
        WHEN "1001" => seg <= "1101111";  -- 9
        WHEN OTHERS => seg <= "0000000";  -- apagado para valores > 9
    END CASE;
END PROCESS;
```

**Ejemplo — FSM con CASE (Moore):**

```vhdl
TYPE estado_t IS (S_IDLE, S_FETCH, S_EXEC, S_WRITE);
SIGNAL estado : estado_t := S_IDLE;

PROCESS(clk, reset)
BEGIN
    IF reset = '1' THEN
        estado <= S_IDLE;
    ELSIF RISING_EDGE(clk) THEN
        CASE estado IS
            WHEN S_IDLE  => IF start = '1' THEN estado <= S_FETCH; END IF;
            WHEN S_FETCH => estado <= S_EXEC;
            WHEN S_EXEC  => IF done = '1'  THEN estado <= S_WRITE;
                            ELSE estado <= S_EXEC; END IF;
            WHEN S_WRITE => estado <= S_IDLE;
        END CASE;
    END IF;
END PROCESS;
```

> **Uso recomendado:**
> - Decodificadores y tablas de verdad.
> - Máquinas de estado finito (FSM): el estado enumerado hace el código legible.
> - Siempre incluir `WHEN OTHERS` aunque se crean cubiertas todas las combinaciones.

> **Errores típicos:**
> - Omitir `WHEN OTHERS` con `STD_LOGIC_VECTOR` (tiene más de 2^n combinaciones por los 9 valores de STD_LOGIC) → advertencia o latch.
> - Usar `CASE` con un selector de tipo `INTEGER` sin `RANGE` → el rango puede ser enorme.
> - Intentar comparar rangos (`WHEN valor > 5`) → no válido en CASE; usar `IF`.

---

### 4.4 `FOR ... LOOP`

Bucle con número de iteraciones **conocido en compilación**. El sintetizador lo
despliega como hardware paralelo replicado (unrolling), no como un contador.

**Sintaxis:**

```vhdl
FOR variable IN rango LOOP
    -- sentencias
END LOOP;
```

**Ejemplo — inversor de bits (espejo de vector):**

```vhdl
PROCESS(entrada)
BEGIN
    FOR i IN 0 TO 7 LOOP
        salida(7 - i) <= entrada(i);
    END LOOP;
END PROCESS;
```

**Ejemplo — detector de primero-en-uno (priority encoder) iterativo:**

```vhdl
PROCESS(req)
    VARIABLE encontrado : BOOLEAN := FALSE;
BEGIN
    indice   <= (OTHERS => '0');
    encontrado := FALSE;
    FOR i IN 0 TO 15 LOOP
        IF req(i) = '1' AND NOT encontrado THEN
            indice    <= TO_UNSIGNED(i, 4);
            encontrado := TRUE;
        END IF;
    END LOOP;
END PROCESS;
```

**Ejemplo — suma de acumulador (uso en simulación):**

```vhdl
PROCESS
    VARIABLE suma : INTEGER := 0;
BEGIN
    FOR i IN 1 TO 100 LOOP
        suma := suma + i;
    END LOOP;
    resultado <= TO_UNSIGNED(suma, 16);
    WAIT;
END PROCESS;
```

> **Uso recomendado:**
> - Operar sobre todos los bits de un vector.
> - Generar estructuras regulares (flip-flops en cadena, CRC, etc.).
> - El índice del bucle es **solo de lectura** dentro del loop; no se puede asignar.

> **Errores típicos:**
> - Intentar usar el índice como señal destino (`i <= i + 1`) → error; `i` es inmutable.
> - Bucles con límites dependientes de señales (no constantes) → el sintetizador rechaza.
> - Confundir `FOR LOOP` concurrente (`GENERATE`) con el secuencial (`PROCESS`).

---

### 4.5 `WHILE ... LOOP`

Bucle cuya condición se evalúa antes de cada iteración. El número de ciclos puede ser
**desconocido** en compilación, por eso **no es sintetizable** en la mayoría de
herramientas. Su uso principal es en testbenches.

**Sintaxis:**

```vhdl
WHILE condicion LOOP
    -- sentencias
END LOOP;
```

**Ejemplo — testbench que estimula hasta encontrar resultado esperado:**

```vhdl
PROCESS
    VARIABLE intentos : INTEGER := 0;
BEGIN
    entrada <= (OTHERS => '0');
    WAIT FOR 5 ns;
    WHILE salida /= X"FF" AND intentos < 256 LOOP
        entrada <= STD_LOGIC_VECTOR(TO_UNSIGNED(intentos, 8));
        WAIT FOR 10 ns;
        intentos := intentos + 1;
    END LOOP;
    ASSERT salida = X"FF"
        REPORT "No se encontró el valor esperado"
        SEVERITY WARNING;
    WAIT;
END PROCESS;
```

> **Uso recomendado:** exclusivamente en testbenches y modelos de simulación.

> **Errores típicos:**
> - Intentar sintetizar un `WHILE` con condición dependiente de señales → error de herramienta.
> - Bucle infinito en simulación por no actualizar la condición de salida.

---

### 4.6 `GENERATE`

Replica sentencias **concurrentes** (no dentro de `PROCESS`). Equivale al `FOR LOOP`
pero a nivel estructural: crea múltiples instancias de hardware en paralelo.

**Sintaxis FOR GENERATE:**

```vhdl
etiqueta: FOR variable IN rango GENERATE
    -- sentencias concurrentes / instancias de componentes
END GENERATE etiqueta;
```

**Ejemplo — registros de desplazamiento en cadena:**

```vhdl
-- Conecta N flip-flops en serie automáticamente
ARCHITECTURE rtl OF shift_n IS
    SIGNAL cadena : STD_LOGIC_VECTOR(N DOWNTO 0);
BEGIN
    cadena(0) <= entrada;

    gen_etapas: FOR i IN 0 TO N-1 GENERATE
        ff: d_flipflop PORT MAP (
            clk => clk,
            d   => cadena(i),
            q   => cadena(i+1)
        );
    END GENERATE gen_etapas;

    salida <= cadena(N);
END ARCHITECTURE rtl;
```

**Sintaxis IF GENERATE (VHDL-93/2008):**

```vhdl
-- Incluir o excluir hardware según un genérico
gen_rst: IF TIENE_RESET GENERATE
    reset_sig <= NOT reset_n;
END GENERATE gen_rst;

gen_no_rst: IF NOT TIENE_RESET GENERATE
    reset_sig <= '0';
END GENERATE gen_no_rst;
```

> **Uso recomendado:**
> - Módulos parametrizables donde `N` viene de un `GENERIC`.
> - Evitar copiar y pegar instancias manuales de componentes idénticos.

> **Errores típicos:**
> - Usar `GENERATE` dentro de un `PROCESS` → error de sintaxis; GENERATE es concurrente.
> - Olvidar la etiqueta de cierre `END GENERATE etiqueta` → error de compilación en Quartus.

---

### 4.7 `COMPONENT` y `PORT MAP`

Permiten reutilizar módulos y construir diseños **jerárquicos** (estructurales).
Un componente es la "declaración de interfaz" de un módulo externo.

**Flujo completo en tres pasos:**

```vhdl
ARCHITECTURE estructural OF sumador4b IS

    ---------- PASO 1: declarar el componente ----------
    COMPONENT fa IS   -- full adder de 1 bit
        PORT (
            a, b, cin : IN  STD_LOGIC;
            s, cout   : OUT STD_LOGIC
        );
    END COMPONENT fa;

    ---------- PASO 2: señales de interconexión ----------
    SIGNAL c : STD_LOGIC_VECTOR(3 DOWNTO 1);

BEGIN
    ---------- PASO 3: instanciar con PORT MAP ----------
    -- Mapeo posicional (por orden de puertos):
    u0: fa PORT MAP (a(0), b(0), '0',  s(0), c(1));
    -- Mapeo nominal (recomendado, más legible):
    u1: fa PORT MAP (a => a(1), b => b(1), cin => c(1), s => s(1), cout => c(2));
    u2: fa PORT MAP (a => a(2), b => b(2), cin => c(2), s => s(2), cout => c(3));
    u3: fa PORT MAP (a => a(3), b => b(3), cin => c(3), s => s(3), cout => cout);

END ARCHITECTURE estructural;
```

**Puerto no conectado — usar `OPEN`:**

```vhdl
-- Si un puerto de salida no se usa
u4: fa PORT MAP (a => x, b => y, cin => '0', s => res, cout => OPEN);
```

> **Uso recomendado:**
> - Mapeo nominal (`puerto => señal`) en lugar de posicional para evitar errores.
> - Para diseños con muchos componentes iguales, combinar con `GENERATE`.
> - Declarar componentes en un `PACKAGE` compartido cuando se usan en varios archivos.

> **Errores típicos:**
> - El nombre del componente no coincide exactamente con el nombre de la entidad → error de enlace.
> - Usar `OPEN` en puertos de **entrada** (no válido; siempre deben conectarse).
> - Confundir el orden de los puertos en mapeo posicional.

---

### 4.8 `GENERIC` / `GENERIC MAP`

Los genéricos son **parámetros de tiempo de diseño** que permiten crear módulos
configurables sin duplicar código. Se declaran en la entidad antes de los puertos.

**Declaración con valores por defecto:**

```vhdl
ENTITY contador IS
    GENERIC (
        NBITS  : INTEGER := 8;      -- ancho del contador
        MODULO : INTEGER := 256     -- valor de desbordamiento
    );
    PORT (
        clk    : IN  STD_LOGIC;
        reset  : IN  STD_LOGIC;
        q      : OUT STD_LOGIC_VECTOR(NBITS-1 DOWNTO 0)
    );
END ENTITY contador;

ARCHITECTURE rtl OF contador IS
    SIGNAL cuenta : INTEGER RANGE 0 TO MODULO-1 := 0;
BEGIN
    q <= STD_LOGIC_VECTOR(TO_UNSIGNED(cuenta, NBITS));

    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            cuenta <= 0;
        ELSIF RISING_EDGE(clk) THEN
            IF cuenta = MODULO - 1 THEN
                cuenta <= 0;
            ELSE
                cuenta <= cuenta + 1;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE rtl;
```

**Instanciar con GENERIC MAP:**

```vhdl
-- Contador de 4 bits módulo 10 (BCD)
cnt_bcd: contador
    GENERIC MAP (NBITS => 4, MODULO => 10)
    PORT MAP   (clk => clk, reset => rst, q => digito);

-- Contador de 8 bits módulo 256 (usa valores por defecto)
cnt_byte: contador
    PORT MAP (clk => clk, reset => rst, q => byte_out);
```

> **Uso recomendado:**
> - Parametrizar anchos de bus, profundidad de memorias, divisores de frecuencia.
> - Siempre asignar valores por defecto para que el módulo compile solo sin `GENERIC MAP`.

> **Errores típicos:**
> - Usar el genérico como límite de señal sin verificar que sea potencia de 2.
> - Pasar un genérico a un rango que genere tamaño 0 o negativo → error de elaboración.

---

### 4.9 `FUNCTION`

Una función toma parámetros de **solo lectura** y devuelve **un único valor**. Puede
usarse tanto dentro de procesos como en sentencias concurrentes.

**Sintaxis:**

```vhdl
FUNCTION nombre (parametro1 : tipo; ...) RETURN tipo_retorno IS
    -- declaraciones locales
BEGIN
    -- sentencias secuenciales
    RETURN expresion;
END FUNCTION nombre;
```

**Ejemplo — función de paridad:**

```vhdl
FUNCTION paridad_par(v : STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
    VARIABLE resultado : STD_LOGIC := '0';
BEGIN
    FOR i IN v'RANGE LOOP
        resultado := resultado XOR v(i);
    END LOOP;
    RETURN resultado;
END FUNCTION paridad_par;

-- Uso concurrente (fuera de proceso)
bit_paridad <= paridad_par(datos);

-- Uso dentro de proceso
PROCESS(datos)
BEGIN
    IF paridad_par(datos) = '1' THEN
        error_par <= '1';
    END IF;
END PROCESS;
```

**Ejemplo — función de conversión de entero a BCD (2 dígitos):**

```vhdl
FUNCTION int_a_bcd2(val : INTEGER RANGE 0 TO 99)
    RETURN STD_LOGIC_VECTOR IS
    VARIABLE decenas, unidades : INTEGER;
BEGIN
    decenas  := val / 10;
    unidades := val MOD 10;
    RETURN STD_LOGIC_VECTOR(TO_UNSIGNED(decenas,  4)) &
           STD_LOGIC_VECTOR(TO_UNSIGNED(unidades, 4));
END FUNCTION int_a_bcd2;
```

> **Uso recomendado:**
> - Operaciones que se repiten en varios puntos del diseño (paridad, CRC, conversiones).
> - Los atributos de vector (`v'LENGTH`, `v'RANGE`, `v'HIGH`, `v'LOW`) hacen las
>   funciones genéricas.

> **Errores típicos:**
> - No poner `RETURN` en todos los caminos de ejecución → error de compilación.
> - Intentar asignar señales dentro de una función pura → usar `PROCEDURE` en su lugar.
> - Función con bucle de límite variable que el sintetizador no puede inferir.

---

### 4.10 `PROCEDURE`

Un procedimiento puede tener parámetros `IN`, `OUT` e `INOUT` y **no devuelve valor**
directamente. Se llama desde dentro de un proceso o como sentencia concurrente.

**Sintaxis:**

```vhdl
PROCEDURE nombre (
    SIGNAL   entrada  : IN  tipo;
    SIGNAL   salida   : OUT tipo;
    VARIABLE var_io   : INOUT tipo
) IS
    -- declaraciones locales
BEGIN
    -- sentencias secuenciales
END PROCEDURE nombre;
```

**Ejemplo — procedimiento de reset de bus:**

```vhdl
PROCEDURE limpiar_bus (
    SIGNAL bus : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL oe  : OUT STD_LOGIC
) IS
BEGIN
    bus <= (OTHERS => '0');
    oe  <= '0';
END PROCEDURE limpiar_bus;

-- Llamada desde un proceso
PROCESS(reset)
BEGIN
    IF reset = '1' THEN
        limpiar_bus(dato_bus, output_enable);
    END IF;
END PROCESS;
```

**Ejemplo — procedimiento de testbench para generar pulso de reloj:**

```vhdl
PROCEDURE gen_clk (
    SIGNAL clk    : OUT STD_LOGIC;
    CONSTANT ciclos : IN INTEGER
) IS
BEGIN
    FOR i IN 1 TO ciclos LOOP
        clk <= '0'; WAIT FOR 10 ns;
        clk <= '1'; WAIT FOR 10 ns;
    END LOOP;
END PROCEDURE gen_clk;

-- Uso en testbench
gen_clk(clk_tb, 100);  -- genera 100 ciclos de reloj
```

> **Uso recomendado:**
> - Secuencias de inicialización en testbenches.
> - Operaciones que modifican múltiples señales simultáneamente.

> **Errores típicos:**
> - Usar `WAIT` dentro de un procedimiento llamado desde un proceso con lista de
>   sensibilidad → error; solo se puede usar `WAIT` en procesos sin lista de sensibilidad.

---

### 4.11 `PACKAGE`

Un paquete agrupa declaraciones (tipos, constantes, funciones, procedimientos) que
se quieren compartir entre múltiples archivos del proyecto.

**Estructura — dos archivos separados (recomendado):**

```vhdl
-- Archivo: tipos_proyecto.vhd
PACKAGE tipos_proyecto IS
    -- Tipos globales del proyecto
    CONSTANT CLK_FREQ  : INTEGER := 50_000_000;  -- 50 MHz
    CONSTANT BUS_ANCHO : INTEGER := 8;

    TYPE byte_t  IS ARRAY (0 TO 7)  OF STD_LOGIC;
    TYPE estado_t IS (REPOSO, ACTIVO, ERROR, RESET);

    -- Solo declaración; implementación en PACKAGE BODY
    FUNCTION suma_saturada(a, b : UNSIGNED(7 DOWNTO 0))
        RETURN UNSIGNED;
END PACKAGE tipos_proyecto;

PACKAGE BODY tipos_proyecto IS
    FUNCTION suma_saturada(a, b : UNSIGNED(7 DOWNTO 0))
        RETURN UNSIGNED IS
        VARIABLE r : UNSIGNED(8 DOWNTO 0);
    BEGIN
        r := ('0' & a) + ('0' & b);
        IF r(8) = '1' THEN
            RETURN X"FF";       -- satura en 255
        ELSE
            RETURN r(7 DOWNTO 0);
        END IF;
    END FUNCTION suma_saturada;
END PACKAGE BODY tipos_proyecto;
```

**Uso en otro archivo:**

```vhdl
LIBRARY work;
USE work.tipos_proyecto.all;

ENTITY mi_modulo IS
    PORT (a, b : IN UNSIGNED(7 DOWNTO 0); r : OUT UNSIGNED(7 DOWNTO 0));
END ENTITY mi_modulo;

ARCHITECTURE rtl OF mi_modulo IS
BEGIN
    r <= suma_saturada(a, b);   -- función del paquete
END ARCHITECTURE rtl;
```

> **Uso recomendado:**
> - Crear un paquete por proyecto con todos los tipos y constantes compartidos.
> - Compilar el paquete antes que los módulos que lo usan (orden de compilación).

> **Errores típicos:**
> - Olvidar compilar el paquete primero → error "unit not found".
> - Declarar el mismo tipo en el paquete y en la arquitectura → conflicto de tipos.
> - Modificar el paquete y no recompilar todos los módulos que dependen de él.

---

### 4.12 `WAIT`

Suspende la ejecución de un proceso hasta que se cumpla una condición. Se usa casi
exclusivamente en **testbenches**. Un proceso con `WAIT` **no puede tener** lista de
sensibilidad.

**Formas de WAIT:**

```vhdl
-- 1. Espera por tiempo absoluto
WAIT FOR 20 ns;

-- 2. Espera hasta que cambie cualquiera de las señales listadas
WAIT ON clk, reset;

-- 3. Espera hasta que se cumpla una expresión
WAIT UNTIL clk = '1';
WAIT UNTIL RISING_EDGE(clk);
WAIT UNTIL (contador = 10 AND listo = '1');

-- 4. Combinación de condición y tiempo límite
WAIT UNTIL listo = '1' FOR 100 ns;  -- máximo 100 ns

-- 5. Suspensión indefinida (detiene la simulación)
WAIT;
```

**Ejemplo — testbench típico con WAIT:**

```vhdl
PROCESS
BEGIN
    -- Condiciones iniciales
    reset <= '1'; entrada <= X"00";
    WAIT FOR 20 ns;

    -- Liberar reset
    reset <= '0';
    WAIT FOR 10 ns;

    -- Aplicar estímulos
    entrada <= X"A5";
    WAIT UNTIL RISING_EDGE(clk);     -- espera 1 ciclo
    WAIT UNTIL RISING_EDGE(clk);     -- espera otro ciclo

    ASSERT salida = X"5A"
        REPORT "Fallo: resultado incorrecto" SEVERITY ERROR;

    WAIT;   -- fin de la simulación
END PROCESS;
```

> **Uso recomendado:**
> - Testbenches: primera opción para controlar el flujo temporal.
> - No usar en procesos de síntesis.

> **Errores típicos:**
> - Mezclar lista de sensibilidad y `WAIT` en el mismo proceso → error de compilación.
> - `WAIT FOR` con tiempo 0 (`WAIT FOR 0 ns`) no avanza el tiempo, crea un delta-cycle.
> - Olvidar el `WAIT` final → el proceso se reinicia infinitamente y la simulación no termina.

---

### 4.13 `ASSERT`

Verifica condiciones en simulación e imprime mensajes. No sintetiza como hardware;
es ignorado por el sintetizador. Fundamental para **auto-verificar testbenches**.

**Sintaxis:**

```vhdl
ASSERT condicion
    REPORT "mensaje"
    SEVERITY nivel;
```

**Niveles de severidad:**

| Nivel | Comportamiento típico del simulador |
|-------|-------------------------------------|
| `NOTE` | Imprime el mensaje, continúa |
| `WARNING` | Imprime advertencia, continúa |
| `ERROR` | Imprime error, puede detener la simulación |
| `FAILURE` | Detiene la simulación inmediatamente |

**Ejemplos:**

```vhdl
-- Verificación de resultado esperado
ASSERT (salida = esperado)
    REPORT "ERROR: salida=" & TO_STRING(salida) &
           " esperado=" & TO_STRING(esperado)
    SEVERITY ERROR;

-- Marca el fin de la simulación de forma limpia
ASSERT FALSE
    REPORT "*** Simulación completada sin errores ***"
    SEVERITY NOTE;

-- Verificación de precondición en arquitectura
ASSERT (NBITS >= 2 AND NBITS <= 16)
    REPORT "NBITS fuera de rango válido (2..16)"
    SEVERITY FAILURE;
```

**ASSERT concurrente (fuera de proceso):**

```vhdl
ARCHITECTURE rtl OF modulo IS
BEGIN
    -- Se evalúa siempre que cambien las señales involucradas
    ASSERT NOT (wr = '1' AND rd = '1')
        REPORT "Conflicto: escritura y lectura simultáneas"
        SEVERITY ERROR;
END ARCHITECTURE rtl;
```

> **Uso recomendado:**
> - Verificar salidas esperadas en testbenches en lugar de inspeccionar manualmente.
> - Verificar restricciones de genéricos en tiempo de elaboración.
> - Señalar fin de simulación con `SEVERITY NOTE` para distinguirlo de un error.

> **Errores típicos:**
> - Confundir `ASSERT condicion` (falla si es `FALSE`) con un `IF`: la condición debe
>   ser la situación **correcta**, no el error.
> - Usar `TO_STRING` sin `USE std.textio.all` en simuladores que lo requieren.

---

*[⬆ Volver al Índice](#índice)*

---
