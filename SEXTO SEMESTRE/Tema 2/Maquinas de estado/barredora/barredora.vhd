---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
-- Entidad para el control de una barredora
ENTITY barredora IS
    PORT (
        CLK       : IN  STD_LOGIC;
        RST       : IN  STD_LOGIC;
        SENSOR    : IN  STD_LOGIC; -- 1: Obstáculo detectado, 0: Camino libre
        MOTOR_IZQ : OUT STD_LOGIC; -- Rueda Izquierda
        MOTOR_DER : OUT STD_LOGIC  -- Rueda Derecha
    );
END ENTITY barredora;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE rtl OF barredora IS
    -- Definición de estados según la lógica Moore
    -- Secuencia: A_1 (00) -> D (01) -> A_2 (11) -> I (10) -> A_1 ...
    TYPE estado_t IS (A_1, D, A_2, I);
    SIGNAL EST_ACT, EST_SIG : estado_t;
BEGIN

    -- Proceso secuencial: Actualización de estado
    PROCESS(CLK, RST)
    BEGIN
        IF RST = '1' THEN
            EST_ACT <= A_1;
        ELSIF RISING_EDGE(CLK) THEN
            EST_ACT <= EST_SIG;
        END IF;
    END PROCESS;

    -- Proceso combinacional: Lógica de estado siguiente
    PROCESS(EST_ACT, SENSOR)
    BEGIN
        CASE EST_ACT IS
            WHEN A_1 =>
                IF SENSOR = '1' THEN EST_SIG <= D;
                ELSE                 EST_SIG <= A_1;
                END IF;
            
            WHEN D =>
                IF SENSOR = '0' THEN EST_SIG <= A_2;
                ELSE                 EST_SIG <= D;
                END IF;
            
            WHEN A_2 =>
                IF SENSOR = '1' THEN EST_SIG <= I;
                ELSE                 EST_SIG <= A_2;
                END IF;
            
            WHEN I =>
                IF SENSOR = '0' THEN EST_SIG <= A_1;
                ELSE                 EST_SIG <= I;
                END IF;
            
            WHEN OTHERS => EST_SIG <= A_1;
        END CASE;
    END PROCESS;

    -- Proceso combinacional: Lógica de salida (Moore)
    PROCESS(EST_ACT)
    BEGIN
        CASE EST_ACT IS
            WHEN A_1 | A_2 => MOTOR_IZQ <= '1'; MOTOR_DER <= '1'; -- Avance (11)
            WHEN D         => MOTOR_IZQ <= '0'; MOTOR_DER <= '1'; -- Derecha (01)
            WHEN I         => MOTOR_IZQ <= '1'; MOTOR_DER <= '0'; -- Izquierda (10)
            WHEN OTHERS    => MOTOR_IZQ <= '1'; MOTOR_DER <= '1';
        END CASE;
    END PROCESS;

END ARCHITECTURE rtl;