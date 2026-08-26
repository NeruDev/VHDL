-- biblioteca
library ieee;
use ieee.std_logic_1164.all;

-- entidad
entity demux1a4 is
    port (
         x: in std_logic;                     -- entrada
         s: in std_logic_vector(1 downto 0);  -- selector
         a, b, c, d: out std_logic             -- salidas
    );
end entity demux1a4;

-- arquitectura con ruta de datos
architecture una of demux1a4 is
begin
    a <= not s(1) and not s(0) and x;

    b <= not s(1) and s(0) and x;

    c <= s(1) and not s(0) and x; 

    d <= s(1) and s(0) and x;
end architecture una;

-- arquitectura con when-else
architecture dos of demux1a4 is
begin
    a <= x when s = "00" else
               '0';
       
    b <= x when s = "01" else
               '0';
       
    c <= x when s = "10" else
               '0';
       
    d <= x when s = "11" else
               '0';
end architecture dos;

-- arquitectura con with-select
architecture tres of demux1a4 is
begin
    with s select 
         a <= x when "00",
                   '0' when others;

    with s select 
         b <= x when "01",
                   '0' when others;
    
    with s select 
         c <= x when "10",
                   '0' when others;
    
    with s select 
         d <= x when "11",
                   '0' when others;
end architecture tres;

-- arquitectura con process y asignaciones simples
architecture cuatro of demux1a4 is
begin
    process (x, s) is
    begin
         a <= not s(1) and not s(0) and x;

         b <= not s(1) and s(0) and x;

         c <= s(1) and not s(0) and x; 

         d <= s(1) and s(0) and x;
    end process;
end architecture cuatro;

-- arquitectura con process y if-else
architecture cinco of demux1a4 is
begin
    process (x, s) is
    begin
         if s = "00" then
             a <= x;
             b <= '0';
             c <= '0';
             d <= '0';
         elsif  s = "01" then
             a <= '0';
             b <= x;
             c <= '0';
             d <= '0';
         elsif s = "10" then
             a <= '0';
             b <= '0';
             c <= x;
             d <= '0';
         elsif s = "11" then
             a <= '0';
             b <= '0';
             c <= '0';
             d <= x;
         else
             a <= '0';
             b <= '0';
             c <= '0';
             d <= '0';
         end if;
      end process;
end architecture cinco;

-- arquitectura con process y if-else y buenas practicas
architecture cincoa of demux1a4 is
begin
    process (x, s) is
    begin
         -- buenas practicas
         -- asignar el valor por omision
         a <= '0';
         b <= '0';
         c <= '0';
         d <= '0';

         -- asignar unicamente la que cambia
         if s = "00" then
             a <= x;
         elsif  s = "01" then
             b <= x;
         elsif s = "10" then
             c <= x;
         elsif s = "11" then
             d <= x;
         else
             null;
         end if;
      end process;
end architecture cincoa;

-- arquitectura con process y case
architecture seis of demux1a4 is
begin
    process (x, s) is
    begin
         case s is
         when "00" =>
             a <= x;
             b <= '0';
             c <= '0';
             d <= '0';
         when "01" =>
             a <= '0';
             b <= x;
             c <= '0';
             d <= '0';
         when "10" =>
             a <= '0';
             b <= '0';
             c <= x;
             d <= '0';
         when "11" =>
             a <= '0';
             b <= '0';
             c <= '0';
             d <= x;
         when others =>
             a <= '0';
             b <= '0';
             c <= '0';
             d <= '0';
         end case;
    end process;
end architecture seis;

-- arquitectura con process y case y buenas practicas
architecture seisa of demux1a4 is
begin
    process (x, s) is
    begin
         -- buenas practicas
         -- asignar el valor por omision
         a <= '0';
         b <= '0';
         c <= '0';
         d <= '0';

         -- asignar unicamente la que cambia
         case s is
         when "00" =>
             a <= x;
         when "01" =>
             b <= x;
         when "10" =>
             c <= x;
         when "11" =>
             d <= x;
         when others =>
             null;
         end case;
    end process;
end architecture seisa;

-- configuracion, seleccionar la arquitectura a utilizar 
configuration miconfi of demux1a4 is
    for seis
    end for;
end configuration miconfi;
