---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY paridad IS
   PORT (
      CLK    : IN  STD_LOGIC;
      RST    : IN  STD_LOGIC;
      DIGITO : IN  STD_LOGIC;
      PAR    : OUT STD_LOGIC
   );
END ENTITY paridad;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE UNO OF paridad IS
    -- Definicion de los estados de la maquina
    TYPE estados IS (E_PAR, E_IMPAR);
    SIGNAL estado_actual, estado_siguiente : estados;
BEGIN
    -- Logica de memoria (Registro de Estado)
    PROCESS (CLK, RST)
    BEGIN
        IF RST = '1' THEN
            estado_actual <= E_PAR;
        ELSIF rising_edge(CLK) THEN
            estado_actual <= estado_siguiente;
        END IF;
    END PROCESS;

    -- Logica de estado siguiente
    PROCESS (estado_actual, DIGITO)
    BEGIN
        CASE estado_actual IS
            WHEN E_PAR =>
                IF DIGITO = '1' THEN
                    estado_siguiente <= E_IMPAR;
                ELSE
                    estado_siguiente <= E_PAR;
                END IF;

            WHEN E_IMPAR =>
                IF DIGITO = '1' THEN
                    estado_siguiente <= E_PAR;
                ELSE
                    estado_siguiente <= E_IMPAR;
                END IF;
                
            WHEN OTHERS =>
                estado_siguiente <= E_PAR;
        END CASE;
    END PROCESS;

    -- Logica de salida (Salida tipo Moore)
    PROCESS (estado_actual)
    BEGIN
        CASE estado_actual IS
            WHEN E_PAR =>
                PAR <= '1';
            WHEN E_IMPAR =>
                PAR <= '0';
            WHEN OTHERS =>
                PAR <= '1';
        END CASE;
    END PROCESS;

END ARCHITECTURE UNO;
