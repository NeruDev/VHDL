--------------------------------------------------------------------------------
-- Entidad: banco_registros
-- Arquitectura: rtl
-- Descripción: Conjunto de 8 registros de propósito general (R0 a R7). 
--              Permite dos lecturas simultáneas y una escritura por ciclo.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.procesador_pkg.all;

entity banco_registros is
    port (
        clk      : in  std_logic;
        clear    : in  std_logic;                                -- Reset sincrónico
        wr       : in  std_logic;                                -- Write Enable
        SelRegW  : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0); -- Selector de registro a escribir
        SelRegRA : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0); -- Selector de registro para Bus A
        SelRegRB : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0); -- Selector de registro para Bus B
        entDat   : in  std_logic_vector(DATA_WIDTH-1 downto 0);     -- Dato a escribir (desde bus de datos)
        SalA     : out std_logic_vector(DATA_WIDTH-1 downto 0);     -- Salida hacia operando A de ALU
        SalB     : out std_logic_vector(DATA_WIDTH-1 downto 0)      -- Salida hacia operando B de ALU
    );
end entity;

architecture rtl of banco_registros is
    -- Arreglo que contiene los 8 registros de 8 bits
    type registro_array is array (0 to (2**REG_ADDR_WIDTH)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal registros : registro_array;
begin
    ----------------------------------------------------------------------------
    -- Lectura asíncrona (Combinacional)
    -- Los datos están disponibles inmediatamente al cambiar la dirección.
    ----------------------------------------------------------------------------
    SalA <= registros(to_integer(unsigned(SelRegRA)));
    SalB <= registros(to_integer(unsigned(SelRegRB)));

    ----------------------------------------------------------------------------
    -- Escritura síncrona (Secuencial)
    -- Los datos se graban en el flanco de subida del reloj.
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                -- Reset: Pone todos los registros a cero
                for i in 0 to (2**REG_ADDR_WIDTH)-1 loop
                    registros(i) <= (others => '0');
                end loop;
            elsif wr = '1' then
                -- Grabación del dato en el registro seleccionado por SelRegW
                registros(to_integer(unsigned(SelRegW))) <= entDat;
            end if;
        end if;
    end process;
end architecture;
