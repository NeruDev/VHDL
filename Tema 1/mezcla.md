# Documentación: Operador Condicional Mezcla (mezcla.vhd)

## Descripción
El archivo `mezcla.vhd` describe un circuito combinacional que realiza una operación aritmética condicional entre dos vectores de 4 bits (`A` y `B`). La operación depende de la comparación entre ambos operandos: resta si `A > B`, suma si `A < B`, y devuelve cero si son iguales.

## Interfaz (Puertos)
*   **A (4 bits):** Primer operando de entrada (sin signo, rango 0–15).
*   **B (4 bits):** Segundo operando de entrada (sin signo, rango 0–15).
*   **RES (4 bits):** Resultado de la operación condicional.

## Funcionamiento Interno
El diseño utiliza un bloque `PROCESS` con variables internas de tipo `UNSIGNED` para realizar las comparaciones y operaciones aritméticas:

```vhdl
UA := UNSIGNED(A);
UB := UNSIGNED(B);

IF UA > UB THEN
   RES <= STD_LOGIC_VECTOR(UA - UB);   -- Resta
ELSIF UA < UB THEN
   RES <= STD_LOGIC_VECTOR(UA + UB);   -- Suma
ELSE
   RES <= (OTHERS => '0');              -- Cero
END IF;
```

Las entradas se convierten a `UNSIGNED` para permitir comparaciones y operaciones aritméticas. El resultado se convierte de vuelta a `STD_LOGIC_VECTOR` para la salida.

## Tabla de Operación

| Condición | Operación | RES |
|:---|:---|:---:|
| A > B | Resta | A − B |
| A < B | Suma | A + B |
| A = B | Identidad cero | 0000 |

## Ejemplo de Operación

| A | B | Condición | RES |
|:---:|:---:|:---|:---:|
| `1010` (10) | `0011` (3) | A > B → Resta | `0111` (7) |
| `0010` (2) | `0101` (5) | A < B → Suma | `0111` (7) |
| `0110` (6) | `0110` (6) | A = B → Cero | `0000` (0) |
| `1111` (15) | `0001` (1) | A > B → Resta | `1110` (14) |
| `0001` (1) | `1111` (15) | A < B → Suma | `0000` (0)* |

> *\*Nota: La suma 1 + 15 = 16, pero al tener solo 4 bits de salida, se produce un desbordamiento (overflow) y el resultado queda truncado a los 4 bits menos significativos.*

### Observaciones
1.  **Desbordamiento:** Cuando `A < B` y la suma `A + B` excede 15 (el máximo para 4 bits sin signo), se produce un truncamiento. El resultado muestra solo los 4 bits menos significativos.
2.  El circuito combina comparación y aritmética en una sola entidad, útil como bloque funcional en diseños más complejos.
3.  La conversión a `UNSIGNED` es necesaria porque `STD_LOGIC_VECTOR` no tiene semántica aritmética por sí solo.
