### Netlist y Descripción de Conexiones por Bloque Funcional

**1. PC (Program Counter / Contador de Programa)**
Este bloque mantiene la dirección de la próxima instrucción a ejecutar en memoria.
*   **Entradas de control:** `clk` (reloj), `Lpc` (carga del PC), `Clear` (reinicio).
*   **Entrada de datos:** `entradaPC` (Bus de 16 bits que proviene directamente de la salida del registro `H | L`).
*   **Salida de datos:** `salida` (Bus de 16 bits que se conecta a la entrada `0` del multiplexor).

**2. Multiplexor de Direcciones**
Selecciona la fuente de la dirección que se enviará a la memoria.
*   **Entradas de datos:** 
    *   Puerto `0`: Bus de 16 bits proveniente de la `salida` del `PC`.
    *   Puerto `1`: Bus de 16 bits proveniente del registro `H | L`.
*   **Entrada de control:** `Seldir` (Señal de 1 bit que decide si la dirección proviene del PC o de HL).
*   **Salida de datos:** `dir` (Bus de 16 bits que va a la entrada de direcciones de la `Memoria 64Kx8`).

**3. Memoria 64Kx8**
Almacena tanto las instrucciones (código) como los datos.
*   **Entradas de control:** `inicia`, `CS` (Chip Select), `OE` (Output Enable para lectura), `WE` (Write Enable para escritura).
*   **Entrada de direcciones:** `dir` (16 bits provenientes del multiplexor).
*   **Puerto bidireccional:** `datos` (8 bits que se conectan directamente al `BusDatos` principal).

**4. BusDatos (Bus del Sistema)**
Es la columna vertebral de la ruta de datos. Es un bus bidireccional de 8 bits que interconecta la `Memoria`, el registro `H | L`, el Banco de Registros (`BR`), el Registro de Instrucción (`RI`) y la salida de la `ALU` (a través de su buffer).

**5. Registro H | L (Puntero de Direcciones/Datos)**
Un registro de 16 bits dividido en dos partes de 8 bits (High y Low). Se usa típicamente para direccionamiento indirecto o para cargar direcciones en el PC.
*   **Entradas de datos:** Toma 8 bits directamente del `BusDatos`.
*   **Entradas de control:** `clk`, `clear`, `LH` (Carga la parte Alta), `LL` (Carga la parte Baja).
*   **Salidas de datos:** Entrega un bus de 16 bits combinado que se bifurca hacia `entradaPC` y hacia el puerto `1` del multiplexor.

**6. BR 8x8 (Banco de Registros)**
Contiene los registros de propósito general (8 registros de 8 bits). Permite leer dos registros simultáneamente y escribir en uno.
*   **Entrada de datos:** `entDat` (8 bits que provienen del `BusDatos`).
*   **Entradas de control:** `clk`, `wr` (Habilitación de escritura).
*   **Selectores:** `SelRegW` (3 bits para elegir dónde escribir), `SelRegRA` (3 bits para elegir qué registro sale por A), `SelRegRB` (3 bits para elegir qué registro sale por B).
*   **Salidas de datos:** `SalA` y `SalB` (Ambas de 8 bits, se conectan directamente a las entradas de la `ALU`).

**7. ALU (Unidad Aritmético Lógica)**
Realiza las operaciones matemáticas y lógicas.
*   **Entradas de datos:** `SalB` y `SalA` (8 bits cada una, desde el BR).
*   **Entrada de control:** `ope` (Bus que define qué operación realizará la ALU, ej. suma, resta, AND).
*   **Salidas de datos:** 
    *   Un bus principal de 8 bits que va hacia el Buffer Tri-estado.
    *   Un bus secundario de 8 bits que informa el estado de la operación hacia el bloque `Flags`.

**8. Buffer Tri-estado a la salida de la ALU**
Evita colisiones en el bus de datos principal.
*   **Entrada de datos:** Señal de 8 bits de la `ALU`.
*   **Entrada de control:** `SalAlu` (Habilita que el resultado pase al bus).
*   **Salida de datos:** Conectada al `BusDatos` de 8 bits.

**9. Flags (Registro de Banderas / Estado)**
Almacena las condiciones resultantes de la última operación de la ALU (Cero, Acarreo, Signo, etc.).
*   **Entrada de datos:** 8 bits desde la `ALU`.
*   **Entradas de control:** `clk`, `LF` (Load Flags), `clear`.
*   **Salida de datos:** `Flags` (8 bits que normalmente van hacia la Unidad de Control para la toma de decisiones en saltos condicionales).

**10. RI (Registro de Instrucción)**
Almacena la instrucción actual que se está decodificando y ejecutando.
*   **Entrada de datos:** 8 bits desde el `BusDatos`.
*   **Entradas de control:** `clk`, `Lri` (Carga del RI), `clear`.
*   **Salida de datos:** `CO` (Código de Operación, 8 bits que van hacia la Unidad de Control, la cual no está dibujada en este esquema pero es la encargada de generar todas las señales de control como `Seldir`, `Lpc`, `SalAlu`, etc.).

---

Para iniciar el código en VHDL usando la metodología top-down, lo ideal es que primero declares la *entidad* de cada uno de estos bloques de manera independiente, y luego crees un archivo estructural de nivel superior (Top-Level) donde uses *port maps* para cablear todas estas señales internas.



Para diseñar la **Unidad de Control (UC)** y traducirla a VHDL, es fundamental entender que este bloque actúa como el "cerebro" del procesador. Su función principal es recibir el código de la instrucción actual, evaluar el estado del procesador y generar, en el momento preciso (sincronizado con el reloj), todas las señales necesarias para que la Ruta de Datos ejecute la instrucción paso a paso.

Basándonos en la imagen de la Unidad de Control y conectándola con la Ruta de Datos que analizamos anteriormente, aquí tienes la descripción exacta de lo que debe realizar cada entrada y salida:

### Entradas (Inputs de la Unidad de Control)

Estas señales le dicen a la Unidad de Control qué está pasando y qué debe hacer.

*   **`rst` (Reset):** Señal asíncrona o síncrona que reinicia la máquina de estados de la Unidad de Control a su estado inicial (fase de *Fetch* o búsqueda de instrucción).
*   **`clk` (Clock):** Señal de reloj del sistema. Marca el ritmo al que la máquina de estados avanza de un paso al siguiente.
*   **`CO` (Código de Operación):** Es una de las entradas más importantes. Proviene de la salida del **Registro de Instrucción (`RI`)** (8 bits). Le indica a la UC qué instrucción específica debe ejecutar (por ejemplo, una suma, un salto, una carga de memoria).
*   **`FZ` (Flag Zero):** Proviene del bloque **`Flags`**. Indica si el resultado de la última operación de la ALU fue cero. Es fundamental para que la UC pueda decidir si ejecutar o ignorar instrucciones de saltos condicionales.

### Salidas (Outputs / Señales de Control)

La UC genera estas señales para gobernar el comportamiento de los distintos bloques de la Ruta de Datos. En VHDL, estas salidas dependerán del estado actual de la máquina de estados y del `CO`.

**Control del Contador de Programa (PC) y Direccionamiento:**
*   **`clear`:** Señal global que se conecta a los pines `Clear` del **`PC`**, registro **`H | L`**, **`RI`** y **`Flags`** para ponerlos a cero.
*   **`Lpc` (Load PC):** Ordena al **`PC`** que cargue la dirección de 16 bits que se encuentra en su entrada `entradaPC` (proveniente del registro H|L). Útil para saltos incondicionales.
*   **`Ipc` (Increment PC):** Ordena al **`PC`** que incremente su valor actual en 1. Se activa típicamente después de leer un byte de la memoria (por ejemplo, durante el *Fetch* de la instrucción).
*   **`SelDir`:** Gobierna el **Multiplexor de Direcciones**. 
    *   Si es `0`, la memoria recibe la dirección del `PC`.
    *   Si es `1`, la memoria recibe la dirección del registro `H | L`.

**Control de Memoria:**
*   **`inicia`:** Señal para habilitar o inicializar el bloque de la **Memoria 64Kx8**.
*   **`cs` (Chip Select):** Habilita el chip de la memoria. Si no está activo, la memoria ignora las lecturas y escrituras.
*   **`oe` (Output Enable):** Habilita la lectura. Ordena a la memoria que coloque el dato almacenado en la dirección `dir` hacia el `BusDatos`.
*   **`we` (Write Enable):** Habilita la escritura. Ordena a la memoria que guarde el valor presente en el `BusDatos` en la dirección especificada por `dir`.

**Control de Registros Auxiliares:**
*   **`LH` (Load High):** Ordena al registro **`H | L`** que guarde el byte presente en el `BusDatos` en su parte Alta (H).
*   **`LL` (Load Low):** Ordena al registro **`H | L`** que guarde el byte presente en el `BusDatos` en su parte Baja (L).
*   **`Lri` (Load RI):** Ordena al **Registro de Instrucción (`RI`)** que capture el byte presente en el `BusDatos`. Se activa durante la fase de *Fetch*.

**Control del Banco de Registros (BR 8x8):**
*   **`wr` (Write):** Habilita la escritura dentro del Banco de Registros.
*   **`SelRegW` (3 bits):** Indica en *cuál* de los 8 registros internos del BR se va a guardar el dato proveniente de la entrada `entDat`.
*   **`RA`:** Habilita la lectura para el puerto A del banco de registros.
*   **`SelRegRA` (3 bits):** Indica *cuál* de los 8 registros se enviará hacia la salida `SalA`.
*   **`RB`:** Habilita la lectura para el puerto B del banco de registros.
*   **`SelRegRB` (3 bits):** Indica *cuál* de los 8 registros se enviará hacia la salida `SalB`.

**Control de la ALU y el Bus de Datos:**
*   **`ope` (Operación ALU):** Bus de control que le indica a la **`ALU`** qué operación aritmética o lógica debe realizar con los datos presentes en `SalA` y `SalB`.
*   **`SalAlu`:** Habilita el **Buffer Tri-estado** a la salida de la ALU. Cuando está activo, el resultado de la operación se vuelca hacia el `BusDatos` principal para poder ser guardado en un registro o en memoria.

### Enfoque para VHDL
Para construir esta Unidad de Control en VHDL, la arquitectura estándar consiste en diseñar una **Máquina de Estados Finitos (FSM - Finite State Machine)**. 
1.  Un proceso síncrono (gobernado por `clk` y `rst`) actualizará el estado actual.
2.  Un proceso combinacional (que evalúa el `estado_actual` y el `CO`) determinará cuál será el `estado_siguiente` y pondrá en '1' o '0' todas las salidas listadas arriba dependiendo de la etapa de la instrucción (Fetch, Decode, Execute).



A continuación, identifico las operaciones, explico la lógica de las banderas y verifico su compatibilidad con tu arquitectura (la Ruta de Datos).

### 1. Identificación de Operaciones (`ope`)
El núcleo de esta ALU es el multiplexor (MUX) principal de la derecha, el cual es gobernado por la señal de control **`ope`**. Dado que el MUX tiene 8 canales de entrada (del 0 al 7), `ope` debe ser un bus de 3 bits. 

Siguiendo las conexiones de arriba hacia abajo hacia los puertos del MUX, las operaciones que realizará la ALU son:

### Operaciones de la ALU

*   **`ope = 000` (Puerto 0): Transferencia A.** La línea negra superior se conecta directamente a la entrada `SalA`.
*   **`ope = 001` (Puerto 1): Transferencia B.** La primera línea roja traza directamente hacia la conexión vertical que baja de la entrada `SalB`. Deja pasar el valor de B sin alteraciones.
*   **`ope = 010` (Puerto 2): AND Lógico.** La segunda línea roja proviene de la compuerta AND, realizando la operación `SalA AND SalB`.
*   **`ope = 011` (Puerto 3): NOT Lógico.** La tercera línea roja proviene de la compuerta NOT conectada al bus de A, realizando `NOT SalA`.
*   **`ope = 100` (Puerto 4): Decremento (DEC A).** La línea negra proviene del primer bloque restador, realizando `SalA - 01`.
*   **`ope = 101` (Puerto 5): Suma Aritmética (ADD).** La línea roja proviene del segundo bloque (sumador), realizando `SalA + SalB`.
*   **`ope = 110` (Puerto 6): Resta Aritmética (SUB).** La línea negra proviene del tercer bloque (restador), realizando `SalA - SalB`.
*   **`ope = 111` (Puerto 7): Incremento (INC A).** La línea roja inferior proviene del cuarto bloque (sumador), realizando `SalA + 01`.

### Coherencia con el Multiplexor de Banderas (FC)

Esta corrección hace que la lógica del segundo multiplexor (el de abajo, que controla la bandera de acarreo/préstamo `FC`) tenga un sentido estructural perfecto. 

Si observas las entradas de ese MUX inferior:
*   **Puertos 0, 1, 2 y 3:** Están conectados a los pines verdes que van a tierra (`0` lógico). Esto es correcto, porque las operaciones de Transferencia A, Transferencia B, AND y NOT no generan acarreo.
*   **Puertos 4 al 7:** Reciben directamente los cables rojo, azul, negro y azul (respectivamente) provenientes de las salidas `c out` (carry) y `b out` (borrow) de los cuatro bloques aritméticos.

### 2. Generación de Banderas (Flags)
El diseño maneja de manera muy inteligente el registro de estado (Flags) compactándolo en un solo bus de 8 bits (`SalidaFlags`) usando un *splitter* (separador de cables invertido). 

* **Bit 0 (`FZ` - Flag Zero):** Se genera mediante un comparador lógico (`= 0`) conectado a la salida de la ALU. Se pondrá en '1' si el resultado de cualquier operación es cero.
* **Bit 1 (`FS` - Flag Sign):** Toma directamente el bit más significativo (el bit 7, indicado por el splitter `6-0 | 7`) de la salida de la ALU. Si es '1', indica un resultado negativo (en complemento a 2).
* **Bit 2 (`FC` - Flag Carry/Borrow):** Utiliza un segundo multiplexor (el de abajo), también controlado por `ope`. Su función es dejar pasar el acarreo (`c out`) o el préstamo (`b out`) **solo** de las operaciones aritméticas (puertos 3, 4, 5 y 6). Para las operaciones lógicas y de transferencia (puertos 0, 1 y 2), manda un `0` a tierra, ya que estas no generan acarreo.
* **Bits 3 al 7:** Están conectados a tierra (`0` lógico), rellenando el bus para cumplir con el estándar de 8 bits del sistema.

### 3. Verificación de Compatibilidad
El diseño es **100% compatible** con el diagrama de bloques de la Ruta de Datos que analizamos anteriormente:

1.  **Entradas:** Tienes `SalA` (8 bits), `SalB` (8 bits) y `ope` (3 bits). Estos coinciden exactamente con las salidas del Banco de Registros (BR 8x8) y la señal de control proveniente de la Unidad de Control.
2.  **Salida de Datos:** Tienes `SalidaALU` (8 bits), que en el diagrama general se conecta al buffer tri-estado (`SalAlu`) para volver al bus de datos principal.
3.  **Salida de Estado:** Tu bus `SalidaFlags` está empaquetado en 8 bits. En el diagrama de la Ruta de Datos, la salida de la ALU entra a un registro llamado `Flags` que, efectivamente, tiene un bus de entrada de 8 bits de ancho (marcado con la línea cruzada y el número 8). 
