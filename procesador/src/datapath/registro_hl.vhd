--------------------------------------------------------------------------------
-- Entidad: registro_hl
-- Arquitectura: rtl
-- Descripción: Par de registros de 8 bits (H y L) que actúan como un puntero 
--              de direcciones de 16 bits para la memoria.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity registro_hl is
    port (
        clk         : in  std_logic;
        clear       : in  std_logic;                        -- Reset sincrónico
        LH          : in  std_logic;                        -- Load High: Carga el byte alto (H)
        LL          : in  std_logic;                        -- Load Low: Carga el byte bajo (L)
        BusDatos_in : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Dato desde el bus
        SalidaHL    : out std_logic_vector(ADDR_WIDTH-1 downto 0)  -- Dirección de 16 bits (H & L)
    );
end entity;

architecture rtl of registro_hl is
    signal H, L : std_logic_vector(DATA_WIDTH-1 downto 0);
begin
    ----------------------------------------------------------------------------
    -- Proceso de carga de registros
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                H <= (others => '0');
                L <= (others => '0');
            else
                -- La carga es independiente para permitir ensamblar direcciones de 8 en 8 bits
                if LH = '1' then
                    H <= BusDatos_in;
                end if;
                if LL = '1' then
                    L <= BusDatos_in;
                end if;
            end if;
        end if;
    end process;

    -- Concatenación de H y L para formar el bus de direcciones de 16 bits
    SalidaHL <= H & L;
end architecture;
