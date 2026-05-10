library ieee;
use ieee.std_logic_1164.all;
use work.procesador_pkg.all;

entity procesador_top is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        fin : out std_logic
    );
end entity;

architecture estructural of procesador_top is

    -- Señales de Control -> Ruta de Datos
    signal w_clear    : std_logic;
    signal w_Lpc      : std_logic;
    signal w_Ipc      : std_logic;
    signal w_SelDir   : std_logic;
    signal w_LH       : std_logic;
    signal w_LL       : std_logic;
    signal w_Lri      : std_logic;
    signal w_SelRegW  : std_logic_vector(2 downto 0);
    signal w_SelRegRA : std_logic_vector(2 downto 0);
    signal w_SelRegRB : std_logic_vector(2 downto 0);
    signal w_wr       : std_logic;
    signal w_ope      : std_logic_vector(2 downto 0);
    signal w_SalAlu   : std_logic;
    signal w_LF       : std_logic;

    -- Señales Ruta de Datos -> Control
    signal w_Flags : std_logic_vector(7 downto 0);
    signal w_CO    : std_logic_vector(7 downto 0);

    -- Señales Control -> Memoria
    signal w_inicia : std_logic;
    signal w_cs     : std_logic;
    signal w_oe     : std_logic;
    signal w_we     : std_logic;

    -- Señales Ruta de Datos <-> Memoria
    signal w_BusDatos : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal w_dir      : std_logic_vector(ADDR_WIDTH-1 downto 0);

begin

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
