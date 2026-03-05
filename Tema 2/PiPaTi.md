# Documentación: Piedra, Papel o Tijera (PiPaTi.vhd)

## Descripción
El archivo `PiPaTi.vhd` describe un circuito combinacional que implementa la lógica del juego "Piedra, Papel o Tijera" para dos jugadores (A y B). El sistema valida las entradas para asegurar que cada jugador seleccione exactamente una opción (codificación *one-hot*) y determina el ganador, un empate o un estado de error.

## Interfaz (Puertos)
*   **Entradas Jugador A:**
    *   `A_Pi` (1 bit): Jugador A selecciona Piedra.
    *   `A_Pa` (1 bit): Jugador A selecciona Papel.
    *   `A_Ti` (1 bit): Jugador A selecciona Tijera.
*   **Entradas Jugador B:**
    *   `B_Pi` (1 bit): Jugador B selecciona Piedra.
    *   `B_Pa` (1 bit): Jugador B selecciona Papel.
    *   `B_Ti` (1 bit): Jugador B selecciona Tijera.
*   **Salidas:**
    *   `Gana_A` (1 bit): Se activa si A gana la ronda.
    *   `Gana_B` (1 bit): Se activa si B gana la ronda.
    *   `Empate` (1 bit): Se activa si ambos jugadores eligen la misma opción.
    *   `Error` (1 bit): Se activa si algún jugador presiona más de un botón o ninguno (entrada inválida).

## Funcionamiento Interno

El diseño utiliza un bloque `PROCESS` combinacional que realiza las siguientes tareas en orden secuencial:

1.  **Inicialización (Prevención de Latches):** Se asignan valores por defecto (`'0'`) a todas las salidas al inicio del proceso. Esto asegura que siempre haya un valor definido, evitando que el sintetizador infiera memorias no deseadas.
2.  **Concatenación:** Se agrupan las entradas individuales en variables vectoriales internas (`vec_A`, `vec_B`) de 3 bits con el formato `Piedra & Papel & Tijera`.
3.  **Validación (One-Hot):** Se verifica que los vectores de entrada sean válidos. Solo se permiten las combinaciones donde hay un único bit activo:
    *   `100` (Piedra)
    *   `010` (Papel)
    *   `001` (Tijera)
    Si un vector es distinto a estos (ej. `110` o `000`), se activa la salida `Error` y se ignora el resto de la lógica.
4.  **Lógica del Juego:**
    *   **Empate:** Si `vec_A` es igual a `vec_B`.
    *   **Gana A:** Se evalúan explícitamente las condiciones de victoria:
        *   Piedra (`A_Pi`) vence a Tijera (`B_Ti`).
        *   Papel (`A_Pa`) vence a Piedra (`B_Pi`).
        *   Tijera (`A_Ti`) vence a Papel (`B_Pa`).
    *   **Gana B:** Si no es error, ni empate, ni gana A, por descarte gana B.

## Tabla de Verdad (Resumen)

| A (Pi,Pa,Ti) | B (Pi,Pa,Ti) | Gana_A | Gana_B | Empate | Error | Nota |
|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| `100` | `001` | 1 | 0 | 0 | 0 | Piedra vs Tijera -> Gana A |
| `010` | `100` | 1 | 0 | 0 | 0 | Papel vs Piedra -> Gana A |
| `001` | `010` | 1 | 0 | 0 | 0 | Tijera vs Papel -> Gana A |
| `100` | `100` | 0 | 0 | 1 | 0 | Piedra vs Piedra -> Empate |
| `001` | `100` | 0 | 1 | 0 | 0 | Tijera vs Piedra -> Gana B |
| `110` | `001` | 0 | 0 | 0 | 1 | A pulsa dos botones -> Error |
| `111` | `010` | 0 | 0 | 0 | 1 | A pulsa tres botones -> Error |
| `000` | `010` | 0 | 0 | 0 | 1 | A no pulsa nada -> Error |

### Observaciones
*   **Variables vs Señales:** Se utilizan variables (`vec_A`, `vec_B`) para el cálculo intermedio dentro del proceso, permitiendo una actualización inmediata del valor concatenado para su posterior comparación en la misma ejecución del proceso.
*   **Prioridad:** La señal de `Error` tiene la prioridad más alta. Si hay error, no se calcula el ganador.