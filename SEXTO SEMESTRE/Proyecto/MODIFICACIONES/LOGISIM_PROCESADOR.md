# Análisis Detallado del Procesador Logisim

Este documento detalla la arquitectura del procesador microprogramado, consolidando tablas de señales, descripciones funcionales y diagramas de flujo por cada bloque del sistema.

---

## 1. Memoria RAM (256x8)

### 1.1. Tabla de Señales
| Tipo | Señal | Ancho | Descripción |
| :--- | :--- | :---: | :--- |
| **Entrada** | `dirL` | 8 bits | Dirección de memoria (00h-FFh). |
| **I/O** | `BusDatos` | 8 bits | Bus bidireccional para datos e instrucciones. |
| **Control** | `we` | 1 bit | Write Enable: Habilita la escritura. |
| **Control** | `oe` | 1 bit | Output Enable: Habilita la lectura (**Activa en Bajo**). |
| **Control** | `cs` | 1 bit | Chip Select: Activa el componente (**Activa en Bajo**). |
| **Control** | `clk` | 1 bit | Señal de sincronización para operaciones de escritura. |

### 1.2. Descripción Funcional
La memoria física es de **256x8**. El direccionamiento se realiza a través de los 8 bits bajos (`dirL`) del bus de direcciones generado por el multiplexor `muxpchl`. 
*   **Nota de Lógica:** Las señales `cs` y `oe` son invertidas mediante compuertas NOT externas a la Unidad de Control.

---

## 2. Contador de Programa (PC)

### 2.1. Tabla de Señales
| Tipo | Señal | Ancho | Descripción |
| :--- | :--- | :---: | :--- |
| **Entrada** | `EntradaPC` | 16 bits | Dirección de destino para saltos (proviene de HL). |
| **Salida** | `salidaPC` | 16 bits | Dirección de la instrucción actual. |
| **Control** | `Lpc` | 1 bit | Carga la dirección presente en `EntradaPC`. |
| **Control** | `Ipc` | 1 bit | Incrementa la dirección (siguiente instrucción). |
| **Control** | `clk` | 1 bit | Señal de sincronización. |
| **Control** | `clr` | 1 bit | Reinicio del contador a 0000h. |

---

## 3. Registro de Instrucción (RI)

### 3.1. Tabla de Señales
| Tipo | Señal | Ancho | Descripción |
| :--- | :--- | :---: | :--- |
| **Entrada** | `BusDatos` | 8 bits | Captura del OpCode desde la RAM. |
| **Salida** | `CO` | 8 bits | Código de operación hacia la Unidad de Control. |
| **Control** | `Lri` | 1 bit | Habilita la carga del registro en el flanco de reloj. |
| **Control** | `clk` | 1 bit | Señal de sincronización. |
| **Control** | `clr` | 1 bit | Reinicio del registro. |

---

## 4. Registro Puntero (HL)

### 4.1. Tabla de Señales
| Tipo | Señal | Ancho | Descripción |
| :--- | :--- | :---: | :--- |
| **Entrada** | `BusDatos` | 8 bits | Byte de datos para cargar en H o L. |
| **Salida** | `SalidaHL` | 16 bits | Dirección de 16 bits concatenada. |
| **Control** | `LH` | 1 bit | Carga el byte alto (H). |
| **Control** | `LL` | 1 bit | Carga el byte bajo (L). |
| **Control** | `clk` | 1 bit | Señal de sincronización. |
| **Control** | `clr` | 1 bit | Reinicio de ambos registros (H y L). |

---

## 5. Banco de Registros (BR)

### 5.1. Tabla de Señales
| Tipo | Señal | Ancho | Descripción |
| :--- | :--- | :---: | :--- |
| **Entrada** | `entDat` | 8 bits | Dato a escribir desde el bus. |
| **Salida** | `SalA` | 8 bits | Operando A para la ALU. |
| **Salida** | `SalB` | 8 bits | Operando B para la ALU. |
| **Control** | `SelRegW` | 3 bits | Dirección del registro de escritura (0-7). |
| **Control** | `SelRegRA`| 3 bits | Dirección del registro de lectura A (0-7). |
| **Control** | `SelRegRB`| 3 bits | Dirección del registro de lectura B (0-7). |
| **Control** | `wr` | 1 bit | Habilitación de escritura. |
| **Control** | `clk` | 1 bit | Señal de sincronización. |
| **Control** | `clr` | 1 bit | Reinicio de todos los registros del banco. |

---

## 6. Unidad Aritmético-Lógica (ALU)

### 6.1. Tabla de Señales
| Tipo | Señal | Ancho | Descripción |
| :--- | :--- | :---: | :--- |
| **Entrada** | `SalA` | 8 bits | Operando A desde el Banco de Registros. |
| **Entrada** | `SalB` | 8 bits | Operando B desde el Banco de Registros. |
| **Salida** | `SalidaALU`| 8 bits | Resultado de la operación aritmética/lógica. |
| **Salida** | `Z, S, C` | 1 bit c/u | Banderas de estado enviadas al Registro de Flags. |
| **Control** | `ope` | 3 bits | Selector de operación. |
| **Control** | `SalAlu` | 1 bit | Habilitación del **Buffer Tri-estado** de salida. |

### 6.2. Descripción del Buffer Tri-estado
La ALU incluye un **Buffer Tri-estado** (bloque `bufferalu`) en su salida. Este componente actúa como un interruptor controlado por la señal `SalAlu`. 
*   Cuando `SalAlu = 1`, el resultado de la operación se coloca en el `BusDatos`. 
*   Cuando `SalAlu = 0`, la salida queda en alta impedancia ('Z'), permitiendo que otros componentes (como la RAM) utilicen el bus sin colisiones.

---

## 7. Registro de Flags (Banderas)

### 7.1. Tabla de Señales
| Tipo | Señal | Ancho | Descripción |
| :--- | :--- | :---: | :--- |
| **Entrada** | `Z, S, C` | 1 bit c/u | Banderas generadas por la ALU. |
| **Salida** | `Flags` | 8 bits | Registro de estado para la UC. |
| **Control** | `Lf` | 1 bit | Habilitación de carga (Load Flags). |
| **Control** | `clk` | 1 bit | Señal de sincronización. |
| **Control** | `clr` | 1 bit | Reinicio del registro de banderas. |

---

## 8. Unidad de Control (UC)

### 8.1. Tabla de Entradas y Salidas Individuales
| Tipo | Señal | Ancho | Función / Destino |
| :--- | :--- | :---: | :--- |
| **IN** | `clk` | 1 bit | Reloj del sistema. |
| **IN** | `rst` | 1 bit | Reset general. |
| **IN** | `Flags` | 8 bits | Estado de la última operación (ALU). |
| **IN** | `CO` | 8 bits | Código de operación (Instrucción). |
| **OUT** | `Clear` | 1 bit | Reinicio de componentes del DataPath. |
| **OUT** | `Lpc` | 1 bit | Control de carga en el PC. |
| **OUT** | `Ipc` | 1 bit | Control de incremento en el PC. |
| **OUT** | `SelDir` | 1 bit | Control del multiplexor `muxpchl`. |
| **OUT** | `inicia` | 1 bit | Inicialización de memoria RAM. |
| **OUT** | `cs` | 1 bit | Chip Select (**Pasa por NOT externo**). |
| **OUT** | `oe` | 1 bit | Output Enable (**Pasa por NOT externo**). |
| **OUT** | `we` | 1 bit | Write Enable para RAM. |
| **OUT** | `LH` | 1 bit | Carga del byte alto de HL. |
| **OUT** | `LL` | 1 bit | Carga del byte bajo de HL. |
| **OUT** | `Lri` | 1 bit | Carga del Registro de Instrucción. |
| **OUT** | `SelRegW` | 3 bits | Selección de registro destino en BR. |
| **OUT** | `SelRegRA`| 3 bits | Selección de lectura A en BR. |
| **OUT** | `SelRegRB`| 3 bits | Selección de lectura B en BR. |
| **OUT** | `wr` | 1 bit | Escritura en el Banco de Registros. |
| **OUT** | `ope` | 3 bits | Selección de operación en la ALU. |
| **OUT** | `SalAlu` | 1 bit | Control del Buffer Tri-estado de la ALU. |
| **OUT** | `LF` | 1 bit | Actualización del Registro de Flags. |
| **OUT** | `fin` | 1 bit | Indicador de término de programa. |

---

## 9. Multiplexor de Direcciones (MUXPCHL)

### 9.1. Tabla de Señales
| Tipo | Señal | Ancho | Descripción |
| :--- | :--- | :---: | :--- |
| **Entrada 0** | `salidaPC` | 16 bits | Dirección secuencial del programa. |
| **Entrada 1** | `SalidaHL` | 16 bits | Dirección de datos apuntada por HL. |
| **Salida** | `dir` | 16 bits | Dirección seleccionada enviada a la memoria. |
| **Control** | `SelDir` | 1 bit | Selector (0: Modo Instrucción, 1: Modo Datos). |

### 9.2. Descripción Funcional
Este bloque permite que la memoria RAM sea compartida para instrucciones y datos. Durante la fase de Fetch, la UC pone `SelDir = 0` para leer desde el PC. Durante instrucciones de acceso a memoria (ej. cargar un registro desde una dirección), la UC pone `SelDir = 1` para usar el puntero HL.

---

## 10. Ciclo de Operación General
1. **Fetch:** `SelDir = 0` -> RAM -> `Lri = 1` -> RI. `Ipc = 1` para siguiente instrucción.
2. **Decode:** UC analiza OpCode y Flags para decidir micro-operaciones.
3. **Execute:** UC activa señales de BR, ALU, HL o RAM según la instrucción.
4. **Write-back:** Se almacenan resultados, se activan `wr` o `we`, y se actualiza el registro de Flags con `LF = 1`.
5. **End:** Si OpCode = `FFh`, se activa la señal `fin`.
