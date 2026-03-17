LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY codificadorBG IS
    PORT (
        clk   : IN  STD_LOGIC;  -- Reloj del sistema
        rst   : IN  STD_LOGIC;  -- Reset asíncrono (inicia una nueva conversión de cadena)
        SYS   : IN  STD_LOGIC;  -- 0: Convierte a Binario (entrada es Gray)
                                -- 1: Convierte a Gray (entrada es Binario)
        N_bit : IN  STD_LOGIC;  -- Bit de entrada serial (ingresar desde el MSB)
        C_BIT : OUT STD_LOGIC   -- Bit de salida convertido
    );
END ENTITY codificadorBG;

ARCHITECTURE fsm OF codificadorBG IS

    -- Definición de los estados:
    -- Los estados representan el valor del BIT BINARIO procesado en el ciclo anterior.
    TYPE estado_t IS (S_PREV_BIN_0, S_PREV_BIN_1);
    SIGNAL estado_actual, estado_siguiente : estado_t;

BEGIN

    -- 1. Registro de Estado (Proceso Secuencial)
    -- En cada flanco de reloj avanzamos un bit en la cadena.
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            estado_actual <= S_PREV_BIN_0; -- Para el MSB, el "bit anterior" imaginario es 0
        ELSIF RISING_EDGE(clk) THEN
            estado_actual <= estado_siguiente;
        END IF;
    END PROCESS;

    -- 2. Lógica de Estado Siguiente y Salida (Proceso Combinacional - FSM Mealy)
    PROCESS(estado_actual, N_bit, SYS)
        VARIABLE v_bit_convertido : STD_LOGIC;
        VARIABLE v_bit_binario    : STD_LOGIC;
    BEGIN
        -- Valor por defecto para evitar latches
        estado_siguiente <= estado_actual;
        
        -- PASO A: Calcular el bit convertido (C_BIT)
        IF estado_actual = S_PREV_BIN_0 THEN
            v_bit_convertido := N_bit XOR '0';
        ELSE
            v_bit_convertido := N_bit XOR '1';
        END IF;
        
        C_BIT <= v_bit_convertido; -- Asignación a la salida

        -- PASO B: Determinar cuál es el bit BINARIO actual para guardarlo en el siguiente estado
        IF SYS = '1' THEN
            -- Modo Binario -> Gray: La propia entrada N_bit es nuestro bit binario
            v_bit_binario := N_bit;
        ELSE
            -- Modo Gray -> Binario: La salida convertida es nuestro bit binario calculado
            v_bit_binario := v_bit_convertido;
        END IF;

        -- PASO C: Transición de estados
        IF v_bit_binario = '1' THEN
            estado_siguiente <= S_PREV_BIN_1;
        ELSE
            estado_siguiente <= S_PREV_BIN_0;
        END IF;

    END PROCESS;

END ARCHITECTURE fsm;