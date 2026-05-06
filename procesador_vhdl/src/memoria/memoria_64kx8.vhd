-- ==============================================================================
-- Archivo: memoria_64kx8.vhd
-- Ubicación: src/memoria/
-- Descripción: Memoria principal de 64KB (Datos e Instrucciones).
-- Utiliza un puerto bidireccional controlado por CS, WE y OE.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity memoria_64kx8 is
    Port ( 
        -- Señales de Control (provenientes de la Unidad de Control)
        inicia : in  std_logic; -- Puede usarse para cargar un programa inicial
        cs     : in  std_logic; -- Chip Select: Activa en '1'
        oe     : in  std_logic; -- Output Enable: Activa en '1' (Lectura)
        we     : in  std_logic; -- Write Enable: Activa en '1' (Escritura)
        
        -- Bus de Direcciones (Proveniente de la Ruta de Datos)
        dir    : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
        
        -- Bus de Datos Bidireccional
        datos  : inout std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end memoria_64kx8;

architecture Comportamiento of memoria_64kx8 is
    -- Definición del tipo de arreglo para 64K posiciones de 8 bits
    type ram_type is array (0 to (2**ADDR_WIDTH) - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    -- Señal que representa la memoria física con un pequeño programa de prueba
    signal RAM : ram_type := (
        0 => x"01", -- Opcode ADD
        1 => x"01", -- Opcode ADD
        2 => x"02", -- Opcode LOAD (ficticio)
        3 => x"FF", -- Opcode Desconocido (Reset/Loop)
        others => (others => '0')
    ); 
begin

    -- Proceso de Escritura (Síncrono o asíncrono dependiendo de la tecnología, 
    -- aquí lo modelamos sensible a cambios en los buses para simulación básica)
    process(cs, we, dir, datos)
    begin
        -- Si el chip está seleccionado y la escritura está habilitada
        if (cs = '1' and we = '1') then
            RAM(to_integer(unsigned(dir))) <= datos;
        end if;
    end process;

    -- =========================================================
    -- Control del Bus Bidireccional (Buffer Tri-estado)
    -- =========================================================
    -- Solo colocamos datos en el bus si el Chip Select y Output Enable están activos,
    -- y Write Enable está desactivado. De lo contrario, el bus queda en Alta Impedancia ('Z').
    datos <= RAM(to_integer(unsigned(dir))) when (cs = '1' and oe = '1' and we = '0') else 
             (others => 'Z');

end Comportamiento;
