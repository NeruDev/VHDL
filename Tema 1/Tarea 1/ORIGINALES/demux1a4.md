# Documentación: Demultiplexor 1 a 4 — Original (demux1a4.vhd)

## Descripción
El archivo `demux1a4.vhd` (versión original del profesor) describe un demultiplexor de 1 entrada y 4 salidas, implementado con **ocho arquitecturas** diferentes que cubren exhaustivamente los estilos de codificación VHDL, incluyendo variantes con buenas prácticas de asignación por defecto.

## Interfaz (Puertos)
*   **x (1 bit):** Entrada de datos del demultiplexor.
*   **s (2 bits):** Selector que determina a cuál salida se dirige la entrada.
    *   `00`: Salida `a`.
    *   `01`: Salida `b`.
    *   `10`: Salida `c`.
    *   `11`: Salida `d`.
*   **a, b, c, d (1 bit c/u):** Salidas del demultiplexor. Solo la seleccionada toma el valor de `x`; las demás permanecen en `'0'`.

## Arquitecturas Implementadas

### Arquitectura UNA — Flujo de datos (Ecuaciones)
Ecuaciones booleanas directas con `AND` y `NOT`.

### Arquitectura DOS — Asignación condicional (WHEN-ELSE)
Cada salida se asigna condicionalmente con `WHEN ... ELSE`.

### Arquitectura TRES — Asignación selectiva (WITH-SELECT)
Un `WITH s SELECT` separado para cada salida.

### Arquitectura CUATRO — PROCESS con asignación simple
Ecuaciones booleanas dentro de un bloque `PROCESS`.

### Arquitectura CINCO — PROCESS con IF-ELSE
Estructura `IF ... ELSIF` con asignación explícita de `'0'` a todas las salidas no seleccionadas en cada rama.

### Arquitectura CINCOA — PROCESS con IF-ELSE (Buenas prácticas)
Mejora de la arquitectura CINCO: se asignan valores por defecto (`'0'`) a todas las salidas al inicio del proceso y luego solo se modifica la salida seleccionada. Esto reduce código repetitivo y evita latches inferenciales:

```vhdl
-- Valores por defecto
a <= '0'; b <= '0'; c <= '0'; d <= '0';
-- Solo se modifica la que cambia
IF s = "00" THEN a <= x;
ELSIF s = "01" THEN b <= x;
...
```

### Arquitectura SEIS — PROCESS con CASE
Estructura `CASE s IS` con asignación explícita en cada rama.

### Arquitectura SEISA — PROCESS con CASE (Buenas prácticas)
Versión mejorada de SEIS con valores por defecto. Misma filosofía que CINCOA.

## Tabla de Verdad

| s(1) | s(0) | a | b | c | d |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 0 | 0 | x | 0 | 0 | 0 |
| 0 | 1 | 0 | x | 0 | 0 |
| 1 | 0 | 0 | 0 | x | 0 |
| 1 | 1 | 0 | 0 | 0 | x |

## Configuración
Actualmente configurada para usar la arquitectura `SEIS` (PROCESS con CASE).

### Observaciones
1.  Las ocho arquitecturas son funcionalmente equivalentes y sirven como ejemplo didáctico de los distintos estilos.
2.  **Buenas prácticas (CINCOA, SEISA):** Asignar valores por defecto al inicio de un `PROCESS` antes de las condiciones es una técnica recomendada. Reduce líneas de código, minimiza errores y previene la inferencia accidental de latches en síntesis.
3.  Este archivo es la versión original proporcionada por el profesor. La versión en la raíz de `Tema 1/` es una versión simplificada con solo tres arquitecturas.
