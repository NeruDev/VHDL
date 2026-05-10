library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package procesador_pkg is

  -- Constantes globales
  constant DATA_WIDTH : integer := 8;
  constant ADDR_WIDTH : integer := 16;
  constant REG_ADDR_WIDTH : integer := 3;

  -- Definición de componentes de la Ruta de Datos

  component pc is
    port (
      clk       : in  std_logic;
      clear     : in  std_logic;
      Lpc       : in  std_logic;
      Ipc       : in  std_logic;
      EntradaPC : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      salidaPC  : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
  end component;

  component registro_instruccion is
    port (
      clk         : in  std_logic;
      clear       : in  std_logic;
      Lri         : in  std_logic;
      BusDatos_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      CO          : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  component registro_hl is
    port (
      clk         : in  std_logic;
      clear       : in  std_logic;
      LH          : in  std_logic;
      LL          : in  std_logic;
      BusDatos_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      SalidaHL    : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
  end component;

  component banco_registros is
    port (
      clk      : in  std_logic;
      clear    : in  std_logic;
      wr       : in  std_logic;
      SelRegW  : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
      SelRegRA : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
      SelRegRB : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0);
      entDat   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      SalA     : out std_logic_vector(DATA_WIDTH-1 downto 0);
      SalB     : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  component alu is
    port (
      SalA      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      SalB      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      ope       : in  std_logic_vector(2 downto 0);
      SalidaALU : out std_logic_vector(DATA_WIDTH-1 downto 0);
      Z         : out std_logic;
      S         : out std_logic;
      C         : out std_logic
    );
  end component;
  
  component buffer_triestado is
    port (
        entrada  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        habilitar: in  std_logic;
        salida   : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  component registro_flags is
    port (
      clk       : in  std_logic;
      clear     : in  std_logic;
      Lf        : in  std_logic;
      Z_in      : in  std_logic;
      S_in      : in  std_logic;
      C_in      : in  std_logic;
      Flags_out : out std_logic_vector(7 downto 0)
    );
  end component;

  component mux_direcciones is
    port (
      SelDir   : in  std_logic;
      salidaPC : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      SalidaHL : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      dir      : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
  end component;

  component ruta_datos is
    port (
      clk         : in    std_logic;
      clear       : in    std_logic;
      -- Señales de control
      Lpc         : in    std_logic;
      Ipc         : in    std_logic;
      SelDir      : in    std_logic;
      LH          : in    std_logic;
      LL          : in    std_logic;
      Lri         : in    std_logic;
      SelRegW     : in    std_logic_vector(2 downto 0);
      SelRegRA    : in    std_logic_vector(2 downto 0);
      SelRegRB    : in    std_logic_vector(2 downto 0);
      wr          : in    std_logic;
      ope         : in    std_logic_vector(2 downto 0);
      SalAlu      : in    std_logic;
      LF_ctrl     : in    std_logic;
      -- Interfaces al exterior
      BusDatos    : inout std_logic_vector(DATA_WIDTH-1 downto 0);
      dir         : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
      CO          : out   std_logic_vector(DATA_WIDTH-1 downto 0);
      Flags       : out   std_logic_vector(7 downto 0)
    );
  end component;

  component memoria_ram is
    port (
      clk    : in    std_logic;
      we     : in    std_logic;
      cs     : in    std_logic;
      oe     : in    std_logic;
      inicia : in    std_logic;
      dir    : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      datos  : inout std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  component unidad_control is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;
      Flags    : in  std_logic_vector(7 downto 0);
      CO       : in  std_logic_vector(7 downto 0);
      clear    : out std_logic;
      Lpc      : out std_logic;
      Ipc      : out std_logic;
      SelDir   : out std_logic;
      inicia   : out std_logic;
      cs       : out std_logic;
      oe       : out std_logic;
      we       : out std_logic;
      LH       : out std_logic;
      LL       : out std_logic;
      Lri      : out std_logic;
      SelRegW  : out std_logic_vector(2 downto 0);
      SelRegRA : out std_logic_vector(2 downto 0);
      SelRegRB : out std_logic_vector(2 downto 0);
      wr       : out std_logic;
      ope      : out std_logic_vector(2 downto 0);
      SalAlu   : out std_logic;
      LF       : out std_logic;
      fin      : out std_logic
    );
  end component;

end package procesador_pkg;
