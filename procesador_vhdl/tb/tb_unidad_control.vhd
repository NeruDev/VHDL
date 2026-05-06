-- ==============================================================================
-- Archivo: tb_unidad_control.vhd
-- Ubicación: tb/
-- Descripción: Testbench robusto para la Unidad de Control.
--              Verifica transiciones de estado y señales de control generadas.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity tb_unidad_control is
end tb_unidad_control;

architecture robust of tb_unidad_control is

    -- Señales de entrada
    signal rst_tb : std_logic := '1';
    signal clk_tb : std_logic := '0';
    signal FZ_tb  : std_logic := '0';
    signal CO_tb  : std_logic_vector(7 downto 0) := (others => '0');

    -- Señales de salida de la UC
    signal clear, Lpc, Ipc, SelDir, inicia, cs, oe, we, LH, LL, Lri, wr, RA, RB, SalAlu, LF : std_logic;
    signal SelRegW, SelRegRA, SelRegRB : std_logic_vector(REG_SEL_W - 1 downto 0);
    signal ope : std_logic_vector(ALU_OP_WIDTH - 1 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    -- Procedimiento para verificar un conjunto de señales críticas
    procedure check_control(
        constant msg : in string;
        constant exp_cs, exp_oe, exp_we : in std_logic;
        constant exp_Lri, exp_Ipc : in std_logic
    ) is
    begin
        assert (cs = exp_cs and oe = exp_oe and we = exp_we)
            report "ERROR MEMORIA [" & msg & "]: cs=" & std_logic'image(cs) & " oe=" & std_logic'image(oe) & " we=" & std_logic'image(we)
            severity error;
        assert (Lri = exp_Lri) report "ERROR Lri [" & msg & "]" severity error;
        assert (Ipc = exp_Ipc) report "ERROR Ipc [" & msg & "]" severity error;
    end procedure;

begin

    DUT: entity work.unidad_control port map (
        rst => rst_tb, clk => clk_tb, FZ => FZ_tb, CO => CO_tb,
        clear => clear, Lpc => Lpc, Ipc => Ipc, SelDir => SelDir, 
        inicia => inicia, cs => cs, oe => oe, we => we, 
        LH => LH, LL => LL, Lri => Lri, SelRegW => SelRegW, 
        wr => wr, RA => RA, SelRegRA => SelRegRA, RB => RB, 
        SelRegRB => SelRegRB, ope => ope, SalAlu => SalAlu, LF => LF
    );

    -- Reloj
    clk_process :process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD/2;
        clk_tb <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Estímulos
    stim_proc: process
    begin
        report "Iniciando Pruebas Robustas de Unidad de Control..." severity note;

        -- 1. Test de Reset
        rst_tb <= '1'; wait for CLK_PERIOD * 1.5; -- 15ns
        assert (clear = '1') report "ERROR: clear no activo en Reset" severity error;
        
        -- 2. Test de Ciclo de Fetch
        rst_tb <= '0';
        wait for CLK_PERIOD; -- 25ns: FETCH1 (Activo desde flanco en 20ns)
        check_control("FETCH1", '1', '1', '0', '0', '0');
        
        wait for CLK_PERIOD; -- 35ns: FETCH2 (Activo desde flanco en 30ns)
        check_control("FETCH2", '1', '1', '0', '1', '1');
        
        -- Preparamos el OPCODE antes de llegar al estado DECODE
        CO_tb <= x"01"; 
        
        wait for CLK_PERIOD; -- 45ns: DECODE (Activo desde flanco en 40ns)
        
        -- 3. Test de Instrucción ADD (Opcode 0x01)
        wait for CLK_PERIOD; -- 55ns: EXEC_ADD (Activo desde flanco en 50ns)
        assert (RA = '1' and RB = '1' and wr = '1' and ope = OP_ADD)
            report "ERROR en señales de EXEC_ADD" severity error;
        
        wait for CLK_PERIOD; -- 65ns: FETCH1 de nuevo
        check_control("RETORNO FETCH1", '1', '1', '0', '0', '0');

        -- 4. Test de Instrucción desconocida
        CO_tb <= x"FF";
        wait for CLK_PERIOD * 2; -- Pasar por FETCH2 y llegar a DECODE
        wait for CLK_PERIOD;     -- Salto por default a FETCH1
        check_control("RECUPERACION OpcDesconocido", '1', '1', '0', '0', '0');

        -- 5. Test de Reset Asíncrono durante ejecución
        CO_tb <= x"01";
        wait for CLK_PERIOD * 3; -- Llegar a EXEC_ADD
        rst_tb <= '1';
        wait for 2 ns;
        assert (clear = '1') report "ERROR: Reset asincrono fallo" severity error;

        report "--- TESTBENCH DE UC ROBUSTO FINALIZADO ---" severity note;
        wait;
    end process;

end architecture;
