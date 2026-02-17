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

PROCESS (a, b, c, d, s) IS
    BEGIN
         a <= x AND NOT s(1) AND NOT s(0);
         b <= x AND NOT s(1) AND s(0);
         c <= x AND s(1) AND NOT s(0);
         d <= x AND s(1) AND s(0);
    END PROCESS;

END ARCHITECTURE UNA;

-- ARQUITECTURA CON WHEN-ELSE

ARCHITECTURE DOS OF demux1a4 IS

BEGIN

    a <= x WHEN s = "00" ELSE '0';
    b <= x WHEN s = "01" ELSE '0';
    c <= x WHEN s = "10" ELSE '0';
    d <= x WHEN s = "11" ELSE '0';

END ARCHITECTURE DOS;

-- ARQUITECTURA CON WITH-SELECT

ARCHITECTURE TRES OF demux1a4 IS

BEGIN
WITH s SELECT
    a <= x WHEN "00",
            '0' WHEN OTHERS;
     
WITH s SELECT
    b <= x WHEN "01",
         '0' WHEN OTHERS;
     
WITH s SELECT
    c <= x WHEN "10",
         '0' WHEN OTHERS;
     
WITH s SELECT
    d <= x WHEN "11",
         '0' WHEN OTHERS;

END ARCHITECTURE TRES;


-- CONFIGURACION, SELECCIONAR LA ARQUITECTURA A UTILIZAR
CONFIGURATION DEMUX_CONFIG OF demux1a4 IS
   FOR DOS 
   END FOR;
END CONFIGURATION DEMUX_CONFIG;