-- biblioteca
library ieee;
use ieee.std_logic_1164.all;

-- entidad
entity mux4a1 is
    port (
         a, b, c, d: in std_logic;   -- entradas
         s: in std_logic_vector(1 downto 0);  -- selector
         x: out std_logic      -- salida
    );
end entity mux4a1;

-- arquitectura con ruta de datos
architecture una of mux4a1 is
begin
    x <= (not s(1) and not s(0) and a) or
               (not s(1) and s(0) and b) or
               (s(1) and not s(0) and c) or 
               (s(1) and s(0) and d);
end architecture una;

-- arquitectura con when-else
architecture dos of mux4a1 is
begin
    x <= a when s = "00" else
               b when s = "01" else
               c when s = "10" else
               d when s = "11" else
               '0';
end architecture dos;

-- arquitectura con with-select
architecture tres of mux4a1 is
begin
    with s select 
         x <= a when "00",
                   b when "01",
                   c when "10",
                   d when "11",
                   '0' when others;
end architecture tres;

-- arquitectura con process y asignacion simple
architecture cuatro of mux4a1 is
begin
    -- entre parentesis lleva la lista sensible (las señales que cambian)
    process (a, b, c, d, s) is
    begin
      x <= (not s(1) and not s(0) and a) or
                  (not s(1) and s(0) and b) or
                  (s(1) and not s(0) and c) or 
                  (s(1) and s(0) and d);
    end process;
end architecture cuatro;

-- arquitectura con process y if-else
architecture cinco of mux4a1 is
begin
    process (a, b, c, d, s) is
    begin
         if s = "00" then
             x <= a;
         elsif s = "01" then
             x <= b;
         elsif s = "10" then
             x <= c;
         elsif s = "11" then
             x <= d;
         else
             x <= '0';
         end if;
    end process;
end architecture cinco;

-- arquitectura con process y case
architecture seis of mux4a1 is
begin
    process (a, b, c, d, s) is
    begin
         case s is
             when "00" =>
                  x <= a;
             when "01" =>
                  x <= b;
             when "10" =>
                  x <= c;
             when "11" =>
                  x <= d;
             when others =>
                  x <= '0';
             end case;
         end process;
end architecture seis;

-- configuracion, seleccionar la arquitectura a utilizar 
configuration miconfi of mux4a1 is
    for seis
    end for;
end configuration miconfi;
