library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.procesador_pkg.all;

entity banco_registros is
    port (
        clk      : in  std_logic;
        clear    : in  std_logic;
        wr       : in  std_logic;
        SelRegW  : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
        SelRegRA : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
        SelRegRB : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
        entDat   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        SalA     : out std_logic_vector(DATA_WIDTH-1 downto 0);
        SalB     : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of banco_registros is
    type registro_array is array (0 to (2**REG_ADDR_WIDTH)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal registros : registro_array;
begin
    -- Lectura asíncrona (como multiplexores combinacionales)
    SalA <= registros(to_integer(unsigned(SelRegRA)));
    SalB <= registros(to_integer(unsigned(SelRegRB)));

    -- Escritura síncrona
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                for i in 0 to (2**REG_ADDR_WIDTH)-1 loop
                    registros(i) <= (others => '0');
                end loop;
            elsif wr = '1' then
                registros(to_integer(unsigned(SelRegW))) <= entDat;
            end if;
        end if;
    end process;
end architecture;
