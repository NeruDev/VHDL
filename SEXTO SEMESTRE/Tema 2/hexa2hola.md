# Decodificador de Mensajes en 7 Segmentos (hexa2hola)

## Descripción
Este diseño es una variación del decodificador de 7 segmentos tradicional. En lugar de limitarse a mostrar números, este decodificador mapea combinaciones de 4 bits a patrones específicos para formar palabras y símbolos en el display, destacando la flexibilidad de la lógica combinacional.

## Puertos
| Nombre | Dirección | Tamaño | Descripción |
| :--- | :--- | :--- | :--- |
| `d3`, `d2`, `d1`, `d0` | `IN` | 1 bit c/u | Entradas de selección del carácter o patrón. |
| `a`, `b`, `c`, `d`, `e`, `f`, `g` | `OUT` | 1 bit c/u | Salidas para controlar los segmentos del display. |

## Tabla de Mapeo (Comportamiento)
Dependiendo de la entrada binaria, el display mostrará los siguientes caracteres o patrones (usando lógica donde `0` enciende el segmento):

- **Caracteres para la palabra "HOLA":**
  - `0000` &rarr; 'H'
  - `0001`, `0110` &rarr; 'O'
  - `0010`, `0101`, `0111` &rarr; 'L'
  - `0011`, `1000` &rarr; 'A'
- **Otros patrones:**
  - `0100` &rarr; Apagado completo (Espacio vacío).
  - `1001` a `1100` &rarr; Muestra las esquinas individuales del display.
  - `1101` a `1111` &rarr; Muestra segmentos horizontales (arriba, abajo, central).

## Detalles de Implementación
El código utiliza concatenación (`d3 & d2 & d1 & d0`) para formar un vector de 4 bits y evaluarlo dentro de una estructura `case`. Al igual que `hexa2seg`, incluye atributos de configuración de pines (`chip_pin`) para conectar directamente la entidad con las entradas y salidas físicas de la placa de desarrollo FPGA de manera predeterminada en Quartus.
