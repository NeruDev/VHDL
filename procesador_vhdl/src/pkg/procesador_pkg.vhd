-- ==============================================================================
-- Archivo: procesador_pkg.vhd
-- Ubicación: src/pkg/
-- Descripción: Paquete global de constantes y tipos para el procesador.
-- Basado en los esquemáticos de la Ruta de Datos y la ALU (Logisim).
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package procesador_pkg is

    -- ----------------------------------------------------------------------
    -- Parámetros de Arquitectura (Basados en Figura 1.7 y Ruta de Datos)
    -- ----------------------------------------------------------------------
    constant DATA_WIDTH : integer := 8;  -- Bus de Datos de 8 bits
    constant ADDR_WIDTH : integer := 16; -- Bus de Direcciones de 16 bits
    constant REG_SEL_W  : integer := 3;  -- 3 bits para seleccionar 1 de 8 registros
    
    -- ----------------------------------------------------------------------
    -- Códigos de Operación de la ALU (Opcodes de 3 bits definidos en Logisim)
    -- ----------------------------------------------------------------------
    constant ALU_OP_WIDTH : integer := 3;
    
    constant OP_TRANS_A : std_logic_vector(2 downto 0) := "000"; -- Pasa SalA
    constant OP_TRANS_B : std_logic_vector(2 downto 0) := "001"; -- Pasa SalB
    constant OP_AND     : std_logic_vector(2 downto 0) := "010"; -- SalA AND SalB
    constant OP_NOT_A   : std_logic_vector(2 downto 0) := "011"; -- NOT SalA
    constant OP_DEC_A   : std_logic_vector(2 downto 0) := "100"; -- SalA - 1
    constant OP_ADD     : std_logic_vector(2 downto 0) := "101"; -- SalA + SalB
    constant OP_SUB     : std_logic_vector(2 downto 0) := "110"; -- SalA - SalB
    constant OP_INC_A   : std_logic_vector(2 downto 0) := "111"; -- SalA + 1

end procesador_pkg;

package body procesador_pkg is
    -- Aquí se pueden definir funciones o procedimientos complejos si se requieren a futuro
end procesador_pkg;
