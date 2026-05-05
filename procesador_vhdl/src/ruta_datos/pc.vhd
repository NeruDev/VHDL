-- ==============================================================================
-- Archivo: pc.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Program Counter (Contador de Programa) de 16 bits.
-- Permite incrementar su valor o cargar una nueva dirección (para saltos).
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity pc is
    Port ( 
        -- Sincronización y Control
        clk       : in  std_logic;
        clear     : in  std_logic; -- Reset asíncrono
        Lpc       : in  std_logic; -- Load PC: Carga una nueva dirección
        Ipc       : in  std_logic; -- Increment PC: Suma 1 al valor actual
        
        -- Datos
        entradaPC : in  std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Viene de H|L
        salida    : out std_logic_vector(ADDR_WIDTH - 1 downto 0)  -- Va al Mux_Dir
    );
end pc;

architecture RTL of pc is
    signal conteo_interno : unsigned(ADDR_WIDTH - 1 downto 0) := (others => '0');
begin

    process(clk, clear)
    begin
        if clear = '1' then
            conteo_interno <= (others => '0');
            
        elsif rising_edge(clk) then
            -- La prioridad lógica la suele tener la carga (Load) sobre el incremento
            if Lpc = '1' then
                conteo_interno <= unsigned(entradaPC);
            elsif Ipc = '1' then
                conteo_interno <= conteo_interno + 1;
            end if;
        end if;
    end process;

    -- Cast a std_logic_vector para la salida
    salida <= std_logic_vector(conteo_interno);

end RTL;
