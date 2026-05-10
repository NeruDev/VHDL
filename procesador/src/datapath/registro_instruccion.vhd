library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity registro_instruccion is
    port (
        clk         : in  std_logic;
        clear       : in  std_logic;
        Lri         : in  std_logic;
        BusDatos_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        CO          : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of registro_instruccion is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                CO <= (others => '0');
            elsif Lri = '1' then
                CO <= BusDatos_in;
            end if;
        end if;
    end process;
end architecture;
