# Documentación: Multiplexor 4 a 1 — Original (mux4a1.vhd)

## Descripción
El archivo `mux4a1.vhd` (versión original del profesor) describe un multiplexor de 4 entradas y 1 salida, implementado con **seis arquitecturas** diferentes que cubren los principales estilos de codificación VHDL: flujo de datos, concurrente condicional, concurrente selectiva, y secuencial con `PROCESS`.

## Interfaz (Puertos)
*   **a, b, c, d (1 bit c/u):** Entradas de datos del multiplexor.
*   **s (2 bits):** Selector que determina qué entrada se conecta a la salida.
    *   `00`: Selecciona `a`.
    *   `01`: Selecciona `b`.
    *   `10`: Selecciona `c`.
    *   `11`: Selecciona `d`.
*   **x (1 bit):** Salida del multiplexor.

## Arquitecturas Implementadas

### Arquitectura UNA — Flujo de datos (Ecuaciones)
Ecuaciones booleanas directas con `AND`, `OR`, `NOT`.

### Arquitectura DOS — Asignación condicional (WHEN-ELSE)
Sentencias concurrentes `WHEN ... ELSE` encadenadas.

### Arquitectura TRES — Asignación selectiva (WITH-SELECT)
Mapeo con `WITH s SELECT` de cada valor del selector a una entrada.

### Arquitectura CUATRO — PROCESS con asignación simple
Ecuaciones booleanas dentro de un bloque `PROCESS` con lista sensible `(a, b, c, d, s)`.

### Arquitectura CINCO — PROCESS con IF-ELSE
Estructura condicional `IF ... ELSIF ... ELSE` dentro de un `PROCESS`.

### Arquitectura SEIS — PROCESS con CASE
Estructura `CASE s IS` dentro de un `PROCESS`, evaluando cada valor posible del selector:

```vhdl
CASE s IS
    WHEN "00" => x <= a;
    WHEN "01" => x <= b;
    WHEN "10" => x <= c;
    WHEN "11" => x <= d;
    WHEN OTHERS => x <= '0';
END CASE;
```

## Tabla de Verdad

| s(1) | s(0) | x |
|:---:|:---:|:---:|
| 0 | 0 | a |
| 0 | 1 | b |
| 1 | 0 | c |
| 1 | 1 | d |

## Configuración
Actualmente configurada para usar la arquitectura `SEIS` (PROCESS con CASE).

### Observaciones
1.  Las seis arquitecturas son funcionalmente equivalentes y sirven como ejemplo didáctico de los distintos estilos de codificación VHDL.
2.  Las arquitecturas CUATRO, CINCO y SEIS utilizan `PROCESS`, lo que las convierte en descripciones secuenciales (comportamentales), a diferencia de las tres primeras que son concurrentes.
3.  Este archivo es la versión original proporcionada por el profesor. La versión en la raíz de `Tema 1/` es una versión simplificada con solo tres arquitecturas.
