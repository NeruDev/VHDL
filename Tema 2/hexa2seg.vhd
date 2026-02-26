-- decodificador de hexadecimal a 7 segmentos

-- bibliotecas
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- entidad
entity hexa2seg is
  port (
    d3, d2, d1, d0: in std_logic;  -- entradas binarias
    a, b, c, d, e, f, g: out std_logic -- salidas al display
  );
  
  attribute chip_pin: string;
  attribute chip_pin of d3: signal is "L2"; -- sw9
  attribute chip_pin of d2: signal is "M1"; -- sw8
  attribute chip_pin of d1: signal is "M2"; -- sw7
  attribute chip_pin of d0: signal is "U11"; -- sw6
  attribute chip_pin of a: signal is "F4";  -- a del 3
  attribute chip_pin of b: signal is "D5"; -- b del 3
  attribute chip_pin of c: signal is "D6"; -- c del 3
  attribute chip_pin of d: signal is "J4"; -- d del 3
  attribute chip_pin of e: signal is "L8"; -- e del 3
  attribute chip_pin of f: signal is "F3"; -- f del 3
  attribute chip_pin of g: signal is "D4"; -- g del 3
  
end entity hexa2seg;

-- arquitectura
architecture una of hexa2seg is
  -- seÃ±ales
begin
  process (d3, d2, d1, d0) is
    -- variables
    variable seg7: std_logic_vector ( 6 downto 0);
    variable entrada: std_logic_vector (3 downto 0);
  begin
    entrada := d3 & d2 & d1 & d0;
    case entrada is
      when "0000" =>
        seg7 := "0000001"; -- cero
      when "0001" =>
        seg7 := "1001111"; -- uno
      when "0010" =>
        seg7 := "0010010"; -- dos
      when "0011" =>
        seg7 := "0000110"; -- tres
      when "0100" =>
        seg7 := "1001100"; -- cuatro
      when "0101" =>
        seg7 := "0100100"; -- cinco
      when "0110" =>
        seg7 := "0000001"; -- seis
      when "0111" =>
        seg7 := "0001111"; -- siete
      when "1000" =>
        seg7 := "0000000"; -- ocho
      when "1001" =>
        seg7 := "0000100"; -- nueve
      when "1010" =>
        seg7 := "0001000"; -- diez a
      when "1011" =>
        seg7 := "1100000"; -- once b
      when "1100" =>
        seg7 := "0110000";  -- doce c
      when "1101" =>
        seg7 := "1000010";  -- trece d
      when "1110" =>
        seg7 := "0110000";  -- catorce e
      when "1111" =>
        seg7 := "0111000";  -- quince f
      when others =>
        seg7 := "1111111";
    end case;
--    (a, b, c, d, e, f, g) <= seg7; -- agregado de 7 elementos
--    a <= seg(6);
--    b <= seg(5);
--    c <= seg(4);
  end process;
end architecture una;