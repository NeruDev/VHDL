--------------------------------------------------------------------------------
-- Entidad: pc (Program Counter)
-- Arquitectura: rtl
-- Descripción: Registro contador de 16 bits que apunta a la siguiente instrucción.
--              Soporta incremento secuencial y saltos (carga paralela).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.procesador_pkg.all;

entity pc is
    port (
        clk       : in  std_logic;
        clear     : in  std_logic;                        -- Reset sincrónico a 0x0000
        Lpc       : in  std_logic;                        -- Load PC: Carga desde EntradaPC (Saltos)
        Ipc       : in  std_logic;                        -- Increment PC: Suma 1 al valor actual
        EntradaPC : in  std_logic_vector(ADDR_WIDTH-1 downto 0); -- Nueva dirección (normalmente HL)
        salidaPC  : out std_logic_vector(ADDR_WIDTH-1 downto 0)  -- Dirección actual hacia memoria
    );
end entity;

architecture rtl of pc is
    signal cuenta : unsigned(ADDR_WIDTH-1 downto 0);
begin
    ----------------------------------------------------------------------------
    -- Lógica del Contador
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                -- Inicializa al principio de la memoria
                cuenta <= (others => '0');
            elsif Lpc = '1' then
                -- Salto: El PC toma el valor de la dirección destino
                cuenta <= unsigned(EntradaPC);
            elsif Ipc = '1' then
                -- Secuencial: El PC avanza a la siguiente posición
                cuenta <= cuenta + 1;
            end if;
        end if;
    end process;
    
    -- Salida continua de la dirección actual
    salidaPC <= std_logic_vector(cuenta);
end architecture;
