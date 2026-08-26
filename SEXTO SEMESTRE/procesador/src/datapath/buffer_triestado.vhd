--------------------------------------------------------------------------------
-- Entidad: buffer_triestado
-- Arquitectura: rtl
-- Descripción: Buffer triestado que controla la conexión de un bus local 
--              al bus de datos común bidireccional.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity buffer_triestado is
    port (
        entrada  : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Dato a enviar
        habilitar: in  std_logic;                               -- Habilitador (SalAlu)
        salida   : out std_logic_vector(DATA_WIDTH-1 downto 0)  -- Conexión al BusDatos
    );
end entity;

architecture rtl of buffer_triestado is
begin
    ----------------------------------------------------------------------------
    -- Lógica Triestado
    ----------------------------------------------------------------------------
    -- habilitar = '1': El dato de entrada fluye hacia la salida.
    -- habilitar = '0': La salida se pone en alta impedancia ('Z'), liberando el bus.
    salida <= entrada when habilitar = '1' else (others => 'Z');
end architecture;
