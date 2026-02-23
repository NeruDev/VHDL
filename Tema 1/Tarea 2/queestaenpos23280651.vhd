---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY queestaenpos23280651 IS

   PORT (
      POSICION : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      DIGITO : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      REPITE : OUT STD_LOGIC
   );
END ENTITY queestaenpos23280651;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNO OF queestaenpos23280651 IS
BEGIN
   PROCESS(POSICION)
   BEGIN
      CASE POSICION IS
         WHEN "000" => -- Posicion 0: 1
            DIGITO <= "0001"; REPITE <= '0';
         WHEN "001" => -- Posicion 1: 5
            DIGITO <= "0101"; REPITE <= '0';
         WHEN "010" => -- Posicion 2: 6
            DIGITO <= "0110"; REPITE <= '0';
         WHEN "011" => -- Posicion 3: 0
            DIGITO <= "0000"; REPITE <= '0';
         WHEN "100" => -- Posicion 4: 8
            DIGITO <= "1000"; REPITE <= '0';
         WHEN "101" => -- Posicion 5: 2 (Repetido en Posicion 7)
            DIGITO <= "0010"; REPITE <= '1';
         WHEN "110" => -- Posicion 6: 3
            DIGITO <= "0011"; REPITE <= '0';
         WHEN "111" => -- Posicion 7: 2 (Repetido en Posicion 5)
            DIGITO <= "0010"; REPITE <= '1';
         WHEN OTHERS =>
            DIGITO <= "0000"; REPITE <= '0';
      END CASE;
   END PROCESS;
END ARCHITECTURE UNO;