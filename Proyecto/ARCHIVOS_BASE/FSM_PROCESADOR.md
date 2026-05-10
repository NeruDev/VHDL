| Estado Actual | Condición (CO / Flags) | Estado Siguiente |
| :--- | :--- | :--- |
| **S00** | CO=XX | **S01** |
| **S01** | CO=XX | **S02** |
| **S02** | CO=70 o 71 o 80 o 81 o 82 o 83 | **S03** |
| **S02** | CO=40 | **S15** |
| **S02** | CO=41 | **S16** |
| **S02** | CO=42 | **S17** |
| **S02** | CO=43 | **S18** |
| **S02** | CO=44 | **S19** |
| **S02** | CO=45 | **S09** |
| **S02** | CO=46 | **S10** |
| **S02** | CO=47 | **S12** |
| **S02** | CO=FF | **S11** |
| **S02** | CO=Resto | **S01** |
| **S03** | CO=XX | **S04** |
| **S04** | CO=XX | **S05** |
| **S05** | CO=XX | **S06** |
| **S06** | CO=70 | **S07** |
| **S06** | CO=71 | **S08** |
| **S06** | CO=80 | **S14** |
| **S06** | CO=81 y FZ=0 | **S01** |
| **S06** | CO=81 y FZ=1 | **S14** |
| **S06** | CO=82 y FC=0 | **S01** |
| **S06** | CO=82 y FC=1 | **S14** |
| **S06** | CO=83 y FS=0 | **S01** |
| **S06** | CO=83 y FS=1 | **S14** |
| **S07** | CO=XX | **S01** |
| **S08** | CO=XX | **S01** |
| **S09** | CO=XX | **S01** |
| **S10** | CO=XX | **S01** |
| **S11** | CO=XX | **S11** |
| **S12** | CO=XX | **S13** |
| **S13** | CO=XX | **S01** |
| **S14** | CO=XX | **S01** |
| **S15** | CO=XX | **S01** |
| **S16** | CO=XX | **S01** |
| **S17** | CO=XX | **S01** |
| **S18** | CO=XX | **S01** |
| **S19** | CO=XX | **S01** |

* Nota: CO=XX indica una transición incondicional en el siguiente ciclo de reloj[cite: 3, 5, 12, 28, 30].

### Interpretación del Flujo de Trabajo (Procesador Básico)

El diagrama representa la unidad de control (máquina de estados finitos) de un procesador básico. Se encarga de coordinar el ciclo clásico de **Búsqueda (Fetch), Decodificación (Decode) y Ejecución (Execute)** de las instrucciones.

Aquí te detallo la anatomía de este flujo:

**1. Fase de Búsqueda (Fetch)**

* 
**Estados `S00` $\rightarrow$ `S01` $\rightarrow$ `S02`:** Este es el camino inicial común para todas las instrucciones. En estos primeros estados, el procesador accede a la memoria, lee la instrucción a ejecutar e incrementa el Contador de Programa (PC).

* El estado `S02` actúa como el **Decodificador**. En este punto, la máquina analiza el valor de `CO` (que es el Código de Operación o *Opcode*) para decidir qué camino de ejecución tomar.


**2. Fase de Ejecución: Operaciones Rápidas (ALU/Registros)**

* 
**Códigos de Operación `40` al `46`:** Representan instrucciones simples que toman un solo ciclo adicional para ejecutarse (entrando a estados como `S15`, `S16`, `S09`, etc.). Tras la operación matemática o lógica, todos regresan incondicionalmente a `S01` (`CO=XX`) para buscar la siguiente instrucción.

* 
**Código `47`:** Esta instrucción requiere dos ciclos de ejecución (`S12` y luego `S13`), antes de volver a `S01`.


**3. Fase de Ejecución: Operaciones Complejas (Memoria y Saltos)**

* 
**Códigos de Operación `70`, `71`, `80` al `83`:** Estas instrucciones son más pesadas y requieren varios ciclos preparatorios (`S03` $\rightarrow$ `S04` $\rightarrow$ `S05` $\rightarrow$ `S06`). Esto sugiere que el procesador está buscando datos adicionales en la memoria (como operandos o direcciones completas de memoria) antes de actuar.

* Al llegar a `S06`, ocurre una sub-decodificación para la ejecución final:
* 
**Ejecuciones estándar (`70`, `71`):** Entran en `S07` o `S08` y terminan.

* 
**Salto incondicional (`80`):** Pasa directo al estado `S14`.

* 
**Saltos condicionales (`81`, `82`, `83`):** Aquí se toman decisiones basadas en los **Flags o Banderas** de la ALU: `FZ` (Flag de Cero), `FC` (Flag de Acarreo) y `FS` (Flag de Signo). Si la condición no se cumple (valor `0`), la máquina no salta y regresa al Fetch en `S01`. Si se cumple (valor `1`), transita al estado `S14` para aplicar el salto o actualización pertinente.

**4. Estados Especiales**

* **Código de Operación `FF`:** Esta es la instrucción de detención (HALT o WAIT). Envía la máquina al estado `S11`, el cual hace un ciclo infinito consigo mismo (`CO=XX` a `S11`), paralizando o suspendiendo la búsqueda de nuevas instrucciones.

* **Condición `CO=Resto`:** Actúa como un mecanismo de seguridad para cualquier Opcode no reconocido o vacío. Retorna la máquina directo a `S01` (comportándose esencialmente como una instrucción NOP o "No Operation").