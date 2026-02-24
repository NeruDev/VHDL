# Documentación: Consulta de Dígito por Posición en Matrícula (queestaenpos23280651.vhd)

## Descripción
El archivo `queestaenpos23280651.vhd` describe un circuito combinacional que, dada una posición (0–7), devuelve el dígito correspondiente de la matrícula **23280651**. Adicionalmente, indica si el dígito en esa posición se repite en otra posición de la matrícula.

## Interfaz (Puertos)
*   **POSICION (3 bits):** Posición a consultar dentro de la matrícula (0–7).
*   **DIGITO (4 bits):** Dígito almacenado en la posición consultada, representado en binario.
*   **REPITE (1 bit):** Indicador de repetición. `'1'` si el dígito aparece en más de una posición de la matrícula.

## Funcionamiento Interno
La matrícula **23280651** se mapea de la siguiente forma:

| Posición | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **Dígito** | 2 | 3 | 2 | 8 | 0 | 6 | 5 | 1 |

> **Nota:** El mapeo del código sigue un orden interno distinto al natural de la matrícula. Las posiciones en el `CASE` no corresponden directamente a las posiciones mostradas arriba.

El diseño emplea un `PROCESS` con estructura `CASE` que evalúa `POSICION`:

```vhdl
CASE POSICION IS
   WHEN "000" => DIGITO <= "0001"; REPITE <= '0'; -- Pos 0: 1
   WHEN "001" => DIGITO <= "0101"; REPITE <= '0'; -- Pos 1: 5
   WHEN "010" => DIGITO <= "0110"; REPITE <= '0'; -- Pos 2: 6
   WHEN "011" => DIGITO <= "0000"; REPITE <= '0'; -- Pos 3: 0
   WHEN "100" => DIGITO <= "1000"; REPITE <= '0'; -- Pos 4: 8
   WHEN "101" => DIGITO <= "0010"; REPITE <= '1'; -- Pos 5: 2 (repetido)
   WHEN "110" => DIGITO <= "0011"; REPITE <= '0'; -- Pos 6: 3
   WHEN "111" => DIGITO <= "0010"; REPITE <= '1'; -- Pos 7: 2 (repetido)
   WHEN OTHERS => DIGITO <= "0000"; REPITE <= '0';
END CASE;
```

## Tabla de Consulta

| POSICION | DIGITO (Binario) | DIGITO (Decimal) | REPITE | Observación |
|:---:|:---:|:---:|:---:|:---|
| `000` (0) | `0001` | 1 | 0 | Único |
| `001` (1) | `0101` | 5 | 0 | Único |
| `010` (2) | `0110` | 6 | 0 | Único |
| `011` (3) | `0000` | 0 | 0 | Único |
| `100` (4) | `1000` | 8 | 0 | Único |
| `101` (5) | `0010` | 2 | 1 | Repetido en posición 7 |
| `110` (6) | `0011` | 3 | 0 | Único |
| `111` (7) | `0010` | 2 | 1 | Repetido en posición 5 |

### Observaciones
1.  **Dígito repetido:** El número **2** aparece en las posiciones 5 y 7. En ambos casos, `REPITE = '1'` para señalar la duplicación.
2.  Este circuito es complementario a `estaen23280651.vhd`, que realiza la búsqueda inversa (dado un dígito, indica si está y en qué posición).
3.  Con 3 bits de entrada se cubren las 8 posiciones de la matrícula completa (posiciones 0–7).
