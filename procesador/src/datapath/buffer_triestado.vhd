library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity buffer_triestado is
    port (
        entrada  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        habilitar: in  std_logic;
        salida   : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of buffer_triestado is
begin
    salida <= entrada when habilitar = '1' else (others => 'Z');
end architecture;
