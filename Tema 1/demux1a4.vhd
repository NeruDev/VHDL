---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY demux1a4 IS
  PORT (
    x : IN  STD_LOGIC; --ENTRADAS
    s : IN  STD_LOGIC_VECTOR(1 DOWNTO 0); --SELECTOR
    a, b, c, d : OUT STD_LOGIC --SALIDA
  );
END ENTITY demux1a4;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNA OF demux1a4 IS

BEGIN   

a <= x AND NOT s(1) AND NOT s(0);
b <= x AND NOT s(1) AND s(0);
c <= x AND s(1) AND NOT s(0);
d <= x AND s(1) AND s(0);

END ARCHITECTURE UNA;