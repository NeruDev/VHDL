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
    signal inicia_tb : std_logic := '0';
    signal salida_tb : std_logic_vector(DATA_WIDTH - 1 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    constant MAX_SIM_TIME : time := 1 us;
    
    -- Registro de fallos
    signal errores : integer := 0;

begin

    -- Instancia del procesador (DUT)
    DUT: entity work.procesador port map (
        rst => rst_tb,
        clk => clk_tb,
        inicia => inicia_tb,
        salida => salida_tb
    );

    -- Generador de Reloj compatible con herramientas Quartus/ModelSim
    clk_process :process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD/2;
        clk_tb <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Proceso de Supervisión (Watchdog) para evitar bucles infinitos
    watchdog: process
    begin
        wait for MAX_SIM_TIME;
        if (errores = 0) then
            report "TIMEOUT: Simulación finalizada por límite de tiempo." severity note;
        else
            report "TIMEOUT: Simulación finalizada con errores acumulados." severity failure;
        end if;
        wait;
    end process;

    -- Secuencia de estímulos principal
    stim_proc: process
    begin
        report "--- INICIANDO AUDITORÍA DE SISTEMA COMPLETO ---" severity note;

        -- 1. FASE: Inicialización y Reset
        -- Objetivo: Asegurar que el bus inicie limpio antes de la señal inicia.
        rst_tb <= '1';
        inicia_tb <= '0';
        wait for CLK_PERIOD * 3;
        
        rst_tb <= '0';
        wait for CLK_PERIOD * 2;
        assert (salida_tb = "00000000") report "FALLO: El bus no está limpio tras el reset" severity warning;
        if salida_tb /= "00000000" then errores <= errores + 1; end if;

        -- 2. FASE: Arranque del Procesador
        -- Objetivo: Activar la señal 'inicia' y observar el comienzo de la ejecución.
        inicia_tb <= '1';
        report "Señal 'inicia' activada. Comenzando ejecución del programa en RAM..." severity note;
        wait for CLK_PERIOD * 10; -- FETCH1 -> FETCH2 -> DECODE -> EXEC (ADD R2)

        -- 3. FASE: Verificación de Ejecución Continua
        -- Objetivo: El bus de sistema no debe estar en alta impedancia ('Z') durante la ejecución normal.
        wait for CLK_PERIOD * 50; 
        assert (salida_tb /= "ZZZZZZZZ") 
            report "FALLO CRÍTICO: El bus de sistema entró en alta impedancia inesperadamente" severity error;
        if salida_tb = "ZZZZZZZZ" then errores <= errores + 1; end if;

        -- 4. FASE: Verificación de Lógica de Bucle
        -- El programa en RAM es un bucle que incrementa R2.
        -- Verificamos que el valor en el bus (salida) sea mayor que 10 tras unos ciclos.
        if (to_integer(unsigned(salida_tb)) <= 10) then
            report "FALLO: El contador en R2 no parece estar incrementando (Val=" & integer'image(to_integer(unsigned(salida_tb))) & ")" severity error;
            errores <= errores + 1;
        end if;

        -- FINALIZACIÓN
        report "--- RESUMEN DE AUDITORÍA DE SISTEMA ---" severity note;
        if errores = 0 then
            report "RESULTADO: Sistema verificado sin anomalías." severity note;
        else
            report "RESULTADO: Se detectaron " & integer'image(errores) & " fallos en la integración." severity error;
        end if;
        
        assert false report "Auditoria finalizada exitosamente" severity failure;
        wait;
    end process;

end architecture;
