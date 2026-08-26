# Documentación: Codificador 4 a 2 con Prioridad (codi4a2p.vhd)

## Descripción
El archivo `codi4a2p.vhd` describe un codificador con prioridad de 4 entradas a 2 salidas. Convierte la posición de la entrada activa de mayor prioridad (`D3` > `D2` > `D1` > `D0`) en un código binario de 2 bits (`B1`, `B0`). Además, incluye una salida de validación (`DV`) que indica si al menos una entrada está activa.

## Interfaz (Puertos)
*   **D3, D2, D1, D0 (1 bit c/u):** Entradas del codificador. `D3` tiene la mayor prioridad.
*   **B1, B0 (1 bit c/u):** Código binario de salida que representa la entrada activa de mayor prioridad.
*   **DV (1 bit):** Salida de dato válido. Se activa (`'1'`) cuando al menos una entrada está en `'1'`.

## Arquitecturas Implementadas
El diseño presenta **tres arquitecturas** con diferentes estilos de codificación:

### Arquitectura UNA — Flujo de datos (Ecuaciones)
Implementa la codificación directamente con ecuaciones booleanas:

```vhdl
B1 <= D3 OR D2;
B0 <= D3 OR (NOT D2 AND D1);
DV <= D3 OR D2 OR D1 OR D0;
```

### Arquitectura DOS — Asignación condicional (WHEN-ELSE)
Evalúa las condiciones de cada salida de forma descriptiva:

```vhdl
B1 <= '1' WHEN (D3 = '1' OR D2 = '1') ELSE '0';
B0 <= '1' WHEN (D3 = '1' OR (D2 = '0' AND D1 = '1')) ELSE '0';
DV <= '1' WHEN (D3 = '1' OR D2 = '1' OR D1 = '1' OR D0 = '1') ELSE '0';
```

### Arquitectura TRES — Asignación selectiva (WITH-SELECT)
Concatena las entradas en un entero y usa `WITH ... SELECT` con rangos numéricos:

```vhdl
UD <= D3 & D2 & D1 & D0;
D <= TO_INTEGER(UD);

WITH D SELECT
B1 <= '0' WHEN 0 TO 3,
      '1' WHEN 4 TO 15,
      '0' WHEN OTHERS;
```

## Tabla de Verdad (Prioridad)

| D3 | D2 | D1 | D0 | B1 | B0 | DV |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 0 | 0 | 0 | 1 | 0 | 0 | 1 |
| 0 | 0 | 1 | X | 0 | 1 | 1 |
| 0 | 1 | X | X | 1 | 0 | 1 |
| 1 | X | X | X | 1 | 1 | 1 |

> *X = don't care (no importa el valor, la prioridad superior ya decidió la salida).*

## Configuración
Se utiliza un bloque `CONFIGURATION` para seleccionar la arquitectura activa. Actualmente está configurada para usar la arquitectura `TRES` (WITH-SELECT con rangos enteros).

### Observaciones
1.  **Prioridad:** La entrada `D3` tiene la máxima prioridad. Si `D3 = '1'`, la salida siempre será `"11"` sin importar el estado de las demás.
2.  **Dato Válido (DV):** Es esencial para distinguir el caso donde ninguna entrada está activa (`"00"` sin dato válido) del caso donde `D0` está activa (`"00"` con dato válido).
3.  La arquitectura TRES convierte las entradas a un tipo entero para aprovechar los rangos (`0 TO 3`, `4 TO 15`), lo cual simplifica la escritura para muchos casos.
