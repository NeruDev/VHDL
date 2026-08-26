library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control is
  port (
    clk: in std_logic;
    rst: in std_logic;
    Flags: in std_logic_vector (7 downto 0);
    CO: in std_logic_vector (7 downto 0);
    clear: out std_logic;
    Lpc, Ipc, SelDir: out std_logic;
    inicia, cs, oe, we: out std_logic;
    LH, LL, Lri: out std_logic;
    SelRegW, SelRegRA, SelRegRB: out std_logic_vector (2 downto 0);
    wr: out std_logic;
    ope: out std_logic_vector (2 downto 0);
    SalAlu, LF: out std_logic;
    fin: out std_logic;
    idEstado: out std_logic_vector (4 downto 0)
  );
end entity control;

architecture una of control is
begin
end architecture una;

