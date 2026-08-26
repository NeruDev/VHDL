-- ==============================================================================
-- Archivo: procesador_pkg.vhd
-- Ubicación: src/pkg/
-- Descripción: Paquete global de constantes y definiciones del procesador.
--              Contiene los parámetros de arquitectura y los códigos de 
--              operación (Opcodes) para la ALU y el procesador.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package procesador_pkg is

    -- ----------------------------------------------------------------------
    -- PARÁMETROS DE ARQUITECTURA
    -- ----------------------------------------------------------------------
    constant DATA_WIDTH : integer := 8;  -- Bus de Datos: 8 bits
    constant ADDR_WIDTH : integer := 16; -- Bus de Direcciones: 16 bits (64KB)
    constant REG_SEL_W  : integer := 3;  -- Selección de 8 registros (2^3)
    
    -- ----------------------------------------------------------------------
    -- CÓDIGOS DE OPERACIÓN DE LA ALU (Microinstrucciones)
    -- ----------------------------------------------------------------------
    -- Estos códigos se envían desde la UC directamente a la ALU.
    constant ALU_OP_WIDTH : integer := 3;
    
    constant OP_TRANS_A : std_logic_vector(2 downto 0) := "000"; -- Salida = SalA
    constant OP_TRANS_B : std_logic_vector(2 downto 0) := "001"; -- Salida = SalB
    constant OP_AND     : std_logic_vector(2 downto 0) := "010"; -- Salida = SalA AND SalB
    constant OP_NOT_A   : std_logic_vector(2 downto 0) := "011"; -- Salida = NOT SalA
    constant OP_DEC_A   : std_logic_vector(2 downto 0) := "100"; -- Salida = SalA - 1
    constant OP_ADD     : std_logic_vector(2 downto 0) := "101"; -- Salida = SalA + SalB
    constant OP_SUB     : std_logic_vector(2 downto 0) := "110"; -- Salida = SalA - SalB
    constant OP_INC_A   : std_logic_vector(2 downto 0) := "111"; -- Salida = SalA + 1

    -- ----------------------------------------------------------------------
    -- OPCODES DEL PROCESADOR (Instrucciones de Alto Nivel)
    -- ----------------------------------------------------------------------
    -- Formato de instrucción: [Opcode (5 bits) | Registro (3 bits)]
    -- ----------------------------------------------------------------------
    
    -- Instrucciones Aritmético-Lógicas (Registro -> Registro)
    constant INST_NOP   : std_logic_vector(4 downto 0) := "00000"; -- No Operación
    constant INST_ADD   : std_logic_vector(4 downto 0) := "00001"; -- Rd = Rd + R1
    constant INST_SUB   : std_logic_vector(4 downto 0) := "00010"; -- Rd = Rd - R1
    constant INST_AND   : std_logic_vector(4 downto 0) := "00011"; -- Rd = Rd AND R1
    constant INST_NOT   : std_logic_vector(4 downto 0) := "00100"; -- Rd = NOT Rd
    constant INST_INC   : std_logic_vector(4 downto 0) := "00101"; -- Rd = Rd + 1
    constant INST_DEC   : std_logic_vector(4 downto 0) := "00110"; -- Rd = Rd - 1
    constant INST_MOV   : std_logic_vector(4 downto 0) := "00111"; -- Rd = R1
    
    -- Instrucciones de Transferencia (Memoria/Inmediatos)
    constant INST_LDI   : std_logic_vector(4 downto 0) := "01000"; -- Rd = <byte_inmediato>
    constant INST_LDHL  : std_logic_vector(4 downto 0) := "01001"; -- HL = <dir_16_bits>
    constant INST_LDA   : std_logic_vector(4 downto 0) := "01010"; -- Rd = RAM[HL]
    constant INST_STA   : std_logic_vector(4 downto 0) := "01011"; -- RAM[HL] = Rd
    
    -- Instrucciones de Control (Saltos)
    constant INST_JMP   : std_logic_vector(4 downto 0) := "10000"; -- PC = HL
    constant INST_JZ    : std_logic_vector(4 downto 0) := "10001"; -- Si Z=1, PC = HL
    constant INST_JNZ   : std_logic_vector(4 downto 0) := "10010"; -- Si Z=0, PC = HL
    constant INST_JC    : std_logic_vector(4 downto 0) := "10011"; -- Si C=1, PC = HL
    constant INST_JNC   : std_logic_vector(4 downto 0) := "10100"; -- Si C=0, PC = HL
    constant INST_JS    : std_logic_vector(4 downto 0) := "10101"; -- Si S=1, PC = HL
    constant INST_JNS   : std_logic_vector(4 downto 0) := "10110"; -- Si S=0, PC = HL

end procesador_pkg;

package body procesador_pkg is
    -- Aquí se pueden definir funciones o procedimientos complejos si se requieren a futuro
end procesador_pkg;
