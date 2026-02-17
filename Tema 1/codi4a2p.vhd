---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY codi4a2p IS

   PORT (
      D3, D2, D1, D0 : IN  STD_LOGIC;
      B1, B0 : OUT STD_LOGIC;
      DV : OUT STD_LOGIC
   );
END ENTITY codi4a2p;

---------------------------------------------------------------------
-- ARQUITECTURA 1: FLUJO DE DATOS (ECUACIONES)
---------------------------------------------------------------------
ARCHITECTURE UNA OF codi4a2p IS
BEGIN

   B1 <= D3 OR D2;
   B0 <= D3 OR (NOT D2 AND D1);
   DV <= D3 OR D2 OR D1 OR D0;

END ARCHITECTURE UNA;

---------------------------------------------------------------------
-- ARQUITECTURA 2: ASIGNACION CONDICIONAL (WHEN ELSE)
---------------------------------------------------------------------

ARCHITECTURE DOS OF codi4a2p IS
BEGIN

B1 <= '1' WHEN (D3 = '1' OR D2 = '1') ELSE '0';
B0 <= '1' WHEN (D3 = '1' OR (D2 = '0' AND D1 = '1')) ELSE '0';
DV <= '1' WHEN (D3 = '1' OR D2 = '1' OR D1 = '1' OR D0 = '1') ELSE '0';

END ARCHITECTURE DOS;

---------------------------------------------------------------------
-- ARQUITECTURA 3: ASIGNACION SELECTIVA (WITH SELECT)
---------------------------------------------------------------------

ARCHITECTURE TRES OF codi4a2p IS
   SIGNAL D : INTEGER RANGE 0 TO 15;
   SIGNAL UD : UNSIGNED (3 DOWNTO 0);
BEGIN

UD <= D3 & D2 & D1 & D0;
D <= TO_INTEGER(UD);

WITH D SELECT
B1 <= '0' WHEN 0 TO 3,
         '1' WHEN 4 TO 15,
         '0' WHEN OTHERS;

WITH D SELECT
B0 <= '0' WHEN 0 TO 1,
         '1' WHEN 2 TO 3,
         '0' WHEN 4 TO 7,
         '1' WHEN 8 TO 15,
         '0' WHEN OTHERS;

WITH D SELECT
DV <= '0' WHEN 0,
         '1' WHEN 1 TO 15,
         '0' WHEN OTHERS;

END ARCHITECTURE TRES;

---------------------------------------------------------------------
-- CONFIGURACION
---------------------------------------------------------------------
CONFIGURATION CONFI OF CODI4A2P IS
      FOR TRES
      END FOR;
END CONFIGURATION CONFI;
