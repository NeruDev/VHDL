library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.procesador_pkg.all;

entity memoria_ram is
    port (
        clk    : in    std_logic;
        we     : in    std_logic;
        cs     : in    std_logic;
        oe     : in    std_logic;
        inicia : in    std_logic;
        dir    : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
        datos  : inout std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of memoria_ram is
    -- Memoria de 256x8 (solo usamos los 8 bits bajos de la dirección)
    type banco is array (0 to 255) of std_logic_vector(DATA_WIDTH-1 downto 0);
    
    function inicia_ram return banco is 
        variable tempo : banco := (others => (others => '0'));
    begin 
        for addr in 0 to 255 loop 
            -- Inicializa cada celda con el valor de su dirección por defecto
            tempo(addr) := std_logic_vector(to_unsigned(addr, DATA_WIDTH));
        end loop;
        
        -- Programa extraído de TEST_PROCESADOR.md
        tempo(0)  := x"70";  -- R1 <- M[0035]
        tempo(1)  := x"35";
        tempo(2)  := x"00";

        tempo(3)  := x"46";  -- R0 <- R1

        tempo(4)  := x"47";  -- R1 <- 5E
        tempo(5)  := x"5E";  
      
        tempo(6)  := x"45";  -- R1 <- R0 + R1
        
        tempo(7)  := x"71";  -- M[0036] <- R1
        tempo(8)  := x"36";
        tempo(9)  := x"00";

        tempo(10) := x"82";  -- JC 000F (15)
        tempo(11) := x"0F";
        tempo(12) := x"00";
        
        tempo(13) := x"10";  -- Trampa
        tempo(14) := x"20";  -- Trampa

        tempo(15) := x"42";  -- R1 <- R1 - 1

        tempo(16) := x"81";  -- JZ 002C (44)
        tempo(17) := x"2C";
        tempo(18) := x"00";
        
        tempo(19) := x"42";  -- R1 <- R1 - 1

        tempo(20) := x"81";  -- JZ 0019 (25)
        tempo(21) := x"19";
        tempo(22) := x"00";
        
        tempo(23) := x"11";  -- Trampa
        tempo(24) := x"21";  -- Trampa
        
        tempo(25) := x"43";  -- R1 <- R1 + 1

        tempo(26) := x"40";  -- R1 <- not R1
        
        tempo(27) := x"83";  -- JS 0020 (32)
        tempo(28) := x"20";
        tempo(29) := x"00";
        
        tempo(30) := x"12";  -- Trampa
        tempo(31) := x"22";  -- Trampa
        
        tempo(32) := x"47";  -- R1 <- F9
        tempo(33) := x"F9";
        
        tempo(34) := x"41";  -- R1 <- R0 and R1
            
        tempo(35) := x"70";  -- R1 <- M[0036]
        tempo(36) := x"36";
        tempo(37) := x"00";

        tempo(38) := x"80";  -- JMP 002C (45)
        tempo(39) := x"2C";
        tempo(40) := x"00";
        
        tempo(41) := x"13";  -- Trampa
        tempo(42) := x"14";  -- Trampa
        tempo(43) := x"15";  -- Trampa

        tempo(44) := x"FF";  -- Fin

        -- Datos
        tempo(16#035#) := x"A4";
        tempo(16#036#) := x"B5";
        tempo(16#037#) := x"C6";
        
        return tempo;
    end function;

    signal contenido : banco := inicia_ram;
begin

    -- Escritura síncrona
    process(clk)
    begin
        if rising_edge(clk) then
            if inicia = '1' then
                contenido <= inicia_ram;
            elsif cs = '0' and we = '1' then
                -- Solo usa los 8 bits bajos de la dirección
                contenido(to_integer(unsigned(dir(7 downto 0)))) <= datos;
            end if;
        end if;
    end process;

    -- Lectura asíncrona para que el dato esté listo en el mismo ciclo (comportamiento de Logisim)
    datos <= contenido(to_integer(unsigned(dir(7 downto 0)))) when cs = '0' and oe = '0' else (others => 'Z');

end architecture;
