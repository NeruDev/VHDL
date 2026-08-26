-- Librerias
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Entidad

entity puertas_logicas is
    Port (
        a : in  STD_LOGIC;
        b : in  STD_LOGIC;
        y_and  : out STD_LOGIC;
        y_or   : out STD_LOGIC;
        y_not  : out STD_LOGIC;
        y_nand : out STD_LOGIC;
    	y_nor  : out STD_LOGIC;
    	y_xor  : out STD_LOGIC;
    	y_xnor : out STD_LOGIC
    );
end entity puertas_logicas;

-- Arquitectura

architecture una of puertas_logicas is
begin
    -- instrucciones concurrentes
    -- asignaciones simples
    y_and <= a AND b;
    y_or  <= a OR b;
    y_not <= NOT a;
    y_nand <= a NAND b;
    y_nor <= a NOR b;
    y_xor <= a XOR b;
    y_xnor <= a XNOR b;
    
end architecture una;
