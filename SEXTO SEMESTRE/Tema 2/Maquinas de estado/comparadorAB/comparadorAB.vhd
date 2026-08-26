LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY comparadorAB IS
    PORT (
        CLK : IN  STD_LOGIC;
        RST : IN  STD_LOGIC;  -- Reset asíncrono para reiniciar la comparación
        A   : IN  STD_LOGIC;  -- Bit de la cadena A (entra LSB primero)
        B   : IN  STD_LOGIC;  -- Bit de la cadena B (entra LSB primero)
        Am  : OUT STD_LOGIC;  -- Salida: A es mayor
        Bm  : OUT STD_LOGIC;  -- Salida: B es mayor
        I   : OUT STD_LOGIC   -- Salida: A y B son iguales
    );
END ENTITY comparadorAB;

ARCHITECTURE rtl OF comparadorAB IS
    -- Definición de los 3 estados del comparador
    TYPE estado_t IS (S_I, S_Am, S_Bm);
    SIGNAL estado_actual, estado_siguiente : estado_t;
BEGIN

    -- 1. PROCESO DE REGISTRO (Secuencial síncrono con Reset asíncrono)
    PROCESS(CLK, RST)
    BEGIN
        IF RST = '1' THEN
            estado_actual <= S_I; -- Al inicio, si no han entrado bits, son "iguales"
        ELSIF RISING_EDGE(CLK) THEN
            estado_actual <= estado_siguiente;
        END IF;
    END PROCESS;

    -- 2. LÓGICA DE ESTADO SIGUIENTE (Combinacional)
    PROCESS(estado_actual, A, B)
    BEGIN
        -- Valor por defecto: mantener el estado (previene latches si se omiten ramas)
        estado_siguiente <= estado_actual;

        CASE estado_actual IS
            WHEN S_I =>
                IF A = '1' AND B = '0' THEN
                    estado_siguiente <= S_Am; -- A es mayor en el bit actual
                ELSIF A = '0' AND B = '1' THEN
                    estado_siguiente <= S_Bm; -- B es mayor en el bit actual
                END IF;
                -- Si son iguales, se mantiene por defecto en S_I

            WHEN S_Am =>
                -- Si entra un bit de mayor peso que contradice, cambia a Bm
                IF A = '0' AND B = '1' THEN
                    estado_siguiente <= S_Bm;
                END IF;
                -- Si son iguales u otra vez A>B, sigue ganando A (se mantiene S_Am)

            WHEN S_Bm =>
                -- Si entra un bit de mayor peso que contradice, cambia a Am
                IF A = '1' AND B = '0' THEN
                    estado_siguiente <= S_Am;
                END IF;
                -- Si son iguales u otra vez B>A, sigue ganando B (se mantiene S_Bm)
                
        END CASE;
    END PROCESS;

    -- 3. LÓGICA DE SALIDA (Combinacional pura de Moore)
    PROCESS(estado_actual)
    BEGIN
        -- Valores por defecto a '0'
        Am <= '0';
        Bm <= '0';
        I  <= '0';

        CASE estado_actual IS
            WHEN S_I  => I  <= '1';
            WHEN S_Am => Am <= '1';
            WHEN S_Bm => Bm <= '1';
        END CASE;
    END PROCESS;

END ARCHITECTURE rtl;