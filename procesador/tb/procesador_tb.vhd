library ieee;
use ieee.std_logic_1164.all;

entity procesador_tb is
end entity;

architecture testbench of procesador_tb is

    component procesador_top is
        port (
            clk : in  std_logic;
            rst : in  std_logic;
            fin : out std_logic
        );
    end component;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal fin : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    uut: procesador_top port map (
        clk => clk,
        rst => rst,
        fin => fin
    );

    -- Generación de reloj
    clk_process: process
    begin
        while fin = '0' loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait; -- Detener simulación cuando fin = '1'
    end process;

    -- Proceso de estímulos (Reset inicial)
    stim_proc: process
    begin
        rst <= '1';
        wait for CLK_PERIOD * 2;
        rst <= '0';
        
        -- La simulación correrá hasta que 'fin' se vuelva '1' gracias al proceso del reloj
        wait until fin = '1';
        
        -- Esperar un poco más para observar el estado final
        wait for CLK_PERIOD * 5;
        
        assert false report "Simulacion completada exitosamente." severity note;
        wait;
    end process;

end architecture;
