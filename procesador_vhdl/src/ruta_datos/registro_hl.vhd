-- ==============================================================================
-- Archivo: registro_hl.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Registro combinado H|L de 16 bits (High y Low).
-- Permite cargar la parte alta y baja de manera independiente desde un bus de 8 bits.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity registro_hl is
    Port ( 
        clk       : in  std_logic;
        clear     : in  std_logic;
        LH        : in  std_logic; -- Load High: Carga el byte alto
        LL        : in  std_logic; -- Load Low: Carga el byte bajo
        
        entDat    : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Desde el BusDatos (8 bits)
        salida_hl : out std_logic_vector(ADDR_WIDTH - 1 downto 0)  -- Hacia entradaPC y Mux (16 bits)
    );
end registro_hl;

architecture RTL of registro_hl is
    signal reg_H : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal reg_L : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
begin

    process(clk, clear)
    begin
        if clear = '1' then
            reg_H <= (others => '0');
            reg_L <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Se evalúan de manera independiente; la Unidad de Control 
            -- podría teóricamente mandar cargar ambos al mismo tiempo.
            if LH = '1' then
                reg_H <= entDat;
            end if;
            
            if LL = '1' then
                reg_L <= entDat;
            end if;
        end if;
    end process;

    -- Concatenación de ambos registros de 8 bits para formar el bus de 16 bits
    -- El operador '&' une el registro High (bits 15 downto 8) y el Low (bits 7 downto 0)
    salida_hl <= reg_H & reg_L;

end RTL;
