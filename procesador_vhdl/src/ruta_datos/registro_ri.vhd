-- ==============================================================================
-- Archivo: registro_ri.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Registro de Instrucción (RI) de 8 bits.
-- Captura la instrucción leída desde la memoria.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity registro_ri is
    Port ( 
        clk    : in  std_logic;
        clear  : in  std_logic;
        Lri    : in  std_logic; -- Load RI: Habilita la captura del bus
        
        entDat : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Viene del BusDatos
        CO     : out std_logic_vector(DATA_WIDTH - 1 downto 0)  -- Va a la Unidad de Control
    );
end registro_ri;

architecture RTL of registro_ri is
    signal registro_interno : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
begin

    process(clk, clear)
    begin
        if clear = '1' then
            registro_interno <= (others => '0');
            
        elsif rising_edge(clk) then
            if Lri = '1' then
                registro_interno <= entDat;
            end if;
        end if;
    end process;

    CO <= registro_interno;

end RTL;
