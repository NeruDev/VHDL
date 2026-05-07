-- ==============================================================================
-- Archivo: registro_flags.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Registro de estado que almacena las banderas de la ALU.
--              Permite que la Unidad de Control tome decisiones (saltos)
--              basándose en el resultado de operaciones previas.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity registro_flags is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map)
        -- ======================================================================
        clk       : in  std_logic; -- Reloj del Sistema
        clear     : in  std_logic; -- Reset Global
        LF        : in  std_logic; -- Load Flags: Habilita la captura de banderas
        
        -- Datos de entrada desde la ALU (bit 0=Z, bit 1=S, bit 2=C)
        Flags_in  : in  std_logic_vector(7 downto 0); 
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map)
        -- ======================================================================
        Flags_out : out std_logic_vector(7 downto 0) -- Hacia la Unidad de Control
    );
end registro_flags;

architecture RTL of registro_flags is
    -- ----------------------------------------------------------------------
    -- SEÑALES INTERNAS
    -- ----------------------------------------------------------------------
    signal registro_interno : std_logic_vector(7 downto 0) := (others => '0');
begin

    -- ----------------------------------------------------------------------
    -- PROCESO SÍNCRONO: ALMACENAMIENTO DE BANDERAS
    -- ----------------------------------------------------------------------
    process(clk, clear)
    begin
        if clear = '1' then
            registro_interno <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Solo se actualiza cuando la UC lo ordena (LF='1')
            if LF = '1' then
                registro_interno <= Flags_in;
            end if;
        end if;
    end process;

    -- Salida concurrente
    Flags_out <= registro_interno;

end RTL;
