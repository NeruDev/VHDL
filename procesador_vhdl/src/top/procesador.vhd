-- ==============================================================================
-- Archivo: procesador.vhd
-- Ubicación: src/top/
-- Descripción: Instancia principal. Conecta UC, Ruta de Datos y Memoria.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity procesador is
    Port ( 
        rst    : in  std_logic;
        clk    : in  std_logic;
        salida : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end procesador;

architecture Estructural of procesador is

    -- Cables de Control Generales
    signal cable_clear, cable_Lpc, cable_Ipc, cable_SelDir, cable_inicia : std_logic;
    signal cable_cs, cable_oe, cable_we, cable_LH, cable_LL, cable_Lri : std_logic;
    signal cable_wr, cable_RA, cable_RB, cable_SalAlu, cable_LF : std_logic;
    
    -- Cables de Control de Buses
    signal cable_SelRegW, cable_SelRegRA, cable_SelRegRB : std_logic_vector(REG_SEL_W - 1 downto 0);
    signal cable_ope : std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
    
    -- Cables de Datos y Direcciones
    signal cable_FZ : std_logic;
    signal cable_CO : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal cable_dir : std_logic_vector(ADDR_WIDTH - 1 downto 0);
    
    -- Bus Principal del Sistema (Bidireccional interno)
    signal BusSistema : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin

    -- Instancia 1: Unidad de Control
    UC: entity work.unidad_control port map (
        rst => rst, clk => clk, FZ => cable_FZ, CO => cable_CO,
        clear => cable_clear, Lpc => cable_Lpc, Ipc => cable_Ipc, 
        SelDir => cable_SelDir, inicia => cable_inicia, cs => cable_cs, 
        oe => cable_oe, we => cable_we, LH => cable_LH, LL => cable_LL, 
        Lri => cable_Lri, SelRegW => cable_SelRegW, wr => cable_wr, 
        RA => cable_RA, SelRegRA => cable_SelRegRA, RB => cable_RB, 
        SelRegRB => cable_SelRegRB, ope => cable_ope, SalAlu => cable_SalAlu, 
        LF => cable_LF 
    );

    -- Instancia 2: Ruta de Datos
    RD: entity work.ruta_datos port map (
        clk => clk,
        clear => cable_clear, Lpc => cable_Lpc, Ipc => cable_Ipc, SelDir => cable_SelDir,
        LH => cable_LH, LL => cable_LL, Lri => cable_Lri,
        SelRegW => cable_SelRegW, wr => cable_wr,
        RA => cable_RA, SelRegRA => cable_SelRegRA,
        RB => cable_RB, SelRegRB => cable_SelRegRB,
        ope => cable_ope, SalAlu => cable_SalAlu, LF => cable_LF,
        FZ => cable_FZ, CO => cable_CO,
        dir => cable_dir, BusDatos => BusSistema
    );

    -- Instancia 3: Memoria 64Kx8
    MEM: entity work.memoria_64kx8 port map (
        inicia => cable_inicia, cs => cable_cs, oe => cable_oe, we => cable_we,
        dir => cable_dir, datos => BusSistema
    );

    -- Salida principal del procesador (solo para monitoreo externo)
    salida <= BusSistema;

end Estructural;
