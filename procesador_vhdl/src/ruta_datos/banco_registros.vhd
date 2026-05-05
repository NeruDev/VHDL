-- ==============================================================================
-- Archivo: banco_registros.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Banco de 8 registros de propósito general de 8 bits.
--              Cuenta con 1 puerto de escritura síncrona y 2 puertos de 
--              lectura asíncrona (combinacional).
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity banco_registros is
    Port ( 
        -- Sincronización y Control General
        clk      : in  std_logic;
        
        -- Puerto de Escritura (Write)
        wr       : in  std_logic;
        SelRegW  : in  std_logic_vector(REG_SEL_W - 1 downto 0);
        entDat   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        
        -- Puerto de Lectura A
        RA       : in  std_logic; -- Habilitador de lectura A (Desde Unidad de Control)
        SelRegRA : in  std_logic_vector(REG_SEL_W - 1 downto 0);
        SalA     : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        
        -- Puerto de Lectura B
        RB       : in  std_logic; -- Habilitador de lectura B (Desde Unidad de Control)
        SelRegRB : in  std_logic_vector(REG_SEL_W - 1 downto 0);
        SalB     : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end banco_registros;

architecture RTL of banco_registros is
    -- Definimos el tipo de arreglo: 8 posiciones (2^3) de 8 bits cada una
    type reg_array is array (0 to (2**REG_SEL_W) - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    -- Inicializamos todos los registros en cero para simulación limpia
    signal registros : reg_array := (others => (others => '0'));
begin

    -- =========================================================
    -- Proceso de Escritura (Síncrono)
    -- =========================================================
    process(clk)
    begin
        if rising_edge(clk) then
            -- Solo escribe si el habilitador 'wr' está en alto
            if wr = '1' then
                -- Convertimos el vector lógico a un entero (unsigned) para indexar la matriz
                registros(to_integer(unsigned(SelRegW))) <= entDat;
            end if;
        end if;
    end process;

    -- =========================================================
    -- Lógica de Lectura (Asíncrona / Combinacional)
    -- =========================================================
    -- Si el habilitador de lectura correspondiente está activo, volcamos el 
    -- valor del registro a la salida. De lo contrario, enviamos ceros para 
    -- mantener el bus estable y reducir el consumo de energía (toggling).
    
    SalA <= registros(to_integer(unsigned(SelRegRA))) when RA = '1' else (others => '0');
    SalB <= registros(to_integer(unsigned(SelRegRB))) when RB = '1' else (others => '0');

end RTL;
