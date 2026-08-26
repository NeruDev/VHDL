---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY sumaAB IS

   PORT (
      A, B : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
      S: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      C: OUT STD_LOGIC
   );
END ENTITY sumaAB;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNO OF sumaAB IS

      SIGNAL SS : STD_LOGIC_VECTOR(4 DOWNTO 0);

BEGIN

      SS <= STD_LOGIC_VECTOR(UNSIGNED('0' & A) + UNSIGNED('0' & B));

      S <= SS(3 DOWNTO 0);
      C <= SS(4);

END ARCHITECTURE UNO;