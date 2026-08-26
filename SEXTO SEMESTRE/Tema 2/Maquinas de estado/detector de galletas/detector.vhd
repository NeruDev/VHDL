LIBRARY ieee;
USE ieee.std_logic_1164.all;

-- Máquina de estados para clasificación de galletas por tamaño
ENTITY detector_galletas IS
    PORT (
        clk   : IN  STD_LOGIC;  -- Reloj del sistema
        rst   : IN  STD_LOGIC;  -- Reset asíncrono
        s1    : IN  STD_LOGIC;  -- Sensor 1 (El primero en la línea)
        s2    : IN  STD_LOGIC;  -- Sensor 2
        s3    : IN  STD_LOGIC;  -- Sensor 3 (El último en la línea)
        a1    : OUT STD_LOGIC;  -- Actuador para galleta tamaño 1
        a2    : OUT STD_LOGIC;  -- Actuador para galleta tamaño 2
        a3    : OUT STD_LOGIC   -- Actuador para galleta tamaño 3
    );
END ENTITY detector_galletas;

ARCHITECTURE rtl OF detector_galletas IS

    -- Definición de los estados de la FSM (Moore)
    TYPE estado_t IS (IDLE, M1, M2, A1_ON, A2_ON, A3_ON, WAIT_CLEAR);
    SIGNAL estado_actual, estado_siguiente : estado_t;

BEGIN

    -- 1. Registro de Estado (Proceso Secuencial)
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            estado_actual <= IDLE;
        ELSIF RISING_EDGE(clk) THEN
            estado_actual <= estado_siguiente;
        END IF;
    END PROCESS;

    -- 2. Lógica de Estado Siguiente (Proceso Combinacional)
    PROCESS(estado_actual, s1, s2, s3)
    BEGIN
        -- Valor por defecto para evitar inferencia de latches
        estado_siguiente <= estado_actual;

        CASE estado_actual IS
            WHEN IDLE =>
                IF s1 = '1' THEN
                    estado_siguiente <= M1; -- La galleta empezó a entrar
                END IF;

            WHEN M1 =>
                IF s2 = '1' THEN
                    estado_siguiente <= M2; -- Es al menos de tamaño 2
                ELSIF s1 = '0' THEN
                    -- Si el sensor 1 se apaga y el 2 nunca se encendió, es tamaño 1
                    estado_siguiente <= A1_ON;
                END IF;

            WHEN M2 =>
                IF s3 = '1' THEN
                    -- Tan pronto toca el sensor 3, SABEMOS que es tamaño 3
                    estado_siguiente <= A3_ON;
                ELSIF s1 = '0' AND s2 = '0' THEN
                    -- Si abandona los sensores 1 y 2 sin tocar el 3, es tamaño 2
                    estado_siguiente <= A2_ON;
                END IF;

            -- Estados de activación (duran 1 ciclo de reloj)
            WHEN A1_ON | A2_ON | A3_ON =>
                estado_siguiente <= WAIT_CLEAR;

            WHEN WAIT_CLEAR =>
                -- Espera a que la banda esté libre de la galleta actual
                IF s1 = '0' AND s2 = '0' AND s3 = '0' THEN
                    estado_siguiente <= IDLE;
                END IF;

            WHEN OTHERS =>
                estado_siguiente <= IDLE;
        END CASE;
    END PROCESS;

    -- 3. Lógica de Salida (Proceso Combinacional - Depende solo del estado)
    PROCESS(estado_actual)
    BEGIN
        -- Valores por defecto a '0'
        a1 <= '0'; a2 <= '0'; a3 <= '0';

        CASE estado_actual IS
            WHEN A1_ON => a1 <= '1';
            WHEN A2_ON => a2 <= '1';
            WHEN A3_ON => a3 <= '1';
            WHEN OTHERS => -- Se mantienen en 0
        END CASE;
    END PROCESS;

END ARCHITECTURE rtl;