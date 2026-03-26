---------------------------------------------------------------------
-- DISEÑO: Codificador Gray/Binario Didáctico para FPGA
-- DESCRIPCIÓN: Versión con reloj y reset manual mediante switches.
--              Muestra el historial de 4 bits en los displays de 7 seg.
-- CONFIGURACIÓN:
--   - SW0: Reloj Manual (CLK)
--   - SW1: Reset Manual (RST)
--   - SW2: Selección Modo (SYS) - 0:Gray a Bin, 1:Bin a Gray
--   - SW3: Entrada Serial (N_bit)
--   - LEDR0: Salida (C_BIT) - Lógica Negativa (0 enciende)
--   - HEX0-3: Visualización de los últimos 4 bits de entrada
---------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY codificadorBG_FPGA IS
    PORT (
        SW    : IN  STD_LOGIC_VECTOR(3 downto 0); -- [N_bit, SYS, RST, CLK]
        LEDR  : OUT STD_LOGIC_VECTOR(0 downto 0); -- [C_BIT]
        HEX0  : OUT STD_LOGIC_VECTOR(6 downto 0); -- Bit t-3
        HEX1  : OUT STD_LOGIC_VECTOR(6 downto 0); -- Bit t-2
        HEX2  : OUT STD_LOGIC_VECTOR(6 downto 0); -- Bit t-1
        HEX3  : OUT STD_LOGIC_VECTOR(6 downto 0)  -- Bit actual (t)
    );

    -- Asignación de pines según Mapeo de placa.vhd y Asignacion de pines.md
    attribute CHIP_PIN : string;
    attribute CHIP_PIN of SW   : signal is "V12, M22, L21, L22"; -- SW3, SW2, SW1, SW0
    attribute CHIP_PIN of LEDR : signal is "R20";                -- LEDR0
    attribute CHIP_PIN of HEX0 : signal is "E2, F1, F2, H1, H2, J1, J2";
    attribute CHIP_PIN of HEX1 : signal is "D1, D2, G3, H4, H5, H6, E1";
    attribute CHIP_PIN of HEX2 : signal is "D3, E4, E3, C1, C2, G6, G5";
    attribute CHIP_PIN of HEX3 : signal is "D4, F3, L8, J4, D6, D5, F4";

END ENTITY codificadorBG_FPGA;

ARCHITECTURE didactic OF codificadorBG_FPGA IS

    -- Alias para mayor claridad
    alias clk   : std_logic is SW(0);
    alias rst   : std_logic is SW(1);
    alias SYS   : std_logic is SW(2);
    alias N_bit : std_logic is SW(3);

    -- FSM Signals
    TYPE estado_t IS (S_BIN0_OUT0, S_BIN0_OUT1, S_BIN1_OUT0, S_BIN1_OUT1);
    SIGNAL estado_actual, estado_siguiente : estado_t;
    SIGNAL s_c_bit : std_logic;

    -- Registro para historial de 4 bits
    SIGNAL history : std_logic_vector(3 downto 0) := "0000";

    -- Función para decodificar '0' o '1' en 7 segmentos (Ánodo Común)
    function to_7seg(bit_val : std_logic) return std_logic_vector is
    begin
        if bit_val = '0' then
            return "1000000"; -- Muestra '0' (g f e d c b a)
        else
            return "1111001"; -- Muestra '1'
        end if;
    end function;

BEGIN

    -- 1. Registro de Estado, Salida y Desplazamiento de Historial
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            estado_actual <= S_BIN0_OUT0;
            s_c_bit       <= '0';
            history       <= "0000";
        ELSIF RISING_EDGE(clk) THEN
            estado_actual <= estado_siguiente;
            
            -- Desplazamos el historial para ver los bits en los HEX
            history <= history(2 downto 0) & N_bit;

            -- Lógica de salida Moore registrada
            CASE estado_siguiente IS
                WHEN S_BIN0_OUT0 | S_BIN1_OUT0 => s_c_bit <= '0';
                WHEN S_BIN0_OUT1 | S_BIN1_OUT1 => s_c_bit <= '1';
            END CASE;
        END IF;
    END PROCESS;

    -- 2. Lógica de Siguiente Estado (Combinacional)
    PROCESS(estado_actual, N_bit, SYS)
        VARIABLE v_prev_bin, v_curr_out, v_curr_bin : STD_LOGIC;
    BEGIN
        estado_siguiente <= estado_actual;

        -- Bit binario previo
        IF estado_actual = S_BIN0_OUT0 OR estado_actual = S_BIN0_OUT1 THEN
            v_prev_bin := '0';
        ELSE
            v_prev_bin := '1';
        END IF;

        v_curr_out := N_bit XOR v_prev_bin;

        IF SYS = '1' THEN
            v_curr_bin := N_bit;
        ELSE
            v_curr_bin := v_curr_out;
        END IF;

        -- Transición de estado
        IF v_curr_bin = '0' THEN
            IF v_curr_out = '0' THEN estado_siguiente <= S_BIN0_OUT0;
            ELSE estado_siguiente <= S_BIN0_OUT1; END IF;
        ELSE
            IF v_curr_out = '0' THEN estado_siguiente <= S_BIN1_OUT0;
            ELSE estado_siguiente <= S_BIN1_OUT1; END IF;
        END IF;
    END PROCESS;

    -- Salida con Lógica Negativa (invertida para el LED)
    LEDR(0) <= NOT s_c_bit;

    -- Mapeo de historial a los displays de 7 segmentos
    HEX3 <= to_7seg(history(3)); -- Bit más reciente
    HEX2 <= to_7seg(history(2));
    HEX1 <= to_7seg(history(1));
    HEX0 <= to_7seg(history(0)); -- Bit más antiguo

END ARCHITECTURE didactic;
