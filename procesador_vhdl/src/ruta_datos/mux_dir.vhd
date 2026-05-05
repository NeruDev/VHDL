-- ==============================================================================
-- Archivo: mux_dir.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Multiplexor 2 a 1 para el bus de direcciones (16 bits).
-- Selecciona entre la salida del PC (0) y el registro H|L (1).
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity mux_dir is
    Port ( 
        entrada0 : in  std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Desde PC
        entrada1 : in  std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Desde H|L
        SelDir   : in  std_logic;                                 -- Selector desde UC
        salida   : out std_logic_vector(ADDR_WIDTH - 1 downto 0)  -- Hacia Memoria
    );
end mux_dir;

architecture RTL of mux_dir is
begin
    salida <= entrada0 when (SelDir = '0') else entrada1;
end RTL;
