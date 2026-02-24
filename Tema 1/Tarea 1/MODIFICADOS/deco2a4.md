# Documentación: Decodificador 2 a 4 (deco2a4.vhd)

## Descripción
El archivo `deco2a4.vhd` describe un decodificador de 2 entradas a 4 salidas. Convierte un código binario de 2 bits (`B1`, `B0`) en una salida activa en alta entre cuatro líneas (`D0`–`D3`). Solo una salida está en `'1'` a la vez; las demás permanecen en `'0'`. Incluye **seis arquitecturas** con diferentes estilos de codificación.

## Interfaz (Puertos)
*   **B0, B1 (1 bit c/u):** Entrada binaria de 2 bits.
*   **D0, D1, D2, D3 (1 bit c/u):** Salidas decodificadas. Solo una se activa según el valor de la entrada.

## Arquitecturas Implementadas

### Arquitectura PRIMERA — Flujo de datos (Ecuaciones)
```vhdl
D0 <= NOT B1 AND NOT B0;
D1 <= NOT B1 AND B0;
D2 <= B1 AND NOT B0;
D3 <= B1 AND B0;
```

### Arquitectura SEGUNDA — Comportamental (IF)
Usa `PROCESS` con `IF ... ELSIF` para activar la salida correspondiente. Asigna valores por defecto `'0'` a todas las salidas al inicio.

### Arquitectura TERCERA — Comportamental (CASE)
Concatena las entradas en `sel` y usa `CASE sel IS` para activar la salida correspondiente.

### Arquitectura CUARTA — Asignación condicional (WHEN-ELSE)
Emplea una señal vectorial `sal` de 4 bits con `WHEN ... ELSE` y luego asigna cada bit a las salidas individuales.

### Arquitectura QUINTA — Asignación selectiva (WITH-SELECT)
Concatena las entradas en `sel` y usa `WITH sel SELECT` para asignar el vector decodificado.

### Arquitectura SEXTA — Flujo de datos vectorial
Combina ecuaciones booleanas con una señal vectorial intermedia `sal`:
```vhdl
sal(0) <= NOT B1 AND NOT B0;
sal(1) <= NOT B1 AND B0;
sal(2) <= B1 AND NOT B0;
sal(3) <= B1 AND B0;
```

## Tabla de Verdad

| B1 | B0 | D3 | D2 | D1 | D0 |
|:---:|:---:|:---:|:---:|:---:|:---:|
| 0 | 0 | 0 | 0 | 0 | 1 |
| 0 | 1 | 0 | 0 | 1 | 0 |
| 1 | 0 | 0 | 1 | 0 | 0 |
| 1 | 1 | 1 | 0 | 0 | 0 |

## Configuración
Actualmente configurada para usar la arquitectura `SEXTA` (flujo de datos vectorial).

### Observaciones
1.  **Relación inversa con el codificador:** El decodificador realiza la operación inversa al codificador `codi2a4.vhd`. Si se conectan en cascada (codificador → decodificador), se recupera la señal original.
2.  La salida es **one-hot**: exactamente una salida está activa en `'1'` para cada combinación válida de entrada.
3.  Las seis arquitecturas son funcionalmente equivalentes y sirven como referencia comparativa de estilos de codificación VHDL.
