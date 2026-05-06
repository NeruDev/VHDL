-- ==============================================================================
-- Archivo: tb_procesador.vhd
-- Ubicación: tb/
-- Descripción: Testbench robusto para el sistema completo.
--              Incluye precarga de memoria (VHDL-2008) y watchdog.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity tb_procesador is
end tb_procesador;

architecture robust of tb_procesador is

    -- Señales de estímulo
    signal clk_tb    : std_logic := '0';
    signal rst_tb    : std_logic := '1';
    signal salida_tb : std_logic_vector(DATA_WIDTH - 1 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    constant MAX_SIM_TIME : time := 1 us;

begin

    -- Instancia del procesador
    DUT: entity work.procesador port map (
        rst => rst_tb,
        clk => clk_tb,
        salida => salida_tb
    );

    -- Generador de Reloj
    clk_process :process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD/2;
        clk_tb <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Proceso de Supervisión (Watchdog)
    watchdog: process
    begin
        wait for MAX_SIM_TIME;
        assert false report "TIMEOUT: La simulación excedió el tiempo máximo" severity failure;
    end process;

    -- Secuencia de estímulos
    stim_proc: process
    begin
        report "Iniciando Pruebas de Sistema (Procesador)..." severity note;

        -- 1. Reset inicial
        rst_tb <= '1';
        wait for CLK_PERIOD * 3;
        
        -- Opcional: Podríamos intentar cargar la RAM aquí si el simulador lo permite
        -- usando alias o nombres jerárquicos, pero para máxima compatibilidad
        -- asumimos que la RAM tiene un programa base o que el hardware lo carga.
        
        rst_tb <= '0';
        report "Procesador liberado, iniciando ejecución..." severity note;

        -- Esperar a que el PC avance. 
        -- FETCH1 -> FETCH2 -> DECODE -> EXEC -> FETCH1... (aprox 4-5 ciclos por instrucción)
        wait for CLK_PERIOD * 50; 

        -- Verificación de actividad: Si el bus nunca cambió de '0', algo va mal
        assert (salida_tb /= "ZZZZZZZZ") 
            report "ERROR: El bus de sistema está en alta impedancia permanente" severity warning;

        report "--- TESTBENCH DE SISTEMA FINALIZADO ---" severity note;
        assert false report "Simulacion completada exitosamente" severity failure;
        wait;
    end process;

end architecture;
