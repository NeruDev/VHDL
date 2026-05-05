-- ==============================================================================
-- Archivo: divisor_frecuencia.vhd
-- Ubicación: src/top/
-- Descripción: Reduce el reloj de 50MHz a ~1Hz para visualización en LEDs.
-- ==============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divisor_frecuencia is
    Port ( 
        clk_50MHz : in  std_logic;
        clk_lento : out std_logic
    );
end divisor_frecuencia;

architecture RTL of divisor_frecuencia is
    signal contador : integer range 0 to 25000000 := 0;
    signal estado   : std_logic := '0';
begin
    process(clk_50MHz)
    begin
        if rising_edge(clk_50MHz) then
            if contador = 25000000 then
                contador <= 0;
                estado <= not estado;
            else
                contador <= contador + 1;
            end if;
        end if;
    end process;
    clk_lento <= estado;
end RTL;
