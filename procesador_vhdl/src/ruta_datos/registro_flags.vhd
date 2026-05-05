-- ==============================================================================
-- Archivo: registro_flags.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Registro de estado que almacena las banderas de la ALU (FZ, FS, FC).
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity registro_flags is
    Port ( 
        -- Sincronización y Control
        clk       : in  std_logic;
        clear     : in  std_logic; -- Reset asíncrono desde la Unidad de Control
        LF        : in  std_logic; -- Load Flags: Habilita la captura de nuevas banderas
        
        -- Datos
        Flags_in  : in  std_logic_vector(7 downto 0); -- Viene de la ALU
        Flags_out : out std_logic_vector(7 downto 0)  -- Va hacia la Unidad de Control (FZ, etc.)
    );
end registro_flags;

architecture RTL of registro_flags is
    -- Señal interna para retener el estado
    signal registro_interno : std_logic_vector(7 downto 0) := (others => '0');
begin

    -- Proceso síncrono con reset asíncrono
    process(clk, clear)
    begin
        -- El reset asíncrono tiene prioridad máxima
        if clear = '1' then
            registro_interno <= (others => '0');
            
        -- Si no hay clear, evaluamos el flanco del reloj
        elsif rising_edge(clk) then
            -- Solo actualizamos las banderas si la Unidad de Control lo ordena (LF = '1')
            -- Esto evita sobreescribir las banderas durante operaciones que no afectan el estado
            if LF = '1' then
                registro_interno <= Flags_in;
            end if;
        end if;
    end process;

    -- Asignación concurrente de la salida
    Flags_out <= registro_interno;

end RTL;
