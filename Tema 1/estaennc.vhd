-- 

---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY estaennc IS

   PORT (
      A : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
      POSICION : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      SI_ESTA : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
   );
END ENTITY estaennc;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNO OF estaennc IS
BEGIN

   PROCESS (ENT)
      VARIABLE POSICION : INTEGER RANGE 0 TO 8;
      VARIABLE SI_ESTA_NC : INTEGER RANGE 0 TO 1;
   BEGIN
	 CONSTANT NC : INTEGER 23280651; 



   END PROCESS;

END ARCHITECTURE UNO;