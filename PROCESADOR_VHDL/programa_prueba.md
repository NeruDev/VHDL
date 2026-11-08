### Tabla de Auditoría de Hardware (Programa Sin Trampas)

| Dir (PC) | Instrucción | Hexadecimal | Estados Transitados | Resultado Esperado (Auditoría de Hardware) |
| --- | --- | --- | --- | --- |
| **0000** | MOVI 1A | `47 1A` | S01 → S02 → S12 → S13 | **R1 = 1A**. Verifica la lectura del valor inmediato. |
| **0002** | MOV R0 | `46` | S01 → S02 → S10 | **R0 = 1A**. Verifica que el bus interno copie R1 hacia R0. |
| **0003** | MOVI E6 | `47 E6` | S01 → S02 → S12 → S13 | **R1 = E6**. Prepara los operandos para forzar el Carry. |
| **0005** | ADD R1 | `45` | S01 → S02 → S09 | **R1 = 00**. (1A + E6 = 100h, desbordamiento a 8 bits). **Banderas: FC=1, FZ=1**. |
| **0006** | JC 0009 | `82 09 00` | S01 → S02 → S03 → S04 → S05 → S06 → S14 | **Salta a 0009**. La señal `Lpc` se activa al coincidir con `FC=1`. |
| **0009** | MOVI 50 | `47 50` | S01 → S02 → S12 → S13 | **R1 = 50**. R0 sigue conservando su valor 1A. |
| **000B** | SUB R1 | `44` | S01 → S02 → S19 | **R1 = CA**. (1A - 50 = -36 dec = CA hex). **Bandera: FS=1**. Verifica la resta y Signo. |
| **000C** | JS 0010 | `83 10 00` | S01 → S02 → S03 → S04 → S05 → S06 → S14 | **Salta a 0010**. La señal `Lpc` se activa al coincidir con `FS=1`. |
| **000F** | *NOP (Alineación)* | `00` | *(Es omitido por el salto)* | No se ejecuta. Mantiene alineadas las direcciones a los saltos. |
| **0010** | MOVI 01 | `47 01` | S01 → S02 → S12 → S13 | **R1 = 01**. Prepara registro para prueba de Zero. |
| **0012** | DEC R1 | `42` | S01 → S02 → S17 | **R1 = 00**. **Bandera: FZ=1**. Verifica el decremento de la ALU. |
| **0013** | JZ 0016 | `81 16 00` | S01 → S02 → S03 → S04 → S05 → S06 → S14 | **Salta a 0016**. La señal `Lpc` se activa al coincidir con `FZ=1`. |
| **0016** | MOVI 00 | `47 00` | S01 → S02 → S12 → S13 | **R1 = 00**. Limpieza intencional del registro. |
| **0018** | NOT R1 | `40` | S01 → S02 → S15 | **R1 = FF**. Verifica la compuerta inversora bit a bit de la ALU. |
| **0019** | MOV R0 | `46` | S01 → S02 → S10 | **R0 = FF**. |
| **001A** | MOVI 55 | `47 55` | S01 → S02 → S12 → S13 | **R1 = 55**. |
| **001C** | AND R1 | `41` | S01 → S02 → S16 | **R1 = 55**. (FF AND 55 = 55). Verifica el enmascaramiento lógico. |
| **001D** | STORE F000 | `71 F0 00` | S01 → S02 → S03 → S04 → S05 → S06 → S08 | **M(F0) = 55**. MUX direcciona a HL (`F000`), el pin `we` enciende. |
| **0020** | INC R1 | `43` | S01 → S02 → S18 | **R1 = 56**. Verifica el sumador +1 interno. |
| **0021** | LOAD F000 | `70 F0 00` | S01 → S02 → S03 → S04 → S05 → S06 → S07 | **R1 = 55**. Sobreescribe el 56 leyendo exitosamente la RAM en F0. |
| **0024** | JMP 0027 | `80 27 00` | S01 → S02 → S03 → S04 → S05 → S06 → S14 | **Salta a 0027**. Verifica el salto incondicional (Lpc siempre 1). |
| **0027** | MOVI 02 | `47 02` | S01 → S02 → S12 → S13 | **R1 = 02**. |
| **0029** | MOV R0 | `46` | S01 → S02 → S10 | **R0 = 02**. |
| **002A** | MOVI 03 | `47 03` | S01 → S02 → S12 → S13 | **R1 = 03**. |
| **002C** | ADD R1 | `45` | S01 → S02 → S09 | **R1 = 05**. Todas las banderas se apagan: **FZ=0, FC=0, FS=0**. |
| **002D** | JZ 0035 | `81 35 00` | S01 → S02 → S03 → S04 → S05 → S06 → S14 | **PC avanza a 0030**. `Lpc` NO se activa (FZ=0). Evasión exitosa. |
| **0030** | JC 0035 | `82 35 00` | S01 → S02 → S03 → S04 → S05 → S06 → S14 | **PC avanza a 0033**. `Lpc` NO se activa (FC=0). Evasión exitosa. |
| **0033** | JS 0035 | `83 35 00` | S01 → S02 → S03 → S04 → S05 → S06 → S14 | **PC avanza a 0036**. `Lpc` NO se activa (FS=0). Evasión exitosa. |
| **0036** | FIN | `FF` | S01 → S02 → S11 (Bucle) | **Fin de programa**. PC se queda en 0037, la FSM se atrapa en S11 y `Fin` = 1. |

### Cómo validar el éxito de la simulación

Para estar absolutamente seguro de que no se requiere ningún ajuste en el procesador:

1. Deja correr el reloj automáticamente (`Ctrl + K`).
2. Verifica que el programa no se congele ni se reinicie en la dirección `0000`.
3. Comprueba que el procesador termina iluminando la salida `Fin` (pin en estado lógico `1`).
4. Abre la vista de la Memoria y confirma que en la dirección `00F0` se haya escrito el valor `55`.
5. Si estos puntos se cumplen, tu arquitectura, tu datapath y tu máquina de estados en VHDL funcionan de forma óptima y coordinada.