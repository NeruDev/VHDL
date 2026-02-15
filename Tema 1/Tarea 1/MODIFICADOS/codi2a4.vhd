--Codificador 2 a 4

---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY CODI2A4 IS

  PORT (
    D0, D1, D2, D3 : IN  STD_LOGIC;
    B0, B1 : OUT STD_LOGIC
  );
END ENTITY CODI2A4;

---------------------------------------------------------------------
-- ARQUITECTURA 1: FLUJO DE DATOS (ECUACIONES)
---------------------------------------------------------------------
ARCHITECTURE PRIMERA OF CODI2A4 IS
BEGIN
    B1 <= D3 OR D2;
    B0 <= D3 OR D1;
END ARCHITECTURE PRIMERA;

---------------------------------------------------------------------
-- ARQUITECTURA 2: COMPORTAMENTAL (IF)
---------------------------------------------------------------------
ARCHITECTURE SEGUNDA OF CODI2A4 IS
BEGIN
    PROCESS(D0, D1, D2, D3)
    BEGIN
        -- Valores por defecto
        B0 <= '0'; B1 <= '0';
        
        IF D3 = '1' THEN
            B1 <= '1'; B0 <= '1';
        ELSIF D2 = '1' THEN
            B1 <= '1'; B0 <= '0';
        ELSIF D1 = '1' THEN
            B1 <= '0'; B0 <= '1';
        ELSE
            -- D0 activa o ninguna activa resulta en 00
            B1 <= '0'; B0 <= '0';
        END IF;
    END PROCESS;
END ARCHITECTURE SEGUNDA;

---------------------------------------------------------------------
-- ARQUITECTURA 3: COMPORTAMENTAL (CASE)
---------------------------------------------------------------------
ARCHITECTURE TERCERA OF CODI2A4 IS
    SIGNAL sel : STD_LOGIC_VECTOR(3 DOWNTO 0);
BEGIN
    sel <= D3 & D2 & D1 & D0;
    
    PROCESS(sel)
    BEGIN
        B0 <= '0'; B1 <= '0';
        CASE sel IS
            WHEN "1000" => B1 <= '1'; B0 <= '1';
            WHEN "0100" => B1 <= '1'; B0 <= '0';
            WHEN "0010" => B1 <= '0'; B0 <= '1';
            WHEN "0001" => B1 <= '0'; B0 <= '0';
            WHEN OTHERS => NULL;
        END CASE;
    END PROCESS;
END ARCHITECTURE TERCERA;

---------------------------------------------------------------------
-- ARQUITECTURA 4: ASIGNACION CONDICIONAL (WHEN ELSE)
---------------------------------------------------------------------
ARCHITECTURE CUARTA OF CODI2A4 IS
    SIGNAL sal : STD_LOGIC_VECTOR(1 DOWNTO 0);
BEGIN
    
    sal <= "11" WHEN D3 = '1' ELSE
           "10" WHEN D2 = '1' ELSE
           "01" WHEN D1 = '1' ELSE
           "00";
           
    B1 <= sal(1);
    B0 <= sal(0);
END ARCHITECTURE CUARTA;

---------------------------------------------------------------------
-- ARQUITECTURA 5: ASIGNACION SELECTIVA (WITH SELECT)
---------------------------------------------------------------------
ARCHITECTURE QUINTA OF CODI2A4 IS
    SIGNAL sel : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL sal : STD_LOGIC_VECTOR(1 DOWNTO 0);
BEGIN
    sel <= D3 & D2 & D1 & D0;
    
    WITH sel SELECT
        sal <= "11" WHEN "1000",
               "10" WHEN "0100",
               "01" WHEN "0010",
               "00" WHEN OTHERS;
               
    B1 <= sal(1);
    B0 <= sal(0);
END ARCHITECTURE QUINTA;

---------------------------------------------------------------------
-- ARQUITECTURA 6: FLUJO DE DATOS VECTORIAL
---------------------------------------------------------------------
ARCHITECTURE SEXTA OF CODI2A4 IS
    SIGNAL sal : STD_LOGIC_VECTOR(1 DOWNTO 0);
BEGIN
    sal(1) <= D3 OR D2;
    sal(0) <= D3 OR D1;
    
    B1 <= sal(1);
    B0 <= sal(0);
END ARCHITECTURE SEXTA;

---------------------------------------------------------------------
-- CONFIGURACION
---------------------------------------------------------------------
CONFIGURATION CONF OF CODI2A4 IS
    FOR SEXTA
    END FOR;
END CONFIGURATION CONF;