--------------------------------------------------------------------------------
-- Paquete: procesador_pkg
-- Descripción: Definición de constantes globales y componentes necesarios para 
--              la construcción del procesador de 8 bits.
-- Referencias: Proyecto/ARCHIVOS_BASE/MICRO_INSTRUCCIONES.md
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

package procesador_pkg is

  ------------------------------------------------------------------------------
  -- Constantes globales de arquitectura
  ------------------------------------------------------------------------------
  constant DATA_WIDTH : integer := 8;    -- Ancho del bus de datos (8 bits)
  constant ADDR_WIDTH : integer := 16;   -- Ancho del bus de direcciones (16 bits)
  constant REG_ADDR_WIDTH : integer := 3;-- Bits para direccionar 8 registros

  ------------------------------------------------------------------------------
  -- OpCodes ISA (instrucciones de alto nivel)
  ------------------------------------------------------------------------------
  constant OP_XOR : std_logic_vector(7 downto 0) := x"30"; -- XOR R1 <- R0 xor R1
  constant OP_NOT : std_logic_vector(7 downto 0) := x"40"; -- NOT R1 (ya existente)

  ------------------------------------------------------------------------------
  -- Definición de componentes de la Ruta de Datos (Datapath)
  ------------------------------------------------------------------------------

  -- Contador de Programa (PC): Almacena la dirección de la próxima instrucción.
  component pc is
    port (
      clk       : in  std_logic;
      clear     : in  std_logic;                        -- Reset sincrónico
      Lpc       : in  std_logic;                        -- Load PC (Carga desde bus/HL)
      Ipc       : in  std_logic;                        -- Increment PC (PC <- PC + 1)
      EntradaPC : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      salidaPC  : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
  end component;

  -- Registro de Instrucción (RI): Captura el OpCode desde la memoria.
  component registro_instruccion is
    port (
      clk         : in  std_logic;
      clear       : in  std_logic;
      Lri         : in  std_logic;                        -- Load RI
      BusDatos_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      CO          : out std_logic_vector(DATA_WIDTH-1 downto 0) -- Código de Operación
    );
  end component;

  -- Registro HL: Par de registros (8+8 bits) para direccionamiento de 16 bits.
  component registro_hl is
    port (
      clk         : in  std_logic;
      clear       : in  std_logic;
      LH          : in  std_logic;                        -- Load High byte (H)
      LL          : in  std_logic;                        -- Load Low byte (L)
      BusDatos_in : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      SalidaHL    : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
  end component;

  -- Banco de Registros: Almacena operandos (R0 a R7).
  component banco_registros is
    port (
      clk      : in  std_logic;
      clear    : in  std_logic;
      wr       : in  std_logic;                        -- Write Enable
      SelRegW  : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0); -- Selección destino
      SelRegRA : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0); -- Selección operando A
      SelRegRB : in  std_logic_vector(REG_ADDR_WIDTH-1 downto 0); -- Selección operando B
      entDat   : in  std_logic_vector(DATA_WIDTH-1 downto 0);     -- Dato a escribir
      SalA     : out std_logic_vector(DATA_WIDTH-1 downto 0);     -- Bus A hacia ALU
      SalB     : out std_logic_vector(DATA_WIDTH-1 downto 0)      -- Bus B hacia ALU
    );
  end component;

  -- Unidad Lógico Aritmética (ALU): Realiza operaciones matemáticas y lógicas.
  component alu is
    port (
      SalA      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      SalB      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      ope       : in  std_logic_vector(2 downto 0);    -- Código de operación ALU
      SalidaALU : out std_logic_vector(DATA_WIDTH-1 downto 0);
      Z         : out std_logic;                        -- Zero Flag
      S         : out std_logic;                        -- Sign Flag
      C         : out std_logic                         -- Carry Flag
    );
  end component;
  
  -- Buffer Triestado: Controla el flujo de datos hacia el bus compartido.
  component buffer_triestado is
    port (
        entrada  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        habilitar: in  std_logic;                       -- SalAlu en ruta_datos
        salida   : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  -- Registro de Flags: Almacena el estado de las banderas después de una op. ALU.
  component registro_flags is
    port (
      clk       : in  std_logic;
      clear     : in  std_logic;
      Lf        : in  std_logic;                        -- Load Flags
      Z_in      : in  std_logic;
      S_in      : in  std_logic;
      C_in      : in  std_logic;
      Flags_out : out std_logic_vector(7 downto 0)      -- Vector de banderas (Z, S, C...)
    );
  end component;

  -- Mux Direcciones: Selecciona entre PC o HL para el bus de direcciones de memoria.
  component mux_direcciones is
    port (
      SelDir   : in  std_logic;                        -- 0: PC, 1: HL
      salidaPC : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      SalidaHL : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
      dir      : out std_logic_vector(ADDR_WIDTH-1 downto 0)
    );
  end component;

  ------------------------------------------------------------------------------
  -- Unidades de Jerarquía Media
  ------------------------------------------------------------------------------

  -- Ruta de Datos: Encapsula todos los componentes anteriores.
  component ruta_datos is
    port (
      clk         : in    std_logic;
      clear       : in    std_logic;
      -- Señales de control (provenientes de la Unidad de Control)
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
      -- Interfaces externas
      BusDatos    : inout std_logic_vector(DATA_WIDTH-1 downto 0);
      dir         : out   std_logic_vector(ADDR_WIDTH-1 downto 0);
      CO          : out   std_logic_vector(DATA_WIDTH-1 downto 0);
      Flags       : out   std_logic_vector(7 downto 0)
    );
  end component;

  -- Memoria RAM: Almacenamiento de instrucciones y datos.
  component memoria_ram is
    port (
      clk    : in    std_logic;
      we     : in    std_logic;                        -- Write Enable (M(dir) <- Bus)
      cs     : in    std_logic;                        -- Chip Select
      oe     : in    std_logic;                        -- Output Enable (Bus <- M(dir))
      inicia : in    std_logic;                        -- Inicialización de memoria
      dir    : in    std_logic_vector(ADDR_WIDTH-1 downto 0);
      datos  : inout std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  -- Unidad de Control: FSM que orquesta el funcionamiento del procesador.
  component unidad_control is
    port (
      clk      : in  std_logic;
      rst      : in  std_logic;                        -- Reset externo
      Flags    : in  std_logic_vector(7 downto 0);      -- Banderas de la ALU
      CO       : in  std_logic_vector(7 downto 0);      -- OpCode del RI
      clear    : out std_logic;                        -- Reset interno
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
      fin      : out std_logic                         -- Señal de término (HALT)
    );
  end component;

end package procesador_pkg;
