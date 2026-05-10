library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity registro_flags is
    port (
        clk       : in  std_logic;
        clear     : in  std_logic;
        Lf        : in  std_logic;
        Z_in      : in  std_logic;
        S_in      : in  std_logic;
        C_in      : in  std_logic;
        Flags_out : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of registro_flags is
    signal reg : std_logic_vector(7 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                reg <= (others => '0');
            elsif Lf = '1' then
                reg(0) <= Z_in;
                reg(1) <= S_in;
                reg(2) <= C_in;
                -- Los bits restantes no se utilizan, pero se mantienen en su valor actual
                -- o se podrían dejar en '0'. Los dejaremos en '0' por simplicidad.
                reg(7 downto 3) <= (others => '0');
            end if;
        end if;
    end process;

    Flags_out <= reg;
end architecture;
