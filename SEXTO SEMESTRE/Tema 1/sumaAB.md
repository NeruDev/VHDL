# Documentación: Sumador de 4 bits (sumaAB.vhd)

## Descripción
El archivo `sumaAB.vhd` describe un circuito combinacional que realiza la suma binaria sin signo de dos operandos de 4 bits (`A + B`). Produce un resultado de 4 bits y un bit de acarreo (carry).

## Interfaz (Puertos)
*   **A (4 bits):** Primer sumando.
*   **B (4 bits):** Segundo sumando.
*   **S (4 bits):** Resultado de la suma (4 bits menos significativos).
*   **C (1 bit):** Bit de acarreo (carry out). Se activa cuando la suma excede el valor máximo representable en 4 bits (15).

## Funcionamiento Interno
El diseño extiende ambos operandos a 5 bits (añadiendo un `'0'` como bit más significativo) para capturar el acarreo en el bit extra:

```vhdl
SS <= STD_LOGIC_VECTOR(UNSIGNED('0' & A) + UNSIGNED('0' & B));

S <= SS(3 DOWNTO 0);  -- Resultado de 4 bits
C <= SS(4);            -- Bit de acarreo (carry)
```

La señal interna `SS` de 5 bits almacena el resultado completo. Los 4 bits inferiores forman la salida `S` y el bit superior indica el acarreo.

## Ejemplo de Operación

| A | B | S (A+B) | C (Carry) | Interpretación |
|:---:|:---:|:---:|:---:|:---|
| `0011` (3) | `0100` (4) | `0111` (7) | 0 | 3 + 4 = 7 (sin acarreo) |
| `1000` (8) | `0111` (7) | `1111` (15) | 0 | 8 + 7 = 15 (sin acarreo) |
| `1000` (8) | `1000` (8) | `0000` (0) | 1 | 8 + 8 = 16 → acarreo |
| `1111` (15) | `0001` (1) | `0000` (0) | 1 | 15 + 1 = 16 → acarreo |
| `1111` (15) | `1111` (15) | `1110` (14) | 1 | 15 + 15 = 30 → acarreo |

### Observaciones
1.  **Bit de acarreo (C):** Cuando `C = '1'`, la suma ha excedido el rango de 4 bits (resultado mayor a 15). El valor completo sería `{C, S}` = 5 bits.
2.  La extensión a 5 bits (`'0' & A`) es una técnica estándar para detectar el acarreo sin perder información del resultado.
3.  Este diseño es el complemento directo del restador `restaAB.vhd`, con la única diferencia del operador (`+` en lugar de `-`).
