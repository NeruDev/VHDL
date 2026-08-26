# Documentación: Contador de 0's y 1's (cuenta0y1.vhd)

## Descripción
El archivo `cuenta0y1.vhd` describe un circuito combinacional que cuenta la cantidad de bits en `'0'` y la cantidad de bits en `'1'` presentes en un vector de entrada de 8 bits. Los resultados se entregan como vectores de 4 bits, lo que permite representar valores de 0 a 8.

## Interfaz (Puertos)
*   **ENT (8 bits):** Vector de entrada cuyos bits serán contabilizados.
*   **CUENTA0 (4 bits):** Cantidad de bits en `'0'` encontrados en `ENT`.
*   **CUENTA1 (4 bits):** Cantidad de bits en `'1'` encontrados en `ENT`.

## Funcionamiento Interno
El diseño utiliza un bloque `PROCESS` sensible a `ENT` que recorre cada bit del vector de entrada mediante un bucle `FOR ... LOOP`:

```vhdl
FOR I IN ENT'RANGE LOOP
   IF ENT(I) = '0' THEN
      CNT0 := CNT0 + 1;
   ELSE
      CNT1 := CNT1 + 1;
   END IF;
END LOOP;
```

Se emplean **variables** (`CNT0`, `CNT1`) en lugar de señales, ya que las variables se actualizan inmediatamente dentro del proceso, permitiendo la acumulación correcta en cada iteración del bucle. Las señales, por el contrario, solo se actualizan al finalizar el proceso.

Los contadores se inicializan a 0 al inicio de cada ejecución del proceso para evitar acumulaciones residuales. Finalmente, los resultados se convierten de entero a `STD_LOGIC_VECTOR` mediante `TO_UNSIGNED`.

## Ejemplo de Operación

| ENT (8 bits) | CUENTA1 | CUENTA0 |
|:---:|:---:|:---:|
| `00000000` | 0 (`0000`) | 8 (`1000`) |
| `11111111` | 8 (`1000`) | 0 (`0000`) |
| `10101010` | 4 (`0100`) | 4 (`0100`) |
| `11100001` | 4 (`0100`) | 4 (`0100`) |
| `10000000` | 1 (`0001`) | 7 (`0111`) |

### Observaciones
1.  **Variables vs. Señales:** El uso de variables es fundamental en este diseño. Si se usaran señales para `CNT0` y `CNT1`, el bucle no acumularía correctamente, ya que la señal solo retiene la última asignación del proceso.
2.  **Invariante:** Para cualquier entrada de 8 bits, siempre se cumple que `CUENTA0 + CUENTA1 = 8`.
3.  La salida de 4 bits permite representar hasta 15, pero los valores reales nunca superan 8 (el ancho de la entrada).
