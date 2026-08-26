# Documentación: Codificador 2 a 4 (codi2a4.vhd)

## Descripción
El archivo `codi2a4.vhd` describe un codificador de 4 entradas (`D0`–`D3`) a una salida binaria de 2 bits (`B1`, `B0`). Codifica la posición de la entrada activa (asumiendo que solo una está activa a la vez) en su representación binaria correspondiente. Incluye **seis arquitecturas** que muestran diferentes estilos de codificación VHDL.

## Interfaz (Puertos)
*   **D0, D1, D2, D3 (1 bit c/u):** Entradas del codificador. Se espera que solo una esté activa (`'1'`) a la vez.
*   **B0, B1 (1 bit c/u):** Código binario de salida que representa la entrada activa.

## Arquitecturas Implementadas

### Arquitectura PRIMERA — Flujo de datos (Ecuaciones)
```vhdl
B1 <= D3 OR D2;
B0 <= D3 OR D1;
```

### Arquitectura SEGUNDA — Comportamental (IF)
Usa `PROCESS` con estructura `IF ... ELSIF` para evaluar por prioridad (`D3` > `D2` > `D1` > `D0`).

### Arquitectura TERCERA — Comportamental (CASE)
Concatena las entradas en un vector `sel` de 4 bits y usa `CASE sel IS` para mapear cada combinación válida.

### Arquitectura CUARTA — Asignación condicional (WHEN-ELSE)
Usa una señal intermedia `sal` de 2 bits con `WHEN ... ELSE` encadenado y luego asigna cada bit a la salida.

### Arquitectura QUINTA — Asignación selectiva (WITH-SELECT)
Concatena las entradas en `sel` y emplea `WITH sel SELECT` para asignar el código correspondiente.

### Arquitectura SEXTA — Flujo de datos vectorial
Similar a la PRIMERA pero usando una señal vectorial intermedia `sal`:
```vhdl
sal(1) <= D3 OR D2;
sal(0) <= D3 OR D1;
B1 <= sal(1);
B0 <= sal(0);
```

## Tabla de Verdad

| D3 | D2 | D1 | D0 | B1 | B0 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 0 | 0 | 0 | 1 | 0 | 0 |
| 0 | 0 | 1 | 0 | 0 | 1 |
| 0 | 1 | 0 | 0 | 1 | 0 |
| 1 | 0 | 0 | 0 | 1 | 1 |

## Configuración
Actualmente configurada para usar la arquitectura `SEXTA` (flujo de datos vectorial).

### Observaciones
1.  A diferencia de `codi4a2p.vhd`, este codificador **no tiene señal de dato válido (DV)**, por lo que no se puede distinguir entre "ninguna entrada activa" y "D0 activa" (ambas producen `"00"`).
2.  El codificador asume una sola entrada activa a la vez. Si varias entradas están activas simultáneamente, las arquitecturas con prioridad (SEGUNDA) darán preferencia a `D3`, mientras que las de ecuaciones (PRIMERA, SEXTA) producirán combinaciones que podrían no corresponder a ninguna entrada individual.
3.  Las seis arquitecturas demuestran la versatilidad de VHDL para expresar la misma lógica de múltiples formas.
