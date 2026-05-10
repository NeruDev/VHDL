library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ri_top is
  port (
    clk: in std_logic;
    clear: in std_logic;
    Lri: in std_logic;
    BusDatos: in std_logic_vector (7 downto 0);    
    CO: out std_logic_vector (7 downto 0)
  );
end entity ri_top;

architecture una of ri_top is
  signal RI_reg, RI_sig: std_logic_vector (7 downto 0);
begin
  -- Actualizar registros con clk, reset
  process(clk, clear)
  begin
    if (clear = '1') then
      RI_reg <= (others => '0');
    elsif (clk'event and clk='1') then
      RI_reg <= RI_sig;
    end if;
  end process;

  -- Asignaciones a ***_sig
  process (Lri, RI_reg, BusDatos) is
  begin
    -- buenas practicas
    RI_sig <= RI_reg;
    if (Lri = '1') then
      RI_sig <= BusDatos;
    end if;
  end process;
  
  -- Salidas
  process (RI_reg) is
  begin
    CO <= RI_reg;
  end process;
end architecture una;
