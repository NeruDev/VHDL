-- =============================================================================
-- PROYECTO: Codificador Serial Binario/Gray para FPGA
-- ARCHIVO: codificadorBG_serial_FPGA.vhd
-- DESCRIPCIÓN: Implementación serial de conversión Binario <-> Gray.
--              El reloj se acciona manualmente mediante un switch.
--              Mapeo de pines integrado según estándar Cyclone II.
-- 
-- ASIGNACIÓN DE PINES (SW/LED/HEX):
-- - SW(0)  [L22]: N_bit (Entrada serial, MSB primero)
-- - SW(4)  [W12]: SYS (0: Gray -> Binario, 1: Binario -> Gray)
-- - SW(5)  [U12]: RST (Reset del sistema)
-- - SW(6)  [U11]: CLK (Reloj manual por Switch)
-- - LEDR(0)[R20]: C_BIT (Salida convertida)
-- - HEX0   [E2..J2]: Visualización '0' o '1' (Ánodo común)
-- =============================================================================

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY codificadorBG_serial_FPGA IS
    PORT (
        SW    : IN  STD_LOGIC_VECTOR(9 DOWNTO 0); -- 10 Switches
        KEY   : IN  STD_LOGIC_VECTOR(3 DOWNTO 0); -- 4 Botones
        LEDR  : OUT STD_LOGIC_VECTOR(9 DOWNTO 0); -- 10 LEDs Rojos
        LEDG  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- 8 LEDs Verdes
        HEX0  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- Display 0
        HEX1  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- Display 1
        HEX2  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- Display 2
        HEX3  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)  -- Display 3
    );

    -- Atributos de asignación de pines para Cyclone II EP2C20F484C7N
    ATTRIBUTE CHIP_PIN : STRING;
    -- Entradas (SW9..SW0)
    ATTRIBUTE CHIP_PIN OF SW : SIGNAL IS "L2, M1, M2, U11, U12, W12, V12, M22, L21, L22";
    -- Entradas (KEY3..KEY0)
    ATTRIBUTE CHIP_PIN OF KEY : SIGNAL IS "T21, T22, R21, R22";
    -- Salidas (LEDR9..LEDR0)
    ATTRIBUTE CHIP_PIN OF LEDR : SIGNAL IS "R17, R18, U18, Y18, V19, T18, Y19, U19, R19, R20";
    -- Salidas (LEDG7..LEDG0)
    ATTRIBUTE CHIP_PIN OF LEDG : SIGNAL IS "Y21, Y22, W21, W22, V21, V22, U21, U22";
    -- Salidas HEX (g,f,e,d,c,b,a)
    ATTRIBUTE CHIP_PIN OF HEX0 : SIGNAL IS "E2, F1, F2, H1, H2, J1, J2";
    ATTRIBUTE CHIP_PIN OF HEX1 : SIGNAL IS "D1, D2, G3, H4, H5, H6, E1";
    ATTRIBUTE CHIP_PIN OF HEX2 : SIGNAL IS "D3, E4, E3, C1, C2, G6, G5";
    ATTRIBUTE CHIP_PIN OF HEX3 : SIGNAL IS "D4, F3, L8, J4, D6, D5, F4";

END ENTITY codificadorBG_serial_FPGA;

ARCHITECTURE fsm_fpga OF codificadorBG_serial_FPGA IS

    -- Señales internas extraídas de los vectores
    SIGNAL clk   : STD_LOGIC;
    SIGNAL rst   : STD_LOGIC;
    SIGNAL sys   : STD_LOGIC;
    SIGNAL n_bit : STD_LOGIC;
    SIGNAL c_bit : STD_LOGIC;

    -- Estados de la FSM (Moore)
    TYPE estado_t IS (S_BIN0_OUT0, S_BIN0_OUT1, S_BIN1_OUT0, S_BIN1_OUT1);
    SIGNAL estado_actual, estado_siguiente : estado_t;

BEGIN

    -- 1. Mapeo de Señales de Control
    n_bit <= SW(0); -- Entrada de datos serial
    sys   <= SW(4); -- Modo de operación
    rst   <= SW(5); -- Reset
    clk   <= SW(6); -- Reloj Manual (Switch)

    -- 2. Registro de Estado y Salida Sincrónica
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            estado_actual <= S_BIN0_OUT0;
            c_bit         <= '0';
        ELSIF RISING_EDGE(clk) THEN
            estado_actual <= estado_siguiente;
            
            -- Lógica de salida Moore: El bit convertido se registra
            CASE estado_siguiente IS
                WHEN S_BIN0_OUT0 | S_BIN1_OUT0 => c_bit <= '0';
                WHEN S_BIN0_OUT1 | S_BIN1_OUT1 => c_bit <= '1';
            END CASE;
        END IF;
    END PROCESS;

    -- 3. Lógica de Siguiente Estado (Basada en codificadorBG_Logisim.md)
    PROCESS(estado_actual, n_bit, sys)
        VARIABLE v_prev_bin : STD_LOGIC; 
        VARIABLE v_curr_out : STD_LOGIC; 
        VARIABLE v_curr_bin : STD_LOGIC; 
    BEGIN
        -- Extraer el binario previo almacenado en el estado
        IF estado_actual = S_BIN0_OUT0 OR estado_actual = S_BIN0_OUT1 THEN
            v_prev_bin := '0';
        ELSE
            v_prev_bin := '1';
        END IF;

        -- Ecuación fundamental: Salida = Entrada XOR BinarioPrevio
        v_curr_out := n_bit XOR v_prev_bin;

        -- Lógica de realimentación según el modo SYS
        IF sys = '1' THEN
            v_curr_bin := n_bit;      -- Modo Binario -> Gray
        ELSE
            v_curr_bin := v_curr_out;   -- Modo Gray -> Binario
        END IF;

        -- Determinación del próximo estado
        IF v_curr_bin = '0' THEN
            IF v_curr_out = '0' THEN estado_siguiente <= S_BIN0_OUT0;
            ELSE                     estado_siguiente <= S_BIN0_OUT1;
            END IF;
        ELSE
            IF v_curr_out = '0' THEN estado_siguiente <= S_BIN1_OUT0;
            ELSE                     estado_siguiente <= S_BIN1_OUT1;
            END IF;
        END IF;
    END PROCESS;

    -- 4. Visualización de Salidas
    LEDR(0) <= c_bit; -- Salida directa en LED rojo R20
    LEDR(9 DOWNTO 1) <= SW(9 DOWNTO 1); -- El resto de LEDs reflejan los switches
    
    LEDG <= (OTHERS => '0'); -- LEDs verdes apagados

    -- Decodificador HEX0 para mostrar '0' o '1'
    -- Formato: (g, f, e, d, c, b, a) - Ánodo común (0 enciende)
    HEX0 <= "1000000" WHEN c_bit = '0' ELSE -- Muestra '0'
            "1111001";                      -- Muestra '1'

    -- Apagar el resto de los displays
    HEX1 <= (OTHERS => '1');
    HEX2 <= (OTHERS => '1');
    HEX3 <= (OTHERS => '1');

END ARCHITECTURE fsm_fpga;
