---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY mux4a1 IS
  PORT (
    a, b, c, d : IN  STD_LOGIC; --ENTRADAS
    s : IN  STD_LOGIC_VECTOR(1 DOWNTO 0); --SELECTOR
    X : OUT STD_LOGIC --SALIDA
  );
END ENTITY mux4a1;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNA OF mux4a1 IS

BEGIN

X <= (NOT s(1) AND NOT s(0) AND a) OR
     (NOT s(1) AND s(0) AND b) OR
     (s(1) AND NOT s(0) AND c) OR
     (s(1) AND s(0) AND d);

END ARCHITECTURE UNA;

-- ARQUITECTURA CON WHEN-ELSE

ARCHITECTURE DOS OF mux4a1 IS

BEGIN

X <= A WHEN S = "00" ELSE
     B WHEN S = "01" ELSE
     C WHEN S = "10" ELSE
     D WHEN S = "11" ELSE 
     '0';

END ARCHITECTURE DOS;

-- ARQUITECTURA CON WITH-SELECT

ARCHITECTURE TRES OF mux4a1 IS

BEGIN
WITH S SELECT
X <= A WHEN "00",
     B WHEN "01",
     C WHEN "10",
     D WHEN "11",
     '0' WHEN OTHERS;

END ARCHITECTURE TRES;


-- CONFIGURACION, SELECCIONAR LA ARQUITECTURA A UTILIZAR
CONFIGURATION MICONFIG OF mux4a1 IS
  FOR DOS 
  END FOR;
END CONFIGURATION MICONFIG;