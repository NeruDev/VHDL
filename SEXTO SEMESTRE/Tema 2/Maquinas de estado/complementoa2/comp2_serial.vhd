LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY comp2_serial IS
    PORT (
        CLK : IN  STD_LOGIC;
        RST : IN  STD_LOGIC;  -- Reset asíncrono (reinicia para una nueva palabra)
        X   : IN  STD_LOGIC;  -- Bit de entrada (debe entrar LSB primero)
        Y   : OUT STD_LOGIC   -- Bit de salida (Complemento a 2)
    );
END ENTITY comp2_serial;

ARCHITECTURE rtl OF comp2_serial IS
    -- Definición de los 2 estados
    TYPE estado_t IS (S_NO_UNO, S_VISTO_UNO);
    SIGNAL estado_actual, estado_siguiente : estado_t;
BEGIN

    -- 1. PROCESO DE REGISTRO (Secuencial síncrono con Reset asíncrono)
    PROCESS(CLK, RST)
    BEGIN
        IF RST = '1' THEN
            estado_actual <= S_NO_UNO; -- Al iniciar, no hemos visto ningún '1'
        ELSIF RISING_EDGE(CLK) THEN
            estado_actual <= estado_siguiente;
        END IF;
    END PROCESS;

    -- 2. LÓGICA DE ESTADO SIGUIENTE (Combinacional)
    PROCESS(estado_actual, X)
    BEGIN
        -- Valor por defecto: mantenerse en el estado actual
        estado_siguiente <= estado_actual;

        CASE estado_actual IS
            WHEN S_NO_UNO =>
                IF X = '1' THEN
                    estado_siguiente <= S_VISTO_UNO; -- Si llega un 1, cambiamos de estado
                END IF;
            
            WHEN S_VISTO_UNO =>
                -- Una vez visto el primer '1', nos quedamos aquí hasta el Reset
                estado_siguiente <= S_VISTO_UNO;
        END CASE;
    END PROCESS;

    -- 3. LÓGICA DE SALIDA (Combinacional de Mealy: depende del estado Y de la entrada)
    PROCESS(estado_actual, X)
    BEGIN
        CASE estado_actual IS
            WHEN S_NO_UNO =>
                Y <= X;       -- Mantiene los '0' y saca el primer '1' tal cual
                
            WHEN S_VISTO_UNO =>
                Y <= NOT X;   -- Invierte todos los bits posteriores
        END CASE;
    END PROCESS;

END ARCHITECTURE rtl;