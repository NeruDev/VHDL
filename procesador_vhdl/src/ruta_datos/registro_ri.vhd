-- ==============================================================================
-- Archivo: registro_ri.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Registro de Instrucción (RI) de 8 bits.
--              Almacena el código de operación (Opcode) leído desde la memoria
--              durante la fase de FETCH para su posterior decodificación.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity registro_ri is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map)
        -- ======================================================================
        clk    : in  std_logic; -- Reloj del Sistema
        clear  : in  std_logic; -- Reset Global
        Lri    : in  std_logic; -- Load RI: Habilita la captura del bus de datos
        
        entDat : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Dato desde BusDatos
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map)
        -- ======================================================================
        CO     : out std_logic_vector(DATA_WIDTH - 1 downto 0)  -- Hacia Unidad de Control
    );
end registro_ri;

architecture RTL of registro_ri is
    -- ----------------------------------------------------------------------
    -- SEÑALES INTERNAS
    -- ----------------------------------------------------------------------
    signal registro_interno : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
begin

    -- ----------------------------------------------------------------------
    -- PROCESO SÍNCRONO: ALMACENAMIENTO DE INSTRUCCIÓN
    -- ----------------------------------------------------------------------
    process(clk, clear)
    begin
        if clear = '1' then
            registro_interno <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Solo captura el bus cuando la UC activa Lri
            if Lri = '1' then
                registro_interno <= entDat;
            end if;
        end if;
    end process;

    -- Salida concurrente hacia la Unidad de Control
    CO <= registro_interno;

end RTL;
