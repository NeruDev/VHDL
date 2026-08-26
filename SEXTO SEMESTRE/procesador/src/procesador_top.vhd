--------------------------------------------------------------------------------
-- Entidad: procesador_top
-- Arquitectura: estructural
-- Descripción: Módulo de nivel superior que interconecta la Unidad de Control, 
--              la Ruta de Datos y la Memoria RAM para formar el procesador completo.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity procesador_top is
    port (
        clk : in  std_logic;    -- Reloj global del sistema
        rst : in  std_logic;    -- Reset externo (activo en alto)
        fin : out std_logic     -- Bandera de finalización de programa (HALT)
    );
end entity;

architecture estructural of procesador_top is

    ----------------------------------------------------------------------------
    -- Señales de Control Internas (Unidad de Control -> Ruta de Datos)
    ----------------------------------------------------------------------------
    signal w_clear    : std_logic;                        -- Reset interno sincronizado
    signal w_Lpc      : std_logic;                        -- Carga del Contador de Programa
    signal w_Ipc      : std_logic;                        -- Incremento del Contador de Programa
    signal w_SelDir   : std_logic;                        -- Selector de bus de direcciones (PC/HL)
    signal w_LH       : std_logic;                        -- Carga byte alto registro HL
    signal w_LL       : std_logic;                        -- Carga byte bajo registro HL
    signal w_Lri      : std_logic;                        -- Carga registro de instrucción
    signal w_SelRegW  : std_logic_vector(2 downto 0);     -- Dirección registro destino
    signal w_SelRegRA : std_logic_vector(2 downto 0);     -- Dirección operando A
    signal w_SelRegRB : std_logic_vector(2 downto 0);     -- Dirección operando B
    signal w_wr       : std_logic;                        -- Habilitación escritura banco registros
    signal w_ope      : std_logic_vector(2 downto 0);     -- Código de operación ALU
    signal w_SalAlu   : std_logic;                        -- Habilitación salida ALU al bus de datos
    signal w_LF       : std_logic;                        -- Carga de banderas de estado

    ----------------------------------------------------------------------------
    -- Señales de Feedback (Ruta de Datos -> Unidad de Control)
    ----------------------------------------------------------------------------
    signal w_Flags : std_logic_vector(7 downto 0);        -- Banderas Z, S, C
    signal w_CO    : std_logic_vector(7 downto 0);        -- OpCode actual para decodificación

    ----------------------------------------------------------------------------
    -- Señales de Memoria (Unidad de Control -> Memoria)
    ----------------------------------------------------------------------------
    signal w_inicia : std_logic;                        -- Comando para inicializar RAM (si aplica)
    signal w_cs     : std_logic;                        -- Chip Select de la RAM
    signal w_oe     : std_logic;                        -- Output Enable de la RAM (Lectura)
    signal w_we     : std_logic;                        -- Write Enable de la RAM (Escritura)

    ----------------------------------------------------------------------------
    -- Buses Globales (Ruta de Datos <-> Memoria)
    ----------------------------------------------------------------------------
    signal w_BusDatos : std_logic_vector(DATA_WIDTH-1 downto 0); -- Bus bidireccional de datos
    signal w_dir      : std_logic_vector(ADDR_WIDTH-1 downto 0);  -- Bus de direcciones (16 bits)

begin

    ----------------------------------------------------------------------------
    -- Instancia: Unidad de Control (FSM)
    -- Función: Genera las señales de control basadas en el OpCode y las Flags.
    ----------------------------------------------------------------------------
    inst_control: unidad_control port map (
        clk      => clk,
        rst      => rst,
        Flags    => w_Flags,
        CO       => w_CO,
        clear    => w_clear,
        Lpc      => w_Lpc,
        Ipc      => w_Ipc,
        SelDir   => w_SelDir,
        inicia   => w_inicia,
        cs       => w_cs,
        oe       => w_oe,
        we       => w_we,
        LH       => w_LH,
        LL       => w_LL,
        Lri      => w_Lri,
        SelRegW  => w_SelRegW,
        SelRegRA => w_SelRegRA,
        SelRegRB => w_SelRegRB,
        wr       => w_wr,
        ope      => w_ope,
        SalAlu   => w_SalAlu,
        LF       => w_LF,
        fin      => fin
    );

    ----------------------------------------------------------------------------
    -- Instancia: Ruta de Datos (Datapath)
    -- Función: Ejecuta las operaciones físicas (ALU, Registros, PC).
    ----------------------------------------------------------------------------
    inst_ruta_datos: ruta_datos port map (
        clk         => clk,
        clear       => w_clear,
        Lpc         => w_Lpc,
        Ipc         => w_Ipc,
        SelDir      => w_SelDir,
        LH          => w_LH,
        LL          => w_LL,
        Lri         => w_Lri,
        SelRegW     => w_SelRegW,
        SelRegRA    => w_SelRegRA,
        SelRegRB    => w_SelRegRB,
        wr          => w_wr,
        ope         => w_ope,
        SalAlu      => w_SalAlu,
        LF_ctrl     => w_LF,
        BusDatos    => w_BusDatos,
        dir         => w_dir,
        CO          => w_CO,
        Flags       => w_Flags
    );

    ----------------------------------------------------------------------------
    -- Instancia: Memoria RAM
    -- Función: Almacena instrucciones y datos de usuario.
    ----------------------------------------------------------------------------
    inst_memoria: memoria_ram port map (
        clk    => clk,
        we     => w_we,
        cs     => w_cs,
        oe     => w_oe,
        inicia => w_inicia,
        dir    => w_dir,
        datos  => w_BusDatos
    );

end architecture;
