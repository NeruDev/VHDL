# Proyecto Procesador - VHDL

Este directorio contiene el diseno estructural de un procesador de 8 bits con Unidad de Control, Ruta de Datos y Memoria RAM.

## Nueva funcion ISA actualizada: XOR (con NOT existente)

La ampliacion agregada y vigente es `XOR` como operacion nativa de la ALU.  
La instruccion `NOT` ya existia y se mantiene sobre la entrada A (R1).

### Estado funcional
- **XOR**
  - **OpCode ISA:** `x"30"` (`OP_XOR`)
  - **Semantica:** `R1 <- R0 xor R1`
  - **Control:** decodificacion en `S02` y ejecucion en estado `S20`
  - **ALU:** `ope = "001"`
  - **Flags:** `Z` y `S` segun resultado, `C = 0`
- **NOT (existente)**
  - **OpCode ISA:** `x"40"` (`OP_NOT`)
  - **Semantica:** `R1 <- not R1` (NOT sobre A)
  - **ALU:** `ope = "011"`
  - **Flags:** `Z` y `S` segun resultado, `C = 0`

### Archivos impactados por la integracion de XOR
- `src/pkg/procesador_pkg.vhd` (constante `OP_XOR`)
- `src/control/unidad_control.vhd` (estado `S20` y decodificacion de `OP_XOR`)
- `src/datapath/alu.vhd` (caso `ope = "001"` para XOR)
- `tb/tb_alu_xor.vhd` (validacion unitaria de XOR y regresion de NOT/AND/ADD)

## Ejecucion completa del proyecto (PowerShell)

> Requisito: Quartus II 13.0.1 SP1 instalado en `C:\altera\13.0sp1\quartus\bin64`.

```powershell
# 1) Ir al proyecto
cd "G:\REPOSITORIOS GITHUB\VHDL\procesador"

# 2) Asegurar top-level de hardware (evita compilar testbench por error)
& "C:\altera\13.0sp1\quartus\bin64\quartus_sh.exe" -t .\set_top_hw.tcl

# 3) Compilacion completa de hardware
& "C:\altera\13.0sp1\quartus\bin64\quartus_sh.exe" --flow compile procesador_top
```

### Si falla `--flow compile`, ejecutar por etapas

```powershell
cd "G:\REPOSITORIOS GITHUB\VHDL\procesador"
& "C:\altera\13.0sp1\quartus\bin64\quartus_map.exe" procesador_top
& "C:\altera\13.0sp1\quartus\bin64\quartus_fit.exe" procesador_top
& "C:\altera\13.0sp1\quartus\bin64\quartus_asm.exe" procesador_top
& "C:\altera\13.0sp1\quartus\bin64\quartus_sta.exe" procesador_top
```

## Simulacion de prueba unitaria ALU (PowerShell + ModelSim/Questa)

```powershell
cd "G:\REPOSITORIOS GITHUB\VHDL\procesador"
vlib work
vcom src\pkg\procesador_pkg.vhd
vcom src\datapath\alu.vhd
vcom tb\tb_alu_xor.vhd
vsim work.tb_alu_xor
run -all
```

Tambien se puede usar el script:

```powershell
cd "G:\REPOSITORIOS GITHUB\VHDL\procesador"
vsim -do .\tb\run_tb_alu_xor.do
```

## Notas de coherencia del proyecto

- **Entidad top de hardware:** `procesador_top` (`procesador_top.qsf`)
- **Familia FPGA:** Cyclone II
- **Scripts auxiliares de top-level:**
  - `set_top_hw.tcl`: restaura top-level a `procesador_top`
  - `compile_tb.tcl`: configura `procesador_tb` como top-level de prueba
  - `set_top_stress.tcl`: configura `tb_procesador_estres` como top-level de prueba
- **Servidor de lenguaje:** `vhdl_ls.toml` existe en la raiz del workspace `VHDL` (directorio padre de `procesador`)

## Estructura detallada del proyecto

- `src/`: Código fuente VHDL.
  - `control/`: Unidad de Control (`unidad_control.vhd`).
  - `datapath/`: Componentes de ejecución (ALU, Registros, PC, etc.).
  - `memoria/`: Memoria RAM (`memoria_ram.vhd`).
  - `pkg/`: Definiciones globales (`procesador_pkg.vhd`).
  - `procesador_top.vhd`: Entidad de nivel superior.
- `tb/`: Testbenches y scripts.
  - `procesador_tb.vhd`: Testbench del sistema completo.
  - `tb_alu_xor.vhd`: Testbench unitario de la ALU.
  - `tb_procesador_estres.vhd`: Testbench de carga y estrés.
- `procesador_top.qpf/qsf`: Archivos de proyecto Quartus II.
- `set_top_*.tcl`: Scripts para configurar el top-level en Quartus.

## Referencias de Diseño y Validación

Para la construcción y validación de este procesador, se han utilizado los siguientes documentos de diseño como base (disponibles en la documentación del proyecto padre):

- **Arquitectura e Interconexión:** `Proyecto/ARCHIVOS_BASE/MICRO_INSTRUCCIONES.md`
- **Lógica de Control (FSM):** `Proyecto/ARCHIVOS_BASE/FSM_PROCESADOR.md`
- **Plan de Pruebas y Programa Base:** `Proyecto/ARCHIVOS_BASE/TEST_PROCESADOR.md`

Para una descripción detallada de la arquitectura y el set de instrucciones completo, consulte el archivo [PROYECTO_COMPLETO.md](../PROYECTO_COMPLETO.md) en la raíz.

## Futuras mejoras sugeridas

1. Implementar `SHL/SHR` manteniendo compatibilidad con el bus `ope` de 3 bits.
2. Agregar stack pointer para `CALL/RET`.
3. Incorporar interrupciones externas.
4. Definir perifericos mapeados a memoria.
