---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY mezcla IS
   PORT (
      A   : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
      B   : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
      RES : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
   );
END ENTITY mezcla;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNA OF mezcla IS
BEGIN

   PROCESS(A, B)
      VARIABLE UA, UB : UNSIGNED(3 DOWNTO 0);
   BEGIN
      UA := UNSIGNED(A);
      UB := UNSIGNED(B);

      IF UA > UB THEN
         -- Si A > B, se resta A - B
         RES <= STD_LOGIC_VECTOR(UA - UB);
      ELSIF UA < UB THEN
         -- Si A < B, se suma A + B
         RES <= STD_LOGIC_VECTOR(UA + UB);
      ELSE
         -- Si A = B, el resultado es cero
         RES <= (OTHERS => '0');
      END IF;
   END PROCESS;

END ARCHITECTURE UNA;