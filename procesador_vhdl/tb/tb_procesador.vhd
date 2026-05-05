-- ==============================================================================
-- Archivo: tb_procesador.vhd
-- Ubicación: tb/
-- Descripción: Testbench Top-Level. Genera el reloj y el reset para el sistema.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity tb_procesador is
end tb_procesador;

architecture behavior of tb_procesador is

    -- Componente de máximo nivel
    component procesador
    Port ( 
        rst    : in  std_logic;
        clk    : in  std_logic;
        salida : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
    end component;

    -- Señales de estímulo
    signal clk_tb    : std_logic := '0';
    signal rst_tb    : std_logic := '1'; -- Iniciamos en Reset
    signal salida_tb : std_logic_vector(DATA_WIDTH - 1 downto 0);

    -- Período del reloj (ej. 10 ns = 100 MHz)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- Instancia del procesador
    DUT: procesador port map (
        rst => rst_tb,
        clk => clk_tb,
        salida => salida_tb
    );

    -- Generador de Reloj continuo
    clk_process :process
    begin
        clk_tb <= '0';
        wait for CLK_PERIOD/2;
        clk_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- Secuencia de estímulos principal (Reset y ejecución)
    stim_proc: process
    begin
        -- Mantener el procesador en estado de reset por un par de ciclos
        rst_tb <= '1';
        wait for CLK_PERIOD * 2;
        
        -- Liberar el reset: El PC empezará a contar y la UC a decodificar
        rst_tb <= '0';
        
        -- Dejar correr la simulación por suficientes ciclos de reloj para
        -- ver la ejecución de algunas instrucciones en el visor de ondas (Waveform)
        wait for CLK_PERIOD * 50; 
        
        -- Detener la simulación (Esto funciona bien en simuladores modernos)
        assert false report "Simulacion terminada programadamente" severity failure;
        wait;
    end process;

end behavior;
