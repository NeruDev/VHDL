# Proyecto Procesador - VHDL

Este directorio contiene el diseño estructural de un procesador de 8 bits, incluyendo su Unidad de Control, Ruta de Datos y Memoria RAM.

## Actualizacion ISA implementada: XOR (y validacion de NOT)

Esta actualizacion incorpora la instruccion XOR como operacion ALU nativa y valida la instruccion NOT existente. No se agregaron SHL/SHR y el bus `ope` se mantiene en 3 bits.

### Detalles de implementacion
- **OpCode XOR:** `x"30"` (ISA) con semantica `R1 <- R0 xor R1`.
- **ALU:** `ope = "001"` para XOR, con `C = 0` en operaciones logicas; banderas `Z` y `S` se actualizan segun el resultado.
- **Control:** nuevo estado `S20` dedicado a XOR; decodificacion en la etapa `S02`.
- **NOT:** se mantiene `x"40"` con `ope = "011"`; revalidada en el testbench unitario.

### Testbench unitario (ALU)
Se agrego `tb/tb_alu_xor.vhd` para validar XOR y NOT, e incluir una regresion minima de AND y ADD.

### Simulacion rapida (ModelSim/Questa en PATH)
```powershell
# 1. Navegar al directorio del proyecto
cd "g:\REPOSITORIOS GITHUB\VHDL\procesador"

# 2. Compilar unidades necesarias
vlib work
vcom src\pkg\procesador_pkg.vhd
vcom src\datapath\alu.vhd
vcom tb\tb_alu_xor.vhd

# 3. Ejecutar el testbench
vsim work.tb_alu_xor
run -all
```
> Si ModelSim/Questa no esta en PATH, ajuste las rutas a `vcom` y `vsim`.

## Instrucciones de Compilación desde PowerShell

Para compilar el proyecto utilizando **Quartus II 13.0.1 (Service Pack 1)** desde la línea de comandos en Windows 11, ejecute la siguiente secuencia de comandos:

```powershell
# 1. Navegar al directorio del proyecto
cd "g:\REPOSITORIOS GITHUB\VHDL\procesador"

# 2. Ejecutar el flujo de compilación completo (Analysis & Synthesis, Fitter, Assembler, TimeQuest)
& "C:\altera\13.0sp1\quartus\bin64\quartus_sh.exe" --flow compile procesador_top
```

## Alternativa: Símbolo del Sistema (CMD)

Si prefiere utilizar CMD, la secuencia de comandos es la siguiente:

```cmd
:: 1. Cambiar al directorio del proyecto (usar /d para cambiar de unidad si es necesario)
cd /d "g:\REPOSITORIOS GITHUB\VHDL\procesador"

:: 2. Ejecutar la compilación
"C:\altera\13.0sp1\quartus\bin64\quartus_sh.exe" --flow compile procesador_top
```

## Solución de Problemas y Comandos Individuales

Si la compilación automática (`--flow compile`) falla, puede ejecutar cada etapa de forma independiente para identificar el error:

```powershell
# Etapa 1: Análisis y Síntesis (Verifica errores de sintaxis VHDL)
& "C:\altera\13.0sp1\quartus\bin64\quartus_map.exe" procesador_top

# Etapa 2: Fitter (Ajuste a los recursos de la FPGA)
& "C:\altera\13.0sp1\quartus\bin64\quartus_fit.exe" procesador_top

# Etapa 3: Assembler (Generación del archivo .sof/.pof para programar)
& "C:\altera\13.0sp1\quartus\bin64\quartus_asm.exe" procesador_top

# Etapa 4: TimeQuest Timing Analyzer (Análisis de tiempos)
& "C:\altera\13.0sp1\quartus\bin64\quartus_sta.exe" procesador_top
```

### Notas Adicionales
- **Entidad de Nivel Superior:** `procesador_top`
- **Familia de FPGA:** Cyclone II
- **Referencia de Servidor de Lenguaje:** El proyecto utiliza `vhdl_ls.toml` en la raíz para la gestión de librerías (`work`).
- **Simulación:** Los testbenches se encuentran en la carpeta `tb/` y deben ser instanciados referenciando a la librería `work`.

## Estructura del Proyecto
- `src/`: Código fuente VHDL (módulos y paquetes).
- `tb/`: Testbenches para validación.
- `procesador_top.qpf`: Archivo de proyecto Quartus.
- `procesador_top.qsf`: Archivo de asignaciones y configuraciones.

## Funcionalidades Implementadas

### Ampliación del ISA: Instrucción XOR
- **Estado:** ✅ Completado
- **OpCode:** `0x30` (`OP_XOR`)
- **Descripción:** Realiza la operación lógica XOR bit a bit entre el registro R0 y R1, almacenando el resultado en R1 (`R1 <- R0 xor R1`). Actualiza las banderas Zero (`Z`) y Signo (`S`). El acarreo (`C`) se limpia.
- **Archivos Modificados:**
    - `src/pkg/procesador_pkg.vhd`: Definición del OpCode constante.
    - `src/datapath/alu.vhd`: Implementación de la lógica en el `case` de la ALU (ope `001`).
    - `src/control/unidad_control.vhd`: Adición del estado `S20` y decodificación del OpCode.

## Plan de Implementación: Ampliación del ISA

Para ejecutar la ampliación del set de instrucciones sugerida (instrucciones lógicas y de desplazamiento), se seguirá la siguiente hoja de ruta técnica:

### Fase 1: Definición de OpCodes (`src/pkg/procesador_pkg.vhd`)
- Asignar nuevos códigos de operación (OpCodes) para las instrucciones: `XOR`, `NOT`, `SHL` (desplazamiento izquierda) y `SHR` (desplazamiento derecha).
- Definir constantes adicionales si es necesario para los códigos de operación de la ALU (`ope`).

### Fase 2: Actualización de la ALU (`src/datapath/alu.vhd`)
- Modificar el proceso combinacional de la ALU para incluir los nuevos casos en el `case(ope)`.
- Implementar la lógica de desplazamiento utilizando el operador `shift_left`/`shift_right` o mediante concatenación.
- Asegurar que las banderas (`Z`, `S`, `C`) se actualicen correctamente para estas nuevas operaciones.

### Fase 3: Modificación de la Unidad de Control (`src/control/unidad_control.vhd`)
- Actualizar la Máquina de Estados (FSM) para reconocer los nuevos OpCodes durante la etapa de decodificación.
- Configurar las señales de control necesarias para cada nueva instrucción (ej. habilitar la salida de la ALU, cargar el registro destino, etc.).
- La mayoría de estas instrucciones seguirán un ciclo de ejecución similar a las aritméticas actuales (Fetch -> Decode -> Execute -> Writeback).

### Fase 4: Validación y Pruebas (`tb/procesador_tb.vhd`)
- Crear un nuevo programa de prueba en la inicialización de la `memoria_ram.vhd` que utilice las nuevas instrucciones.
- Ejecutar la simulación y verificar mediante los testbenches que los resultados en los registros y las banderas sean los esperados.

### Fase 5: Síntesis Final
- Ejecutar el flujo de compilación en Quartus para asegurar que la lógica adicional no exceda los recursos de la FPGA ni penalice críticamente los tiempos de propagación.

## Futuras Mejoras y Expansiones Sugeridas

Para evolucionar la arquitectura actual del procesador, se sugieren las siguientes implementaciones:

1. **Implementación de un Stack Pointer (SP):**
   - **Justificación:** Actualmente el procesador no soporta llamadas a subrutinas (CALL/RET). Un puntero de pila permitiría almacenar direcciones de retorno en la RAM, facilitando la modularidad del código y el uso de funciones complejas.

2. **Ampliación del Set de Instrucciones (ISA):**
   - **Justificación:** Agregar instrucciones lógicas adicionales (XOR, NOT) o de desplazamiento (SHL, SHR). Esto aumentaría la versatilidad del procesador para tareas de manipulación de bits sin complicar excesivamente la Unidad de Control.

3. **Sistema de Interrupciones Externas:**
   - **Justificación:** Permitir que eventos externos (pulsadores, sensores) detengan la ejecución actual para atender una rutina específica. Esto es fundamental para aplicaciones de tiempo real y control de periféricos.

4. **Controlador de Entrada/Salida (I/O) Mapeado en Memoria:**
   - **Justificación:** Reservar un rango de direcciones de la RAM para interactuar con periféricos (Displays de 7 segmentos, LEDs, UART). Facilitaría la depuración visual en la FPGA al poder "escribir" directamente en los dispositivos de salida.

5. **Pipeline de 2 Etapas (Fetch y Execute):**
   - **Justificación:** Separar la búsqueda de la instrucción de su ejecución para que ocurran en ciclos de reloj distintos pero solapados. Esto aumentaría significativamente la frecuencia máxima de operación y el rendimiento (MIPS).
