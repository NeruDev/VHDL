-- ==============================================================================
-- Archivo: ruta_datos.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Integración ESTRUCTURAL de la Ruta de Datos.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity ruta_datos is
    Port ( 
        clk      : in  std_logic;
        -- Entradas de Control
        clear, Lpc, Ipc, SelDir, LH, LL, Lri, wr, RA, RB, SalAlu, LF : in std_logic;
        SelRegW, SelRegRA, SelRegRB : in std_logic_vector(REG_SEL_W - 1 downto 0);
        ope      : in std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
        -- Salidas hacia UC y Memoria
        FZ       : out std_logic;
        CO       : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        dir      : out std_logic_vector(ADDR_WIDTH - 1 downto 0);
        BusDatos : inout std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end ruta_datos;

architecture Estructural of ruta_datos is

    -- SEÑALES INTERNAS (Cables)
    signal cable_SalA, cable_SalB      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal cable_SalidaALU             : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal cable_Flags_in              : std_logic_vector(7 downto 0);
    signal cable_Flags_out             : std_logic_vector(7 downto 0);
    signal cable_pc_out, cable_hl_out  : std_logic_vector(ADDR_WIDTH - 1 downto 0);

begin

    -- 1. Contador de Programa (PC)
    U_PC: entity work.pc port map (
        clk => clk, clear => clear, Lpc => Lpc, Ipc => Ipc,
        entradaPC => cable_hl_out, salida => cable_pc_out
    );

    -- 2. Registro H|L
    U_HL: entity work.registro_hl port map (
        clk => clk, clear => clear, LH => LH, LL => LL,
        entDat => BusDatos, salida_hl => cable_hl_out
    );

    -- 3. Multiplexor de Direcciones
    U_MUX: entity work.mux_dir port map (
        entrada0 => cable_pc_out, entrada1 => cable_hl_out,
        SelDir => SelDir, salida => dir
    );

    -- 4. Registro de Instrucción (RI)
    U_RI: entity work.registro_ri port map (
        clk => clk, clear => clear, Lri => Lri,
        entDat => BusDatos, CO => CO
    );

    -- 5. Banco de Registros (BR 8x8)
    U_BR: entity work.banco_registros port map (
        clk => clk, wr => wr, SelRegW => SelRegW, entDat => BusDatos,
        RA => RA, SelRegRA => SelRegRA, SalA => cable_SalA,
        RB => RB, SelRegRB => SelRegRB, SalB => cable_SalB
    );

    -- 6. Unidad Aritmético Lógica (ALU)
    U_ALU: entity work.alu port map (
        SalA => cable_SalA, SalB => cable_SalB, ope => ope,
        SalidaALU => cable_SalidaALU, SalidaFlags => cable_Flags_in
    );

    -- 7. Registro de Banderas (Flags)
    U_FLAGS: entity work.registro_flags port map (
        clk => clk, clear => clear, LF => LF,
        Flags_in => cable_Flags_in, Flags_out => cable_Flags_out
    );

    -- Conexión de Flag Zero hacia la Unidad de Control (Bit 0 del bus de Flags)
    FZ <= cable_Flags_out(0);

    -- 8. Buffer Tri-estado de la ALU hacia el Bus de Datos
    BusDatos <= cable_SalidaALU when (SalAlu = '1') else (others => 'Z');

end Estructural;
