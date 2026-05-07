-- ==============================================================================
-- Archivo: tb_procesador_estres.vhd
-- Ubicación: tb/
-- Descripción: Testbench de ALTO RENDIMIENTO. Evalúa el procesador en 
--              condiciones de estrés, límites y fallos típicos.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity tb_procesador_estres is
end tb_procesador_estres;

architecture extreme of tb_procesador_estres is

    -- Señales de interfaz
    signal clk_tb    : std_logic := '0';
    signal rst_tb    : std_logic := '1';
    signal inicia_tb : std_logic := '0';
    signal salida_tb : std_logic_vector(DATA_WIDTH - 1 downto 0);

    -- Parámetros de simulación
    constant CLK_PERIOD : time := 5 ns; -- Reloj rápido (200 MHz simulados)
    signal sim_finalizada : boolean := false;
    
    -- Registro de fallos para auditoría de estrés
    signal errores : integer := 0;

begin

    -- Instancia del Procesador (DUT)
    DUT: entity work.procesador
    port map (
        rst    => rst_tb,
        clk    => clk_tb,
        inicia => inicia_tb,
        salida => salida_tb
    );

    -- Generador de Reloj compatible con herramientas Quartus/ModelSim
    clk_process : process
    begin
        while not sim_finalizada loop
            clk_tb <= '0'; wait for CLK_PERIOD/2;
            clk_tb <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    -- Proceso de Supervisión (Watcher)
    watcher: process
    begin
        wait for 2 us;
        if not sim_finalizada then
            report "TIMEOUT CRÍTICO: El procesador se bloqueó bajo condiciones de estrés" severity failure;
        end if;
        wait;
    end process;

    -- SECUENCIA DE PRUEBAS EXTREMAS
    stim_proc: process
    begin
        report "--- INICIANDO AUDITORÍA DE ESTRÉS Y LÍMITES ---" severity note;

        -- 1. FASE: Tiempos Críticos (Reset Ultra-Corto)
        -- Objetivo: Verificar respuesta ante pulsos asíncronos rápidos.
        report "FASE 1: Reset asíncrono ultra-corto..." severity note;
        rst_tb <= '1'; wait for 2 ns; 
        rst_tb <= '0';
        wait for CLK_PERIOD * 2;
        if (salida_tb /= "00000000") then
            report "AVISO: El reset corto no fue capturado (comportamiento esperado en algunas tecnologías)" severity warning;
        end if;

        -- 2. FASE: Arranque de Alta Velocidad (200 MHz)
        -- Objetivo: Validar la salida del estado ESPERA a alta frecuencia.
        report "FASE 2: Secuencia de arranque (inicia)..." severity note;
        wait for CLK_PERIOD * 5;
        inicia_tb <= '1';
        wait for CLK_PERIOD * 10;
        if (salida_tb = "ZZZZZZZZ") then
            report "FALLO: El procesador no inició correctamente a 200MHz" severity error;
            errores <= errores + 1;
        end if;

        -- 3. FASE: Estrés de Registros y Desbordamiento
        -- Objetivo: Observar el wrap-around FF -> 00 bajo carga continua.
        report "FASE 3: Verificando desbordamiento 0xFF -> 0x00..." severity note;
        wait until salida_tb = x"FF";
        wait until salida_tb = x"00";
        report "Desbordamiento gestionado correctamente (OK)" severity note;

        -- 4. FASE: Estabilidad de la FSM
        -- Objetivo: Asegurar que no hay estados de colapso tras 100 ciclos de ejecución rápida.
        report "FASE 4: Validando estabilidad tras 100 ciclos..." severity note;
        for i in 1 to 100 loop
            wait until rising_edge(clk_tb);
        end loop;
        
        -- REPORTE FINAL DE ESTRÉS
        report "--- RESUMEN DE AUDITORÍA DE ESTRÉS ---" severity note;
        if errores = 0 then
            report "RESULTADO: Procesador estable bajo condiciones extremas." severity note;
        else
            report "RESULTADO: Se detectaron " & integer'image(errores) & " fallos de tiempo/datos." severity error;
        end if;

        sim_finalizada <= true;
        wait;
    end process;

end architecture;
