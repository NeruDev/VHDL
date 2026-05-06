-- ==============================================================================
-- Archivo: tb_alu.vhd
-- Ubicación: tb/
-- Descripción: Testbench exhaustivo para la ALU con autoverificación y casos borde.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity tb_alu is
end tb_alu;

architecture robust of tb_alu is

    -- DUT
    component alu
    Port ( 
        SalA        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        SalB        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        ope         : in  std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
        SalidaALU   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        SalidaFlags : out std_logic_vector(7 downto 0)
    );
    end component;

    signal SalA_tb, SalB_tb : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal ope_tb           : std_logic_vector(ALU_OP_WIDTH - 1 downto 0) := (others => '0');
    signal SalidaALU_tb     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal SalidaFlags_tb   : std_logic_vector(7 downto 0);

begin

    DUT: alu port map (SalA_tb, SalB_tb, ope_tb, SalidaALU_tb, SalidaFlags_tb);

    stim_proc: process
        -- Procedimiento interno para tener visibilidad de las señales del proceso
        procedure check_alu(
            constant a, b : in integer;
            constant op   : in std_logic_vector(2 downto 0);
            constant exp_res : in integer;
            constant exp_z, exp_s, exp_c : in std_logic;
            constant msg  : in string
        ) is
        begin
            SalA_tb <= std_logic_vector(to_unsigned(a, DATA_WIDTH));
            SalB_tb <= std_logic_vector(to_unsigned(b, DATA_WIDTH));
            ope_tb  <= op;
            wait for 10 ns;
            
            assert (to_integer(unsigned(SalidaALU_tb)) = exp_res mod 256)
                report "ERROR RESULTADO [" & msg & "]: Esperado " & integer'image(exp_res mod 256) & 
                       ", Obtenido " & integer'image(to_integer(unsigned(SalidaALU_tb)))
                severity error;
                
            assert (SalidaFlags_tb(0) = exp_z) 
                report "ERROR FLAG Z [" & msg & "]" severity error;
            assert (SalidaFlags_tb(1) = exp_s) 
                report "ERROR FLAG S [" & msg & "]" severity error;
            assert (SalidaFlags_tb(2) = exp_c) 
                report "ERROR FLAG C [" & msg & "]" severity error;
        end procedure;
    begin
        report "Iniciando Pruebas Robustas de ALU..." severity note;

        -- --- OPERACIONES ARITMÉTICAS ---
        
        -- ADD: Casos borde
        check_alu(0, 0, OP_ADD, 0, '1', '0', '0', "ADD 0+0");
        check_alu(127, 1, OP_ADD, 128, '0', '1', '0', "ADD 127+1 (Set Sign)");
        check_alu(255, 1, OP_ADD, 256, '1', '0', '1', "ADD 255+1 (Carry + Zero)");
        check_alu(255, 255, OP_ADD, 510, '0', '1', '1', "ADD 255+255 (Carry + Sign)");

        -- SUB: Casos borde
        check_alu(10, 5, OP_SUB, 5, '0', '0', '0', "SUB 10-5");
        check_alu(5, 5, OP_SUB, 0, '1', '0', '0', "SUB 5-5 (Zero)");
        check_alu(0, 1, OP_SUB, -1, '0', '1', '1', "SUB 0-1 (Borrow/Carry + Sign)");
        check_alu(128, 1, OP_SUB, 127, '0', '0', '0', "SUB 128-1 (Clear Sign)");

        -- INC / DEC
        check_alu(255, 0, OP_INC_A, 256, '1', '0', '1', "INC 255");
        check_alu(0, 0, OP_DEC_A, -1, '0', '1', '1', "DEC 0");

        -- --- OPERACIONES LÓGICAS ---
        
        -- AND
        check_alu(170, 85, OP_AND, 0, '1', '0', '0', "AND AA with 55");
        check_alu(255, 128, OP_AND, 128, '0', '1', '0', "AND FF with 80");

        -- NOT
        check_alu(255, 0, OP_NOT_A, 0, '1', '0', '0', "NOT FF");
        check_alu(0, 0, OP_NOT_A, 255, '0', '1', '0', "NOT 00");

        -- --- TRANSFERENCIAS ---
        check_alu(123, 45, OP_TRANS_A, 123, '0', '0', '0', "TRANS A");
        check_alu(123, 45, OP_TRANS_B, 45, '0', '0', '0', "TRANS B");

        report "--- TESTBENCH DE ALU ROBUSTO FINALIZADO ---" severity note;
        wait;
    end process;

end architecture;
