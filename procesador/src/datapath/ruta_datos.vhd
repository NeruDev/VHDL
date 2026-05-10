library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity ruta_datos is
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
end entity;

architecture estructural of ruta_datos is

    -- Señales internas de interconexión
    signal w_SalidaHL  : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal w_salidaPC  : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal w_SalA      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal w_SalB      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal w_SalidaALU : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    signal w_Z, w_S, w_C : std_logic;

begin

    -- Instancia del Contador de Programa
    inst_pc: pc port map (
        clk       => clk,
        clear     => clear,
        Lpc       => Lpc,
        Ipc       => Ipc,
        EntradaPC => w_SalidaHL,
        salidaPC  => w_salidaPC
    );

    -- Instancia del Registro de Instrucción
    inst_ri: registro_instruccion port map (
        clk         => clk,
        clear       => clear,
        Lri         => Lri,
        BusDatos_in => BusDatos,
        CO          => CO
    );

    -- Instancia del Registro HL
    inst_hl: registro_hl port map (
        clk         => clk,
        clear       => clear,
        LH          => LH,
        LL          => LL,
        BusDatos_in => BusDatos,
        SalidaHL    => w_SalidaHL
    );

    -- Instancia del Banco de Registros
    inst_br: banco_registros port map (
        clk      => clk,
        clear    => clear,
        wr       => wr,
        SelRegW  => SelRegW,
        SelRegRA => SelRegRA,
        SelRegRB => SelRegRB,
        entDat   => BusDatos,
        SalA     => w_SalA,
        SalB     => w_SalB
    );

    -- Instancia de la ALU
    inst_alu: alu port map (
        SalA      => w_SalA,
        SalB      => w_SalB,
        ope       => ope,
        SalidaALU => w_SalidaALU,
        Z         => w_Z,
        S         => w_S,
        C         => w_C
    );

    -- Instancia del Buffer Tri-estado para la salida de la ALU
    inst_buffer_alu: buffer_triestado port map (
        entrada   => w_SalidaALU,
        habilitar => SalAlu,
        salida    => BusDatos
    );

    -- Instancia del Registro de Flags
    inst_flags: registro_flags port map (
        clk       => clk,
        clear     => clear,
        Lf        => LF_ctrl,
        Z_in      => w_Z,
        S_in      => w_S,
        C_in      => w_C,
        Flags_out => Flags
    );

    -- Instancia del Multiplexor de Direcciones
    inst_mux_dir: mux_direcciones port map (
        SelDir   => SelDir,
        salidaPC => w_salidaPC,
        SalidaHL => w_SalidaHL,
        dir      => dir
    );

end architecture;
