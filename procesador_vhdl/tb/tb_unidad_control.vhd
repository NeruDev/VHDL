-- ==============================================================================
-- Archivo: tb_unidad_control.vhd
-- Ubicación: tb/
-- Descripción: Testbench para evaluar la FSM de la Unidad de Control.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_unidad_control is
end tb_unidad_control;

architecture behavior of tb_unidad_control is

    -- Señales de entrada
    signal rst_tb : std_logic := '1';
    signal clk_tb : std_logic := '0';
    signal FZ_tb  : std_logic := '0';
    signal CO_tb  : std_logic_vector(7 downto 0) := (others => '0');

    -- Periodo de reloj
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instancia (Usando work. para auto-enlazado)
    DUT: entity work.unidad_control port map (
        rst => rst_tb, clk => clk_tb, FZ => FZ_tb, CO => CO_tb,
        -- Mapear salidas a open si no se van a leer en el testbench
        clear => open, Lpc => open, Ipc => open, SelDir => open, 
        inicia => open, cs => open, oe => open, we => open, 
        LH => open, LL => open, Lri => open, SelRegW => open, 
        wr => open, RA => open, SelRegRA => open, RB => open, 
        SelRegRB => open, ope => open, SalAlu => open, LF => open
    );

    -- Generador de reloj
    clk_process :process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD/2;
        clk_tb <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Inyección de estímulos
    stim_proc: process
    begin
        -- Estado inicial de Reset
        rst_tb <= '1'; wait for CLK_PERIOD * 2;
        
        -- Liberar reset, la UC debería entrar a FETCH1 y luego FETCH2
        rst_tb <= '0'; 
        wait for CLK_PERIOD * 2;
        
        -- Simulamos que la memoria entregó el OPCODE "01" (Suma)
        CO_tb <= x"01"; 
        wait for CLK_PERIOD * 3; -- Dar tiempo a DECODE y EXEC_ADD
        
        -- Simulamos que la memoria entregó un OPCODE distinto
        CO_tb <= x"02";
        wait for CLK_PERIOD * 3;
        
        assert false report "Fin del testbench de Unidad de Control" severity failure;
        wait;
    end process;

end behavior;
