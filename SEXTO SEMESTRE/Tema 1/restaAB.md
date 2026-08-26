# Documentación: Restador de 4 bits (restaAB.vhd)

## Descripción
El archivo `restaAB.vhd` describe un circuito combinacional que realiza la resta binaria sin signo de dos operandos de 4 bits (`A − B`). Produce un resultado de 4 bits y un bit de préstamo (borrow).

## Interfaz (Puertos)
*   **A (4 bits):** Minuendo (operando del cual se resta).
*   **B (4 bits):** Sustraendo (operando que se resta).
*   **S (4 bits):** Resultado de la resta (4 bits menos significativos).
*   **C (1 bit):** Bit de préstamo (borrow). Indica si `B > A`, es decir, si el resultado es negativo en aritmética sin signo.

## Funcionamiento Interno
El diseño extiende ambos operandos a 5 bits (añadiendo un `'0'` como bit más significativo) para capturar el préstamo en el bit extra:

```vhdl
SS <= STD_LOGIC_VECTOR(UNSIGNED('0' & A) - UNSIGNED('0' & B));

S <= SS(3 DOWNTO 0);  -- Resultado de 4 bits
C <= SS(4);            -- Bit de préstamo (borrow)
```

La señal interna `SS` de 5 bits almacena el resultado completo. Los 4 bits inferiores forman la salida `S` y el bit superior indica el préstamo.

## Ejemplo de Operación

| A | B | S (A−B) | C (Borrow) | Interpretación |
|:---:|:---:|:---:|:---:|:---|
| `0111` (7) | `0011` (3) | `0100` (4) | 0 | 7 − 3 = 4 (sin préstamo) |
| `1010` (10) | `0101` (5) | `0101` (5) | 0 | 10 − 5 = 5 (sin préstamo) |
| `0011` (3) | `0111` (7) | `1100` (12) | 1 | 3 − 7 → préstamo, resultado en complemento a 2 |
| `0000` (0) | `0001` (1) | `1111` (15) | 1 | 0 − 1 → préstamo |
| `0101` (5) | `0101` (5) | `0000` (0) | 0 | 5 − 5 = 0 (sin préstamo) |

### Observaciones
1.  **Bit de préstamo (C):** Cuando `C = '1'`, el resultado de la resta es negativo en aritmética sin signo. El valor en `S` corresponde al complemento a 2 del resultado real.
2.  La extensión a 5 bits (`'0' & A`) es una técnica estándar para detectar el préstamo sin perder información del resultado.
3.  Este diseño es el complemento directo del sumador `sumaAB.vhd`, con la única diferencia del operador (`-` en lugar de `+`).
