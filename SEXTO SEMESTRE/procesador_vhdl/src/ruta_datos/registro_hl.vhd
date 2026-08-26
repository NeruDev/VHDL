-- ==============================================================================
-- Archivo: registro_hl.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Registro especial de 16 bits dividido en dos bytes (High y Low).
--              Se utiliza como puntero de direcciones para acceso a RAM y saltos.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity registro_hl is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map)
        -- ======================================================================
        clk       : in  std_logic; -- Reloj del Sistema
        clear     : in  std_logic; -- Reset Global
        LH        : in  std_logic; -- Load High: Habilita la carga del byte alto (H)
        LL        : in  std_logic; -- Load Low: Habilita la carga del byte bajo (L)
        
        entDat    : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Dato desde BusDatos (8 bits)
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map)
        -- ======================================================================
        salida_hl : out std_logic_vector(ADDR_WIDTH - 1 downto 0)  -- Valor completo (16 bits)
    );
end registro_hl;

architecture RTL of registro_hl is
    -- ----------------------------------------------------------------------
    -- SEÑALES INTERNAS
    -- ----------------------------------------------------------------------
    signal reg_H : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal reg_L : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
begin

    -- ----------------------------------------------------------------------
    -- PROCESO SÍNCRONO: CARGA INDEPENDIENTE DE BYTES
    -- ----------------------------------------------------------------------
    process(clk, clear)
    begin
        if clear = '1' then
            reg_H <= (others => '0');
            reg_L <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Permite cargar H y L en ciclos diferentes o iguales
            if LH = '1' then
                reg_H <= entDat;
            end if;
            
            if LL = '1' then
                reg_L <= entDat;
            end if;
        end if;
    end process;

    -- Concatenación de ambos registros para formar la dirección de 16 bits
    salida_hl <= reg_H & reg_L;

end RTL;
