library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bufferalu_top is
  port (
    salidaAlu: in std_logic_vector (7 downto 0);
    SalAlu: in std_logic;
    BusDatos: out std_logic_vector (7 downto 0)
  );
end entity bufferalu_top;

architecture una of bufferalu_top is
begin
  -- Salidas
  process (SalAlu, salidaALU) is
  begin
    if SalAlu = '1' then
      BusDatos <= salidaALU;
    else
      BusDatos <= (others => 'Z');
    end if;
  end process;
end architecture una;
