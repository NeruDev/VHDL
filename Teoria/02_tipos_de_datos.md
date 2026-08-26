<!--
---
file: Teoria/02_tipos_de_datos.md
description: Tipos de datos escalares, vectoriales, enumerados, arreglos y conversiones en VHDL
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [tipos-datos, std-logic, vector, signed, unsigned, vhdl]
---
-->

# Tipos de datos

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
