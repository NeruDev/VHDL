-- ==============================================================================
-- Archivo: tb_alu.vhd
-- Ubicación: tb/
-- Descripción: Banco de pruebas aislado para validar la ALU.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity tb_alu is
-- Un testbench no tiene puertos de entrada/salida
end tb_alu;

architecture behavior of tb_alu is

    -- Componente a probar (Design Under Test - DUT)
    component alu
    Port ( 
        SalA        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        SalB        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        ope         : in  std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
        SalidaALU   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        SalidaFlags : out std_logic_vector(7 downto 0)
    );
    end component;

    -- Señales para conectar con el DUT
    signal SalA_tb        : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal SalB_tb        : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal ope_tb         : std_logic_vector(ALU_OP_WIDTH - 1 downto 0) := (others => '0');
    signal SalidaALU_tb   : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal SalidaFlags_tb : std_logic_vector(7 downto 0);

begin

    -- Instanciación
    DUT: alu port map (
        SalA => SalA_tb,
        SalB => SalB_tb,
        ope => ope_tb,
        SalidaALU => SalidaALU_tb,
        SalidaFlags => SalidaFlags_tb
    );

    -- Proceso de estímulos
    stim_proc: process
    begin
        -- Test 1: Suma básica (ADD) -> 5 + 3 = 8
        SalA_tb <= x"05"; -- 5 en Hex
        SalB_tb <= x"03"; -- 3 en Hex
        ope_tb  <= "101"; -- Código de ADD
        wait for 10 ns;
        -- Verificación automática en consola
        assert (SalidaALU_tb = x"08") report "Error en ADD: 5+3" severity error;

        -- Test 2: Suma con Acarreo (Carry Flag) -> 255 + 1 = 0 (con acarreo)
        SalA_tb <= x"FF"; -- 255
        SalB_tb <= x"01"; -- 1
        ope_tb  <= "101"; 
        wait for 10 ns;
        assert (SalidaFlags_tb(2) = '1') report "Error en Flag de Acarreo" severity error;
        assert (SalidaFlags_tb(0) = '1') report "Error en Flag Zero" severity error;

        -- Test 3: Resta con resultado negativo (Sign Flag) -> 5 - 10 = -5
        SalA_tb <= x"05"; 
        SalB_tb <= x"0A"; 
        ope_tb  <= "110"; -- Código de SUB
        wait for 10 ns;
        assert (SalidaFlags_tb(1) = '1') report "Error en Flag de Signo" severity error;

        -- Test 4: Transferencia de B
        SalA_tb <= x"AA"; 
        SalB_tb <= x"BB"; 
        ope_tb  <= "001"; -- Código de Trans_B
        wait for 10 ns;
        assert (SalidaALU_tb = x"BB") report "Error en Transferencia B" severity error;

        report "--- TESTBENCH DE ALU FINALIZADO CON EXITO ---" severity note;
        wait; -- Detiene la simulación
    end process;

end behavior;
