--------------------------------------------------------------------------------
-- Entidad: memoria_ram
-- Arquitectura: rtl
-- Descripción: Memoria RAM de 256 bytes (8 bits de datos, 8 bits de direccionamiento
--              efectivo). Contiene el programa de prueba pre-cargado.
-- Referencias: Proyecto/ARCHIVOS_BASE/TEST_PROCESADOR.md
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.procesador_pkg.all;

entity memoria_ram is
    port (
        clk    : in    std_logic;
        we     : in    std_logic;                        -- Write Enable (Activo Alto)
        cs     : in    std_logic;                        -- Chip Select (Activo Bajo)
        oe     : in    std_logic;                        -- Output Enable (Activo Bajo)
        inicia : in    std_logic;                        -- Reinicia contenido a programa base
        dir    : in    std_logic_vector(ADDR_WIDTH-1 downto 0); -- Bus direcciones (16 bits)
        datos  : inout std_logic_vector(DATA_WIDTH-1 downto 0)  -- Bus datos (bidireccional)
    );
end entity;

architecture rtl of memoria_ram is
    -- Definición del banco de memoria de 256 posiciones
    type banco is array (0 to 255) of std_logic_vector(DATA_WIDTH-1 downto 0);
    
    ----------------------------------------------------------------------------
    -- Función: inicia_ram
    -- Propósito: Carga el programa de prueba y datos iniciales en el arreglo.
    ----------------------------------------------------------------------------
    function inicia_ram return banco is 
        variable tempo : banco := (others => (others => '0'));
    begin 
        -- Relleno inicial con valor de dirección
        for addr in 0 to 255 loop 
            tempo(addr) := std_logic_vector(to_unsigned(addr, DATA_WIDTH));
        end loop;
        
        -- PROGRAMA DE PRUEBA (Según TEST_PROCESADOR.md)
        tempo(0)  := x"70";  -- LOAD: R1 <- M[0035]
        tempo(1)  := x"35";
        tempo(2)  := x"00";

        tempo(3)  := x"46";  -- MOV: R0 <- R1

        tempo(4)  := x"47";  -- MOVI: R1 <- 5E
        tempo(5)  := x"5E";  
      
        tempo(6)  := x"45";  -- ADD: R1 <- R0 + R1
        
        tempo(7)  := x"71";  -- STORE: M[0036] <- R1
        tempo(8)  := x"36";
        tempo(9)  := x"00";

        tempo(10) := x"82";  -- JC: Salta a 000F si hay acarreo
        tempo(11) := x"0F";
        tempo(12) := x"00";
        
        tempo(13) := x"10";  -- NOP / Trampa
        tempo(14) := x"20";  -- NOP / Trampa

        tempo(15) := x"42";  -- DEC: R1 <- R1 - 1

        tempo(16) := x"81";  -- JZ: Salta a 002C si es cero
        tempo(17) := x"2C";
        tempo(18) := x"00";
        
        tempo(19) := x"42";  -- DEC: R1 <- R1 - 1

        tempo(20) := x"81";  -- JZ: Salta a 0019 si es cero
        tempo(21) := x"19";
        tempo(22) := x"00";
        
        tempo(23) := x"11";  
        tempo(24) := x"21";  
        
        tempo(25) := x"43";  -- INC: R1 <- R1 + 1

        tempo(26) := x"40";  -- NOT: R1 <- not R1
        
        tempo(27) := x"83";  -- JS: Salta a 0020 si es negativo
        tempo(28) := x"20";
        tempo(29) := x"00";
        
        tempo(30) := x"12";  
        tempo(31) := x"22";  
        
        tempo(32) := x"47";  -- MOVI: R1 <- F9
        tempo(33) := x"F9";
        
        tempo(34) := x"41";  -- AND: R1 <- R0 and R1
            
        tempo(35) := x"70";  -- LOAD: R1 <- M[0036]
        tempo(36) := x"36";
        tempo(37) := x"00";

        tempo(38) := x"80";  -- JMP: Salto incondicional a 002C
        tempo(39) := x"2C";
        tempo(40) := x"00";
        
        tempo(44) := x"FF";  -- FIN: Detención del procesador

        -- DATOS INICIALES
        tempo(16#035#) := x"A4";
        tempo(16#036#) := x"B5";
        tempo(16#037#) := x"C6";
        
        return tempo;
    end function;

    signal contenido : banco := inicia_ram;
begin

    ----------------------------------------------------------------------------
    -- Proceso de Escritura Síncrona
    ----------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if inicia = '1' then
                contenido <= inicia_ram;
            elsif cs = '0' and we = '1' then
                -- Se direcciona usando solo los 8 bits bajos (rango 0-255)
                contenido(to_integer(unsigned(dir(7 downto 0)))) <= datos;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Lógica de Lectura Asíncrona (Combinacional)
    ----------------------------------------------------------------------------
    -- El dato se coloca en el bus si cs y oe están activos (0).
    -- De lo contrario, el bus queda en alta impedancia ('Z').
    datos <= contenido(to_integer(unsigned(dir(7 downto 0)))) when cs = '0' and oe = '0' else (others => 'Z');

end architecture;
