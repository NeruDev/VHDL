library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_procesador_estres is
end entity;

architecture test of tb_procesador_estres is
    -- Senales de conexion
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal fin : std_logic;
    
    -- Constantes de tiempo
    constant CLK_PERIOD : time := 10 ns;
    constant TIMEOUT    : time := 10 us; -- Limite de seguridad
    
    -- Contadores para metricas
    signal cycle_count : integer := 0;

begin

    -- Instancia del procesador
    uut: entity work.procesador_top
    port map (
        clk => clk,
        rst => rst,
        fin => fin
    );

    -- Generador de Reloj con Watchdog
    clk_process: process
    begin
        while now < TIMEOUT and (fin /= '1') loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            cycle_count <= cycle_count + 1;
            wait for CLK_PERIOD / 2;
        end loop;
        
        if now >= TIMEOUT then
            report "### ERROR: SE ALCANZO EL TIEMPO LIMITE (TIMEOUT) ###" severity failure;
        end if;
        
        wait; 
    end process;

    -- Proceso de Estimulos
    stim_proc: process
    begin
        report "--- INICIANDO TEST DE ESTRES DEL PROCESADOR ---";
        rst <= '1';
        wait for CLK_PERIOD * 5; 
        rst <= '0';
        report "Reset liberado. Ejecutando...";

        wait until fin = '1' for TIMEOUT;

        if fin = '1' then
            report "--- SIMULACION FINALIZADA EXITOSAMENTE ---";
            report "Ciclos de reloj totales: " & integer'image(cycle_count);
        end if;

        wait;
    end process;

end architecture;
