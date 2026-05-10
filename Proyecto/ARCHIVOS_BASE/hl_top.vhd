library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hl_top is
  port (
    clk: in std_logic;
    clear: in std_logic;
    LH: in std_logic;
    LL: in std_logic;
    BusDatos: in std_logic_vector (7 downto 0);    
    salidaHL: out std_logic_vector (15 downto 0)
  );
end entity hl_top;

architecture una of hl_top is
  signal H_reg, H_sig: std_logic_vector (7 downto 0);
  signal L_reg, L_sig: std_logic_vector (7 downto 0);
begin
  -- Actualizar registros con clk, reset
  process(clk, clear)
  begin
    if (clear = '1') then
      H_reg <= (others => '0');
      L_reg <= (others => '0');
    elsif (clk'event and clk='1') then
      H_reg <= H_sig;
      L_reg <= L_sig;
    end if;
  end process;

  -- Asignaciones a ***_sig
  process (LH, LL, H_reg, L_reg, BusDatos) is
  begin
    -- buenas practicas
    H_sig <= H_reg;
    L_sig <= L_reg;
    if (LH = '1') then
      H_sig <= BusDatos;
    end if;
    if (LL = '1') then
      L_sig <= BusDatos;
    end if;
  end process;
  
  -- Salidas
  process (H_reg, L_reg) is
  begin
    salidaHL <= H_reg & L_reg;
  end process;
end architecture una;
