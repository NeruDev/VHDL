-- ==============================================================================
-- Archivo: procesador.vhd
-- Ubicación: src/top/
-- Descripción: Entidad de nivel superior (Top-Level) del procesador.
--              Instancia y conecta la Unidad de Control (UC), la Ruta de 
--              Datos (RD) y la Memoria Principal.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity procesador is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map)
        -- ======================================================================
        rst    : in  std_logic; -- Reset Maestro
        clk    : in  std_logic; -- Reloj Maestro
        inicia : in  std_logic; -- Señal de control para el arranque del programa
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map)
        -- ======================================================================
        salida : out std_logic_vector(DATA_WIDTH - 1 downto 0) -- Monitoreo del Bus
    );
end procesador;

architecture Estructural of procesador is

    -- ----------------------------------------------------------------------
    -- CABLES DE INTERCONEXIÓN (Señales locales)
    -- ----------------------------------------------------------------------
    -- Señales de Control (UC -> RD/MEM)
    signal cable_clear, cable_Lpc, cable_Ipc, cable_SelDir : std_logic;
    signal cable_cs, cable_oe, cable_we, cable_LH, cable_LL, cable_Lri : std_logic;
    signal cable_wr, cable_RA, cable_RB, cable_SalAlu, cable_LF : std_logic;
    
    -- Señales de Direccionamiento de Registros
    signal cable_SelRegW, cable_SelRegRA, cable_SelRegRB : std_logic_vector(REG_SEL_W - 1 downto 0);
    signal cable_ope : std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
    
    -- Señales de Estado y Datos
    signal cable_FZ, cable_FC, cable_FS : std_logic; -- Banderas de la ALU
    signal cable_CO : std_logic_vector(DATA_WIDTH - 1 downto 0); -- Opcode decodificado
    signal cable_dir : std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Dirección de memoria
    
    -- Bus Principal del Sistema (Bidireccional)
    signal BusSistema : std_logic_vector(DATA_WIDTH - 1 downto 0);

begin

    -- ----------------------------------------------------------------------
    -- INSTANCIACIÓN DE MÓDULOS PRINCIPALES
    -- ----------------------------------------------------------------------

    -- 1. Unidad de Control (FSM): Orquesta el funcionamiento de todo el sistema.
    UC: entity work.unidad_control port map (
        rst => rst, clk => clk, FZ => cable_FZ, FC => cable_FC, FS => cable_FS, CO => cable_CO,
        clear => cable_clear, Lpc => cable_Lpc, Ipc => cable_Ipc, 
        SelDir => cable_SelDir, inicia => inicia, cs => cable_cs, 
        oe => cable_oe, we => cable_we, LH => cable_LH, LL => cable_LL, 
        Lri => cable_Lri, SelRegW => cable_SelRegW, wr => cable_wr, 
        RA => cable_RA, SelRegRA => cable_SelRegRA, RB => cable_RB, 
        SelRegRB => cable_SelRegRB, ope => cable_ope, SalAlu => cable_SalAlu, 
        LF => cable_LF 
    );

    -- 2. Ruta de Datos (Datapath): Ejecuta las operaciones y almacena valores.
    RD: entity work.ruta_datos port map (
        clk => clk,
        clear => cable_clear, Lpc => cable_Lpc, Ipc => cable_Ipc, SelDir => cable_SelDir,
        LH => cable_LH, LL => cable_LL, Lri => cable_Lri,
        SelRegW => cable_SelRegW, wr => cable_wr,
        RA => cable_RA, SelRegRA => cable_SelRegRA,
        RB => cable_RB, SelRegRB => cable_SelRegRB,
        ope => cable_ope, SalAlu => cable_SalAlu, LF => cable_LF,
        FZ => cable_FZ, FC => cable_FC, FS => cable_FS, CO => cable_CO,
        dir => cable_dir, BusDatos => BusSistema
    );

    -- 3. Memoria Principal (64KB): Almacena el código y los datos.
    MEM: entity work.memoria_64kx8 port map (
        inicia => inicia, cs => cable_cs, oe => cable_oe, we => cable_we,
        dir => cable_dir, datos => BusSistema
    );

    -- Salida para visualización externa
    salida <= BusSistema;

end Estructural;
