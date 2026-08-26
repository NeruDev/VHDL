-- decodificador de hexadecimal a 7 segmentos

---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
entity hexa2hola is
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
  
end entity hexa2hola;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
architecture una of hexa2hola is
  -- señales
begin
  process (d3, d2, d1, d0) is
    -- variables
    variable seg7: std_logic_vector ( 6 downto 0);
    variable entrada: std_logic_vector (3 downto 0);
  begin
    entrada := d3 & d2 & d1 & d0;
    case entrada is
      when "0000" =>
        seg7 := "1001000"; -- H
      when "0001" =>
        seg7 := "0000001"; -- O
      when "0010" =>
        seg7 := "1110001"; -- L
      when "0011" =>
        seg7 := "0001000"; -- A
      when "0100" =>
        seg7 := "1111111"; -- (ESPACIO VACIO)
      when "0101" =>
        seg7 := "1110001"; -- L
      when "0110" =>
        seg7 := "0000001"; -- O
      when "0111" =>
        seg7 := "1110001"; -- L
      when "1000" =>
        seg7 := "0001000"; -- A
      when "1001" =>
        seg7 := "0111101"; -- (ESQUINA SUPERIOR IZQUIERDA) 
      when "1010" =>
        seg7 := "1110011"; -- (ESQUINA INFERIOR IZQUIERDA)
      when "1011" =>
        seg7 := "1100111"; -- (ESQUINA INFERIOR DERECHA)
      when "1100" =>
        seg7 := "0011111";  -- (ESQUINA SUPERIOR DERECHA)
      when "1101" =>
        seg7 := "0111111";  -- (SEGMENTO ARRIBA)
      when "1110" =>
        seg7 := "1110111";  -- (SEGMENTO ABAJO)
      when "1111" =>
        seg7 := "1111110";  -- (SEGMENTO CENTRAL)
      when others =>
        seg7 := "1111111";
    end case;

    a <= seg7(6);
    b <= seg7(5);
    c <= seg7(4);
    d <= seg7(3);
    e <= seg7(2);
    f <= seg7(1);
    g <= seg7(0);
  end process;
end architecture una;