-- ==============================================================================
-- Archivo: procesador_fpga.vhd
-- Ubicación: src/top/
-- Descripción: Módulo de adaptación para hardware real (FPGA Cyclone II).
--              Incluye gestión de reloj lento para visualización humana y 
--              decodificación para displays de 7 segmentos.
-- ==============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity procesador_fpga is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map) - PLACA DE-1 / CYCLONE II
        -- ======================================================================
        CLOCK_50  : in  std_logic; -- Reloj base de la placa (50 MHz)
        KEY       : in  std_logic_vector(0 downto 0); -- Botón 0: Reset Maestro
        SW        : in  std_logic_vector(0 downto 0); -- Switch 0: Señal INICIA
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map) - VISUALIZACIÓN
        -- ======================================================================
        LEDR      : out std_logic_vector(7 downto 0); -- LEDs rojos: Bus de datos binario
        HEX0      : out std_logic_vector(6 downto 0); -- Display 7-seg (Bajo): Bits 0-3
        HEX1      : out std_logic_vector(6 downto 0)  -- Display 7-seg (Alto): Bits 4-7
    );
end procesador_fpga;

architecture Top of procesador_fpga is
    -- ----------------------------------------------------------------------
    -- SEÑALES INTERNAS
    -- ----------------------------------------------------------------------
    signal clk_1hz     : std_logic; -- Reloj de 1 Hz (1 ciclo por segundo)
    signal rst_n       : std_logic; -- Reset invertido ( KEY es activo en bajo)
    signal bus_interno : std_logic_vector(7 downto 0); -- Captura del bus del procesador
begin
    -- Los botones KEY de la placa Cyclone II suelen ser activos en bajo (0 pulsado)
    rst_n <= not KEY(0);

    -- 1. Instancia del Divisor de Frecuencia: Reduce 50MHz -> 1Hz
    U_DIV: entity work.divisor_frecuencia
    port map (
        clk_50MHz => CLOCK_50,
        clk_lento => clk_1hz
    );

    -- 2. Instancia del Núcleo del Procesador (CPU)
    U_CPU: entity work.procesador
    port map (
        rst    => rst_n,
        clk    => clk_1hz,
        inicia => SW(0),
        salida => bus_interno
    );

    -- 3. Decodificador HEX0: Muestra los 4 bits menos significativos (Nivel bajo)
    U_HEX0: entity work.deco_7seg
    port map (
        binario => bus_interno(3 downto 0),
        segmentos => HEX0
    );

    -- 4. Decodificador HEX1: Muestra los 4 bits más significativos (Nivel alto)
    U_HEX1: entity work.deco_7seg
    port map (
        binario => bus_interno(7 downto 4),
        segmentos => HEX1
    );

    -- Copia directa del bus de datos a los LEDs para monitoreo binario
    LEDR <= bus_interno;

end Top;
