-- ==============================================================================
-- Archivo: procesador_fpga.vhd
-- Ubicación: src/top/
-- Descripción: Top-Level para implementación en FPGA Cyclone II.
--              Incluye divisor de frecuencia y decodificadores de 7 seg.
-- ==============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity procesador_fpga is
    Port ( 
        CLOCK_50  : in  std_logic; -- PIN_L1 (50 MHz)
        KEY       : in  std_logic_vector(0 downto 0); -- PIN_R22 (Reset - Botón 0)
        
        -- Salidas visuales
        LEDR      : out std_logic_vector(7 downto 0); -- LEDs rojos para bus binario
        HEX0      : out std_logic_vector(6 downto 0); -- Siete segmentos (Bajo)
        HEX1      : out std_logic_vector(6 downto 0)  -- Siete segmentos (Alto)
    );
end procesador_fpga;

architecture Top of procesador_fpga is
    signal clk_1hz     : std_logic;
    signal rst_n       : std_logic;
    signal bus_interno : std_logic_vector(7 downto 0);
begin
    -- El botón suele ser activo en bajo en estas placas, lo invertimos si es necesario
    rst_n <= not KEY(0);

    -- 1. Instancia del Divisor de Frecuencia
    U_DIV: entity work.divisor_frecuencia
    port map (
        clk_50MHz => CLOCK_50,
        clk_lento => clk_1hz
    );

    -- 2. Instancia del Procesador (Núcleo)
    U_CPU: entity work.procesador
    port map (
        rst    => rst_n,
        clk    => clk_1hz,
        salida => bus_interno
    );

    -- 3. Decodificadores de 7 Segmentos para el Bus de Datos
    -- Parte baja (Bits 0-3)
    U_HEX0: entity work.deco_7seg
    port map (
        binario => bus_interno(3 downto 0),
        segmentos => HEX0
    );

    -- Parte alta (Bits 4-7)
    U_HEX1: entity work.deco_7seg
    port map (
        binario => bus_interno(7 downto 4),
        segmentos => HEX1
    );

    -- 4. LEDs Rojos (Copia del bus binario)
    LEDR <= bus_interno;

end Top;
