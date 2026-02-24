# Documentación: Demultiplexor 1 a 4 (demux1a4.vhd)

## Descripción
El archivo `demux1a4.vhd` describe un circuito combinacional que implementa un demultiplexor de 1 entrada y 4 salidas. Dirige la señal de entrada `x` hacia una de las cuatro salidas (`a`, `b`, `c`, `d`) según el valor de un selector de 2 bits. Las salidas no seleccionadas permanecen en `'0'`.

## Interfaz (Puertos)
*   **x (1 bit):** Entrada de datos del demultiplexor.
*   **s (2 bits):** Selector que determina a cuál salida se dirige la entrada.
    *   `00`: Salida `a`.
    *   `01`: Salida `b`.
    *   `10`: Salida `c`.
    *   `11`: Salida `d`.
*   **a, b, c, d (1 bit c/u):** Salidas del demultiplexor.

## Arquitecturas Implementadas
El diseño presenta **tres arquitecturas** con diferentes estilos de codificación VHDL:

### Arquitectura UNA — Flujo de datos (Ecuaciones en PROCESS)
Implementa la lógica del demultiplexor con ecuaciones booleanas dentro de un bloque `PROCESS`:

```vhdl
a <= x AND NOT s(1) AND NOT s(0);
b <= x AND NOT s(1) AND s(0);
c <= x AND s(1) AND NOT s(0);
d <= x AND s(1) AND s(0);
```

### Arquitectura DOS — Asignación condicional (WHEN-ELSE)
Cada salida se asigna condicionalmente según el valor del selector:

```vhdl
a <= x WHEN s = "00" ELSE '0';
b <= x WHEN s = "01" ELSE '0';
c <= x WHEN s = "10" ELSE '0';
d <= x WHEN s = "11" ELSE '0';
```

### Arquitectura TRES — Asignación selectiva (WITH-SELECT)
Emplea `WITH ... SELECT` individual para cada salida:

```vhdl
WITH s SELECT
    a <= x WHEN "00",
         '0' WHEN OTHERS;
-- (análogamente para b, c, d)
```

## Tabla de Verdad

| s(1) | s(0) | a | b | c | d |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 0 | 0 | x | 0 | 0 | 0 |
| 0 | 1 | 0 | x | 0 | 0 |
| 1 | 0 | 0 | 0 | x | 0 |
| 1 | 1 | 0 | 0 | 0 | x |

## Configuración
Se utiliza un bloque `CONFIGURATION` para seleccionar la arquitectura activa. Actualmente está configurada para usar la arquitectura `DOS` (WHEN-ELSE).

### Observaciones
1.  A diferencia de un multiplexor (muchas entradas → una salida), el demultiplexor realiza la operación inversa (una entrada → muchas salidas).
2.  Las tres arquitecturas son funcionalmente equivalentes.
3.  Se necesita un `WITH ... SELECT` separado para cada salida en la arquitectura TRES, ya que cada salida depende del mismo selector pero tiene un valor diferente.
