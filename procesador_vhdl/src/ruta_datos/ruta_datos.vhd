-- ==============================================================================
-- Archivo: ruta_datos.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Integración ESTRUCTURAL de la Ruta de Datos (Datapath).
--              Interconecta los registros, la ALU, el PC y los buses internos
--              siguiendo las órdenes de la Unidad de Control.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity ruta_datos is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map) - RELOJ Y CONTROL
        -- ======================================================================
        clk      : in  std_logic; -- Reloj del Sistema
        
        -- Señales de Control provenientes de la Unidad de Control
        clear    : in  std_logic; -- Reset asíncrono para registros internos
        Lpc      : in  std_logic; -- Carga PC desde HL
        Ipc      : in  std_logic; -- Incremento de PC
        SelDir   : in  std_logic; -- Selector Mux: 0=PC, 1=HL
        LH       : in  std_logic; -- Habilitador Registro H
        LL       : in  std_logic; -- Habilitador Registro L
        Lri      : in  std_logic; -- Habilitador Registro RI
        wr       : in  std_logic; -- Habilitador Escritura Banco de Registros (BR)
        RA       : in  std_logic; -- Habilitador Lectura BR Puerto A
        RB       : in  std_logic; -- Habilitador Lectura BR Puerto B
        SalAlu   : in  std_logic; -- Control del Buffer Tri-estado de la ALU
        LF       : in  std_logic; -- Habilitador Registro de Flags
        
        -- Selectores de Registros (Direccionamiento del BR)
        SelRegW  : in  std_logic_vector(REG_SEL_W - 1 downto 0); -- Índice Reg Escritura
        SelRegRA : in  std_logic_vector(REG_SEL_W - 1 downto 0); -- Índice Reg Puerto A
        SelRegRB : in  std_logic_vector(REG_SEL_W - 1 downto 0); -- Índice Reg Puerto B
        
        -- Código de Operación de la ALU
        ope      : in  std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map) - ESTADO Y BUSES
        -- ======================================================================
        FZ       : out std_logic; -- Bandera Zero hacia UC
        FC       : out std_logic; -- Bandera Carry hacia UC
        FS       : out std_logic; -- Bandera Signo hacia UC
        CO       : out std_logic_vector(DATA_WIDTH - 1 downto 0); -- Instrucción hacia UC
        dir      : out std_logic_vector(ADDR_WIDTH - 1 downto 0); -- Bus Direcciones hacia Memoria
        
        -- Bus de Datos Bidireccional
        BusDatos : inout std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end ruta_datos;

architecture Estructural of ruta_datos is

    -- ----------------------------------------------------------------------
    -- SEÑALES INTERNAS (Cables de interconexión)
    -- ----------------------------------------------------------------------
    -- Salidas del Banco de Registros (Operandos para ALU)
    signal cable_SalA, cable_SalB      : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    -- Salida directa de la ALU
    signal cable_SalidaALU             : std_logic_vector(DATA_WIDTH - 1 downto 0);
    
    -- Banderas (Flags)
    signal cable_Flags_in              : std_logic_vector(7 downto 0); -- Desde ALU
    signal cable_Flags_out             : std_logic_vector(7 downto 0); -- Desde Reg_Flags
    
    -- Buses de direcciones internos
    signal cable_pc_out, cable_hl_out  : std_logic_vector(ADDR_WIDTH - 1 downto 0);

begin

    -- ----------------------------------------------------------------------
    -- INSTANCIACIÓN DE COMPONENTES
    -- ----------------------------------------------------------------------

    -- 1. Contador de Programa (PC): Almacena la dirección de la siguiente instrucción.
    U_PC: entity work.pc port map (
        clk => clk, clear => clear, Lpc => Lpc, Ipc => Ipc,
        entradaPC => cable_hl_out, salida => cable_pc_out
    );

    -- 2. Registro H|L: Almacena direcciones de 16 bits cargadas desde el bus de 8 bits.
    U_HL: entity work.registro_hl port map (
        clk => clk, clear => clear, LH => LH, LL => LL,
        entDat => BusDatos, salida_hl => cable_hl_out
    );

    -- 3. Multiplexor de Direcciones: Selecciona qué puntero accede a la memoria.
    U_MUX: entity work.mux_dir port map (
        entrada0 => cable_pc_out, entrada1 => cable_hl_out,
        SelDir => SelDir, salida => dir
    );

    -- 4. Registro de Instrucción (RI): Captura el opcode del bus de datos.
    U_RI: entity work.registro_ri port map (
        clk => clk, clear => clear, Lri => Lri,
        entDat => BusDatos, CO => CO
    );

    -- 5. Banco de Registros (BR 8x8): Almacenamiento local de operandos y resultados.
    U_BR: entity work.banco_registros port map (
        clk => clk, wr => wr, SelRegW => SelRegW, entDat => BusDatos,
        RA => RA, SelRegRA => SelRegRA, SalA => cable_SalA,
        RB => RB, SelRegRB => SelRegRB, SalB => cable_SalB
    );

    -- 6. Unidad Aritmético Lógica (ALU): Realiza cálculos según 'ope'.
    U_ALU: entity work.alu port map (
        SalA => cable_SalA, SalB => cable_SalB, ope => ope,
        SalidaALU => cable_SalidaALU, SalidaFlags => cable_Flags_in
    );

    -- 7. Registro de Banderas (Flags): Memoriza el estado de la última operación ALU.
    U_FLAGS: entity work.registro_flags port map (
        clk => clk, clear => clear, LF => LF,
        Flags_in => cable_Flags_in, Flags_out => cable_Flags_out
    );

    -- Conexión de Banderas hacia la Unidad de Control
    -- Mapeo estandarizado: Bit 0 = Zero, Bit 1 = Sign, Bit 2 = Carry
    FZ <= cable_Flags_out(0);
    FS <= cable_Flags_out(1);
    FC <= cable_Flags_out(2);

    -- 8. Buffer Tri-estado de la ALU: Controla cuándo la ALU escribe en el bus compartido.
    BusDatos <= cable_SalidaALU when (SalAlu = '1') else (others => 'Z');

end Estructural;
