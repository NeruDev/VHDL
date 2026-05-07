-- ==============================================================================
-- Archivo: mux_dir.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Multiplexor de direcciones de 16 bits.
--              Selecciona la fuente de la dirección que se envía a la memoria
--              entre el Program Counter (PC) o el registro puntero (HL).
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity mux_dir is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map)
        -- ======================================================================
        entrada0 : in  std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Desde PC (0)
        entrada1 : in  std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Desde HL (1)
        SelDir   : in  std_logic;                                 -- Selector desde UC
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map)
        -- ======================================================================
        salida   : out std_logic_vector(ADDR_WIDTH - 1 downto 0)  -- Hacia Memoria
    );
end mux_dir;

architecture RTL of mux_dir is
begin
    -- Lógica combinacional simple
    salida <= entrada0 when (SelDir = '0') else entrada1;
end RTL;
