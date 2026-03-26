---------------------------------------------------------------------
-- DISEÑO: Codificador Gray/Binario Paralelo de 4 Bits para FPGA
-- DESCRIPCIÓN: Versión paralela del codificador para la placa
--              Cyclone II EP2C20F484C7N.
--              Captura 4 bits de entrada mediante CLK manual,
--              realiza la conversión Gray↔Binario de forma paralela
--              y permite alternar la visualización entre entrada y
--              salida en los displays de 7 segmentos y LEDs rojos
--              mediante un switch de control (VIEW).
--
-- CONFIGURACIÓN DE SWITCHES:
--   - SW0: Bit de entrada 0 (LSB)
--   - SW1: Bit de entrada 1
--   - SW2: Bit de entrada 2
--   - SW3: Bit de entrada 3 (MSB)
--   - SW4: Selección de Modo (SYS) - 0:Gray→Bin, 1:Bin→Gray
--   - SW5: Reset Manual (RST) - Limpia los registros
--   - SW6: Reloj Manual (CLK) - Captura datos en flanco de subida
--   - SW7: Control de Visualización (VIEW) - 0:Entrada, 1:Salida
--
-- SALIDAS:
--   - LEDR0-3: 4 bits según VIEW (entrada o salida)
--   - HEX0-3:  Cada display muestra '0' o '1' del bit correspondiente
--              según el estado de VIEW (asíncrono al CLK)
---------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY codificadorBG IS
    PORT (
        SW    : IN  STD_LOGIC_VECTOR(7 downto 0); -- [VIEW, CLK, RST, SYS, D3, D2, D1, D0]
        LEDR  : OUT STD_LOGIC_VECTOR(3 downto 0); -- Bits visualizados (entrada o salida)
        HEX0  : OUT STD_LOGIC_VECTOR(6 downto 0); -- Bit 0 visualizado
        HEX1  : OUT STD_LOGIC_VECTOR(6 downto 0); -- Bit 1 visualizado
        HEX2  : OUT STD_LOGIC_VECTOR(6 downto 0); -- Bit 2 visualizado
        HEX3  : OUT STD_LOGIC_VECTOR(6 downto 0)  -- Bit 3 visualizado
    );

    -- Asignación de pines según Mapeo de placa.vhd y Asignacion de pines.md
    -- Placa: Cyclone II EP2C20F484C7N
    attribute CHIP_PIN : string;
    -- Entrada: SW(7)=M2, SW(6)=U11, SW(5)=U12, SW(4)=W12, SW(3)=V12, SW(2)=M22, SW(1)=L21, SW(0)=L22
    attribute CHIP_PIN of SW   : signal is "M2, U11, U12, W12, V12, M22, L21, L22";
    -- Salida: LEDR(3)=Y19, LEDR(2)=U19, LEDR(1)=R19, LEDR(0)=R20
    attribute CHIP_PIN of LEDR : signal is "Y19, U19, R19, R20";
    -- Displays de 7 segmentos (orden: g, f, e, d, c, b, a)
    attribute CHIP_PIN of HEX0 : signal is "E2, F1, F2, H1, H2, J1, J2";
    attribute CHIP_PIN of HEX1 : signal is "D1, D2, G3, H4, H5, H6, E1";
    attribute CHIP_PIN of HEX2 : signal is "D3, E4, E3, C1, C2, G6, G5";
    attribute CHIP_PIN of HEX3 : signal is "D4, F3, L8, J4, D6, D5, F4";

END ENTITY codificadorBG;

ARCHITECTURE paralelo OF codificadorBG IS

    -- Alias para mayor claridad en la lectura del código
    alias dato_in : std_logic_vector(3 downto 0) is SW(3 downto 0); -- Bits de entrada
    alias SYS     : std_logic is SW(4);  -- Modo: 0=Gray→Bin, 1=Bin→Gray
    alias rst     : std_logic is SW(5);  -- Reset manual
    alias clk     : std_logic is SW(6);  -- Reloj manual
    alias VIEW    : std_logic is SW(7);  -- Control de visualización

    -- Registros internos capturados por el CLK manual
    SIGNAL reg_entrada : std_logic_vector(3 downto 0) := "0000"; -- Entrada capturada
    SIGNAL reg_salida  : std_logic_vector(3 downto 0) := "0000"; -- Salida convertida

    -- Señales combinacionales de conversión
    SIGNAL s_gray2bin : std_logic_vector(3 downto 0); -- Resultado Gray → Binario
    SIGNAL s_bin2gray : std_logic_vector(3 downto 0); -- Resultado Binario → Gray

    -- Señal seleccionada para visualización
    SIGNAL s_visualizar : std_logic_vector(3 downto 0);

    -- Función para decodificar '0' o '1' en 7 segmentos (Ánodo Común: '0' enciende)
    -- Formato: segmentos (g, f, e, d, c, b, a)
    function to_7seg(bit_val : std_logic) return std_logic_vector is
    begin
        if bit_val = '0' then
            return "1000000"; -- Muestra '0'
        else
            return "1111001"; -- Muestra '1'
        end if;
    end function;

BEGIN

    ---------------------------------------------------------------
    -- 1. LÓGICA DE CONVERSIÓN COMBINACIONAL (siempre activa)
    ---------------------------------------------------------------
    -- Opera sobre dato_in (switches en vivo) para que al momento
    -- del flanco de CLK, reg_salida capture la conversión correcta
    -- del dato actual, no del ciclo anterior.

    -- Conversión Gray → Binario (paralela)
    -- B(3) = G(3)
    -- B(i) = B(i+1) XOR G(i)  para i = 2, 1, 0
    s_gray2bin(3) <= dato_in(3);
    s_gray2bin(2) <= dato_in(3) XOR dato_in(2);
    s_gray2bin(1) <= dato_in(3) XOR dato_in(2) XOR dato_in(1);
    s_gray2bin(0) <= dato_in(3) XOR dato_in(2) XOR dato_in(1) XOR dato_in(0);

    -- Conversión Binario → Gray (paralela)
    -- G(3) = B(3)
    -- G(i) = B(i+1) XOR B(i)  para i = 2, 1, 0
    s_bin2gray(3) <= dato_in(3);
    s_bin2gray(2) <= dato_in(3) XOR dato_in(2);
    s_bin2gray(1) <= dato_in(2) XOR dato_in(1);
    s_bin2gray(0) <= dato_in(1) XOR dato_in(0);

    ---------------------------------------------------------------
    -- 2. REGISTRO DE CAPTURA (secuencial con CLK manual)
    ---------------------------------------------------------------
    -- Captura los 4 bits de entrada y calcula la salida convertida
    -- al detectar el flanco de subida del reloj manual (SW6).
    -- El reset limpia ambos registros.
    PROCESS(clk, rst)
    BEGIN
        IF rst = '1' THEN
            reg_entrada <= "0000";
            reg_salida  <= "0000";
        ELSIF RISING_EDGE(clk) THEN
            -- Capturar la entrada actual
            reg_entrada <= dato_in;
            -- Calcular y registrar la salida según el modo
            IF SYS = '1' THEN
                reg_salida <= s_bin2gray; -- Binario → Gray
            ELSE
                reg_salida <= s_gray2bin; -- Gray → Binario
            END IF;
        END IF;
    END PROCESS;

    ---------------------------------------------------------------
    -- 3. MULTIPLEXOR DE VISUALIZACIÓN (asíncrono)
    ---------------------------------------------------------------
    -- VIEW = '0': Muestra los bits de ENTRADA capturados
    -- VIEW = '1': Muestra los bits de SALIDA convertidos
    -- El cambio es instantáneo al mover el switch (asíncrono al CLK)
    s_visualizar <= reg_salida WHEN VIEW = '1' ELSE reg_entrada;

    ---------------------------------------------------------------
    -- 4. SALIDAS: LEDs rojos y Displays de 7 Segmentos
    ---------------------------------------------------------------

    -- Los LEDs rojos muestran los 4 bits seleccionados por VIEW
    LEDR <= s_visualizar;

    -- Cada display de 7 segmentos muestra '0' o '1' del bit correspondiente
    HEX0 <= to_7seg(s_visualizar(0)); -- Bit 0 (LSB)
    HEX1 <= to_7seg(s_visualizar(1)); -- Bit 1
    HEX2 <= to_7seg(s_visualizar(2)); -- Bit 2
    HEX3 <= to_7seg(s_visualizar(3)); -- Bit 3 (MSB)

END ARCHITECTURE paralelo;
