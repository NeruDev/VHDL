-- ==============================================================================
-- Archivo: memoria_64kx8.vhd
-- Ubicación: src/memoria/
-- Descripción: Memoria principal de 64 Kilobytes (Datos e Instrucciones).
--              Actúa como RAM compartida del sistema con interfaz bidireccional.
--              Incluye un programa de prueba precargado.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity memoria_64kx8 is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map) - CONTROL Y DIRECCIONES
        -- ======================================================================
        inicia : in  std_logic; -- Señal de inicio (Reservada para futuras expansiones)
        cs     : in  std_logic; -- Chip Select: Habilita el acceso a la memoria física
        oe     : in  std_logic; -- Output Enable: Habilita la lectura (Dato -> Bus)
        we     : in  std_logic; -- Write Enable: Habilita la escritura (Bus -> RAM)
        
        -- Bus de Direcciones (16 bits = 65,536 posiciones)
        dir    : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
        
        -- ======================================================================
        -- MAPA BIDIRECCIONAL (Inout Map) - DATOS
        -- ======================================================================
        datos  : inout std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end memoria_64kx8;

architecture Comportamiento of memoria_64kx8 is
    -- ----------------------------------------------------------------------
    -- TIPOS DE DATOS Y SEÑALES INTERNAS
    -- ----------------------------------------------------------------------
    -- Definición de la matriz de memoria: 64k posiciones de 8 bits
    type ram_type is array (0 to (2**ADDR_WIDTH) - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    -- Programa de prueba: Carga 10 en R2 e incrementa R2 infinitamente
    -- Formato: [Opcode (5 bits) | Registro (3 bits)]
    -- LDI R2 = "01000" & "010" = 01000010 = 0x42
    -- INC R2 = "00101" & "010" = 00101010 = 0x2A
    signal RAM : ram_type := (
        0 => x"42", -- INST_LDI R2
        1 => x"0A", -- Valor: 10
        2 => x"48", -- INST_LDHL
        3 => x"00", -- Dirección High
        4 => x"05", -- Dirección Low (Apunta al INC)
        5 => x"2A", -- INST_INC R2
        6 => x"80", -- INST_JMP (Opcode 0x80)
        others => (others => '0')
    ); 
begin

    -- ----------------------------------------------------------------------
    -- LÓGICA DE ESCRITURA (Combinacional/Síncrona Asistida)
    -- ----------------------------------------------------------------------
    -- La escritura ocurre cuando Chip Select y Write Enable están activos.
    process(cs, we, dir, datos)
    begin
        if (cs = '1' and we = '1') then
            RAM(to_integer(unsigned(dir))) <= datos;
        end if;
    end process;

    -- ----------------------------------------------------------------------
    -- CONTROL DEL BUS BIDIRECCIONAL (Buffer Tri-estado)
    -- ----------------------------------------------------------------------
    -- La memoria solo coloca datos en el bus si:
    -- 1. Está seleccionada (cs = '1')
    -- 2. Se ha solicitado lectura (oe = '1')
    -- 3. NO se está escribiendo (we = '0') -> Crucial para evitar cortocircuitos
    datos <= RAM(to_integer(unsigned(dir))) when (cs = '1' and oe = '1' and we = '0') else 
             (others => 'Z'); -- En cualquier otro caso, desconecta del bus (Alta Impedancia)

end Comportamiento;
