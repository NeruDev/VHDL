--------------------------------------------------------------------------------
-- Entidad: registro_instruccion (RI)
-- Arquitectura: rtl
-- Descripción: Captura y mantiene el Código de Operación (OpCode) durante el 
--              ciclo de instrucción para que la Unidad de Control lo decodifique.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity registro_instruccion is
    port (
        clk         : in  std_logic;
        clear       : in  std_logic;                        -- Reset sincrónico
        Lri         : in  std_logic;                        -- Load RI: Habilita la captura del OpCode
        BusDatos_in : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Dato desde memoria
        CO          : out std_logic_vector(DATA_WIDTH-1 downto 0)  -- OpCode hacia Unidad de Control
    );
end entity;

architecture rtl of registro_instruccion is
begin
    ----------------------------------------------------------------------------
    -- Proceso de captura
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                CO <= (others => '0');
            elsif Lri = '1' then
                -- Se carga el OpCode en la fase de Fetch
                CO <= BusDatos_in;
            end if;
        end if;
    end process;
end architecture;
