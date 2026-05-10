library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity registro_hl is
    port (
        clk         : in  std_logic;
        clear       : in  std_logic;
        LH          : in  std_logic;
        LL          : in  std_logic;
        BusDatos_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        SalidaHL    : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of registro_hl is
    signal H, L : std_logic_vector(DATA_WIDTH-1 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                H <= (others => '0');
                L <= (others => '0');
            else
                if LH = '1' then
                    H <= BusDatos_in;
                end if;
                if LL = '1' then
                    L <= BusDatos_in;
                end if;
            end if;
        end if;
    end process;

    SalidaHL <= H & L;
end architecture;
