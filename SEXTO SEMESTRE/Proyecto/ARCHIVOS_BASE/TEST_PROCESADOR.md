# Programa de Prueba Exhaustiva para el Procesador

| Dirección (PC) | Etiqueta | Operación / Comentario / Esperado | OpCode | Op L / Dir L | Op H / Dir H |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **0000** | | R1=M(0035) -> A4 | 70 | 35 | 00 |
| **0003** | | R0=R1 -> A4 | 46 | | |
| **0004** | | R1=5E -> 5E | 47 | 5E | |
| **0006** | | R1=R0+R1 -> 02 | 45 | | |
| **0007** | | M(0036)=R1 -> 02 | 71 | 36 | 00 |
| **000A** | | JC FUECARRY1 | 82 | 0F | 00 |
| **000D** | | 10 | 10 | | |
| **000E** | | 20 | 20 | | |
| **000F** | **FUECARRY1**| R1=R1-1 -> 01 | 42 | | |
| **0010** | | JZ FUEZERO1 | 81 | 2C | 00 |
| **0013** | | R1=R1-1 -> 00 | 42 | | |
| **0014** | | JZ FUEZERO2 | 81 | 19 | 00 |
| **0017** | | 11 | 11 | | |
| **0018** | | 21 | 21 | | |
| **0019** | **FUEZERO2** | R1=R1+1 -> 01 | 43 | | |
| **001A** | | R1=notR1 -> FE | 40 | | |
| **001B** | | JS FUESIGNO1 | 83 | 20 | 00 |
| **001E** | | 12 | 12 | | |
| **001F** | | 22 | 22 | | |
| **0020** | **FUESIGNO1**| R1=F9 -> F9 | 47 | F9 | |
| **0022** | | R1=R0 and R1 -> A0 | 41 | | |
| **0023** | | R1=M(0036) -> 02 | 70 | 36 | 00 |
| **0026** | | JMP FUEZERO1 | 80 | 2C | 00 |
| **0029** | | 13 | 13 | | |
| **002A** | | 14 | 14 | | |
| **002B** | | 15 | 15 | | |
| **002C** | **FUEZERO1** | FIN | FF | | |
| **0035** | | Dato: A4 | | | |
| **0036** | | Dato: B5 | | | |
| **0037** | | Dato: C6 | | | |


A nivel de ingeniería, este tipo de código se conoce como una **rutina de prueba o *testbench***. Su propósito no es hacer algo útil para el usuario, sino estresar deliberadamente todos los caminos físicos (multiplexores, buses, registros y banderas de la ALU) del procesador para verificar que el silicio o la simulación (probablemente en Quartus o Proteus) funciona según lo diseñado en la máquina de estados.

---

### Análisis Lógico y Verificación del Datapath

Este programa es brillante porque audita meticulosamente los estados descritos en tus tablas anteriores. Las instrucciones no se eligieron al azar, están diseñadas para forzar la activación de las banderas (Flags) de la ALU y comprobar que el control de flujo y la memoria responden correctamente.

Esto es lo que el programa comprueba paso a paso:

**1. Verificación de Accesos a Memoria y Registros Básicos (0000 - 0004)**

* Carga un valor de la memoria de datos (`A4` en la dirección `0035`) hacia `R1` comprobando la instrucción `LOAD`.

* Mueve ese valor a `R0` (`MOV`) para salvaguardarlo y luego le inyecta un valor inmediato a `R1` (`5E` mediante `MOVI`). Esto verifica las rutas internas del banco de registros.

**2. Prueba de la Bandera de Acarreo (FC) y Salto JC (0006 - 000E)**

* Aquí ocurre la magia matemática: Suma `A4 + 5E`.

* En decimal: $164 + 94 = 258$.
* Como el procesador es de 8 bits, el máximo es 255. Ocurre un desbordamiento, el resultado queda en `02` y la bandera de acarreo (`FC`) se pone en `1`.

* Guarda el resultado (`02`) en memoria (`0036`) comprobando el `STORE`.

* Inmediatamente evalúa `JC FUECARRY1`. Si el FSM diseñado previamente funciona, como `FC=1`, el Contador de Programa (PC) debe saltar a `000F`.

* **Las Trampas:** Fíjate en las direcciones `000D` y `000E`. Contienen "basura" (`10`, `20`). Si el salto condicional falla y el procesador sigue ejecutando secuencialmente, intentará ejecutar esos valores como instrucciones, provocando un error. Es una trampa para probar si el salto realmente ocurrió.

**3. Prueba de la Bandera de Cero (FZ) y Salto JZ (000F - 0018)**

* Decrementa `R1` (que valía `02`), dejándolo en `01`.

* Ejecuta `JZ FUEZERO1`. Como `R1` no es cero (`FZ=0`), el salto **no** debe ocurrir. Esto verifica que el procesador sepa *ignorar* un salto cuando la condición es falsa.

* Vuelve a decrementar `R1` (de `01` pasa a `00`), forzando `FZ=1`.

* Ejecuta `JZ FUEZERO2`. Ahora sí debe saltar a `0019`, evadiendo las trampas `11` y `21` en `0017` y `0018`.


**4. Prueba de la Bandera de Signo (FS) y Salto JS (0019 - 001F)**

* Incrementa `R1` para que vuelva a valer `01`.

* Le aplica un `NOT` a nivel de bits: El inverso de `0000 0001` es `1111 1110` (`FE` en hexadecimal).

* En binario con signo (complemento a 2), si el bit más significativo (el de la izquierda) es `1`, el número es negativo. Por lo tanto, `FS` se enciende.
* El salto `JS FUESIGNO1` debe activarse saltando a `0020`, esquivando las trampas `12` y `22`.

**5. Prueba de ALU Lógica y Fin de Ejecución (0020 - 002C)**

* Asigna el valor `F9` a `R1`.

* Ejecuta un `AND` lógico entre `R0` (que aún conservaba el valor original `A4` desde el paso 1) y `R1` (`F9`).

* 
`1010 0100` (A4) AND `1111 1001` (F9) resulta en `1010 0000` (`A0`).

* Finalmente, prueba el salto incondicional `JMP` hacia `002C`, evitando las últimas trampas (`13`, `14`, `15`) para llegar al estado de detención segura `FF` (FIN).