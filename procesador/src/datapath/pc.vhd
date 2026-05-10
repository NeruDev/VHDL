library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.procesador_pkg.all;

entity pc is
    port (
        clk       : in  std_logic;
        clear     : in  std_logic;
        Lpc       : in  std_logic;
        Ipc       : in  std_logic;
        EntradaPC : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        salidaPC  : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of pc is
    signal cuenta : unsigned(ADDR_WIDTH-1 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                cuenta <= (others => '0');
            elsif Lpc = '1' then
                cuenta <= unsigned(EntradaPC);
            elsif Ipc = '1' then
                cuenta <= cuenta + 1;
            end if;
        end if;
    end process;
    
    salidaPC <= std_logic_vector(cuenta);
end architecture;
