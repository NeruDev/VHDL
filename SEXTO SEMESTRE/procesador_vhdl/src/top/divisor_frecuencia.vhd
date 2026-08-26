-- ==============================================================================
-- Archivo: divisor_frecuencia.vhd
-- Ubicación: src/top/
-- Descripción: Generador de base de tiempos. Reduce la frecuencia del cristal 
--              base de la placa (50MHz) a una frecuencia apta para la 
--              observación humana (aprox. 1 Hz).
-- ==============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divisor_frecuencia is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map)
        -- ======================================================================
        clk_50MHz : in  std_logic; -- Reloj rápido (50 millones de pulsos/seg)
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map)
        -- ======================================================================
        clk_lento : out std_logic  -- Reloj lento (1 pulso/seg)
    );
end divisor_frecuencia;

architecture RTL of divisor_frecuencia is
    -- ----------------------------------------------------------------------
    -- SEÑALES INTERNAS
    -- ----------------------------------------------------------------------
    -- Para obtener 1Hz de un reloj de 50MHz, necesitamos contar hasta 25 millones 
    -- y luego invertir el estado (toggle) del reloj de salida.
    signal contador : integer range 0 to 25000000 := 0;
    signal estado   : std_logic := '0';
begin

    -- ----------------------------------------------------------------------
    -- PROCESO SÍNCRONO: DIVISIÓN POR CONTEO
    -- ----------------------------------------------------------------------
    process(clk_50MHz)
    begin
        if rising_edge(clk_50MHz) then
            if contador = 25000000 then
                contador <= 0;
                estado <= not estado; -- Invierte el nivel (0 -> 1 o 1 -> 0)
            else
                contador <= contador + 1;
            end if;
        end if;
    end process;

    -- Salida del reloj dividido
    clk_lento <= estado;

end RTL;
