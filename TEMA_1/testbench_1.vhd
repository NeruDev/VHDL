-- Librerias

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entidad

entity tb_puertas_logicas is
end tb_puertas_logicas;

-- Arquitectura

architecture sim of tb_puertas_logicas is
    signal ta, tb : STD_LOGIC := '0';
    signal ty_and, ty_or, ty_not, ty_nand, ty_nor, ty_xor, ty_xnor : STD_LOGIC;
begin
    -- crear instancia y cablearla 
    uut: entity work.puertas_logicas
        port map (
            a => ta,
            b => tb,
            y_and  => ty_and,
            y_or   => ty_or,
            y_not  => ty_not,
            y_nand => ty_nand,
    		y_nor  => ty_nor,
    		y_xor  => ty_xor,
    		y_xnor => ty_xnor
        );

    -- Estímulos
    process
    begin
        -- Caso 1: a=0, b=0
        ta <= '0'; tb <= '0';
        wait for 10 ns;
        
        -- Caso 2: a=0, b=1
        ta <= '0'; tb <= '1';
        wait for 10 ns;

        -- Caso 3: a=1, b=0
        ta <= '1'; tb <= '0';
        wait for 10 ns;

        -- Caso 4: a=1, b=1
        ta <= '1'; tb <= '1';
        wait for 10 ns;

        wait;
    end process;
    
end architecture sim;
