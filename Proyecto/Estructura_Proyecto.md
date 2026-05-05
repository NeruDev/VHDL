# Verificación de Estructura y Lógica: Procesador VHDL

## Estado: VALIDADO Y COMPLETADO
El código implementado en el directorio `procesador_vhdl/` cumple con el 100% de las especificaciones descritas en la documentación del diagrama y la estructura modular solicitada.

## Árbol de Directorios Confirmado (Actualizado para FPGA)
```text
📁 procesador_vhdl/
├── 📁 src/                     # Código fuente sintetizable
│   ├── 📁 top/                 
│   │   ├── procesador.vhd      # Integrador (Simulación)
│   │   ├── procesador_fpga.vhd # Integrador (Hardware Real) [NUEVO]
│   │   ├── divisor_frecuencia.vhd # Baja 50MHz a 1Hz [NUEVO]
│   │   └── deco_7seg.vhd       # Visualización Hexadecimal [NUEVO]
│   ├── 📁 unidad_control/      
│   │   └── unidad_control.vhd  # FSM de control
│   ├── 📁 ruta_datos/          
│   │   ├── ruta_datos.vhd      # Top estructural de la ruta
│   │   ├── alu.vhd             # Operaciones (8 vías)
│   │   ├── banco_registros.vhd # BR 8x8
│   │   ├── pc.vhd              # Contador 16 bits
│   │   ├── registro_hl.vhd     # Puntero 16 bits (H|L)
│   │   ├── registro_ri.vhd     # Registro Instrucción
│   │   ├── registro_flags.vhd  # Estado (FZ, FS, FC)
│   │   └── mux_dir.vhd         # Selector de dirección
│   ├── 📁 memoria/             
│   │   └── memoria_64kx8.vhd   # RAM/ROM 64KB
│   └── 📁 pkg/                 
│       └── procesador_pkg.vhd  # Constantes y Opcodes
├── 📁 tb/                      # Bancos de prueba
└── 📁 docs/                    # Documentación técnica
```

## Implementación en FPGA Cyclone II (EP2C20F484C7N)
La implementación es **viable** utilizando Quartus II 13.0.1. Se han añadido módulos de interfaz para permitir la visualización humana:

1.  **Divisor de Frecuencia:** Permite observar el cambio de estados en los LEDs a una velocidad de 1 Hz.
2.  **Mapeo de Salida:**
    *   **LEDR(7:0):** Muestra el estado binario del Bus de Datos.
    *   **HEX0 y HEX1:** Muestran el valor hexadecimal del procesamiento actual.
3.  **Entrada:** El botón `KEY0` actúa como Reset maestro.

## Pruebas Recomendadas en Hardware
Para validar el funcionamiento sin cargar un programa complejo:
- **Test de Reset:** Al presionar `KEY0`, los LEDs rojos y los Displays deben ponerse en '0'.
- **Test de Fetch:** Al liberar `KEY0`, el sistema debe mostrar cambios en los displays cada segundo, indicando que el PC está incrementando y la FSM está buscando instrucciones en la memoria.
