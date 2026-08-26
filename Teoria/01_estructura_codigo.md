<!--
---
file: Teoria/01_estructura_codigo.md
description: Estructura estándar del código VHDL (librerías, entidad, arquitectura y genéricos)
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [librerias, entidad, arquitectura, genericos, vhdl]
---
-->

# Estructura estándar del código

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

*[⬆ Volver al Índice](README.md)*

---
