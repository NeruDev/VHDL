--------------------------------------------------------------------------------
-- Entidad: ruta_datos (Datapath)
-- Arquitectura: estructural
-- Descripción: Encapsula todos los componentes de ejecución física (ALU, 
--              Registros, PC, etc.) e interconecta sus señales internas.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity ruta_datos is
    port (
        clk         : in    std_logic;
        clear       : in    std_logic;                        -- Reset sincrónico global
        -- SEÑALES DE CONTROL (Desde Unidad de Control)
        Lpc         : in    std_logic;                        -- Load PC
        Ipc         : in    std_logic;                        -- Increment PC
        SelDir      : in    std_logic;                        -- Mux Dir (0:PC, 1:HL)
        LH          : in    std_logic;                        -- Load H
        LL          : in    std_logic;                        -- Load L
        Lri         : in    std_logic;                        -- Load RI
        SelRegW     : in    std_logic_vector(2 downto 0);     -- Registro destino
        SelRegRA    : in    std_logic_vector(2 downto 0);     -- Registro operando A
        SelRegRB    : in    std_logic_vector(2 downto 0);     -- Registro operando B
        wr          : in    std_logic;                        -- Write banco registros
        ope         : in    std_logic_vector(2 downto 0);     -- Operación ALU
        SalAlu      : in    std_logic;                        -- Habilita salida ALU al bus
        LF_ctrl     : in    std_logic;                        -- Load Flags
        -- INTERFACES EXTERNAS
        BusDatos    : inout std_logic_vector(DATA_WIDTH-1 downto 0); -- Bus bidireccional
        dir         : out   std_logic_vector(ADDR_WIDTH-1 downto 0);  -- Bus direcciones RAM
        CO          : out   std_logic_vector(DATA_WIDTH-1 downto 0);  -- OpCode para la UC
        Flags       : out   std_logic_vector(7 downto 0)              -- Banderas para la UC
    );
end entity;

architecture estructural of ruta_datos is

    ----------------------------------------------------------------------------
    -- SEÑALES INTERNAS DE INTERCONEXIÓN
    ----------------------------------------------------------------------------
    signal w_SalidaHL  : std_logic_vector(ADDR_WIDTH-1 downto 0); -- Dirección desde HL
    signal w_salidaPC  : std_logic_vector(ADDR_WIDTH-1 downto 0); -- Dirección desde PC
    signal w_SalA      : std_logic_vector(DATA_WIDTH-1 downto 0); -- Operando A hacia ALU
    signal w_SalB      : std_logic_vector(DATA_WIDTH-1 downto 0); -- Operando B hacia ALU
    signal w_SalidaALU : std_logic_vector(DATA_WIDTH-1 downto 0); -- Resultado ALU
    
    signal w_Z, w_S, w_C : std_logic; -- Banderas temporales desde ALU

begin

    ----------------------------------------------------------------------------
    -- INSTANCIACIÓN DE COMPONENTES
    ----------------------------------------------------------------------------

    -- Contador de Programa: Gestiona la secuencia de ejecución
    inst_pc: pc port map (
        clk       => clk,
        clear     => clear,
        Lpc       => Lpc,
        Ipc       => Ipc,
        EntradaPC => w_SalidaHL, -- En saltos, el PC carga el valor de HL
        salidaPC  => w_salidaPC
    );

    -- Registro de Instrucción: Almacena el código de operación actual
    inst_ri: registro_instruccion port map (
        clk         => clk,
        clear       => clear,
        Lri         => Lri,
        BusDatos_in => BusDatos,
        CO          => CO
    );

    -- Registro HL: Actúa como puntero de memoria de 16 bits
    inst_hl: registro_hl port map (
        clk         => clk,
        clear       => clear,
        LH          => LH,
        LL          => LL,
        BusDatos_in => BusDatos,
        SalidaHL    => w_SalidaHL
    );

    -- Banco de Registros: Almacenamiento local de operandos y resultados
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

    -- ALU: Realiza el procesamiento de datos
    inst_alu: alu port map (
        SalA      => w_SalA,
        SalB      => w_SalB,
        ope       => ope,
        SalidaALU => w_SalidaALU,
        Z         => w_Z,
        S         => w_S,
        C         => w_C
    );

    -- Buffer Tri-estado: Controla cuándo la ALU escribe en el bus compartido
    inst_buffer_alu: buffer_triestado port map (
        entrada   => w_SalidaALU,
        habilitar => SalAlu,
        salida    => BusDatos
    );

    -- Registro de Flags: Persiste el estado de la última operación ALU
    inst_flags: registro_flags port map (
        clk       => clk,
        clear     => clear,
        Lf        => LF_ctrl,
        Z_in      => w_Z,
        S_in      => w_S,
        C_in      => w_C,
        Flags_out => Flags
    );

    -- Multiplexor de Direcciones: Selecciona la fuente para el direccionamiento RAM
    inst_mux_dir: mux_direcciones port map (
        SelDir   => SelDir,
        salidaPC => w_salidaPC,
        SalidaHL => w_SalidaHL,
        dir      => dir
    );

end architecture;
