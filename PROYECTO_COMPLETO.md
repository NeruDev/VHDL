# PROYECTO COMPLETO - Procesador VHDL

## 1. Resumen del proyecto
Este proyecto implementa un procesador didactico de 8 bits con bus de datos de 8 bits y bus de direcciones de 16 bits. La arquitectura se basa en una Unidad de Control (UC) con una Maquina de Estados Finitos (FSM) que orquesta una Ruta de Datos (datapath) y una memoria RAM. El conjunto soporta instrucciones basicas de movimiento, logica, aritmetica, acceso a memoria y saltos condicionales.

## 2. Arquitectura general (topologia)
- **procesador_top** integra tres bloques principales: Unidad de Control, Ruta de Datos y Memoria RAM.
- **Unidad de Control (UC)**: FSM que genera senales de control segun el opcode (CO) y las banderas (Flags).
- **Ruta de Datos**: PC, RI, HL, banco de registros, ALU, buffer triestado, registro de banderas y multiplexor de direcciones.
- **Memoria RAM**: RAM de 256x8 con bus bidireccional y control por `cs`, `oe`, `we` e `inicia`.

## 3. Bloques funcionales y su rol
### 3.1 Memoria RAM (256x8)
- Direccionamiento efectivo por 8 bits bajos del bus de direcciones.
- Lectura asincrona con `cs=0` y `oe=0`.
- Escritura sincrona con `cs=0` y `we=1`.
- `inicia` recarga el programa base.

### 3.2 Contador de Programa (PC)
- Registro de 16 bits con carga paralela (`Lpc`) e incremento (`Ipc`).
- Salida continua al bus de direcciones cuando `SelDir=0`.

### 3.3 Registro de Instruccion (RI)
- Captura el OpCode desde `BusDatos` con `Lri=1`.
- Entrega el codigo de operacion a la UC por `CO`.

### 3.4 Registro HL
- Par de registros de 8 bits que forman una direccion de 16 bits.
- `LH` carga el byte alto, `LL` carga el byte bajo.
- `SalidaHL` alimenta el MUX de direcciones y el PC en saltos.

### 3.5 Banco de Registros (R0-R7)
- Dos lecturas combinacionales (A y B) y una escritura sincrona.
- `SelRegRA`, `SelRegRB` seleccionan operandos para ALU.
- `SelRegW` y `wr` controlan la escritura.

### 3.6 ALU + Buffer Triestado
- ALU de 8 bits con operaciones logicas y aritmeticas (`ope`).
- Genera banderas `Z`, `S`, `C`.
- Buffer triestado habilita la salida al bus con `SalAlu`.

### 3.7 Registro de Banderas
- Almacena `Z`, `S`, `C` bajo `LF`.
- Entrega `Flags` a la UC para saltos condicionales.

### 3.8 Multiplexor de Direcciones
- Selecciona entre `salidaPC` y `SalidaHL` con `SelDir`.

### 3.9 Unidad de Control (UC)
- FSM que implementa los estados S00 a S19.
- Decodifica `CO` y evalua `Flags` para dirigir el flujo.
- Genera senales de control para ruta de datos y memoria.

## 4. Senales y buses clave
- `BusDatos`: bus bidireccional de 8 bits compartido por ALU y RAM.
- `dir`: bus de direcciones de 16 bits hacia RAM (solo 8 bits bajos usados).
- `cs` y `oe` activos en bajo; `we` activo en alto.
- `clear` reinicia los registros internos en la ruta de datos.

## 5. Ciclo de operacion general
1. **Reset (S00)**: `clear=1` e `inicia=1`.
2. **Fetch (S01)**: `RI <- M(PC)` con `cs=0`, `oe=0`, `Lri=1`.
3. **Fetch1/Decode (S02)**: `PC <- PC + 1` y decodificacion del `CO`.
4. **Execute**:
   - **Instrucciones con operando de 16 bits** (LOAD, STORE, JMP, JZ, JC, JS):
     - **S03-S06** ensamblan HL desde memoria.
     - **S07/S08/S14** ejecutan la operacion final.
   - **ALU rapidas** (NOT, AND, DEC, INC, SUB, ADD, MOV):
     - Ejecutan en un solo estado (S09, S10, S15-S19).
   - **MOVI**: usa S12 para cargar y S13 para incrementar PC.
5. **FIN (S11)**: estado de detencion permanente.

## 6. Instrucciones soportadas y estados
| OpCode | Instruccion | Estados principales | Accion resumida |
| :--- | :--- | :--- | :--- |
| 70h | LOAD dir | S03-S07 | `R1 <- M(HL)` |
| 71h | STORE dir | S03-S08 | `M(HL) <- R1` |
| 40h | NOT R1 | S15 | `R1 <- not R1` |
| 41h | AND R1 | S16 | `R1 <- R0 and R1` |
| 42h | DEC R1 | S17 | `R1 <- R1 - 1` |
| 43h | INC R1 | S18 | `R1 <- R1 + 1` |
| 44h | SUB R1 | S19 | `R1 <- R0 - R1` |
| 45h | ADD R1 | S09 | `R1 <- R0 + R1` |
| 46h | MOV R0 | S10 | `R0 <- R1` |
| 47h | MOVI K | S12-S13 | `R1 <- M(PC)` + `PC <- PC + 1` |
| 80h | JMP dir | S03-S06, S14 | `PC <- HL` |
| 81h | JZ dir | S03-S06, S14 | `if FZ=1 then PC <- HL` |
| 82h | JC dir | S03-S06, S14 | `if FC=1 then PC <- HL` |
| 83h | JS dir | S03-S06, S14 | `if FS=1 then PC <- HL` |
| FFh | FIN | S11 | Detencion |

## 7. Programa de prueba (TEST_PROCESADOR)
El programa de prueba estresa la ruta de datos y la UC con:
- **Acceso a memoria**: LOAD y STORE validan `SelDir`, `cs`, `oe`, `we` y el bus.
- **Bandera de acarreo (FC)**: suma que desborda y salto `JC`.
- **Bandera de cero (FZ)**: `DEC` hasta cero y salto `JZ`.
- **Bandera de signo (FS)**: `NOT` para forzar MSB=1 y salto `JS`.
- **ALU logica**: `AND` entre R0 y R1.
- **Control de flujo**: `JMP` final y `FIN`.
- **Trampas**: bytes intermedios para detectar fallos en saltos.

## 8. Arbol de directorios (solo VHDL y testbenches)

### 8.1 JSON
```json
{
  "procesador": {
    "src": {
      "control": [
        "unidad_control.vhd"
      ],
      "datapath": [
        "alu.vhd",
        "banco_registros.vhd",
        "buffer_triestado.vhd",
        "mux_direcciones.vhd",
        "pc.vhd",
        "registro_flags.vhd",
        "registro_hl.vhd",
        "registro_instruccion.vhd",
        "ruta_datos.vhd"
      ],
      "memoria": [
        "memoria_ram.vhd"
      ],
      "pkg": [
        "procesador_pkg.vhd"
      ],
      "root": [
        "procesador_top.vhd"
      ]
    },
    "tb": [
      "procesador_tb.vhd",
      "tb_procesador_estres.vhd"
    ]
  }
}
```

### 8.2 YAML
```yaml
procesador:
  src:
    control:
      - unidad_control.vhd
    datapath:
      - alu.vhd
      - banco_registros.vhd
      - buffer_triestado.vhd
      - mux_direcciones.vhd
      - pc.vhd
      - registro_flags.vhd
      - registro_hl.vhd
      - registro_instruccion.vhd
      - ruta_datos.vhd
    memoria:
      - memoria_ram.vhd
    pkg:
      - procesador_pkg.vhd
    root:
      - procesador_top.vhd
  tb:
    - procesador_tb.vhd
    - tb_procesador_estres.vhd
```

## 9. Tabla de archivos y funcion (solo VHDL y tb)
| Archivo | Funcion | Bloque |
| :--- | :--- | :--- |
| procesador/src/procesador_top.vhd | Integra UC, ruta de datos y RAM | Top | 
| procesador/src/control/unidad_control.vhd | FSM y senales de control | UC |
| procesador/src/pkg/procesador_pkg.vhd | Constantes y componentes | Paquete |
| procesador/src/datapath/ruta_datos.vhd | Interconexion de bloques de ejecucion | Datapath |
| procesador/src/datapath/pc.vhd | Contador de programa con carga/incremento | Datapath |
| procesador/src/datapath/registro_instruccion.vhd | Registro de instruccion (CO) | Datapath |
| procesador/src/datapath/registro_hl.vhd | Registro HL para direccionamiento | Datapath |
| procesador/src/datapath/mux_direcciones.vhd | MUX entre PC y HL | Datapath |
| procesador/src/datapath/banco_registros.vhd | Banco de registros R0-R7 | Datapath |
| procesador/src/datapath/alu.vhd | ALU de 8 bits y banderas | Datapath |
| procesador/src/datapath/buffer_triestado.vhd | Buffer triestado hacia BusDatos | Datapath |
| procesador/src/datapath/registro_flags.vhd | Registro de banderas | Datapath |
| procesador/src/memoria/memoria_ram.vhd | RAM 256x8 con programa base | Memoria |
| procesador/tb/procesador_tb.vhd | Testbench basico del procesador | Testbench |
| procesador/tb/tb_procesador_estres.vhd | Testbench de estres con watchdog | Testbench |

## 10. Referencias usadas
- Proyecto/ARCHIVOS_BASE/MICRO_INSTRUCCIONES.md
- Proyecto/ARCHIVOS_BASE/FSM_PROCESADOR.md
- Proyecto/ARCHIVOS_BASE/TEST_PROCESADOR.md
- Proyecto/MODIFICACIONES/LOGISIM_PROCESADOR.md
