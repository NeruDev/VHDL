-- ==============================================================================
-- Archivo: pc.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Program Counter (PC) de 16 bits.
--              Mantiene el puntero a la dirección de memoria de la instrucción actual.
--              Permite incrementos secuenciales o carga de nuevas direcciones.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity pc is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map)
        -- ======================================================================
        clk       : in  std_logic; -- Reloj del Sistema
        clear     : in  std_logic; -- Reset Síncrono/Asíncrono (Limpia a 0x0000)
        Lpc       : in  std_logic; -- Load PC: Habilita la carga desde 'entradaPC'
        Ipc       : in  std_logic; -- Increment PC: Suma 1 al valor actual
        
        -- Datos de entrada (16 bits)
        entradaPC : in  std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Desde Registro HL
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map)
        -- ======================================================================
        salida    : out std_logic_vector(ADDR_WIDTH - 1 downto 0)  -- Hacia Mux_Dir
    );
end pc;

architecture RTL of pc is
    -- ----------------------------------------------------------------------
    -- SEÑALES INTERNAS
    -- ----------------------------------------------------------------------
    signal conteo_interno : unsigned(ADDR_WIDTH - 1 downto 0) := (others => '0');
begin

    -- ----------------------------------------------------------------------
    -- PROCESO SÍNCRONO: GESTIÓN DEL CONTADOR
    -- ----------------------------------------------------------------------
    process(clk, clear)
    begin
        -- El reset (clear) tiene prioridad máxima
        if clear = '1' then
            conteo_interno <= (others => '0');
            
        elsif rising_edge(clk) then
            -- La carga (Lpc) tiene prioridad sobre el incremento (Ipc)
            if Lpc = '1' then
                conteo_interno <= unsigned(entradaPC);
            elsif Ipc = '1' then
                conteo_interno <= conteo_interno + 1;
            end if;
        end if;
    end process;

    -- Salida concurrente con conversión de tipo
    salida <= std_logic_vector(conteo_interno);

end RTL;
