-- Script de simulacion para tb_alu_xor (ModelSim/Questa)
-- Ejecutar desde la raiz del proyecto: g:\REPOSITORIOS GITHUB\VHDL\procesador

vlib work
vcom src/pkg/procesador_pkg.vhd
vcom src/datapath/alu.vhd
vcom tb/tb_alu_xor.vhd
vsim work.tb_alu_xor
run -all
