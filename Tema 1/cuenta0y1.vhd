-- Contador de 0's y 1's

---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY cuenta0y1 IS

   PORT (
      ENT : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
      CUENTA0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      CUENTA1 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
   );
END ENTITY cuenta0y1;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNO OF cuenta0y1 IS
BEGIN

   PROCESS (ENT)
      -- Se usan variables porque se actualizan de forma inmediata dentro del bucle.
      -- Las señales solo se actualizan al finalizar el proceso, lo que impediría la acumulación.
      VARIABLE CNT0 : INTEGER RANGE 0 TO 8;
      VARIABLE CNT1 : INTEGER RANGE 0 TO 8;
   BEGIN

      CNT0 := 0; -- Inicialización necesaria en cada ejecución del proceso
      CNT1 := 0;

      FOR I IN ENT'RANGE LOOP
         IF ENT(I) = '0' THEN
            CNT0 := CNT0 + 1;
         ELSE
            CNT1 := CNT1 + 1;
         END IF;
      END LOOP;

      -- Conversión de los resultados finales a std_logic_vector
      CUENTA0 <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT0, 4));
      CUENTA1 <= STD_LOGIC_VECTOR(TO_UNSIGNED(CNT1, 4));
   END PROCESS;

END ARCHITECTURE UNO;