-- ==============================================================================
-- Archivo: banco_registros.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Banco de 8 registros de propósito general de 8 bits cada uno.
--              Implementa una memoria interna rápida con un puerto de escritura
--              síncrono y dos puertos de lectura asíncronos.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity banco_registros is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map)
        -- ======================================================================
        clk      : in  std_logic; -- Reloj del Sistema
        
        -- Puerto de Escritura (Síncrono)
        wr       : in  std_logic; -- Habilitador de Escritura (Write Enable)
        SelRegW  : in  std_logic_vector(REG_SEL_W - 1 downto 0); -- Selección de registro (0-7)
        entDat   : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Dato a escribir
        
        -- Puerto de Lectura A (Asíncrono)
        RA       : in  std_logic; -- Habilitador de Lectura Puerto A
        SelRegRA : in  std_logic_vector(REG_SEL_W - 1 downto 0); -- Selección Reg A
        
        -- Puerto de Lectura B (Asíncrono)
        RB       : in  std_logic; -- Habilitador de Lectura Puerto B
        SelRegRB : in  std_logic_vector(REG_SEL_W - 1 downto 0); -- Selección Reg B
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map)
        -- ======================================================================
        SalA     : out std_logic_vector(DATA_WIDTH - 1 downto 0); -- Valor leído en A
        SalB     : out std_logic_vector(DATA_WIDTH - 1 downto 0)  -- Valor leído en B
    );
end banco_registros;

architecture RTL of banco_registros is
    -- ----------------------------------------------------------------------
    -- TIPOS DE DATOS Y SEÑALES INTERNAS
    -- ----------------------------------------------------------------------
    -- Definimos la estructura de memoria: 8 filas de 8 bits
    type reg_array is array (0 to (2**REG_SEL_W) - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    -- Inicializamos todos los registros en cero para asegurar un estado conocido
    signal registros : reg_array := (others => (others => '0'));
begin

    -- ----------------------------------------------------------------------
    -- PROCESO SÍNCRONO: ESCRITURA EN REGISTROS
    -- ----------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            -- Solo se modifica el contenido si el habilitador 'wr' está en alto
            if wr = '1' then
                registros(to_integer(unsigned(SelRegW))) <= entDat;
            end if;
        end if;
    end process;

    -- ----------------------------------------------------------------------
    -- LÓGICA COMBINACIONAL: LECTURA ASÍNCRONA
    -- ----------------------------------------------------------------------
    -- Las lecturas no dependen del reloj; el dato está disponible en cuanto
    -- cambian los índices de selección y los habilitadores.
    -- Si el habilitador está en '0', se fuerza la salida a cero.
    
    SalA <= registros(to_integer(unsigned(SelRegRA))) when RA = '1' else (others => '0');
    SalB <= registros(to_integer(unsigned(SelRegRB))) when RB = '1' else (others => '0');

end RTL;
