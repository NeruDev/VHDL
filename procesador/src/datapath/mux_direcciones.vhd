library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity mux_direcciones is
    port (
        SelDir   : in  std_logic;
        salidaPC : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        SalidaHL : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        dir      : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of mux_direcciones is
begin
    dir <= salidaPC when SelDir = '0' else SalidaHL;
end architecture;
