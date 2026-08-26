-- ==============================================================================
-- Archivo: unidad_control.vhd
-- Ubicación: src/unidad_control/
-- Descripción: Máquina de estados (FSM) que actúa como el "cerebro" del procesador.
--              Decodifica las instrucciones del Registro de Instrucción (RI)
--              y genera la secuencia de señales de control necesarias.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity unidad_control is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map)
        -- ======================================================================
        rst    : in  std_logic; -- Reset Global (Activo en '1')
        clk    : in  std_logic; -- Reloj del Sistema
        FZ     : in  std_logic; -- Flag de Cero (Zero): '1' si el resultado ALU fue 0
        FC     : in  std_logic; -- Flag de Acarreo (Carry): '1' si hubo desbordamiento
        FS     : in  std_logic; -- Flag de Signo (Sign): '1' si el resultado fue negativo
        CO     : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Código de Operación (desde RI)
        inicia : in  std_logic; -- Señal de arranque externo para salir de ESPERA
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map) - SEÑALES DE CONTROL
        -- ======================================================================
        -- Control de Registros y PC
        clear  : out std_logic; -- Limpia PC, Registros y Flags (Reset Lógico)
        Lpc    : out std_logic; -- Carga PC (Load PC) desde HL
        Ipc    : out std_logic; -- Incrementa PC (Increment PC)
        SelDir : out std_logic; -- Multiplexor de Direcciones: '0'=PC, '1'=HL
        
        -- Control de Memoria
        cs     : out std_logic; -- Chip Select (Activa Memoria)
        oe     : out std_logic; -- Output Enable (Lectura de Memoria)
        we     : out std_logic; -- Write Enable (Escritura en Memoria)
        
        -- Control de Bus Interno y Datos
        LH     : out std_logic; -- Carga Registro H (Parte alta de dirección)
        LL     : out std_logic; -- Carga Registro L (Parte baja de dirección)
        Lri    : out std_logic; -- Carga Registro de Instrucción (RI)
        
        -- Control del Banco de Registros (BR)
        wr     : out std_logic; -- Habilita Escritura en el Banco de Registros
        SelRegW: out std_logic_vector(REG_SEL_W - 1 downto 0); -- Selecciona Reg para Escritura
        RA     : out std_logic; -- Habilita Lectura Puerto A
        SelRegRA: out std_logic_vector(REG_SEL_W - 1 downto 0); -- Selecciona Reg para Puerto A
        RB     : out std_logic; -- Habilita Lectura Puerto B
        SelRegRB: out std_logic_vector(REG_SEL_W - 1 downto 0); -- Selecciona Reg para Puerto B
        
        -- Control de la ALU
        ope    : out std_logic_vector(ALU_OP_WIDTH - 1 downto 0); -- Operación para la ALU
        SalAlu : out std_logic; -- Activa el Buffer Tri-estado de la ALU hacia BusDatos
        LF     : out std_logic  -- Load Flags: Captura el estado actual de la ALU
    );
end unidad_control;

architecture FSM of unidad_control is
    -- ----------------------------------------------------------------------
    -- TIPOS DE DATOS Y SEÑALES
    -- ----------------------------------------------------------------------
    -- Definición de los estados del procesador (Ciclo de Instrucción)
    type estado_t is (
        RESET_ST,       -- Estado inicial de reset
        ESPERA,         -- Espera señal externa 'inicia'
        FETCH1,         -- Fase 1: Apunta a memoria con PC
        FETCH2,         -- Fase 2: Lee instrucción de memoria al RI
        DECODE,         -- Decodifica Opcode y decide bifurcación
        EXEC_ALU,       -- Ejecuta operaciones aritmético-lógicas
        EXEC_LDI1,      -- Carga Inmediata Fase 1 (Lectura de dato)
        EXEC_LDI2,      -- Carga Inmediata Fase 2 (Escritura en BR)
        EXEC_LDH1,      -- Carga HL Fase 1 (Byte Alto H)
        EXEC_LDH2,      -- Carga HL Fase 2 (Byte Alto H)
        EXEC_LDL1,      -- Carga HL Fase 3 (Byte Bajo L)
        EXEC_LDL2,      -- Carga HL Fase 4 (Byte Bajo L)
        EXEC_LDA1,      -- Carga desde RAM Fase 1 (Direccionamiento [HL])
        EXEC_LDA2,      -- Carga desde RAM Fase 2 (Lectura y Escritura)
        EXEC_STA1,      -- Almacena en RAM (Escritura en [HL])
        EXEC_JMP,       -- Ejecuta salto (PC <= HL)
        EXEC_MOV        -- Mueve datos entre registros del banco
    );
    
    signal estado_actual, estado_siguiente : estado_t;
    
    -- Señales internas de decodificación
    signal opcode  : std_logic_vector(4 downto 0); -- Parte superior del CO (Instrucción)
    signal reg_sel : std_logic_vector(2 downto 0); -- Parte inferior del CO (Registro destino)

begin

    -- ----------------------------------------------------------------------
    -- LÓGICA DE DECODIFICACIÓN
    -- ----------------------------------------------------------------------
    -- Se separa el Código de Operación en sus componentes funcionales
    opcode  <= CO(7 downto 3);
    reg_sel <= CO(2 downto 0);

    -- ----------------------------------------------------------------------
    -- PROCESO SÍNCRONO (Actualización de Estado)
    -- ----------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            estado_actual <= RESET_ST;
        elsif rising_edge(clk) then
            estado_actual <= estado_siguiente;
        end if;
    end process;

    -- ----------------------------------------------------------------------
    -- PROCESO COMBINACIONAL (Salidas y Próximo Estado)
    -- ----------------------------------------------------------------------
    process(estado_actual, opcode, reg_sel, FZ, FC, FS, inicia)
    begin
        -- =====================================================
        -- VALORES POR DEFECTO (Prevención de Latches)
        -- =====================================================
        clear <= '0'; Lpc <= '0'; Ipc <= '0'; SelDir <= '0';
        cs <= '0'; oe <= '0'; we <= '0';
        LH <= '0'; LL <= '0'; Lri <= '0'; wr <= '0';
        RA <= '0'; RB <= '0'; SalAlu <= '0'; LF <= '0';
        ope <= OP_TRANS_A; 
        
        -- Configuración por defecto de registros dinámicos
        SelRegW   <= reg_sel; 
        SelRegRA  <= reg_sel;
        SelRegRB  <= "001"; -- R1 es operando secundario por defecto
        
        estado_siguiente <= estado_actual;

        case estado_actual is
            -- -------------------------------------------------
            -- CICLO BÁSICO: RESET -> ESPERA -> FETCH
            -- -------------------------------------------------
            when RESET_ST =>
                clear <= '1';
                estado_siguiente <= ESPERA;
            
            when ESPERA =>
                if inicia = '1' then
                    estado_siguiente <= FETCH1;
                else
                    estado_siguiente <= ESPERA;
                end if;
                
            when FETCH1 =>
                SelDir <= '0'; -- PC suministra dirección
                cs <= '1'; oe <= '1'; -- Lectura de memoria
                estado_siguiente <= FETCH2;
                
            when FETCH2 =>
                SelDir <= '0'; cs <= '1'; oe <= '1';
                Lri <= '1';    -- Captura byte en RI
                Ipc <= '1';    -- PC apunta a siguiente byte
                estado_siguiente <= DECODE;
                
            when DECODE =>
                case opcode is
                    when INST_NOP   => estado_siguiente <= FETCH1;
                    when INST_ADD | INST_SUB | INST_AND | INST_NOT | INST_INC | INST_DEC => 
                        estado_siguiente <= EXEC_ALU;
                    when INST_LDI   => estado_siguiente <= EXEC_LDI1;
                    when INST_LDHL  => estado_siguiente <= EXEC_LDH1;
                    when INST_LDA   => estado_siguiente <= EXEC_LDA1;
                    when INST_STA   => estado_siguiente <= EXEC_STA1;
                    when INST_JMP   => estado_siguiente <= EXEC_JMP;
                    -- Saltos Condicionales
                    when INST_JZ    => if FZ = '1' then estado_siguiente <= EXEC_JMP; else estado_siguiente <= FETCH1; end if;
                    when INST_JNZ   => if FZ = '0' then estado_siguiente <= EXEC_JMP; else estado_siguiente <= FETCH1; end if;
                    when INST_JC    => if FC = '1' then estado_siguiente <= EXEC_JMP; else estado_siguiente <= FETCH1; end if;
                    when INST_JNC   => if FC = '0' then estado_siguiente <= EXEC_JMP; else estado_siguiente <= FETCH1; end if;
                    when INST_JS    => if FS = '1' then estado_siguiente <= EXEC_JMP; else estado_siguiente <= FETCH1; end if;
                    when INST_JNS   => if FS = '0' then estado_siguiente <= EXEC_JMP; else estado_siguiente <= FETCH1; end if;
                    when INST_MOV   => estado_siguiente <= EXEC_MOV;
                    when others     => estado_siguiente <= FETCH1;
                end case;
            
            -- -------------------------------------------------
            -- ESTADOS DE EJECUCIÓN (Microinstrucciones)
            -- -------------------------------------------------
            when EXEC_ALU =>
                RA <= '1'; RB <= '1'; wr <= '1'; SalAlu <= '1'; LF <= '1';
                if    opcode = INST_ADD then ope <= OP_ADD;
                elsif opcode = INST_SUB then ope <= OP_SUB;
                elsif opcode = INST_AND then ope <= OP_AND;
                elsif opcode = INST_NOT then ope <= OP_NOT_A;
                elsif opcode = INST_INC then ope <= OP_INC_A;
                elsif opcode = INST_DEC then ope <= OP_DEC_A;
                end if;
                estado_siguiente <= FETCH1;

            when EXEC_LDI1 =>
                SelDir <= '0'; cs <= '1'; oe <= '1'; -- Lee dato inmediato de memoria
                estado_siguiente <= EXEC_LDI2;

            when EXEC_LDI2 =>
                wr <= '1';     -- Escribe dato en registro seleccionado
                Ipc <= '1';    -- Avanza PC tras el operando
                estado_siguiente <= FETCH1;

            when EXEC_LDH1 =>
                SelDir <= '0'; cs <= '1'; oe <= '1';
                estado_siguiente <= EXEC_LDH2;
            
            when EXEC_LDH2 => 
                LH <= '1';     -- Carga Registro H
                Ipc <= '1'; 
                estado_siguiente <= EXEC_LDL1;

            when EXEC_LDL1 =>
                SelDir <= '0'; cs <= '1'; oe <= '1';
                estado_siguiente <= EXEC_LDL2;

            when EXEC_LDL2 => 
                LL <= '1';     -- Carga Registro L
                Ipc <= '1'; 
                estado_siguiente <= FETCH1;

            when EXEC_LDA1 =>
                SelDir <= '1'; -- Dirección viene de HL
                cs <= '1'; oe <= '1';
                estado_siguiente <= EXEC_LDA2;

            when EXEC_LDA2 => 
                wr <= '1';     -- Guarda dato leído en registro seleccionado
                estado_siguiente <= FETCH1;

            when EXEC_STA1 =>
                SelDir <= '1'; -- Dirección de RAM viene de HL
                cs <= '1'; we <= '1'; -- Escritura habilitada
                RA <= '1'; ope <= OP_TRANS_A; SalAlu <= '1'; -- Pone registro en bus
                estado_siguiente <= FETCH1;

            when EXEC_JMP =>
                Lpc <= '1';    -- Carga PC con el contenido de HL
                estado_siguiente <= FETCH1;

            when EXEC_MOV =>
                RA <= '0'; RB <= '1'; -- Lee de R1
                ope <= OP_TRANS_B; SalAlu <= '1'; 
                wr <= '1';     -- Escribe en el registro indicado por reg_sel
                estado_siguiente <= FETCH1;

            when others =>
                estado_siguiente <= FETCH1;
        end case;
    end process;
end FSM;
