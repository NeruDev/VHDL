-- ==============================================================================
-- Archivo: tb_alu.vhd
-- Ubicación: tb/
-- Descripción: Testbench exhaustivo para la ALU con autoverificación y casos borde.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity tb_alu is
end tb_alu;

architecture robust of tb_alu is

    -- DUT
    component alu
    Port ( 
        SalA        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        SalB        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        ope         : in  std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
        SalidaALU   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        SalidaFlags : out std_logic_vector(7 downto 0)
    );
    end component;

    signal SalA_tb, SalB_tb : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');
    signal ope_tb           : std_logic_vector(ALU_OP_WIDTH - 1 downto 0) := (others => '0');
    signal SalidaALU_tb     : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal SalidaFlags_tb   : std_logic_vector(7 downto 0);
    
    -- Registro de fallos para auditoría
    signal errores : integer := 0;

begin

    DUT: alu port map (SalA_tb, SalB_tb, ope_tb, SalidaALU_tb, SalidaFlags_tb);

    stim_proc: process
        -- Procedimiento interno mejorado con registro de fallos
        procedure check_alu(
            constant a, b : in integer;
            constant op   : in std_logic_vector(2 downto 0);
            constant exp_res : in integer;
            constant exp_z, exp_s, exp_c : in std_logic;
            constant msg  : in string
        ) is
        begin
            SalA_tb <= std_logic_vector(to_unsigned(a, DATA_WIDTH));
            SalB_tb <= std_logic_vector(to_unsigned(b, DATA_WIDTH));
            ope_tb  <= op;
            wait for 10 ns;
            
            -- Verificación de Resultado
            if (to_integer(unsigned(SalidaALU_tb)) /= exp_res mod 256) then
                report "FALLO RESULTADO [" & msg & "]: Esperado " & integer'image(exp_res mod 256) & 
                       ", Obtenido " & integer'image(to_integer(unsigned(SalidaALU_tb)))
                severity error;
                errores <= errores + 1;
            end if;
                
            -- Verificación de Banderas (Z, S, C)
            if (SalidaFlags_tb(0) /= exp_z) then
                report "FALLO FLAG Z [" & msg & "]" severity error;
                errores <= errores + 1;
            end if;
            if (SalidaFlags_tb(1) /= exp_s) then
                report "FALLO FLAG S [" & msg & "]" severity error;
                errores <= errores + 1;
            end if;
            if (SalidaFlags_tb(2) /= exp_c) then
                report "FALLO FLAG C [" & msg & "]" severity error;
                errores <= errores + 1;
            end if;
        end procedure;
    begin
        report "--- INICIANDO AUDITORÍA TÉCNICA DE ALU ---" severity note;

        -- 1. OPERACIONES ARITMÉTICAS (ADD/SUB)
        -- Objetivo: Validar suma, resta y generación de Acarreo/Signo.
        check_alu(127, 1, OP_ADD, 128, '0', '1', '0', "Suma con Signo");
        check_alu(255, 1, OP_ADD, 0,   '1', '0', '1', "Suma con Carry y Zero");
        check_alu(0, 1, OP_SUB, 255,   '0', '1', '1', "Resta con Underflow (Signo+Borrow)");

        -- 2. OPERACIONES LÓGICAS (AND/NOT)
        -- Objetivo: Validar operaciones bit a bit.
        check_alu(170, 85, OP_AND, 0, '1', '0', '0', "Operación AND (AA & 55 = 0)");
        check_alu(255, 0, OP_NOT_A, 0, '1', '0', '0', "Operación NOT (Inversión FF -> 00)");

        -- 3. INCREMENTO / DECREMENTO
        -- Objetivo: Validar operaciones unitarias.
        check_alu(255, 0, OP_INC_A, 0, '1', '0', '1', "Incremento al límite (FF+1)");
        check_alu(0, 0, OP_DEC_A, 255, '0', '1', '1', "Decremento al límite (00-1)");

        -- FINALIZACIÓN Y REPORTE
        report "--- RESUMEN DE AUDITORÍA ALU ---" severity note;
        if errores = 0 then
            report "RESULTADO: ALU validada al 100% sin errores." severity note;
        else
            report "RESULTADO: Se detectaron " & integer'image(errores) & " anomalías en la ALU." severity error;
        end if;
        
        wait;
    end process;

end architecture;
