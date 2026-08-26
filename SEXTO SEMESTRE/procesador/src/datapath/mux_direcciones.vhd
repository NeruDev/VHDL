--------------------------------------------------------------------------------
-- Entidad: mux_direcciones
-- Arquitectura: rtl
-- Descripción: Multiplexor de 16 bits que selecciona la fuente para el bus de 
--              direcciones de la memoria RAM.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity mux_direcciones is
    port (
        SelDir   : in  std_logic;                                -- 0: PC, 1: HL
        salidaPC : in  std_logic_vector(ADDR_WIDTH-1 downto 0); -- Dirección secuencial
        SalidaHL : in  std_logic_vector(ADDR_WIDTH-1 downto 0); -- Dirección para LOAD/STORE
        dir      : out std_logic_vector(ADDR_WIDTH-1 downto 0)  -- Bus de direcciones RAM
    );
end entity;

architecture rtl of mux_direcciones is
begin
    ----------------------------------------------------------------------------
    -- Lógica de selección
    ----------------------------------------------------------------------------
    -- SelDir = '0': Se usa el PC para el Fetch de instrucciones.
    -- SelDir = '1': Se usa HL para acceder a datos específicos (LOAD/STORE).
    dir <= salidaPC when SelDir = '0' else SalidaHL;
end architecture;
