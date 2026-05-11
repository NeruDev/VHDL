--------------------------------------------------------------------------------
-- Entidad: registro_flags
-- Arquitectura: rtl
-- Descripción: Almacena las banderas de estado generadas por la ALU.
--              Banderas implementadas: Zero (Z), Signo (S), Acarreo (C).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity registro_flags is
    port (
        clk       : in  std_logic;
        clear     : in  std_logic;                        -- Reset sincrónico
        Lf        : in  std_logic;                        -- Load Flags: Habilita actualización
        Z_in      : in  std_logic;                        -- Zero Flag desde ALU
        S_in      : in  std_logic;                        -- Sign Flag desde ALU
        C_in      : in  std_logic;                        -- Carry Flag desde ALU
        Flags_out : out std_logic_vector(7 downto 0)      -- Vector de banderas para la UC
    );
end entity;

architecture rtl of registro_flags is
    -- Registro interno de 8 bits
    signal reg : std_logic_vector(7 downto 0);
begin
    ----------------------------------------------------------------------------
    -- Proceso de almacenamiento de banderas
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                reg <= (others => '0');
            elsif Lf = '1' then
                -- Mapeo de banderas según convención interna
                reg(0) <= Z_in; -- Bit 0: Zero
                reg(1) <= S_in; -- Bit 1: Signo
                reg(2) <= C_in; -- Bit 2: Acarreo
                
                -- Bits 3 a 7 reservados (se mantienen en 0)
                reg(7 downto 3) <= (others => '0');
            end if;
        end if;
    end process;

    -- Salida hacia la Unidad de Control para saltos condicionales
    Flags_out <= reg;
end architecture;
