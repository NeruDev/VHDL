project_new procesador_top -overwrite
set_global_assignment -name FAMILY "Cyclone II"
set_global_assignment -name TOP_LEVEL_ENTITY procesador_tb
set_global_assignment -name VHDL_FILE src/pkg/procesador_pkg.vhd
set_global_assignment -name VHDL_FILE src/control/unidad_control.vhd
set_global_assignment -name VHDL_FILE src/datapath/alu.vhd
set_global_assignment -name VHDL_FILE src/datapath/banco_registros.vhd
set_global_assignment -name VHDL_FILE src/datapath/buffer_triestado.vhd
set_global_assignment -name VHDL_FILE src/datapath/mux_direcciones.vhd
set_global_assignment -name VHDL_FILE src/datapath/pc.vhd
set_global_assignment -name VHDL_FILE src/datapath/registro_flags.vhd
set_global_assignment -name VHDL_FILE src/datapath/registro_hl.vhd
set_global_assignment -name VHDL_FILE src/datapath/registro_instruccion.vhd
set_global_assignment -name VHDL_FILE src/datapath/ruta_datos.vhd
set_global_assignment -name VHDL_FILE src/memoria/memoria_ram.vhd
set_global_assignment -name VHDL_FILE src/procesador_top.vhd
set_global_assignment -name VHDL_FILE tb/procesador_tb.vhd
set_global_assignment -name VHDL_FILE tb/tb_alu_xor.vhd
project_close
