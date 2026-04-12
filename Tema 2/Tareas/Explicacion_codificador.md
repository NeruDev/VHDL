# ¿Cómo funciona el Codificador Binario ↔ Gray? (Guía Didáctica)

Esta guía explica paso a paso cómo diseñamos el "cerebro" (la lógica) de nuestro codificador para Logisim. Si no estás familiarizado con la electrónica digital, piensa en esto como una **receta para transformar códigos**.

---

## 1. El Concepto: ¿Qué estamos intentando hacer?

Imagina que tienes una fila de interruptores (Código Binario) y quieres convertirlos a un código donde solo cambie un interruptor a la vez (Código Gray). O viceversa.

Para hacer esto bit por bit (de forma "serial"), el circuito no puede ser "olvidadizo". Necesita saber qué bit binario calculó en el paso anterior para poder calcular el siguiente. Por eso usamos una **Máquina de Estados** (un circuito con memoria).

### Los protagonistas (Variables):
Para que sea más fácil, cambiaremos los nombres técnicos por nombres descriptivos:

| Nombre Técnico | Nombre Amigable | ¿Qué significa? |
| :--- | :--- | :--- |
| **SYS** | `MODO` | **0** para convertir Gray → Binario / **1** para Binario → Gray. |
| **N** | `DATO_ENTRANTE` | El bit que está llegando justo ahora por el cable. |
| **Q1** | `BIT_BIN_GUARDADO` | El bit binario que calculamos en el paso anterior y tenemos guardado en la memoria. |
| **Q0** | `SALIDA_ACTUAL` | El resultado de la conversión que estamos viendo en la pantalla en este momento. |

---

## 2. La Regla de Oro: La operación XOR (Diferencia)

Todo este circuito se basa en una sola operación llamada **XOR** (O exclusivo). Piensa en ella como un **"Detector de Diferencia"**:
*   Si los dos bits que comparas son **diferentes**, el resultado es **1**.
*   Si son **iguales**, el resultado es **0**.

### La Receta de Conversión:
No importa en qué modo estés, el **nuevo resultado** siempre se calcula igual:
> `Nuevo_Resultado` = `DATO_ENTRANTE` comparado (XOR) con `BIT_BIN_GUARDADO`.

---

## 3. El Secreto: ¿Qué guardamos para después?

Aquí es donde el `MODO` cambia las cosas. Aunque el resultado se calcule igual, lo que decidimos **guardar en la memoria** para el siguiente bit depende de qué estemos convirtiendo:

1.  **Si conviertes Binario → Gray (`MODO` = 1):**
    Guardas en la memoria el bit original que entró (`DATO_ENTRANTE`).
2.  **Si conviertes Gray → Binario (`MODO` = 0):**
    Guardas en la memoria el resultado que acabas de calcular (`Nuevo_Resultado`).

---

## 4. Construyendo la Tabla de Decisiones (Paso a Paso)

Vamos a pensar como el circuito. Tenemos que decidir qué bits enviar a la memoria para el próximo paso (`BIT_BIN_PROXIMO` y `SALIDA_PROXIMA`).

| MODO | DATO ENTRANTE | BIT BIN. GUARDADO | **Cálculo de Diferencia** (XOR) | **¿Qué guardamos para el futuro?** |
| :---: | :---: | :---: | :---: | :--- |
| `MODO` | `ENTRADA` | `MEMORIA` | `ENTRADA` ⊕ `MEMORIA` | `BIT_BIN_PROXIMO` / `SALIDA_PROXIMA` |
| **0** (G→B) | 0 | 0 | 0 ⊕ 0 = **0** | Guardamos el resultado (**0**) y la salida (**0**) |
| **0** (G→B) | 1 | 0 | 1 ⊕ 0 = **1** | Guardamos el resultado (**1**) y la salida (**1**) |
| **0** (G→B) | 0 | 1 | 0 ⊕ 1 = **1** | Guardamos el resultado (**1**) y la salida (**1**) |
| **0** (G→B) | 1 | 1 | 1 ⊕ 1 = **0** | Guardamos el resultado (**0**) y la salida (**0**) |
| **1** (B→G) | 0 | 0 | 0 ⊕ 0 = **0** | Guardamos la entrada (**0**) y la salida (**0**) |
| **1** (B→G) | 1 | 0 | 1 ⊕ 0 = **1** | Guardamos la entrada (**1**) y la salida (**1**) |
| **1** (B→G) | 0 | 1 | 0 ⊕ 1 = **1** | Guardamos la entrada (**0**) y la salida (**1**) |
| **1** (B→G) | 1 | 1 | 1 ⊕ 1 = **0** | Guardamos la entrada (**1**) y la salida (**0**) |

---

## 5. Traduciendo a "Cerebro Electrónico" (Ecuaciones)

Gracias a que usamos nombres claros, las fórmulas para armar el circuito en Logisim se vuelven lógicas:

1.  **Para la Salida:** 
    Es simplemente lo que esté guardado en la memoria de salida.
    > `SALIDA` = `SALIDA_ACTUAL`

2.  **Para decidir el próximo Resultado:**
    Es siempre la comparación XOR.
    > `SALIDA_PROXIMA` = `DATO_ENTRANTE` XOR `BIT_BIN_GUARDADO`

3.  **Para decidir qué recordar (El bit binario):**
    Es un pequeño dilema: "¿Uso la entrada o uso el resultado?". Esto se resuelve con un interruptor lógico (Multiplexor):
    > `BIT_BIN_PROXIMO` = Si `MODO` es 1, usa `DATO_ENTRANTE`. Si es 0, usa `SALIDA_PROXIMA`.

---

## 6. Resumen para Logisim

Para armar esto, usarás dos **Flip-Flops JK** (que son como pequeñas cajas fuertes para guardar un bit). 

*   **Caja 1 (`Q1`):** Guarda el `BIT_BIN_GUARDADO`. Sus entradas J y K se encargan de actualizarlo según el `MODO`.
*   **Caja 2 (`Q0`):** Guarda la `SALIDA_ACTUAL`. Sus entradas J y K simplemente copian el `Nuevo_Resultado` calculado.

**¿Por qué usar JK?** 
Porque los Flip-Flops JK son muy eficientes: si les dices que el bit debe cambiar (Toggle), lo hacen automáticamente, lo cual encaja perfecto con la lógica XOR (que básicamente dice "si la entrada es 1, cambia el estado anterior").

---

## 7. De la Idea al Circuito: Mapas de Karnaugh y Flip-Flops JK

Para que Logisim construya el circuito, necesitamos darle "órdenes" a los Flip-Flops JK. Estas órdenes se llaman **Entradas de Excitación** (J y K). 

### 7.1 ¿Cómo "hablarle" a un Flip-Flop JK? (Tabla de Excitación)
El Flip-Flop JK es como un empleado que obedece cuatro órdenes básicas. Para saber qué J y K usar, miramos qué queremos que pase con el bit que tenemos guardado:

| ¿Qué queremos que pase? | Orden J | Orden K | Explicación |
| :--- | :---: | :---: | :--- |
| Que el 0 **siga siendo 0** | **0** | **X** | "No hagas nada (0), y no me importa (X) si intentas resetear". |
| Que el 0 **cambie a 1** | **1** | **X** | "¡Pon un 1! (1), no importa (X) lo demás". |
| Que el 1 **cambie a 0** | **X** | **1** | "No importa (X) el 1, ¡pero limpia la memoria! (1)". |
| Que el 1 **siga siendo 1** | **X** | **0** | "No me importa (X), pero no borres nada (0)". |

*La **X** significa "No importa" (Don't Care). Esto es genial porque nos permite elegir 0 o 1 según nos convenga para que el circuito sea más pequeño.*

### 7.2 Los Mapas de Karnaugh: El "Sudoku" de la Lógica
Un Mapa de Karnaugh es una cuadrícula donde ponemos todas las combinaciones posibles de nuestras entradas (`MODO`, `ENTRADA`, `MEMORIA`) para ver dónde se forman grupos de "1" y "X". Cuanto más grande sea el grupo, más simple es el cableado.

#### Ejemplo: ¿Cómo decidimos J de la Salida (`J0`)?
Si analizamos cuándo la `SALIDA` debe pasar de 0 a 1, el mapa nos muestra que esto ocurre cuando el `DATO_ENTRANTE` es diferente al `BIT_BIN_GUARDADO`.

**Mapa de Karnaugh para J0 (Resumido):**
| | ENTRADA = 0 | ENTRADA = 1 |
| :--- | :---: | :---: |
| **MEMORIA = 0** | 0 | **1** |
| **MEMORIA = 1** | X | X |

> **Análisis:** En la primera fila (Memoria=0), queremos un **1** solo si la Entrada es 1. En la segunda fila, no nos importa (X). Si elegimos que esas X sean 0, nos queda la definición de una diferencia.

### 7.3 Las Ecuaciones Finales (El "ADN" del circuito)

Después de resolver los mapas para cada entrada J y K, obtenemos estas cuatro reglas maestras que Logisim usa para cablear todo:

#### Para el Bit Binario (Memoria Interna):
*   **J1 = `DATO_ENTRANTE`**  
    *(Simplemente: "Si entra un 1, prepárate para guardar un 1")*
*   **K1 = `MODO` XOR `DATO_ENTRANTE`**  
    *(Usa un detector de diferencia entre el modo y la entrada para decidir si borrar el 1 guardado)*

#### Para la Salida (Lo que vemos):
*   **J0 = `BIT_BIN_GUARDADO` XOR `DATO_ENTRANTE`**  
    *(La salida cambia a 1 si lo que recordamos es distinto a lo que entra)*
*   **K0 = NOT (J0)**  
    *(O más fácil: es un XNOR. Si son iguales, la salida se apaga o se queda en cero)*

---

## 8. El Mapa Maestro de Diseño: De las Tablas al Circuito

Para construir una Máquina de Estados con Flip-Flops JK, necesitamos "traducir" nuestras ideas a tablas que el hardware pueda entender. Este es el camino que sigue un diseñador de circuitos.

### 8.1 Paso 1: Entender al "Actor Principal" (Tabla de Verdad del JK)
Primero, recordamos cómo reacciona un Flip-Flop JK a las señales que le enviamos. Esta tabla muestra qué pasa con el bit guardado ($Q$) cuando llega un pulso de reloj:

| J | K | Resultado ($Q_{próximo}$) | Nombre de la acción |
| :---: | :---: | :---: | :--- |
| 0 | 0 | No cambia | **Mantener** (Keep) |
| 0 | 1 | Se vuelve 0 | **Borrar** (Reset) |
| 1 | 0 | Se vuelve 1 | **Escribir** (Set) |
| 1 | 1 | Se invierte | **Cambiar** (Toggle) |

### 8.2 Paso 2: El "Manual de Instrucciones" (Tabla de Excitación)
Esta es la tabla más importante para el diseñador. Nos dice: "Si mi bit está en 'X' valor y quiero que pase a 'Y' valor, ¿qué botones (J y K) debo presionar?".

| De (Actual) | A (Próximo) | **Orden J** | **Orden K** | Explicación |
| :---: | :---: | :---: | :---: | :--- |
| **0** | **0** | 0 | X | No mandes señal de "Escribir". |
| **0** | **1** | 1 | X | Manda señal de "Escribir". |
| **1** | **0** | X | 1 | Manda señal de "Borrar". |
| **1** | **1** | X | 0 | No mandes señal de "Borrar". |

### 8.3 Paso 3: La Gran Tabla de Decisiones (Tabla de Transición Didáctica)
Aquí unimos todo. Tenemos dos Flip-Flops: **FF_BIN** (`Q1`) que recuerda el bit binario, y **FF_OUT** (`Q0`) que muestra el resultado. 

Para cada situación, decidimos qué órdenes enviar a los J y K de cada uno. (Aquí mostramos las combinaciones clave):

| MODO | ENTRADA | MEM_1 (Bin) | MEM_0 (Out) | **J1 K1** (Órdenes Bin) | **J0 K0** (Órdenes Out) | Acción Resultante |
| :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| 0 (G→B) | 0 | 0 | 0 | **0 X** | **0 X** | Mantener todo en 0 |
| 0 (G→B) | 1 | 0 | 0 | **1 X** | **1 X** | Escribir 1 en ambos |
| 0 (G→B) | 1 | 1 | 1 | **X 0** | **X 0** | Mantener ambos en 1 |
| 1 (B→G) | 0 | 1 | 0 | **X 1** | **1 X** | Borrar Binario, Activar Salida |
| 1 (B→G) | 1 | 1 | 0 | **X 0** | **0 X** | Mantener Binario, Salida sigue en 0 |

### 8.4 Paso 4: La Arquitectura del Circuito (Funcionamiento en conjunto)

Para que los dos Flip-Flops trabajen en equipo como una máquina de estados, el circuito se organiza en un ciclo de tres bloques:

1.  **Bloque de Entradas:** Recibe el `DATO_ENTRANTE` y el `MODO`.
2.  **Lógica de Estado Siguiente (El "Cerebro"):** Son las compuertas XOR y XNOR. Ellas reciben las entradas y lo que los Flip-Flops están recordando.
3.  **Registro de Estado (La "Memoria"):** Son los dos Flip-Flops JK. Ellos guardan la información hasta el siguiente pulso de reloj.

#### ¿Cómo se conectan en Logisim?
*   **Reloj Sincronizado (CLK):** El cable de reloj llega a **ambos** Flip-Flops al mismo tiempo. Esto garantiza que cambien de estado al unísono.
*   **Retroalimentación (Feedback):** La salida del primer Flip-Flop (`BIT_BIN_GUARDADO`) vuelve hacia atrás y entra a las compuertas del segundo Flip-Flop. Es decir, **lo que el primer Flip-Flop recuerda ayuda al segundo a decidir qué mostrar.**
*   **Conexiones Finales:**
    *   **J1:** Conectado directamente a la Entrada.
    *   **K1:** Conectado a `MODO XOR ENTRADA`.
    *   **J0:** Conectado a `MEMORIA_BIN XOR ENTRADA`.
    *   **K0:** Conectado a `MEMORIA_BIN XNOR ENTRADA` (o XOR + Inversor).

Este conjunto de conexiones hace que, bit tras bit, la información fluya, se compare y se transforme correctamente entre Binario y Gray.

---

## 9. La Arquitectura Moore: El Corazón del Sistema

El diseño de nuestro codificador sigue el modelo de una **Máquina de Estados de Moore**. En este modelo, la salida del circuito depende **únicamente** de lo que hay guardado en la memoria en ese momento. 

Imagina que el circuito es un equipo de tres departamentos trabajando en armonía:

### 9.1 Bloque 1: Lógica de Estado Siguiente (El Departamento de Planificación)
Este bloque mira al futuro. Recibe la `ENTRADA` actual, el `MODO` y lo que hay en la `MEMORIA` ahora mismo. Su único trabajo es responder a la pregunta: 
> **"Si el reloj suena ahora mismo, ¿qué deberíamos guardar en la memoria para el siguiente paso?"**

Este departamento no cambia nada todavía; solo prepara las señales (J y K) que se enviarán a los Flip-Flops.

### 9.2 Bloque 2: Registro de Estado (El Departamento de Archivo)
Aquí es donde viven nuestros dos Flip-Flops JK. Son los encargados de la **Memoria**. 
*   No hacen nada hasta que el **Reloj (CLK)** da la orden (el flanco de subida). 
*   En ese instante exacto, "capturan" los planes del Departamento de Planificación y los guardan bajo llave.
*   Lo que antes era el "Estado Siguiente" se convierte ahora en el **"Estado Actual"**.

### 9.3 Bloque 3: Lógica de Salida (El Departamento de Relaciones Públicas)
En una Máquina de Moore, este departamento es el más sencillo. Solo mira qué hay guardado en la memoria (`MEM_0`) y lo muestra directamente al exterior como `C_BIT`. 
> **Regla de oro Moore:** No le importa lo que esté pasando en la entrada en este instante; solo le importa lo que la memoria ya ha confirmado y guardado. Esto evita que el resultado "parpadee" si hay ruido en la entrada.

### 9.4 ¿Cómo funcionan en conjunto? (El Ciclo Infinito)

1.  **Preparación:** La Lógica de Estado Siguiente calcula el próximo bit basándose en el bit que está llegando.
2.  **Sincronización:** El Reloj suena. La Memoria se actualiza con el nuevo bit.
3.  **Exhibición:** La Lógica de Salida muestra el nuevo bit convertido.
4.  **Retroalimentación (Feedback):** Ese nuevo bit guardado vuelve inmediatamente al Departamento de Planificación para ayudar a calcular el siguiente bit de la cadena.

Este ciclo se repite para cada bit del código (por ejemplo, 4 veces para un número de 4 bits), permitiendo que un circuito tan pequeño pueda procesar cadenas de información de cualquier longitud.

---
*Este documento es una guía pedagógica diseñada para el curso de VHDL. Para detalles técnicos de implementación y tablas de excitación completas, consulta el archivo `codificadorBG_Logisim.md`.*
