--------------------------------------------------------------------------------
-- Testbench: tb_alu_xor
-- Arquitectura: test
-- Descripcion: Verifica la operacion XOR y valida NOT junto a una regresion
--              minima de operaciones existentes (AND, ADD).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.procesador_pkg.all;

entity tb_alu_xor is
end entity;

architecture test of tb_alu_xor is

    ----------------------------------------------------------------------------
    -- Senales de interconexion
    ----------------------------------------------------------------------------
    signal SalA      : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal SalB      : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal ope       : std_logic_vector(2 downto 0) := (others => '0');
    signal SalidaALU : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal Z         : std_logic;
    signal S         : std_logic;
    signal C         : std_logic;

    ----------------------------------------------------------------------------
    -- Codigos de operacion de la ALU
    ----------------------------------------------------------------------------
    constant OPE_PASS : std_logic_vector(2 downto 0) := "000";
    constant OPE_XOR  : std_logic_vector(2 downto 0) := "001";
    constant OPE_AND  : std_logic_vector(2 downto 0) := "010";
    constant OPE_NOT  : std_logic_vector(2 downto 0) := "011";
    constant OPE_ADD  : std_logic_vector(2 downto 0) := "101";

begin

    ----------------------------------------------------------------------------
    -- Instancia de la ALU
    ----------------------------------------------------------------------------
    uut: entity work.alu port map (
        SalA      => SalA,
        SalB      => SalB,
        ope       => ope,
        SalidaALU => SalidaALU,
        Z         => Z,
        S         => S,
        C         => C
    );

    ----------------------------------------------------------------------------
    -- Proceso de estimulos y verificaciones
    ----------------------------------------------------------------------------
    stim_proc: process
    begin
        ------------------------------------------------------------------------
        -- XOR
        ------------------------------------------------------------------------
        SalA <= x"55";
        SalB <= x"AA";
        ope  <= OPE_XOR;
        wait for 1 ns;
        assert SalidaALU = x"FF" report "XOR 55 AA: resultado incorrecto" severity failure;
        assert Z = '0' report "XOR 55 AA: Z incorrecto" severity failure;
        assert S = '1' report "XOR 55 AA: S incorrecto" severity failure;
        assert C = '0' report "XOR 55 AA: C incorrecto" severity failure;

        SalA <= x"80";
        SalB <= x"80";
        ope  <= OPE_XOR;
        wait for 1 ns;
        assert SalidaALU = x"00" report "XOR 80 80: resultado incorrecto" severity failure;
        assert Z = '1' report "XOR 80 80: Z incorrecto" severity failure;
        assert S = '0' report "XOR 80 80: S incorrecto" severity failure;
        assert C = '0' report "XOR 80 80: C incorrecto" severity failure;

        SalA <= x"0F";
        SalB <= x"F0";
        ope  <= OPE_XOR;
        wait for 1 ns;
        assert SalidaALU = x"FF" report "XOR 0F F0: resultado incorrecto" severity failure;
        assert Z = '0' report "XOR 0F F0: Z incorrecto" severity failure;
        assert S = '1' report "XOR 0F F0: S incorrecto" severity failure;
        assert C = '0' report "XOR 0F F0: C incorrecto" severity failure;

        ------------------------------------------------------------------------
        -- NOT (existente)
        ------------------------------------------------------------------------
        SalA <= x"00";
        SalB <= x"00";
        ope  <= OPE_NOT;
        wait for 1 ns;
        assert SalidaALU = x"FF" report "NOT 00: resultado incorrecto" severity failure;
        assert Z = '0' report "NOT 00: Z incorrecto" severity failure;
        assert S = '1' report "NOT 00: S incorrecto" severity failure;
        assert C = '0' report "NOT 00: C incorrecto" severity failure;

        SalA <= x"FF";
        SalB <= x"00";
        ope  <= OPE_NOT;
        wait for 1 ns;
        assert SalidaALU = x"00" report "NOT FF: resultado incorrecto" severity failure;
        assert Z = '1' report "NOT FF: Z incorrecto" severity failure;
        assert S = '0' report "NOT FF: S incorrecto" severity failure;
        assert C = '0' report "NOT FF: C incorrecto" severity failure;

        ------------------------------------------------------------------------
        -- Regresion minima (AND, ADD)
        ------------------------------------------------------------------------
        SalA <= x"0F";
        SalB <= x"F3";
        ope  <= OPE_AND;
        wait for 1 ns;
        assert SalidaALU = x"03" report "AND 0F F3: resultado incorrecto" severity failure;
        assert Z = '0' report "AND 0F F3: Z incorrecto" severity failure;
        assert S = '0' report "AND 0F F3: S incorrecto" severity failure;
        assert C = '0' report "AND 0F F3: C incorrecto" severity failure;

        SalA <= x"FF";
        SalB <= x"01";
        ope  <= OPE_ADD;
        wait for 1 ns;
        assert SalidaALU = x"00" report "ADD FF 01: resultado incorrecto" severity failure;
        assert Z = '1' report "ADD FF 01: Z incorrecto" severity failure;
        assert S = '0' report "ADD FF 01: S incorrecto" severity failure;
        assert C = '1' report "ADD FF 01: C incorrecto" severity failure;

        report "Simulacion ALU XOR/NOT completada" severity note;
        wait;
    end process;

end architecture;
