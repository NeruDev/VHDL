-- Decodificador 2 a 4

---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY DECO2A4 IS

    PORT (
         B0, B1 : IN  STD_LOGIC;
         D0, D1, D2, D3 : OUT STD_LOGIC
    );
END ENTITY DECO2A4;

---------------------------------------------------------------------
-- ARQUITECTURA 1: FLUJO DE DATOS (ECUACIONES)
---------------------------------------------------------------------
ARCHITECTURE PRIMERA OF DECO2A4 IS
BEGIN
         D0 <= NOT B1 AND NOT B0;
         D1 <= NOT B1 AND B0;
         D2 <= B1 AND NOT B0;
         D3 <= B1 AND B0;
END ARCHITECTURE PRIMERA;

---------------------------------------------------------------------
-- ARQUITECTURA 2: COMPORTAMENTAL (IF)
---------------------------------------------------------------------
ARCHITECTURE SEGUNDA OF DECO2A4 IS
BEGIN
         PROCESS(B0, B1)
         BEGIN
                  -- Valores por defecto
                  D0 <= '0'; D1 <= '0'; D2 <= '0'; D3 <= '0';
        
                  IF B1 = '0' AND B0 = '0' THEN
                           D0 <= '1';
                  ELSIF B1 = '0' AND B0 = '1' THEN
                           D1 <= '1';
                  ELSIF B1 = '1' AND B0 = '0' THEN
                           D2 <= '1';
                  ELSE
                           D3 <= '1';
                  END IF;
         END PROCESS;
END ARCHITECTURE SEGUNDA;

---------------------------------------------------------------------
-- ARQUITECTURA 3: COMPORTAMENTAL (CASE)
---------------------------------------------------------------------
ARCHITECTURE TERCERA OF DECO2A4 IS
         SIGNAL sel : STD_LOGIC_VECTOR(1 DOWNTO 0);
BEGIN
         sel <= B1 & B0;
    
         PROCESS(sel)
         BEGIN
                  D0 <= '0'; D1 <= '0'; D2 <= '0'; D3 <= '0';
                  CASE sel IS
                           WHEN "00" => D0 <= '1';
                           WHEN "01" => D1 <= '1';
                           WHEN "10" => D2 <= '1';
                           WHEN "11" => D3 <= '1';
                           WHEN OTHERS => NULL;
                  END CASE;
         END PROCESS;
END ARCHITECTURE TERCERA;

---------------------------------------------------------------------
-- ARQUITECTURA 4: ASIGNACION CONDICIONAL (WHEN ELSE)
---------------------------------------------------------------------
ARCHITECTURE CUARTA OF DECO2A4 IS
         SIGNAL sel : STD_LOGIC_VECTOR(1 DOWNTO 0);
         SIGNAL sal : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
         sel <= B1 & B0;
    
         sal <= "0001" WHEN sel = "00" ELSE
                        "0010" WHEN sel = "01" ELSE
                        "0100" WHEN sel = "10" ELSE
                        "1000";
           
         D0 <= sal(0);
         D1 <= sal(1);
         D2 <= sal(2);
         D3 <= sal(3);
END ARCHITECTURE CUARTA;

---------------------------------------------------------------------
-- ARQUITECTURA 5: ASIGNACION SELECTIVA (WITH SELECT)
---------------------------------------------------------------------
ARCHITECTURE QUINTA OF DECO2A4 IS
         SIGNAL sel : STD_LOGIC_VECTOR(1 DOWNTO 0);
         SIGNAL sal : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
         sel <= B1 & B0;
    
         WITH sel SELECT
                  sal <= "0001" WHEN "00",
                                 "0010" WHEN "01",
                                 "0100" WHEN "10",
                                 "1000" WHEN "11",
                                 "0000" WHEN OTHERS;
               
         D0 <= sal(0);
         D1 <= sal(1);
         D2 <= sal(2);
         D3 <= sal(3);
END ARCHITECTURE QUINTA;

---------------------------------------------------------------------
-- ARQUITECTURA 6: FLUJO DE DATOS VECTORIAL
---------------------------------------------------------------------
ARCHITECTURE SEXTA OF DECO2A4 IS
         SIGNAL sal : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
         sal(0) <= NOT B1 AND NOT B0;
         sal(1) <= NOT B1 AND B0;
         sal(2) <= B1 AND NOT B0;
         sal(3) <= B1 AND B0;
    
         D0 <= sal(0);
         D1 <= sal(1);
         D2 <= sal(2);
         D3 <= sal(3);
END ARCHITECTURE SEXTA;

---------------------------------------------------------------------
-- CONFIGURACION
---------------------------------------------------------------------
CONFIGURATION SETTINGS OF DECO2A4 IS
         FOR SEXTA
         END FOR;
END CONFIGURATION SETTINGS;