--------------------------------------------------------------------------------
-- Entidad: unidad_control
-- Arquitectura: rtl
-- Descripción: Unidad de Control que implementa la Máquina de Estados Finitos (FSM) 
--              para orquestar el ciclo de Búsqueda, Decodificación y Ejecución.
-- Referencias: 
--   - Proyecto/ARCHIVOS_BASE/FSM_PROCESADOR.md (Tabla de estados)
--   - Proyecto/ARCHIVOS_BASE/MICRO_INSTRUCCIONES.md (Acciones por instrucción)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity unidad_control is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;                        -- Reset externo (hardware)
        Flags    : in  std_logic_vector(7 downto 0);      -- Entrada de banderas (Z, S, C)
        CO       : in  std_logic_vector(7 downto 0);      -- Código de Operación del RI
        clear    : out std_logic;                        -- Reset interno para registros
        Lpc      : out std_logic;                        -- Load PC: Carga PC desde bus/HL
        Ipc      : out std_logic;                        -- Increment PC: PC <- PC + 1
        SelDir   : out std_logic;                        -- Multiplexor bus direcciones (0:PC, 1:HL)
        inicia   : out std_logic;                        -- Señal de arranque/init memoria
        cs       : out std_logic;                        -- Chip Select RAM (activo bajo)
        oe       : out std_logic;                        -- Output Enable RAM (activo bajo)
        we       : out std_logic;                        -- Write Enable RAM (activo alto en este diseño)
        LH       : out std_logic;                        -- Load High: Carga H del par HL
        LL       : out std_logic;                        -- Load Low: Carga L del par HL
        Lri      : out std_logic;                        -- Load RI: Captura instrucción
        SelRegW  : out std_logic_vector(2 downto 0);     -- Registro destino en banco registros
        SelRegRA : out std_logic_vector(2 downto 0);     -- Selector operando A (ALU)
        SelRegRB : out std_logic_vector(2 downto 0);     -- Selector operando B (ALU)
        wr       : out std_logic;                        -- Write Enable banco registros
        ope      : out std_logic_vector(2 downto 0);     -- Operación para la ALU
        SalAlu   : out std_logic;                        -- Habilitación buffer triestado ALU
        LF       : out std_logic;                        -- Load Flags: Actualiza registro banderas
        fin      : out std_logic                         -- Señal de término (Halt)
    );
end entity;

architecture rtl of unidad_control is

    -- Definición de estados según FSM_PROCESADOR.md
    type state_type is (S00, S01, S02, S03, S04, S05, S06, S07, S08, 
                        S09, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19);
    signal current_state, next_state : state_type;

    -- Mapeo de banderas de estado para saltos condicionales
    alias FZ : std_logic is Flags(0); -- Zero Flag
    alias FS : std_logic is Flags(1); -- Sign Flag
    alias FC : std_logic is Flags(2); -- Carry Flag

begin

    ----------------------------------------------------------------------------
    -- Proceso secuencial: Actualización del estado actual
    ----------------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            current_state <= S00;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Proceso combinacional: Lógica de estado siguiente y salidas de control
    ----------------------------------------------------------------------------
    process(current_state, CO, FZ, FS, FC)
    begin
        -- ASIGNACIÓN DE VALORES POR DEFECTO (Previene la generación de latches)
        clear    <= '0';
        Lpc      <= '0';
        Ipc      <= '0';
        SelDir   <= '0';
        inicia   <= '0';
        cs       <= '1'; -- RAM inactiva por defecto
        oe       <= '1'; -- Lectura RAM inactiva por defecto
        we       <= '0'; -- Escritura RAM inactiva por defecto
        LH       <= '0';
        LL       <= '0';
        Lri      <= '0';
        SelRegW  <= "000";
        SelRegRA <= "000";
        SelRegRB <= "000";
        wr       <= '0';
        ope      <= "000";
        SalAlu   <= '0';
        LF       <= '0';
        fin      <= '0';

        next_state <= current_state;

        case current_state is
            --------------------------------------------------------------------
            -- CICLO DE FETCH (BÚSQUEDA)
            --------------------------------------------------------------------
            when S00 => -- RESET: Inicialización del sistema
                clear  <= '1';
                inicia <= '1';
                next_state <= S01;

            when S01 => -- FETCH0: Lectura del OpCode desde la dirección del PC
                cs  <= '0';
                oe  <= '0';
                Lri <= '1'; -- Captura en Registro de Instrucción
                next_state <= S02;

            when S02 => -- FETCH1: Incremento de PC y Decodificación de Instrucción
                Ipc <= '1';
                case CO is
                    -- Instrucciones que requieren operando de 16 bits (LOAD, STORE, JUMPS)
                    when x"70" | x"71" | x"80" | x"81" | x"82" | x"83" => next_state <= S03;
                    -- Instrucciones ALU rápidas (1 solo ciclo de ejecución)
                    when x"40" => next_state <= S15; -- NOT R1
                    when x"41" => next_state <= S16; -- AND R1
                    when x"42" => next_state <= S17; -- DEC R1
                    when x"43" => next_state <= S18; -- INC R1
                    when x"44" => next_state <= S19; -- SUB R1
                    when x"45" => next_state <= S09; -- ADD R1
                    when x"46" => next_state <= S10; -- MOV R0, R1
                    when x"47" => next_state <= S12; -- MOVI K
                    when x"FF" => next_state <= S11; -- HALT
                    when others => next_state <= S01; -- NOP / Desconocida
                end case;

            --------------------------------------------------------------------
            -- RUTINA DE CAPTURA DE DIRECCIÓN DE 16 BITS (HL)
            --------------------------------------------------------------------
            when S03 => -- Lee byte bajo de la dirección y guarda en L
                cs <= '0';
                oe <= '0';
                LL <= '1';
                next_state <= S04;

            when S04 => -- PC apunta al byte alto
                Ipc <= '1';
                next_state <= S05;

            when S05 => -- Lee byte alto de la dirección y guarda en H
                cs <= '0';
                oe <= '0';
                LH <= '1';
                next_state <= S06;

            when S06 => -- PC apunta a la siguiente instrucción, sub-decodificación
                Ipc <= '1';
                case CO is
                    when x"70" => next_state <= S07; -- LOAD
                    when x"71" => next_state <= S08; -- STORE
                    when x"80" => next_state <= S14; -- JMP (incondicional)
                    when x"81" => -- JZ
                        if FZ = '1' then next_state <= S14; else next_state <= S01; end if;
                    when x"82" => -- JC
                        if FC = '1' then next_state <= S14; else next_state <= S01; end if;
                    when x"83" => -- JS
                        if FS = '1' then next_state <= S14; else next_state <= S01; end if;
                    when others => next_state <= S01;
                end case;

            --------------------------------------------------------------------
            -- FASE DE EJECUCIÓN: ACCESO A MEMORIA Y SALTOS
            --------------------------------------------------------------------
            when S07 => -- LOAD: R1 <- M(HL). Usa SelDir para direccionar con HL
                SelDir  <= '1';
                cs      <= '0';
                oe      <= '0';
                SelRegW <= "001"; -- Destino R1
                wr      <= '1';
                next_state <= S01;

            when S08 => -- STORE: M(HL) <- R1. Usa bypass de ALU (ope 000)
                SelDir   <= '1';
                cs       <= '0';
                we       <= '1';
                SelRegRA <= "001"; -- Origen R1
                ope      <= "000"; -- Pass-through
                SalAlu   <= '1';   -- Habilita dato al bus
                next_state <= S01;

            when S14 => -- JUMP: PC <- HL. Actualiza PC con el valor ensamblado en HL
                Lpc <= '1';
                next_state <= S01;

            --------------------------------------------------------------------
            -- FASE DE EJECUCIÓN: OPERACIONES ALU
            --------------------------------------------------------------------
            when S09 => -- ADD: R1 <- R0 + R1
                SelRegW  <= "001";
                SelRegRA <= "000";
                SelRegRB <= "001";
                ope      <= "101"; -- SUMA
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';   -- Actualiza banderas
                next_state <= S01;

            when S10 => -- MOV: R0 <- R1
                SelRegW  <= "000";
                SelRegRA <= "001";
                ope      <= "000"; -- Bypass
                SalAlu   <= '1';
                wr       <= '1';
                next_state <= S01;

            when S12 => -- MOVI: R1 <- M(PC). Carga inmediata de un byte
                cs      <= '0';
                oe      <= '0';
                SelRegW <= "001";
                wr      <= '1';
                next_state <= S13;

            when S13 => -- Ajuste de PC tras MOVI
                Ipc <= '1';
                next_state <= S01;

            when S15 => -- NOT: R1 <- not R1
                SelRegW  <= "001";
                SelRegRA <= "001";
                ope      <= "011";
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            when S16 => -- AND: R1 <- R0 and R1
                SelRegW  <= "001";
                SelRegRA <= "000";
                SelRegRB <= "001";
                ope      <= "010";
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            when S17 => -- DEC: R1 <- R1 - 1
                SelRegW  <= "001";
                SelRegRA <= "001";
                ope      <= "100"; -- RESTA 1
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            when S18 => -- INC: R1 <- R1 + 1
                SelRegW  <= "001";
                SelRegRA <= "001";
                ope      <= "111"; -- SUMA 1
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            when S19 => -- SUB: R1 <- R0 - R1
                SelRegW  <= "001";
                SelRegRA <= "000";
                SelRegRB <= "001";
                ope      <= "110"; -- RESTA
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            --------------------------------------------------------------------
            -- ESTADOS ESPECIALES
            --------------------------------------------------------------------
            when S11 => -- HALT: Detiene el procesador en un bucle infinito
                fin <= '1';
                next_state <= S11;

            when others =>
                next_state <= S00;
        end case;
    end process;

end architecture;
