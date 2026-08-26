---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY estaen23280651 IS

   PORT (
      A : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
      POSICION : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      SI_ESTA : OUT STD_LOGIC
   );
END ENTITY estaen23280651;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNO OF estaen23280651 IS
BEGIN
   PROCESS(A)
   BEGIN

      SI_ESTA  <= '0';
      POSICION <= "000";

      CASE A IS
         WHEN "0001" => -- 1 en posicion 0
            SI_ESTA <= '1'; POSICION <= "000";
         WHEN "0101" => -- 5 en posicion 1
            SI_ESTA <= '1'; POSICION <= "001";
         WHEN "0110" => -- 6 en posicion 2
            SI_ESTA <= '1'; POSICION <= "010";
         WHEN "0000" => -- 0 en posicion 3
            SI_ESTA <= '1'; POSICION <= "011";
         WHEN "1000" => -- 8 en posicion 4
            SI_ESTA <= '1'; POSICION <= "100";
         WHEN "0010" => -- 2 en posicion 5 
            SI_ESTA <= '1'; POSICION <= "101";
         WHEN "0011" => -- 3 en posicion 6
            SI_ESTA <= '1'; POSICION <= "110";
         WHEN OTHERS =>
            NULL;
      END CASE;
   END PROCESS;

END ARCHITECTURE UNO;