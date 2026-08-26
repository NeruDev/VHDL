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

ARCHITECTURE fsm_moore OF codificadorBG IS

    -- Definición de los estados Moore:
    -- Cada estado representa la combinación del bit binario actual y la salida generada.
    -- S_BINx_OUTy: x es el valor binario del bit, y es el valor de la salida C_BIT.
    TYPE estado_t IS (S_BIN0_OUT0, S_BIN0_OUT1, S_BIN1_OUT0, S_BIN1_OUT1);
    SIGNAL estado_actual, estado_siguiente : estado_t;

BEGIN

    -- 1. Registro de Estado y Salida Sincrónica (Proceso Secuencial)
    -- En una FSM Moore, la salida depende solo del estado. Al implementarla aquí,
    -- aseguramos que C_BIT esté registrado y libre de transitorios (glitches).
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            -- Inicialización: bit binario previo = 0, salida = 0
            estado_actual <= S_BIN0_OUT0;
            C_BIT         <= '0';
        ELSIF RISING_EDGE(clk) THEN
            estado_actual <= estado_siguiente;
            
            -- Lógica de salida Moore: C_BIT se actualiza según el estado al que se transiciona
            CASE estado_siguiente IS
                WHEN S_BIN0_OUT0 | S_BIN1_OUT0 =>
                    C_BIT <= '0';
                WHEN S_BIN0_OUT1 | S_BIN1_OUT1 =>
                    C_BIT <= '1';
            END CASE;
        END IF;
    END PROCESS;

    -- 2. Lógica de Siguiente Estado (Proceso Combinacional)
    PROCESS(estado_actual, N_bit, SYS)
        VARIABLE v_prev_bin : STD_LOGIC; -- Valor binario del bit anterior
        VARIABLE v_curr_out : STD_LOGIC; -- Salida calculada para el bit actual
        VARIABLE v_curr_bin : STD_LOGIC; -- Valor binario del bit actual
    BEGIN
        -- Asignación por defecto
        estado_siguiente <= estado_actual;

        -- PASO A: Extraer el valor binario del bit anterior desde el estado actual
        IF estado_actual = S_BIN0_OUT0 OR estado_actual = S_BIN0_OUT1 THEN
            v_prev_bin := '0';
        ELSE
            v_prev_bin := '1';
        END IF;

        -- PASO B: Calcular la salida Moore para el bit de entrada actual
        -- La lógica XOR entre la entrada y el bit binario previo se mantiene igual.
        v_curr_out := N_bit XOR v_prev_bin;

        -- PASO C: Determinar el bit BINARIO actual para el almacenamiento en el próximo estado
        IF SYS = '1' THEN
            -- Modo Binario -> Gray: La propia entrada N_bit es el bit binario
            v_curr_bin := N_bit;
        ELSE
            -- Modo Gray -> Binario: El bit binario es la salida calculada
            v_curr_bin := v_curr_out;
        END IF;

        -- PASO D: Definir la transición al siguiente estado Moore
        -- El estado siguiente debe reflejar tanto el binario actual como la salida calculada.
        IF v_curr_bin = '0' THEN
            IF v_curr_out = '0' THEN
                estado_siguiente <= S_BIN0_OUT0;
            ELSE
                estado_siguiente <= S_BIN0_OUT1;
            END IF;
        ELSE
            IF v_curr_out = '0' THEN
                estado_siguiente <= S_BIN1_OUT0;
            ELSE
                estado_siguiente <= S_BIN1_OUT1;
            END IF;
        END IF;

    END PROCESS;

END ARCHITECTURE fsm_moore;
