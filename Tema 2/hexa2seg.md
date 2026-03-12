# Decodificador de Hexadecimal a 7 Segmentos (hexa2seg)

## Descripción
Este circuito combinacional es un decodificador que convierte una entrada binaria de 4 bits (representando un dígito hexadecimal de 0 a F) en las 7 señales de control necesarias para encender los segmentos correspondientes de un display de 7 segmentos. 

## Puertos
| Nombre | Dirección | Tamaño | Descripción |
| :--- | :--- | :--- | :--- |
| `d3`, `d2`, `d1`, `d0` | `IN` | 1 bit c/u | Entradas de datos binarios (formando el número hexadecimal). |
| `a`, `b`, `c`, `d`, `e`, `f`, `g` | `OUT` | 1 bit c/u | Salidas de control para cada segmento del display. |

## Detalles de Implementación
El decodificador está implementado utilizando un bloque `process` que evalúa la combinación de las entradas mediante una sentencia `case`. La lógica de salida asume un display de **ánodo común** o de lógica invertida, donde un `0` lógico enciende el segmento y un `1` lógico lo apaga.

- Ejemplo: Para la entrada `"0000"`, la salida es `"0000001"`, lo que significa que todos los segmentos (a,b,c,d,e,f) se encienden, excepto el segmento central (g), formando así el número '0'.

El archivo incluye la asignación directa de pines (atributos `chip_pin`) para una placa de desarrollo específica, vinculando las entradas a interruptores (SW6 a SW9) y las salidas a los pines del display 3.
