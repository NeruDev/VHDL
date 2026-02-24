# Documentación: Desplazador de Barril (sbarril.vhd)

## Descripción
El archivo `sbarril.vhd` describe un circuito combinacional que realiza la rotación de un vector de 4 bits (`ENTRADA`). A diferencia de un desplazamiento lógico donde los bits se pierden, en una rotación los bits que salen por un extremo reingresan por el opuesto.

## Interfaz (Puertos)
*   **ENTRADA (4 bits):** Vector de datos original.
*   **SENTIDO (1 bit):** Control de dirección.
    *   `0`: Derecha (Sentido Horario).
    *   `1`: Izquierda (Sentido Antihorario).
*   **ROTAR (2 bits):** Cantidad de desplazamientos.
    *   `00`: 0 posiciones.
    *   `01`: 1 posición.
    *   `10`: 2 posiciones.
    *   `11`: 3 posiciones.
*   **SALIDA (4 bits):** Resultado de la rotación.

## Funcionamiento Interno
El diseño utiliza una señal interna `control` de 3 bits, formada por la concatenación de `SENTIDO` y `ROTAR`:

```vhdl
control <= SENTIDO & ROTAR;
```

Esta señal alimenta una estructura `WITH ... SELECT` que actúa como un multiplexor de 8 a 1. La rotación se implementa reordenando los índices del vector de entrada mediante el operador de concatenación (`&`).

## Tabla de Verdad y Lógica

| SENTIDO | ROTAR | Control (Binario) | Operación Realizada | Lógica VHDL (Reordenamiento) |
|:---:|:---:|:---:|:---|:---|
| 0 | 00 | **000** | Derecha 0 (Identidad) | `ENTRADA` |
| 0 | 01 | **001** | Derecha 1 posición | `ENTRADA(0) & ENTRADA(3 DOWNTO 1)` |
| 0 | 10 | **010** | Derecha 2 posiciones | `ENTRADA(1 DOWNTO 0) & ENTRADA(3 DOWNTO 2)` |
| 0 | 11 | **011** | Derecha 3 posiciones | `ENTRADA(2 DOWNTO 0) & ENTRADA(3)` |
| 1 | 00 | **100** | Izquierda 0 (Identidad) | `ENTRADA` |
| 1 | 01 | **101** | Izquierda 1 posición | `ENTRADA(2 DOWNTO 0) & ENTRADA(3)` |
| 1 | 10 | **110** | Izquierda 2 posiciones | `ENTRADA(1 DOWNTO 0) & ENTRADA(3 DOWNTO 2)` |
| 1 | 11 | **111** | Izquierda 3 posiciones | `ENTRADA(0) & ENTRADA(3 DOWNTO 1)` |

### Observaciones
1.  **Equivalencias:** En un barril de 4 bits, rotar 1 a la izquierda es equivalente a rotar 3 a la derecha. El código aprovecha esto usando la misma lógica de concatenación para casos equivalentes (ej. `011` y `101`).
2.  **Caso de 2 posiciones:** La lógica para `010` y `110` es idéntica, ya que rotar media vuelta (2 de 4) produce el mismo resultado en ambos sentidos.