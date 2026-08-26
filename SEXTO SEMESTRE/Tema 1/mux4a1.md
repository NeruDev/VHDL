# Documentación: Multiplexor 4 a 1 (mux4a1.vhd)

## Descripción
El archivo `mux4a1.vhd` describe un circuito combinacional que implementa un multiplexor de 4 entradas y 1 salida. Selecciona una de las cuatro señales de entrada (`a`, `b`, `c`, `d`) y la envía a la salida `X`, según el valor de un selector de 2 bits.

## Interfaz (Puertos)
*   **a, b, c, d (1 bit c/u):** Entradas de datos del multiplexor.
*   **s (2 bits):** Selector que determina qué entrada se conecta a la salida.
    *   `00`: Selecciona `a`.
    *   `01`: Selecciona `b`.
    *   `10`: Selecciona `c`.
    *   `11`: Selecciona `d`.
*   **X (1 bit):** Salida del multiplexor.

## Arquitecturas Implementadas
El diseño presenta **tres arquitecturas** distintas que resuelven la misma función lógica con diferentes estilos de codificación VHDL:

### Arquitectura UNA — Flujo de datos (Ecuaciones)
Implementa la función del multiplexor directamente mediante ecuaciones booleanas con operadores `AND`, `OR` y `NOT`:

```vhdl
X <= (NOT s(1) AND NOT s(0) AND a) OR
     (NOT s(1) AND s(0) AND b) OR
     (s(1) AND NOT s(0) AND c) OR
     (s(1) AND s(0) AND d);
```

### Arquitectura DOS — Asignación condicional (WHEN-ELSE)
Utiliza la sentencia concurrente `WHEN ... ELSE` para evaluar el selector de forma encadenada:

```vhdl
X <= A WHEN S = "00" ELSE
     B WHEN S = "01" ELSE
     C WHEN S = "10" ELSE
     D WHEN S = "11" ELSE
     '0';
```

### Arquitectura TRES — Asignación selectiva (WITH-SELECT)
Emplea `WITH ... SELECT` para mapear cada valor del selector a una entrada:

```vhdl
WITH S SELECT
X <= A WHEN "00",
     B WHEN "01",
     C WHEN "10",
     D WHEN "11",
     '0' WHEN OTHERS;
```

## Tabla de Verdad

| s(1) | s(0) | X |
|:---:|:---:|:---:|
| 0 | 0 | a |
| 0 | 1 | b |
| 1 | 0 | c |
| 1 | 1 | d |

## Configuración
Se utiliza un bloque `CONFIGURATION` para seleccionar la arquitectura activa. Actualmente está configurada para usar la arquitectura `DOS` (WHEN-ELSE).

### Observaciones
1.  Las tres arquitecturas son funcionalmente equivalentes y producen el mismo comportamiento en simulación y síntesis.
2.  La arquitectura con ecuaciones booleanas (UNA) refleja directamente la lógica a nivel de compuertas.
3.  Las arquitecturas DOS y TRES son más legibles y se prefieren en diseños de mayor complejidad.
