library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memoria is
  generic (
    N: integer := 8;
    n_dir: integer := 8
  );
  port (
    clk: in std_logic;
    we: in std_logic;
    cs: in std_logic;
    oe: in std_logic;
    inicia: in std_logic;
--    dir: in std_logic_vector (n_dir -1 downto 0);
--    datos : inout std_logic_vector (N - 1 downto 0)
    dir: in std_logic_vector (7 downto 0);
    datos : inout std_logic_vector (7 downto 0)
  );
end entity memoria;

architecture Comportamiento of memoria is
  subtype registro is std_logic_vector (N - 1 downto 0);
  type banco is array (0 to (2 ** n_dir) - 1) of registro;
  
  function inicia_ram return banco is 
    variable tempo : banco := (others => (others => '0'));
  begin 
    for addr in 0 to 2 ** n_dir - 1 loop 
      -- Inicializa cada celda con el valor de su direccion
      tempo(addr) := std_logic_vector(to_unsigned(addr, N));
    end loop;
    -- Cambia las celdas donde esta el programa
    tempo(0) := x"70";  -- R1 <- M[0035]
    tempo(1) := x"35";
    tempo(2) := x"00";

    tempo(3) := x"46";  -- R0 <- R1

    tempo(4) := x"70";  -- R1 <- M[0036]
    tempo(5) := x"36";
    tempo(6) := x"00";

    tempo(7) := x"45";  -- R1 <- R0 + R1

    tempo(8) := x"71";  -- M[0037] <- R1
    tempo(9) := x"37";
    tempo(10) := x"00";
    
    tempo(11) := x"70";  -- R1 <- M[0037]
    tempo(12) := x"37";
    tempo(13) := x"00";
    
    tempo(14) := x"90";  -- No Existe   

    tempo(15) := x"FF";  -- Fin

    tempo(16#035#) := x"A4";
    tempo(16#036#) := x"B5";
    tempo(16#037#) := x"C6";
    
    return tempo;
  end inicia_ram;

  function inicia_ram2 return banco is 
    variable tempo : banco := (others => (others => '0'));
  begin 
    for addr in 0 to 2 ** n_dir - 1 loop 
      -- Inicializa cada celda con el valor de su direccion
      tempo(addr) := std_logic_vector(to_unsigned(addr, N));
    end loop;
    -- Cambia las celdas donde esta el programa
    tempo(0) := x"70";  -- R1 <- M[0035]
    tempo(1) := x"35";
    tempo(2) := x"00";

    tempo(3) := x"46";  -- R0 <- R1

    tempo(4) := x"47";  -- R1 <- 5E
    tempo(5) := x"5E";  
  
    tempo(6) := x"45";  -- R1 <- R0 + R1
    
    tempo(7) := x"71";  -- M[0036] <- R1
    tempo(8) := x"36";
    tempo(9) := x"00";

    tempo(10) := x"82";  -- JC 000F (15)
    tempo(11) := x"0F";
    tempo(12) := x"00";
    
    tempo(13) := x"10";
    tempo(14) := x"20";

    tempo(15) := x"42";  -- R1 <- R1 - 1

    tempo(16) := x"81";  -- JZ 002C (44)
    tempo(17) := x"2C";
    tempo(18) := x"00";
    
    tempo(19) := x"42";  -- R1 <- R1 - 1

    tempo(20) := x"81";  -- JZ 002C (25)
    tempo(21) := x"19";
    tempo(22) := x"00";
    
    tempo(23) := x"11";
    tempo(24) := x"21";
    
    tempo(25) := x"43";  -- R1 <- R1 + 1

    tempo(26) := x"40";  -- R1 <- not R1
    
    tempo(27) := x"83";  -- JS 0020 (32)
    tempo(28) := x"20";
    tempo(29) := x"00";
    
    tempo(30) := x"12";
    tempo(31) := x"22";
    
    tempo(32) := x"47";  -- R1 <- F9
    tempo(33) := x"F9";
    
    tempo(34) := x"41";  -- R1 <- R0 and R1
        
    tempo(35) := x"70";  -- R1 <- M[0036]
    tempo(36) := x"36";
    tempo(37) := x"00";

    tempo(38) := x"80";  -- JMP 002C (45)
    tempo(39) := x"2C";
    tempo(40) := x"00";
    
    tempo(41) := x"13";
    tempo(42) := x"14";
    tempo(43) := x"15";

    tempo(44) := x"FF";  -- Fin

    tempo(16#035#) := x"A4";
    tempo(16#036#) := x"B5";
    tempo(16#037#) := x"C6";
    
    return tempo;
  end inicia_ram2;

  function inicia_ram3 return banco is 
    variable tempo : banco := (others => (others => '0'));
  begin 
    for addr in 0 to 2 ** n_dir - 1 loop 
      -- Inicializa cada celda con el valor de su direccion
      tempo(addr) := std_logic_vector(to_unsigned(addr, N));
    end loop;
    -- Cambia las celdas donde esta el programa
    tempo(0) := x"47";  -- R1 <- 39
    tempo(1) := x"39";
    tempo(2) := x"46";  -- R0 <- R1
    tempo(3) := x"47";  -- R1 <- F3
    tempo(4) := x"F3";
    tempo(5) := x"45";  -- R1 <- R0 + R1
    tempo(6) := x"FF";  -- Fin

    return tempo;
  end inicia_ram3;

  function inicia_ram4 return banco is 
    variable tempo : banco := (others => (others => '0'));
  begin 
    for addr in 0 to 2 ** n_dir - 1 loop 
      -- Inicializa cada celda con el valor de su direccion
      tempo(addr) := std_logic_vector(to_unsigned(addr, N));
    end loop;
    -- Cambia las celdas donde esta el programa
    tempo(0) := x"47";  -- R1 <- 39
    tempo(1) := x"F3";
    tempo(2) := x"71";  -- M[0035] <- R1
    tempo(3) := x"35";  
    tempo(4) := x"00";
    tempo(5) := x"46";  -- R0 <- R1
    tempo(6) := x"47";  -- R1 <- F3
    tempo(7) := x"39";
    tempo(8) := x"71";  -- M[0036] <- R1
    tempo(9) := x"36";
    tempo(10) := x"00";
    tempo(11) := x"44";  -- R1 <- R0 - R1
    tempo(12) := x"82";  -- JC 0013 (19)
    tempo(13) := x"13";
    tempo(14) := x"00";
    tempo(15) := x"70";  -- R1 <- M[0035]
    tempo(16) := x"35";
    tempo(17) := x"00";
    tempo(18) := x"FF";  -- Fin
    tempo(19) := x"70";  -- R1 <- M[0036]
    tempo(20) := x"36";
    tempo(21) := x"00";
    tempo(22) := x"FF";  -- Fin

    return tempo;
  end inicia_ram4;

  function inicia_ram5 return banco is 
    variable tempo : banco := (others => (others => '0'));
  begin 
    for addr in 0 to 2 ** n_dir - 1 loop 
      -- Inicializa cada celda con el valor de su direccion
      tempo(addr) := std_logic_vector(to_unsigned(addr, N));
    end loop;
    -- Cambia las celdas donde esta el programa
    tempo(0) := x"70";  -- R1 <- M[0035]
    tempo(1) := x"35";
    tempo(2) := x"00";

    tempo(3) := x"46";  -- R0 <- R1

    tempo(4) := x"70";  -- R1 <- M[0036]
    tempo(5) := x"36";
    tempo(6) := x"00";

    tempo(7) := x"44";  -- R1 <- R0 - R1

    tempo(8) := x"81";  -- JZ 0011
    tempo(9) := x"11";
    tempo(10) := x"00";

    tempo(11) := x"47";  -- R1 <- 02
    tempo(12) := x"02";
    
    tempo(13) := x"71";  -- M[0037] <- R1
    tempo(14) := x"37";
    tempo(15) := x"00";

    tempo(16) := x"FF";  -- FIN
    
    tempo(17) := x"47";  -- R1 <- 01
    tempo(18) := x"01";
    
    tempo(19) := x"71";  -- M[0037] <- R1
    tempo(20) := x"37";
    tempo(21) := x"00";

    tempo(22) := x"FF";  -- FIN

    tempo(16#035#) := x"A4";
    tempo(16#036#) := x"A4";
    tempo(16#037#) := x"C6";
    
    return tempo;
  end inicia_ram5;

	function inicia_ram6 return banco is 
		variable tempo : banco := (others => (others => '0'));
	begin 
		for addr in 0 to 2 ** n_dir - 1 loop 
			-- Inicializa cada celda con el valor de su direccion
			tempo(addr) := std_logic_vector(to_unsigned(addr, N));
		end loop;
		-- Cambia las celdas donde esta el programa
		tempo(0) := x"70";	-- R1 <- M[1234]
		tempo(1) := x"34";
		tempo(2) := x"12";

		tempo(3) := x"71";	-- M[5678] <- R1
		tempo(4) := x"78";	
		tempo(5) := x"56";

		tempo(6) := x"45";  -- R1 <- R0 + R1
        
		tempo(7) := x"46";	-- R0 <- R1

		tempo(8) := x"47";	-- R1 <- 9A
		tempo(9) := x"9A";
        
		tempo(10) := x"80"; -- GOTO 0003
		tempo(11) := x"03";
		tempo(12) := x"00";
		
		tempo(13) := x"FF";	-- FIN (no se ejecuta por el salto previo)
        
		tempo(34) := x"86"; -- dato 
        
		tempo(78) := x"86"; -- dato

		
		return tempo;
	end inicia_ram6;
  
  signal contenido: banco; -- := inicia_ram;
  signal midir: std_logic_vector (dir'range);
  signal midatos: std_logic_vector (datos'range);
begin
  escritura: process (inicia, clk, cs, we, dir, datos)
    begin
    if inicia = '1' then
      -- null;
      contenido <= inicia_ram6;
    elsif (clk'event and clk = '1') then
      if (cs = '0' and we = '1') then
        contenido (to_integer (unsigned (dir))) <= datos;
      end if;
    end if;
    -- debiera ser sincrono
    midir <= dir;
  end process;

  lectura: process (oe, cs, contenido, midir) is
  begin
    if (cs = '0' and oe = '0') then
      datos <= contenido (to_integer (unsigned (midir)));
    else
      datos <= (others => 'Z');
    end if;    
  end process;
end architecture comportamiento;

