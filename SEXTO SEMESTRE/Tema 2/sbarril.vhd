-- Barril binario (4 bits)

---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY sbarril IS

   PORT (
      ENTRADA : IN  STD_LOGIC_VECTOR(3 DOWNTO 0); -- entrada de 4 bits que representa el estado actual del barril
      SENTIDO : IN  STD_LOGIC; -- 0: sentido derecha, 1: sentido izquierda
      ROTAR : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- 00: no rotar, 01: rotar una posición, 10: rotar dos posiciones, 11: rotar tres posiciones (MANTENERSE EN SU POSICIÓN)
      SALIDA : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- resultado de la rotación de la entrada según el sentido y la cantidad de rotaciones indicada
   );
END ENTITY sbarril;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNO OF sbarril IS
   SIGNAL control : STD_LOGIC_VECTOR(2 DOWNTO 0);
BEGIN
   -- Señal de control que combina el sentido y la cantidad de rotaciones
   control <= SENTIDO & ROTAR;

   -- Selección de la rotación basada en la señal de control
   WITH control SELECT
      SALIDA <= ENTRADA                                   WHEN "000", -- 0: Derecha, 0 posiciones
                ENTRADA(0) & ENTRADA(3 DOWNTO 1)          WHEN "001", -- 0: Derecha, 1 posición
                ENTRADA(1 DOWNTO 0) & ENTRADA(3 DOWNTO 2) WHEN "010", -- 0: Derecha, 2 posiciones
                ENTRADA(2 DOWNTO 0) & ENTRADA(3)          WHEN "011", -- 0: Derecha, 3 posiciones
                ENTRADA                                   WHEN "100", -- 1: Izquierda, 0 posiciones
                ENTRADA(2 DOWNTO 0) & ENTRADA(3)          WHEN "101", -- 1: Izquierda, 1 posición
                ENTRADA(1 DOWNTO 0) & ENTRADA(3 DOWNTO 2) WHEN "110", -- 1: Izquierda, 2 posiciones
                ENTRADA(0) & ENTRADA(3 DOWNTO 1)          WHEN "111", -- 1: Izquierda, 3 posiciones
                (OTHERS => '0')                           WHEN OTHERS;
END ARCHITECTURE UNO;