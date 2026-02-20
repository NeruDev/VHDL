
# Teoría de VHDL

## Índice

1. [Estructura estándar del código](#1-estructura-estándar-del-código)
   - [1.1 Librerías y paquetes](#11-librerías-y-paquetes)
   - [1.2 Entidad — modos de puerto](#12-entidad-entity)
   - [1.3 Arquitectura — estilos de descripción](#13-arquitectura-architecture)
   - [1.4 Genéricos — parámetros en tiempo de diseño](#14-genéricos-generic)

2. [Tipos de datos](#2-tipos-de-datos)
   - [2.1 Escalares: BIT, STD_LOGIC, BOOLEAN, INTEGER](#21-tipos-escalares-básicos)
   - [2.2 Vectores: STD_LOGIC_VECTOR, UNSIGNED, SIGNED y conversiones](#22-tipos-vectoriales)
   - [2.3 Tipos enumerados](#23-tipos-enumerados)
   - [2.4 Arreglos y registros](#24-arreglos-y-registros)

3. [Señales, Variables y Constantes](#3-señales-variables-y-constantes)
   - [El modelo de ejecución: delta-cycles](#el-modelo-de-ejecución-de-vhdl-delta-cycles)
   - [Comparativa general](#comparativa)
   - [SIGNAL — alambres y registros](#señal)
   - [VARIABLE — cálculo local inmediato](#variable)
   - [CONSTANT — parámetros fijos de elaboración](#constante)
   - [Atributos de señal: 'EVENT, 'STABLE, 'LAST_VALUE](#atributos-de-señal)
   - [Errores típicos](#errores-típicos-con-señales-y-variables)

4. [Palabras clave principales](#4-palabras-clave-principales)
   - [4.1 PROCESS — secuencial vs combinacional](#41-process)
   - [4.2 IF / ELSIF / ELSE — prioridad en hardware](#42-if--elsif--else)
   - [4.3 CASE — selección sin prioridad](#43-case)
   - [4.4 FOR ... LOOP — hardware replicado](#44-for--loop)
   - [4.5 WHILE ... LOOP — bucle condicional](#45-while--loop)
   - [4.6 GENERATE — instanciación masiva](#46-generate)
   - [4.7 COMPONENT / PORT MAP — jerarquía](#47-component-y-port-map)
   - [4.8 GENERIC / GENERIC MAP — parametrización](#48-generic--generic-map)
   - [4.9 FUNCTION — valor de retorno único](#49-function)
   - [4.10 PROCEDURE — múltiples salidas](#410-procedure)
   - [4.11 PACKAGE / PACKAGE BODY — código reutilizable](#411-package)
   - [4.12 WAIT — suspensión de proceso](#412-wait)
   - [4.13 ASSERT — verificación en simulación](#413-assert)

5. [Operadores](#5-operadores)
   - [5.1 Lógicos](#51-lógicos)
   - [5.2 Relacionales](#52-relacionales)
   - [5.3 Aritméticos](#53-aritméticos)
   - [5.4 Concatenación y desplazamiento](#54-concatenación-y-desplazamiento)
   - [5.5 Precedencia de operadores](#55-precedencia-de-operadores)

6. [Lógica concurrente vs. secuencial](#6-lógica-concurrente-vs-secuencial)
   - [6.1 Sentencias concurrentes: simple, condicional, selección](#61-sentencias-concurrentes)
   - [6.2 Sentencias secuenciales: combinacional, registros, latches](#62-sentencias-secuenciales)
   - [6.3 Comunicación entre procesos mediante señales](#63-comunicación-entre-procesos)
   - [6.4 Resumen: guía de elección](#64-resumen-guía-de-elección)

---

## 1. Estructura estándar del código

Todo archivo VHDL se organiza en tres secciones obligatorias: **librerías**, **entidad** y **arquitectura**.

```
LIBRARY ...          -- Librerías a incluir
USE ...              -- Paquetes de las librerías

ENTITY nombre IS     -- Interfaz externa (puertos E/S)
    PORT (...);
END ENTITY nombre;

ARCHITECTURE rtl OF nombre IS
    -- Declaraciones internas (señales, componentes, etc.)
BEGIN
    -- Descripción del comportamiento o estructura
END ARCHITECTURE rtl;
```

### 1.1 Librerías y paquetes

VHDL es un lenguaje **fuertemente tipado**: los tipos de datos, funciones aritméticas
y operadores extendidos no están incorporados directamente en el lenguaje base, sino
en **librerías** que deben importarse explícitamente. Esto permite que el mismo
estándar sea usado desde simulación pura hasta síntesis en FPGA sin imponer
dependencias innecesarias.

Una **librería** (`LIBRARY`) es un repositorio compilado de paquetes. Un
**paquete** (`PACKAGE`) es una colección de declaraciones: tipos, constantes,
funciones y procedimientos. La cláusula `USE` importa el contenido de un paquete
al ámbito del archivo actual.

Las librerías más importantes son:

| Librería | Paquete | Qué aporta |
|----------|---------|------------|
| `ieee` | `std_logic_1164` | `STD_LOGIC`, `STD_LOGIC_VECTOR` y sus operaciones |
| `ieee` | `numeric_std` | `UNSIGNED`, `SIGNED` y aritmética (+, -, *, conversiones) |
| `std` | `standard` | Tipos básicos (`BIT`, `INTEGER`, `BOOLEAN`). **Siempre visible, no declarar** |
| `std` | `textio` | Lectura/escritura de archivos (solo simulación) |
| `work` | *(nombre del paquete)* | Código propio del proyecto actual |

```vhdl
LIBRARY ieee;
USE ieee.std_logic_1164.all;  -- STD_LOGIC y STD_LOGIC_VECTOR
USE ieee.numeric_std.all;     -- UNSIGNED, SIGNED y conversiones aritméticas
```

> **Uso recomendado:** usar `ieee.numeric_std` para aritmética. Las librerías
> `std_logic_arith` y `std_logic_unsigned` (de Synopsys) son no estándar y pueden
> generar conflictos cuando se mezclan con `numeric_std` en el mismo archivo.

> **Nota:** `LIBRARY std` y `USE std.standard.all` son **implícitos** siempre;
> nunca es necessary declararlos. `LIBRARY work` también es implícito.

### 1.2 Entidad (ENTITY)

Define los **puertos de entrada y salida**: la "caja negra" del módulo.

```vhdl
ENTITY sumador IS
    PORT (
        a      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);  -- entrada de 4 bits
        b      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);  -- entrada de 4 bits
        suma   : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);  -- resultado (5 bits)
        acarreo: OUT STD_LOGIC                       -- bit de acarreo
    );
END ENTITY sumador;
```

Modos de puerto:

| Modo | Descripción |
|------|-------------|
| `IN` | Solo lectura desde el exterior |
| `OUT` | Solo escritura hacia el exterior |
| `INOUT` | Lectura y escritura (buses bidireccionales) |
| `BUFFER` | Salida que también puede leerse internamente |

### 1.3 Arquitectura (ARCHITECTURE)

Describe el **comportamiento o estructura** del módulo.

```vhdl
ARCHITECTURE rtl OF sumador IS
    SIGNAL resultado_interno : STD_LOGIC_VECTOR(4 DOWNTO 0);
BEGIN
    resultado_interno <= ('0' & a) + ('0' & b);
    suma    <= resultado_interno(3 DOWNTO 0);
    acarreo <= resultado_interno(4);
END ARCHITECTURE rtl;
```

Un mismo módulo puede tener múltiples arquitecturas (con distintos nombres). Solo
una se activa durante la compilación/síntesis.

> **Estilos de descripción comunes:**
> - `rtl` (Register Transfer Level): describe transferencias de registros, el más habitual.
> - `behavioral`: modela el comportamiento sin preocuparse de la implementación física.
> - `structural`: conecta componentes como en un esquemático.
> - `dataflow`: usa asignaciones concurrentes para describir flujo de datos.

### 1.4 Genéricos (GENERIC)

Permiten parametrizar un módulo en tiempo de diseño sin cambiar su código fuente.
Equivalen a los *parámetros* en Verilog o a las plantillas en C++.

```vhdl
ENTITY shift_reg IS
    GENERIC (
        ANCHO : INTEGER := 8;   -- valor por defecto
        ETAPAS: INTEGER := 4
    );
    PORT (
        clk   : IN  STD_LOGIC;
        entrada: IN  STD_LOGIC_VECTOR(ANCHO-1 DOWNTO 0);
        salida : OUT STD_LOGIC_VECTOR(ANCHO-1 DOWNTO 0)
    );
END ENTITY shift_reg;
```

Instanciar con **GENERIC MAP** para pasar los valores:

```vhdl
shift16: shift_reg
    GENERIC MAP (ANCHO => 16, ETAPAS => 8)
    PORT MAP    (clk => clk, entrada => dato_in, salida => dato_out);
```

> **Uso recomendado:** parametrizar anchos de bus, profundidad de FIFO, divisores de
> reloj. Evitar genéricos de tipo `STRING` en síntesis.

> **Error típico:** olvidar que los genéricos solo existen en tiempo de compilación;
> no se pueden modificar en tiempo de ejecución (simulación dinámica).

---

*[⬆ Volver al Índice](#índice)*

---

## 2. Tipos de datos

En VHDL, un **tipo** define dos cosas: el **conjunto de valores** posibles que puede
tomar un objeto y las **operaciones permitidas** sobre él. A diferencia de lenguajes
como C, VHDL no permite mezclar tipos libremente: asignar un `STD_LOGIC_VECTOR` a
un `UNSIGNED` directamente es un error de compilación aunque ambos sean vectores de
bits. Esta estrictez es intencional: ayuda a detectar errores de diseño antes de
llevar el circuito a hardware.

Desde la perspectiva del hardware, los tipos cumplen tres funciones:
1. **Determinar el ancho de bus** que el sintetizador asigna a cada señal.
2. **Indicar la semántica aritmética** (sin signo, con signo, sin interpretación numérica).
3. **Acotar el espacio de estados** de los contadores y registros para optimizar el área.

### 2.1 Tipos escalares básicos

Los tipos escalares representan un **único valor** (no un vector). Son el bloque
constructivo más simple del sistema de tipos de VHDL.

#### `BIT`

`BIT` es el tipo lógico **nativo** del estándar VHDL-87. Solo puede tomar los
valores `'0'` y `'1'`. Es el concepto más puro de un bit digital, pero carece de
representación para buses en alta impedancia o señales desconocidas, por lo que
resulta insuficiente para modelar hardware real con buses compartidos.

```vhdl
SIGNAL enable : BIT := '0';
enable <= '1';
-- Las operaciones permitidas son AND, OR, NOT, NAND, NOR, XOR, XNOR
```

> **Cuándo usar `BIT`:** rara vez en diseño real. Sirve en modelos abstractos o
> cuando se verifica la lógica pura sin importar efectos físicos del bus.

#### `STD_LOGIC`

`STD_LOGIC` es el tipo estándar de la industria para diseño digital en VHDL. Está
definido en `ieee.std_logic_1164` y extiende `BIT` con **9 valores posibles**, lo
que permite modelar situaciones reales del hardware: múltiples drivers en un bus,
buses tri-estado y señales no inicializadas.

El corazón de `STD_LOGIC` es su **tabla de resolución**: cuando dos drivers atacan
el mismo nodo (situación que ocurre en buses compartidos), la tabla determina el
valor resultante. Por ejemplo, `'0'` forzado + `'1'` forzado = `'X'` (conflicto);
`'0'` forzado + `'Z'` = `'0'` (el driver activo gana).

| Valor | Tipo | Significado |
|-------|------|-------------|
| `'U'` | Simulación | No inicializado (valor de arranque por defecto) |
| `'X'` | Simulación/síntesis | Desconocido forzado (conflicto de drivers) |
| `'0'` | Síntesis | Cero lógico forzado |
| `'1'` | Síntesis | Uno lógico forzado |
| `'Z'` | Síntesis | Alta impedancia (bus tri-estado) |
| `'W'` | Simulación | Desconocido débil |
| `'L'` | Simulación | Cero débil (pull-down) |
| `'H'` | Simulación | Uno débil (pull-up) |
| `'-'` | Síntesis/sim. | Don't care (indiferente, para optimización) |

En síntesis, solo `'0'`, `'1'` y `'Z'` se mapean directamente a transistores.
Los demás valores son herramientas de **simulación** para detectar problemas.

```vhdl
SIGNAL dato   : STD_LOGIC;         -- valor inicial: 'U' en simulación
SIGNAL bus_oe : STD_LOGIC := 'Z';  -- bus en alta impedancia por defecto
dato <= '1';

-- Bus tri-estado: el driver solo conduce cuando oe='1'
bus_out <= dato WHEN oe = '1' ELSE 'Z';
```

> **Uso recomendado:** usar `STD_LOGIC` para prácticamente todo. Si en simulación
> aparece `'X'` o `'U'` en señales de control críticas, indica un bug de diseño
> (señal sin driver, conflicto, o lógica no inicializada).

#### `BOOLEAN`

`BOOLEAN` es el tipo de resultado de expresiones **lógicas y comparaciones**.
No tiene representación directa en bits; el sintetizador lo convierte a lógica
combinacional. Su uso principal es en condiciones `IF`, `WHILE` y genéricos.

```vhdl
SIGNAL igual    : BOOLEAN;
SIGNAL en_rango : BOOLEAN;

igual    <= (a = b);                          -- TRUE si a y b son iguales bit a bit
en_rango <= (contador >= 5) AND (contador <= 10);  -- TRUE si está en [5, 10]

-- En síntesis se convierte en puertas lógicas:
-- igual -> comparador de igualdad de N bits
-- en_rango -> dos comparadores + puerta AND
```

#### `INTEGER`

`INTEGER` es un tipo entero con signo de implementación indefinida (el estándar
garantiza al menos 32 bits, de −2³¹ a 2³¹−1). El sintetizador **no puede inferir
el ancho de bus** a menos que se restrinja con `RANGE`. Sin restricción, puede
generar un bus de 32 bits aunque el valor nunca supere 255.

```vhdl
-- SIN RANGE: el sintetizador puede generar 32 bits (ineficiente)
SIGNAL contador_malo : INTEGER := 0;

-- CON RANGE: el sintetizador infiere exactamente ceil(log2(256)) = 8 bits
SIGNAL contador : INTEGER RANGE 0 TO 255 := 0;
contador <= contador + 1;  -- wrapping no automático; hay que manejarlo
```

> **Detalle técnico:** el sintetizador calcula el ancho mínimo como
> ⌈log₂(max − min + 1)⌉ bits para rangos sin signo, o un bit adicional para rangos
> negativos. El rango también actúa como verificación en simulación: asignar un
> valor fuera del rango genera un error en tiempo de simulación.

#### `NATURAL` y `POSITIVE`

Son **subtipos** de `INTEGER` con restricciones predefinidas. Un subtipo hereda
todos los operadores del tipo base pero limita el rango de valores válidos.

```vhdl
-- NATURAL: enteros >= 0  (0, 1, 2, ... 2^31-1)
-- POSITIVE: enteros >= 1 (1, 2, 3, ... 2^31-1)
SIGNAL indice   : NATURAL  := 0;
SIGNAL longitud : POSITIVE := 1;

-- Uso habitual: índices de arreglos y parámetros de tamaño
CONSTANT N : POSITIVE := 8;   -- garantiza que N no puede ser 0 ni negativo
```

### 2.2 Tipos vectoriales

Los tipos vectoriales representan **grupos de bits con una dirección** de indexado.
En hardware corresponden directamente a **buses**: grupos de conductores que
transportan palabras de datos, direcciones o señales de control.

VHDL permite declarar vectores en dos direcciones:
- `DOWNTO`: índice mayor en el MSB — `(7 DOWNTO 0)`, el más habitual en hardware.
- `TO`: índice menor en el MSB — `(0 TO 7)`, poco usado en síntesis.

Usar `DOWNTO` es el convenio universal porque coincide con la notación binaria
estándar: el bit 7 es el más significativo (2⁷ = 128) y el bit 0 es el menos
significativo (2⁰ = 1).

#### `STD_LOGIC_VECTOR`

`STD_LOGIC_VECTOR` es simplemente un **arreglo de `STD_LOGIC`**. No tiene
semántica numérica propia: el sintetizador lo trata como un conjunto de cables sin
interpretación aritmética. Esto significa que no se puede sumar directamente;
hay que convertirlo a `UNSIGNED` o `SIGNED` primero.

```vhdl
SIGNAL bus8  : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL nibble: STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010";

-- Acceso a bits individuales
bus8(7) <= '1';                  -- MSB
bus8(0) <= '0';                  -- LSB

-- Acceso a sub-rangos (slices)
bus8(7 DOWNTO 4) <= "1100";      -- nibble superior
bus8(3 DOWNTO 0) <= nibble;      -- nibble inferior = otro vector

-- (OTHERS => valor): inicializar todos los bits al mismo valor
bus8 <= (OTHERS => '0');         -- pone a cero todos los bits
bus8 <= (OTHERS => '1');         -- pone a uno todos los bits
```

Literales: VHDL permite escribir valores usando distintas bases. El prefijo
determina la base:

```vhdl
SIGNAL byte : STD_LOGIC_VECTOR(7 DOWNTO 0);
byte <= X"A3";        -- hexadecimal: A=1010, 3=0011 -> "10100011"
byte <= O"243";       -- octal: 2=010, 4=100, 3=011 -> "010100011" (requiere múltiplo de 3 bits)
byte <= B"1010_0011"; -- binario explícito con separador visual '_'
```

> **Detalle técnico:** `STD_LOGIC_VECTOR` no define qué número representa el
> patrón de bits. `"10000000"` puede ser 128 (sin signo) o −128 (complemento a 2).
> Para dar semántica numérica, usar `UNSIGNED` o `SIGNED`.

#### `UNSIGNED` y `SIGNED`

Definidos en `ieee.numeric_std`, estos tipos son también arreglos de `STD_LOGIC`
pero con **semántica aritmética** definida:

- `UNSIGNED`: interpreta el patrón de bits como un entero sin signo en base binaria.
  Rango: 0 a 2ᴺ−1 para N bits.
- `SIGNED`: interpreta el patrón de bits como entero con signo en **complemento a 2**.
  Rango: −2ᴺ⁻¹ a 2ᴺ⁻¹−1 para N bits.

Esta distinción es crítica en hardware: los circuitos de comparación y extensión
de signo son distintos para `UNSIGNED` y `SIGNED`.

```vhdl
SIGNAL u_val : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');  -- 0
SIGNAL s_val : SIGNED(7 DOWNTO 0)   := (OTHERS => '0');  -- 0

u_val <= u_val + 1;        -- wrap: 255 + 1 = 0  (overflow natural)
s_val <= s_val - 1;        -- wrap: -128 - 1 = 127 (overflow natural)

-- Comparación: el resultado es correcto según la semántica
-- "11111111" como UNSIGNED = 255 > "00000000" = 0  -> TRUE
-- "11111111" como SIGNED   = -1  < "00000000" = 0  -> TRUE
```

**Conversiones entre tipos** — tabla completa:

```vhdl
SIGNAL vec  : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL unum : UNSIGNED(7 DOWNTO 0);
SIGNAL snum : SIGNED(7 DOWNTO 0);
SIGNAL inum : INTEGER;

-- Conversiones de tipo (type cast) - solo reinterpretan los bits, no los cambian
vec  <= STD_LOGIC_VECTOR(unum);   -- UNSIGNED  -> STD_LOGIC_VECTOR
vec  <= STD_LOGIC_VECTOR(snum);   -- SIGNED    -> STD_LOGIC_VECTOR
unum <= UNSIGNED(vec);            -- STD_LOGIC_VECTOR -> UNSIGNED
snum <= SIGNED(vec);              -- STD_LOGIC_VECTOR -> SIGNED

-- Conversiones de valor (cambian la representación)
inum <= TO_INTEGER(unum);         -- UNSIGNED -> INTEGER (valor numérico)
inum <= TO_INTEGER(snum);         -- SIGNED   -> INTEGER (valor numérico con signo)
unum <= TO_UNSIGNED(inum, 8);     -- INTEGER  -> UNSIGNED de 8 bits
snum <= TO_SIGNED(inum, 8);       -- INTEGER  -> SIGNED   de 8 bits

-- Resize: cambiar el ancho preservando el valor
unum <= RESIZE(u_pequeno, 8);     -- extiende por la izquierda con '0'
snum <= RESIZE(s_pequeno, 8);     -- extiende preservando el bit de signo
```

> **Error típico:** intentar sumar dos `STD_LOGIC_VECTOR` directamente:
> `resultado <= a + b;` — error de compilación porque `STD_LOGIC_VECTOR` no
> sobrecarga el operador `+`. Convertir a `UNSIGNED`/`SIGNED` primero.

### 2.3 Tipos enumerados

Un tipo enumerado es un tipo definido por el usuario que consiste en un **conjunto
ordinal y nombrado de valores**. El programador decide qué valores existen y les
asigna nombres descriptivos. El sintetizador se encarga de asignar automáticamente
una codificación binaria (usualmente one-hot o binaria compacta, configurable en
Quartus).

La ventaja frente a usar `STD_LOGIC_VECTOR` para los estados es doble:
1. **Legibilidad:** el código dice `WHEN PROCESANDO` en lugar de `WHEN "010"`, lo
   que reduce errores de tipeo y facilita el mantenimiento.
2. **Seguridad:** el sintetizador y el simulador verifican que solo se usen valores
   del tipo; asignar un valor inexistente es error de compilación.

```vhdl
-- Declaración del tipo (zona de declaraciones de la arquitectura)
TYPE estado_t IS (REPOSO, INICIO, PROCESANDO, FIN);
SIGNAL estado_actual : estado_t := REPOSO;  -- valor inicial obligatorio para simulación
```

**Codificación que elige Quartus por defecto:**

| Estado | Binario | One-hot |
|--------|---------|----------|
| REPOSO | `00` | `0001` |
| INICIO | `01` | `0010` |
| PROCESANDO | `10` | `0100` |
| FIN | `11` | `1000` |

En one-hot cada estado usa un flip-flop dedicado, lo que acelera la lógica siguiente
a expensas de más flip-flops. En FPGA (abundancia de FFs) es generalmente mejor.

```vhdl
-- FSM de 4 estados con CASE
PROCESS(clk, reset)
BEGIN
    IF reset = '1' THEN
        estado_actual <= REPOSO;    -- reset asíncrono
    ELSIF RISING_EDGE(clk) THEN
        CASE estado_actual IS
            WHEN REPOSO     =>
                IF iniciar = '1' THEN estado_actual <= INICIO; END IF;
            WHEN INICIO     => estado_actual <= PROCESANDO;
            WHEN PROCESANDO =>
                IF listo = '1'  THEN estado_actual <= FIN;
                ELSE                 estado_actual <= PROCESANDO; END IF;
            WHEN FIN        => estado_actual <= REPOSO;
        END CASE;
    END IF;
END PROCESS;
```

**Atributos útiles de tipos enumerados:**

```vhdl
-- T'POS(valor)  -> posición ordinal del valor (0, 1, 2...)
-- T'VAL(n)      -> valor en la posición n
-- T'SUCC(valor) -> siguiente valor en la enumeración
-- T'PRED(valor) -> valor anterior
SIGNAL sig : estado_t;
sig <= estado_t'SUCC(estado_actual);  -- avanza al siguiente estado (cuidado en el último)
```

> **Error típico:** no poner `WHEN OTHERS` en el `CASE` de una FSM. Aunque todos
> los estados estén cubiertos, los bits extra de la codificación pueden crear
> estados ilegales no manejados que corrompen la FSM en hardware real.

### 2.4 Arreglos y registros

VHDL permite construir **tipos compuestos** agrupando múltiples valores bajo un
único nombre. Hay dos categorías:

- **Array:** colección indexada de elementos del **mismo tipo**.
- **Record:** colección de elementos de **tipos distintos** identificados por nombre.

En hardware, ambos se implementan como grupos de bits concatenados (registros o
bancos de memoria).

#### Array personalizado

Un array se declara especificando el **rango de índices** y el **tipo del elemento**.
El índice puede ser cualquier tipo discreto (entero, enumerado).

```vhdl
-- Array de 16 palabras de 8 bits: equivale a una pequeña memoria ROM/RAM
TYPE memoria_t IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL rom : memoria_t;

-- Inicialización por posición (aggregate literal)
rom <= (
    0      => X"FF",
    1      => X"00",
    2      => X"A5",
    OTHERS => X"00"   -- resto de posiciones a cero
);

-- Acceso por índice variable (requiere que el índice sea una señal o variable)
SIGNAL addr : INTEGER RANGE 0 TO 15;
dato_salida <= rom(addr);   -- mux de 16 entradas inferido por el sintetizador
```

**Array de un solo bit (bus interno):**

```vhdl
-- Arreglo de STD_LOGIC_VECTOR: útil para buses entre módulos
TYPE bus_array_t IS ARRAY (0 TO 3) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL canales : bus_array_t;
canales(0) <= X"12";
canales(1) <= X"34";
```

**Atributos de arreglos:**

```vhdl
SIGNAL v : STD_LOGIC_VECTOR(7 DOWNTO 0);
-- v'LENGTH   -> número de elementos (8)
-- v'HIGH     -> índice mayor (7)
-- v'LOW      -> índice menor (0)
-- v'RANGE    -> rango completo (7 DOWNTO 0), usado en FOR LOOP
-- v'REVERSE_RANGE -> rango invertido (0 TO 7)

FOR i IN v'RANGE LOOP   -- itera de 7 a 0
    ...
END LOOP;
```

#### Record (registro)

Un record agrupa **campos de tipos distintos** bajo un nombre compuesto. Es el
equivalente VHDL de una `struct` en C. En hardware, todos los campos se
concatenan en un vector de bits del tamaño total.

```vhdl
-- Ejemplo: descriptor de un canal SPI
TYPE spi_config_t IS RECORD
    clk_div   : INTEGER RANGE 0 TO 255;          -- divisor de reloj
    modo      : STD_LOGIC_VECTOR(1 DOWNTO 0);    -- modo SPI (0..3)
    habilitar : STD_LOGIC;                       -- enable del módulo
    msb_first : BOOLEAN;                         -- orden de bits
END RECORD;

SIGNAL spi_cfg : spi_config_t;

-- Asignación campo a campo
spi_cfg.clk_div   <= 24;
spi_cfg.modo      <= "01";
spi_cfg.habilitar <= '1';
spi_cfg.msb_first <= TRUE;

-- Asignación por agregado (todos los campos a la vez)
spi_cfg <= (clk_div => 24, modo => "01", habilitar => '1', msb_first => TRUE);

-- Lectura de campos
IF spi_cfg.habilitar = '1' AND spi_cfg.msb_first THEN
    ...
END IF;
```

> **Nota:** un `RECORD` no puede tener valores por defecto en VHDL-93. En VHDL-2008
> sí es posible con la sintaxis `:= valor` en la declaración del campo.
> Quartus II 13 soporta un subconjunto de VHDL-2008.

> **Uso recomendado:** los records son ideales para pasar grupos de parámetros de
> configuración entre módulos mediante `PORT MAP`, haciendo el código más legible
> que usar decenas de señales individuales.

---

*[⬆ Volver al Índice](#índice)*

---

## 3. Señales, Variables y Constantes

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

## 4. Palabras clave principales

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

## 5. Operadores

### 5.1 Lógicos
Aplicables a `STD_LOGIC`, `STD_LOGIC_VECTOR`, `BIT` y `BOOLEAN`.

| Operador | Descripción | Ejemplo |
|----------|-------------|---------|
| `AND`  | Y lógico | `s <= a AND b;` |
| `OR`   | O lógico | `s <= a OR b;` |
| `NAND` | Y negado | `s <= a NAND b;` |
| `NOR`  | O negado | `s <= a NOR b;` |
| `XOR`  | O exclusivo | `s <= a XOR b;` |
| `XNOR` | O exclusivo negado | `s <= a XNOR b;` |
| `NOT`  | Negación | `s <= NOT a;` |

```vhdl
SIGNAL a, b, c, y : STD_LOGIC;
y <= (a AND b) OR (NOT c);
```

### 5.2 Relacionales
Devuelven `BOOLEAN`. Se usan en condiciones `IF` y `WHEN`.

| Operador | Significado |
|----------|-------------|
| `=`  | Igual |
| `/=` | Distinto |
| `<`  | Menor que |
| `<=` | Menor o igual |
| `>`  | Mayor que |
| `>=` | Mayor o igual |

```vhdl
IF (contador >= MAX_CUENTA) THEN ...
IF (estado /= ERROR) THEN ...
```

> `<=` se usa también como operador de asignación de señal. El contexto determina
> si es comparación o asignación.

### 5.3 Aritméticos
Requieren `ieee.numeric_std` con tipos `UNSIGNED` o `SIGNED`.

| Operador | Descripción |
|----------|-------------|
| `+` | Suma |
| `-` | Resta |
| `*` | Multiplicación |
| `/` | División (solo potencias de 2 en síntesis) |
| `MOD` | Módulo |
| `REM` | Resto |
| `ABS` | Valor absoluto |

```vhdl
SIGNAL a, b, suma : UNSIGNED(7 DOWNTO 0);
suma <= a + b;
suma <= a - b;
suma <= a * b;  -- el resultado puede necesitar más bits
```

### 5.4 Concatenación y desplazamiento

```vhdl
-- Concatenación con &
SIGNAL hi    : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"AB";
SIGNAL lo    : STD_LOGIC_VECTOR(7 DOWNTO 0) := X"CD";
SIGNAL bytes : STD_LOGIC_VECTOR(15 DOWNTO 0);
bytes <= hi & lo;   -- resultado: X"ABCD"

-- Insertar un bit en la posición más significativa (shift-in)
SIGNAL sreg : STD_LOGIC_VECTOR(7 DOWNTO 0);
sreg <= bit_entrada & sreg(7 DOWNTO 1);  -- desplaza derecha e inserta

-- Desplazamiento con operadores nativos
SIGNAL vec : STD_LOGIC_VECTOR(7 DOWNTO 0);
vec <= vec SLL 1;  -- desplazamiento lógico izquierda (rellena con '0')
vec <= vec SRL 1;  -- desplazamiento lógico derecha  (rellena con '0')
vec <= vec SLA 1;  -- desplazamiento aritmético izq. (rellena con bit[0])
vec <= vec SRA 1;  -- desplazamiento aritmético der. (rellena con MSB)
vec <= vec ROL 1;  -- rotación circular izquierda
vec <= vec ROR 1;  -- rotación circular derecha
```

> **Nota:** los operadores `SLL`/`SRL`/`SLA`/`SRA`/`ROL`/`ROR` tienen soporte
> irregular en herramientas de síntesis. Para máxima compatibilidad (Quartus II 13),
> preferir la concatenación explícita con `&` y slices.

### 5.5 Precedencia de operadores

De mayor a menor prioridad (los de mayor prioridad se evalúan primero):

| Prioridad | Operadores |
|-----------|------------|
| 1 (máxima) | `NOT`, `ABS`, `**` |
| 2 | `*`, `/`, `MOD`, `REM` |
| 3 | `+`, `-` (unarios) |
| 4 | `+`, `-`, `&` |
| 5 | `SLL`, `SRL`, `SLA`, `SRA`, `ROL`, `ROR` |
| 6 | `=`, `/=`, `<`, `<=`, `>`, `>=` |
| 7 | `AND`, `OR`, `NAND`, `NOR`, `XOR`, `XNOR` |

> **Regla práctica:** `AND`, `OR`, `XOR`, etc. tienen la **misma** prioridad en VHDL
> (a diferencia de C o Python). Usar paréntesis siempre que se mezclen:

```vhdl
-- INCORRECTO (ambigüedad, comportamiento inesperado):
y <= a AND b OR c;

-- CORRECTO (explícito):
y <= (a AND b) OR c;
```

---

*[⬆ Volver al Índice](#índice)*

---

## 6. Lógica concurrente vs. secuencial

Una de las diferencias fundamentales entre VHDL y los lenguajes de programación
convencionales es que VHDL describe **hardware que existe físicamente en paralelo**.
Varias puertas, registros y bloques de lógica operan **al mismo tiempo**, no uno
tras otro. El lenguaje refleja esta realidad con dos tipos de sentencias:

- **Sentencias concurrentes:** existen fuera de cualquier proceso. Todas se "ejecutan"
  permanentemente y en paralelo, exactamente como las puertas de un circuito.
- **Sentencias secuenciales:** existen dentro de un `PROCESS`. Se ejecutan en orden,
  pero el proceso completo es, en sí mismo, una entidad concurrente.

La clave es entender que **un proceso es una sentencia concurrente** cuyo contenido
se ejecuta de forma secuencial cuando se activa. Varios procesos coexisten en paralelo
en la arquitectura, pero el interior de cada proceso es algorítmico.

---

### 6.1 Sentencias concurrentes

Las sentencias concurrentes describen **relaciones permanentes** entre señales.
Equivalen a conexiones de hardware: no hay "orden de ejecución", simplemente se
reevalúan cada vez que cambien las señales de las que dependen (igual que una puerta
lógica que reacciona instantáneamente a sus entradas).

**Tipos de sentencias concurrentes en VHDL:**

#### Asignación de señal simple
La forma más directa. Describe una función combinacional pura.

```vhdl
ARCHITECTURE rtl OF logica IS
BEGIN
    -- Estas tres líneas coexisten en paralelo; no hay orden entre ellas
    y1 <= a AND b;
    y2 <= a OR  c;
    y3 <= NOT (a XOR b);  -- en hardware: un inversor alimentado por un XOR
END ARCHITECTURE rtl;
```

#### Asignación condicional (`WHEN ... ELSE`)
Equivale a un **multiplexor con prioridad** (igual que un `IF` secuencial).
La primera condición verdadera gana; las demás se ignoran.

```vhdl
ARCHITECTURE rtl OF mux4 IS
BEGIN
    -- Estructura hardware: árbol de mux 2:1 encadenados
    salida <= a WHEN sel = "00" ELSE
              b WHEN sel = "01" ELSE
              c WHEN sel = "10" ELSE
              d;  -- caso por defecto (equivale al ELSE final)
END ARCHITECTURE rtl;
```

> **Detalle:** la prioridad existe porque el hardware sintetizado es un árbol de
> multiplexores, no lógica paralela. Si todas las condiciones son mutuamente
> excluyentes y no importa el orden, `WITH ... SELECT` es más eficiente.

#### Asignación con selección (`WITH ... SELECT`)
Equivale a un **multiplexor sin prioridad**: todas las ramas son paralelas y
mutuamente excluyentes. Genera hardware más compacto que `WHEN ... ELSE` cuando
todas las condiciones dependen del mismo selector.

```vhdl
WITH sel SELECT
    salida <= a   WHEN "00",
              b   WHEN "01",
              c   WHEN "10",
              d   WHEN "11",
              'X' WHEN OTHERS;  -- obligatorio para STD_LOGIC_VECTOR
```

#### Instancias de componentes y `GENERATE`
También son sentencias concurrentes (ver secciones 4.7 y 4.6).

```vhdl
ARCHITECTURE rtl OF sistema IS
BEGIN
    u1: sumador PORT MAP (...);   -- concurrente: instancia de hardware
    u2: sumador PORT MAP (...);   -- concurrente: otra instancia independiente
    enable <= sel AND cs_n;       -- concurrente: puerta lógica
END ARCHITECTURE rtl;
```

---

### 6.2 Sentencias secuenciales

Las sentencias secuenciales solo pueden aparecer dentro de un `PROCESS`, una
`FUNCTION` o una `PROCEDURE`. Se ejecutan **en orden, línea por línea**, como un
programa de software, pero recordando siempre que el proceso completo es una
unidad concurrente para el resto del diseño.

El sintetizador analiza el comportamiento del proceso para inferir el tipo de hardware:

- Si todas las salidas del proceso dependen solo de sus entradas actuales (sin memoria
  entre activaciones) → **lógica combinacional** (puertas, muxes).
- Si el proceso tiene condiciones sobre `RISING_EDGE(clk)` o `clk'EVENT` → **lógica
  secuencial** (flip-flops, registros).
- Si alguna salida no es asignada en todas las ramas del proceso → **latch** (elemento
  de memoria no controlado por reloj; generalmente un error de diseño).

**Inferencia de combinacional:**

```vhdl
-- El sintetizador infiere 4 multiplexores de 8 bits (uno por bit de salida)
PROCESS(a, b, c, d, sel)  -- TODAS las entradas en la lista
BEGIN
    CASE sel IS
        WHEN "00"   => salida <= a;
        WHEN "01"   => salida <= b;
        WHEN "10"   => salida <= c;
        WHEN OTHERS => salida <= d;
    END CASE;
END PROCESS;
```

**Inferencia de registros:**

```vhdl
-- El sintetizador infiere N flip-flops D con enable y reset
PROCESS(clk, reset)
BEGIN
    IF reset = '1' THEN
        q <= (OTHERS => '0');       -- FF con reset asíncrono activo-alto
    ELSIF RISING_EDGE(clk) THEN
        IF enable = '1' THEN
            q <= d;                 -- FF con clock-enable
        END IF;
    END IF;
END PROCESS;
```

**Inferencia de latch (normalmente NO deseado):**

```vhdl
-- ¡CUIDADO! salida no se asigna cuando sel = "10" → latch inferido
PROCESS(a, b, sel)
BEGIN
    IF sel = "00" THEN
        salida <= a;        -- asignado
    ELSIF sel = "01" THEN
        salida <= b;        -- asignado
    -- sel = "10" y "11": salida no se asigna → el sintetizador infiere un latch
    END IF;
END PROCESS;

-- CORRECCIÓN: asignar un valor por defecto al inicio del proceso
PROCESS(a, b, sel)
BEGIN
    salida <= '0';          -- valor por defecto SIEMPRE se asigna primero
    IF sel = "00" THEN
        salida <= a;
    ELSIF sel = "01" THEN
        salida <= b;
    END IF;
    -- Ahora para sel = "10" y "11", salida toma el valor por defecto '0'
END PROCESS;
```

---

### 6.3 Comunicación entre procesos

Los procesos se comunican entre sí **exclusivamente a través de señales**. Un proceso
no puede leer ni escribir las variables de otro proceso. Este diseño refleja la
realidad del hardware: los módulos se comunican por conductores, no por memoria
compartida.

```vhdl
ARCHITECTURE rtl OF pipeline IS
    SIGNAL etapa1_out : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- señal de comunicación
    SIGNAL etapa2_out : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
    -- Proceso 1: primera etapa del pipeline
    p_etapa1: PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            etapa1_out <= transformar(entrada);   -- escribe la señal compartida
        END IF;
    END PROCESS p_etapa1;

    -- Proceso 2: segunda etapa (depende de la salida del proceso 1)
    p_etapa2: PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            etapa2_out <= procesar(etapa1_out);   -- lee la señal compartida
        END IF;
    END PROCESS p_etapa2;
    -- etapa1_out actúa como el registro intermedio del pipeline
END ARCHITECTURE rtl;
```

> **Regla importante:** una señal solo debe ser **escrita** (driver) por **un único**
> proceso o sentencia concurrente. Si dos procesos asignan la misma señal, es un
> error de driver múltiple (múltiples conductores en conflicto). Excepción: señales
> de tipo `STD_LOGIC` con lógica de resolución (buses tri-estado con `'Z'`).

---

### 6.4 Resumen: guía de elección

| Criterio | Usar sentencia concurrente | Usar PROCESS secuencial |
|---|---|---|
| Lógica combinacional simple | `<=`, `WHEN ELSE`, `WITH SELECT` | OK también, pero es más verboso |
| Lógica con múltiples condiciones | `WHEN ELSE` (pocos casos) | `IF`/`CASE` dentro de proceso |
| Lógica secuencial (registros, FF) | No posible directamente | **Obligatorio con PROCESS** |
| Máquina de estados (FSM) | No recomendado | **Obligatorio con PROCESS + CASE** |
| Cálculo de múltiples pasos encadenados | Difícil (múltiples señales intermedias) | **Preferir PROCESS con VARIABLE** |
| Instanciar componentes | `PORT MAP` (es concurrente) | No aplica |
| Replicar hardware (N instancias) | `GENERATE` | No aplica |

> **Regla general:** si el hardware que describes tiene **memoria** (necesita recordar
> un valor de un ciclo al siguiente), usa un `PROCESS` con `RISING_EDGE(clk)`.
> Si es **puramente combinacional**, puedes usar sentencias concurrentes o un proceso
> combinacional, a gusto del diseñador.

---

*[⬆ Volver al Índice](#índice)*
