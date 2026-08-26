-- ==============================================================================
-- Archivo: tb_unidad_control.vhd
-- Ubicación: tb/
-- Descripción: Testbench robusto para la Unidad de Control.
--              Verifica transiciones de estado y señales de control generadas.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity tb_unidad_control is
end tb_unidad_control;

architecture robust of tb_unidad_control is

    -- Señales de entrada
    signal rst_tb : std_logic := '1';
    signal clk_tb : std_logic := '0';
    signal FZ_tb  : std_logic := '0';
    signal FC_tb  : std_logic := '0'; -- Flag Carry (Nuevo)
    signal FS_tb  : std_logic := '0'; -- Flag Sign (Nuevo)
    signal CO_tb  : std_logic_vector(7 downto 0) := (others => '0');
    signal inicia_in : std_logic := '0';

    -- Señales de salida de la UC
    signal clear, Lpc, Ipc, SelDir, inicia_out, cs, oe, we, LH, LL, Lri, wr, RA, RB, SalAlu, LF : std_logic;
    signal SelRegW, SelRegRA, SelRegRB : std_logic_vector(REG_SEL_W - 1 downto 0);
    signal ope : std_logic_vector(ALU_OP_WIDTH - 1 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    
    -- Registro de fallos
    signal errores : integer := 0;

    -- Procedimiento para verificar un conjunto de señales críticas
    procedure check_control(
        constant msg : in string;
        constant exp_cs, exp_oe, exp_we : in std_logic;
        constant exp_Lri, exp_Ipc : in std_logic;
        signal err_cnt : inout integer
    ) is
    begin
        if (cs /= exp_cs or oe /= exp_oe or we /= exp_we) then
            report "ERROR MEMORIA [" & msg & "]: cs=" & std_logic'image(cs) & " oe=" & std_logic'image(oe) & " we=" & std_logic'image(we)
            severity error;
            err_cnt <= err_cnt + 1;
        end if;
        
        if (Lri /= exp_Lri) then
            report "ERROR Lri [" & msg & "]" severity error;
            err_cnt <= err_cnt + 1;
        end if;
        
        if (Ipc /= exp_Ipc) then
            report "ERROR Ipc [" & msg & "]" severity error;
            err_cnt <= err_cnt + 1;
        end if;
    end procedure;

begin

    -- Instancia de la Unidad de Control (DUT)
    DUT: entity work.unidad_control port map (
        rst => rst_tb, clk => clk_tb, FZ => FZ_tb, FC => FC_tb, FS => FS_tb, CO => CO_tb,
        clear => clear, Lpc => Lpc, Ipc => Ipc, SelDir => SelDir, 
        inicia => inicia_in, cs => cs, oe => oe, we => we, 
        LH => LH, LL => LL, Lri => Lri, SelRegW => SelRegW, 
        wr => wr, RA => RA, SelRegRA => SelRegRA, RB => RB, 
        SelRegRB => SelRegRB, ope => ope, SalAlu => SalAlu, LF => LF
    );

    -- Generador de Reloj compatible con ModelSim/Quartus
    clk_process :process
    begin
        clk_tb <= '0'; wait for CLK_PERIOD/2;
        clk_tb <= '1'; wait for CLK_PERIOD/2;
    end process;

    -- Proceso principal de estímulos y validación
    stim_proc: process
    begin
        report "--- INICIANDO AUDITORÍA DE UNIDAD DE CONTROL ---" severity note;

        -- 1. PRUEBA: Reset del Sistema
        -- Objetivo: Verificar que el procesador limpie señales y entre en ESPERA.
        rst_tb <= '1'; wait for CLK_PERIOD * 2;
        assert (clear = '1') report "FALLO: Señal clear no se activó en Reset" severity error;
        if clear /= '1' then errores <= errores + 1; end if;
        
        -- 2. PRUEBA: Estado de ESPERA
        -- Objetivo: El procesador no debe avanzar a FETCH si inicia = '0'.
        rst_tb <= '0';
        wait for CLK_PERIOD * 2;
        check_control("ESPERA", '0', '0', '0', '0', '0', errores);
        
        -- 3. PRUEBA: Ciclo de FETCH (Arranque)
        -- Objetivo: Validar FETCH1 y FETCH2 tras activar señal 'inicia'.
        inicia_in <= '1';
        wait for CLK_PERIOD; -- FETCH1
        check_control("FETCH1", '1', '1', '0', '0', '0', errores);
        
        wait for CLK_PERIOD; -- FETCH2
        check_control("FETCH2", '1', '1', '0', '1', '1', errores);
        
        -- 4. PRUEBA: Decodificación Dinámica (ADD R2)
        -- Objetivo: Verificar que se extraiga el registro R2 (binario 010) del Opcode.
        -- Opcode ADD = 00001 -> CO = 00001 010 = 0x0A
        CO_tb <= x"0A"; 
        wait for CLK_PERIOD; -- Estado DECODE
        wait for CLK_PERIOD; -- Estado EXEC_ALU
        assert (RA = '1' and wr = '1' and SelRegW = "010" and ope = OP_ADD)
            report "FALLO: Señales de EXEC_ALU (ADD R2) incorrectas" severity error;
        if not (RA = '1' and wr = '1' and SelRegW = "010" and ope = OP_ADD) then 
            errores <= errores + 1; 
        end if;

        -- 5. PRUEBA: Saltos Condicionales (JZ)
        -- Objetivo: Verificar salto si FZ = '1'.
        CO_tb <= x"89"; -- JZ (Opcode 10001 & 001, aunque reg no importa en JMP) -> 0x89
        FZ_tb <= '1';
        wait for CLK_PERIOD * 3; -- Pasar por FETCHs y DECODE
        assert (Lpc = '1') report "FALLO: Salto JZ no se ejecutó con FZ=1" severity error;
        if Lpc /= '1' then errores <= errores + 1; end if;

        -- FINALIZACIÓN Y REPORTE
        report "--- RESUMEN DE AUDITORÍA UC ---" severity note;
        if errores = 0 then
            report "RESULTADO: Todas las pruebas pasaron exitosamente." severity note;
        else
            report "RESULTADO: Se detectaron " & integer'image(errores) & " fallos técnicos." severity error;
        end if;
        
        wait;
    end process;

end architecture;
