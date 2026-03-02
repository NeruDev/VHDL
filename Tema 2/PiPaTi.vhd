---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY PiPaTi IS

   PORT (
      A_Pi, A_Pa, A_Ti, B_Pi, B_Pa, B_Ti : IN  STD_LOGIC;
      Gana_A, Gana_B, Empate, Error : OUT STD_LOGIC
   );
END ENTITY PiPaTi;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNO OF PiPaTi IS

BEGIN

  PROCESS (A_Pi, A_Pa, A_Ti, B_Pi, B_Pa, B_Ti) IS
    VARIABLE vec_A, vec_B : STD_LOGIC_VECTOR(2 DOWNTO 0);
  BEGIN
    -- Inicialización de salidas (evita latches)
    Gana_A <= '0';
    Gana_B <= '0';
    Empate <= '0';
    Error  <= '0';

    -- Concatenación de entradas: Piedra(2), Papel(1), Tijera(0)
    vec_A := A_Pi & A_Pa & A_Ti;
    vec_B := B_Pi & B_Pa & B_Ti;

    -- Verificación de validez: Solo una tecla pulsada por jugador (One-Hot)
    IF (vec_A /= "100" AND vec_A /= "010" AND vec_A /= "001") OR
       (vec_B /= "100" AND vec_B /= "010" AND vec_B /= "001") THEN
       Error <= '1';
    ELSE
       IF vec_A = vec_B THEN
          Empate <= '1';
       ELSIF (A_Pi = '1' AND B_Ti = '1') OR  -- Piedra gana a Tijera
             (A_Pa = '1' AND B_Pi = '1') OR  -- Papel gana a Piedra
             (A_Ti = '1' AND B_Pa = '1') THEN -- Tijera gana a Papel
          Gana_A <= '1';
       ELSE
          Gana_B <= '1';
       END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE UNO;