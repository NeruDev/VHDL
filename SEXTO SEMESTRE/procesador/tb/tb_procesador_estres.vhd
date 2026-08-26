--------------------------------------------------------------------------------
-- Testbench: tb_procesador_estres
-- Arquitectura: test
-- Descripción: Banco de pruebas avanzado con mecanismos de seguridad y métricas.
--              Incluye un Watchdog para prevenir bucles infinitos y un contador
--              de ciclos para evaluar el rendimiento del procesador.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity tb_procesador_estres is
end entity;

architecture test of tb_procesador_estres is
    ----------------------------------------------------------------------------
    -- Señales de conexión
    ----------------------------------------------------------------------------
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal fin : std_logic;
    
    ----------------------------------------------------------------------------
    -- Constantes de configuración
    ----------------------------------------------------------------------------
    constant CLK_PERIOD : time := 10 ns;
    constant TIMEOUT    : time := 10 us; -- Límite de seguridad: Detiene la simulación si falla el HALT
    
    ----------------------------------------------------------------------------
    -- Señales de monitoreo (Métricas)
    ----------------------------------------------------------------------------
    signal cycle_count : integer := 0; -- Contador de ciclos de reloj transcurridos

begin

    ----------------------------------------------------------------------------
    -- Instancia del procesador (Unit Under Test)
    ----------------------------------------------------------------------------
    uut: entity work.procesador_top
    port map (
        clk => clk,
        rst => rst,
        fin => fin
    );

    ----------------------------------------------------------------------------
    -- Proceso: Generador de Reloj con Watchdog
    -- Descripción: Controla la ejecución del tiempo. Si el procesador no termina
    --              dentro del TIMEOUT, se considera una falla catastrófica (bucle).
    ----------------------------------------------------------------------------
    clk_process: process
    begin
        -- Oscila mientras el tiempo sea válido y no se haya detectado el fin
        while now < TIMEOUT and (fin /= '1') loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            cycle_count <= cycle_count + 1; -- Incrementa métrica de ciclos
            wait for CLK_PERIOD / 2;
        end loop;
        
        -- Verificación de seguridad
        if now >= TIMEOUT then
            report "### ERROR: SE ALCANZO EL TIEMPO LIMITE (TIMEOUT) ###" severity failure;
        end if;
        
        wait; 
    end process;

    ----------------------------------------------------------------------------
    -- Proceso: Secuencia de Estímulos y Reportes
    -- Descripción: Controla el flujo del test y reporta resultados por consola.
    ----------------------------------------------------------------------------
    stim_proc: process
    begin
        report "--- INICIANDO TEST DE ESTRES DEL PROCESADOR ---";
        
        -- Reset prolongado para asegurar estabilidad inicial
        rst <= '1';
        wait for CLK_PERIOD * 5; 
        rst <= '0';
        report "Reset liberado. Ejecutando programa en memoria...";

        -- Sincronización con el final de la ejecución
        wait until fin = '1' for TIMEOUT;

        ------------------------------------------------------------------------
        -- REPORTES FINALES
        ------------------------------------------------------------------------
        if fin = '1' then
            report "--- SIMULACION FINALIZADA EXITOSAMENTE ---";
            report "Ciclos de reloj totales consumidos: " & integer'image(cycle_count);
            -- Nota: El número de ciclos depende de la complejidad de las instrucciones ejecutadas.
        end if;

        wait;
    end process;

end architecture;
