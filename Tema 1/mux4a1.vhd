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

X <= NOT s(1) AND NOT s(0) AND a OR
     NOT s(1) AND s(0) AND b OR
     s(1) AND NOT s(0) AND c OR
     s(1) AND s(0) AND d;

END ARCHITECTURE UNA;