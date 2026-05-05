-- ==============================================================================
-- Archivo: unidad_control.vhd
-- Ubicación: src/unidad_control/
-- Descripción: Máquina de estados que decodifica instrucciones y genera 
--              señales de control para la Ruta de Datos y Memoria.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.procesador_pkg.all;

entity unidad_control is
    Port ( 
        -- Entradas de Sincronización y Estado
        rst    : in  std_logic;
        clk    : in  std_logic;
        FZ     : in  std_logic; -- Flag Zero desde la ALU
        CO     : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Código de Operación (desde RI)
        
        -- Salidas de Control (Hacia Ruta de Datos y Memoria)
        clear  : out std_logic;
        Lpc    : out std_logic;
        Ipc    : out std_logic;
        SelDir : out std_logic;
        inicia : out std_logic;
        cs     : out std_logic;
        oe     : out std_logic;
        we     : out std_logic;
        LH     : out std_logic;
        LL     : out std_logic;
        Lri    : out std_logic;
        SelRegW: out std_logic_vector(REG_SEL_W - 1 downto 0);
        wr     : out std_logic;
        RA     : out std_logic;
        SelRegRA: out std_logic_vector(REG_SEL_W - 1 downto 0);
        RB     : out std_logic;
        SelRegRB: out std_logic_vector(REG_SEL_W - 1 downto 0);
        ope    : out std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
        SalAlu : out std_logic;
        LF     : out std_logic  -- Load Flags: Habilita la captura de nuevas banderas
    );
end unidad_control;

architecture FSM of unidad_control is
    -- Definición de los estados del procesador
    type estado_t is (RESET_ST, FETCH1, FETCH2, DECODE, EXEC_ADD, EXEC_LOAD);
    signal estado_actual, estado_siguiente : estado_t;
begin

    -- Proceso Síncrono: Actualiza el estado en cada flanco de subida del reloj
    process(clk, rst)
    begin
        if rst = '1' then
            estado_actual <= RESET_ST;
        elsif rising_edge(clk) then
            estado_actual <= estado_siguiente;
        end if;
    end process;

    -- Proceso Combinacional: Determina salidas y próximo estado
    process(estado_actual, CO, FZ)
    begin
        -- Valores por defecto para evitar latches inferidos (muy importante en VHDL)
        clear <= '0'; Lpc <= '0'; Ipc <= '0'; SelDir <= '0';
        inicia <= '0'; cs <= '0'; oe <= '0'; we <= '0';
        LH <= '0'; LL <= '0'; Lri <= '0'; wr <= '0';
        RA <= '0'; RB <= '0'; SalAlu <= '0'; LF <= '0';
        ope <= (others => '0'); SelRegW <= "000"; 
        SelRegRA <= "000"; SelRegRB <= "000";
        
        estado_siguiente <= estado_actual; -- Por defecto, mantiene el estado

        case estado_actual is
            when RESET_ST =>
                clear <= '1'; -- Limpia PC, Registros y Flags
                estado_siguiente <= FETCH1;
                
            when FETCH1 =>
                -- Fase 1: Apunta a memoria con el PC y pide lectura
                SelDir <= '0'; -- Dirección viene del PC
                cs <= '1'; 
                oe <= '1';
                estado_siguiente <= FETCH2;
                
            when FETCH2 =>
                -- Fase 2: Guarda el dato de la memoria en el RI e incrementa el PC
                SelDir <= '0';
                cs <= '1'; 
                oe <= '1';
                Lri <= '1'; -- Carga Registro de Instrucción
                Ipc <= '1'; -- Incrementa PC para la próxima
                estado_siguiente <= DECODE;
                
            when DECODE =>
                -- Aquí se evalúa el "CO" (Código de Operación) para bifurcar
                -- Ejemplo ficticio: Si CO = x"01" es ADD, si es x"02" es LOAD
                if CO = x"01" then
                    estado_siguiente <= EXEC_ADD;
                elsif CO = x"02" then
                    estado_siguiente <= EXEC_LOAD;
                else
                    estado_siguiente <= FETCH1; -- Si no se reconoce, vuelve a empezar
                end if;
                
            when EXEC_ADD =>
                -- Configura la ALU y el Banco de Registros
                RA <= '1'; RB <= '1';       -- Lee de A y B
                ope <= OP_ADD;              -- Constante importada del procesador_pkg
                SalAlu <= '1';              -- Activa Buffer de ALU hacia BusDatos
                wr <= '1';                  -- Escribe el resultado en un registro
                LF <= '1';                  -- Actualiza las banderas de estado
                estado_siguiente <= FETCH1;
                
            when others =>
                estado_siguiente <= FETCH1;
        end case;
    end process;
end FSM;
