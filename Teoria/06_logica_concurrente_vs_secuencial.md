<!--
---
file: Teoria/06_logica_concurrente_vs_secuencial.md
description: Comparación exhaustiva entre lógica concurrente y secuencial, asignaciones y latches
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [concurrente, secuencial, when-else, with-select, latches, vhdl]
---
-->

# Lógica concurrente vs. secuencial

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

---
