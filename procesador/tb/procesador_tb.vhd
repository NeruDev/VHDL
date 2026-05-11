--------------------------------------------------------------------------------
-- Testbench: procesador_tb
-- Arquitectura: testbench
-- Descripción: Banco de pruebas estándar para la validación del procesador.
--              Simula el ciclo de vida completo desde el reset hasta la instrucción
--              de detención (HALT/FFh).
-- Referencias: Proyecto/ARCHIVOS_BASE/TEST_PROCESADOR.md (Programa de prueba)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity procesador_tb is
end entity;

architecture testbench of procesador_tb is

    ----------------------------------------------------------------------------
    -- Declaración del componente a probar (Unit Under Test - UUT)
    ----------------------------------------------------------------------------
    component procesador_top is
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            fin : out std_logic
        );
    end component;

    ----------------------------------------------------------------------------
    -- Señales de interconexión
    ----------------------------------------------------------------------------
    signal clk : std_logic := '0'; -- Señal de reloj inicializada
    signal rst : std_logic := '0'; -- Señal de reset
    signal fin : std_logic;        -- Señal de terminación desde el procesador

    -- Definición del periodo de reloj (100 MHz equivalentes)
    constant CLK_PERIOD : time := 10 ns;

begin

    ----------------------------------------------------------------------------
    -- Instanciación del Procesador
    ----------------------------------------------------------------------------
    uut: procesador_top port map (
        clk => clk,
        rst => rst,
        fin => fin
    );

    ----------------------------------------------------------------------------
    -- Proceso: Generación de Reloj
    -- Descripción: El reloj oscila mientras la señal 'fin' sea '0'. 
    --              Esto detiene automáticamente la simulación al llegar a la 
    --              instrucción FIN (FFh) cargada en la RAM.
    ----------------------------------------------------------------------------
    clk_process: process
    begin
        while fin = '0' loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait; -- El proceso se suspende indefinidamente al terminar
    end process;

    ----------------------------------------------------------------------------
    -- Proceso: Estímulos (Reset y Secuencia de Prueba)
    -- Descripción: Aplica un reset inicial para sincronizar la FSM de la UC 
    --              y observa la ejecución del programa pre-cargado en memoria.
    ----------------------------------------------------------------------------
    stim_proc: process
    begin
        -- FASE 1: Reset del sistema
        -- Se mantiene el reset por 2 ciclos para asegurar que todos los 
        -- componentes internos (PC, Registros, Flags) vuelvan a su estado base.
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        
        -- FASE 2: Ejecución
        -- El procesador comienza el ciclo Fetch en la dirección 0000h.
        -- Se espera a que la señal 'fin' cambie a '1' (detectado el OpCode FFh).
        wait until fin = '1';
        
        -- FASE 3: Observación final
        -- Se añaden ciclos extra para verificar que el estado se mantenga estable
        -- después de la instrucción de parada.
        wait for CLK_PERIOD * 5;
        
        assert false report "Simulacion completada exitosamente. Verificar trazas de buses." severity note;
        wait;
    end process;

end architecture;
