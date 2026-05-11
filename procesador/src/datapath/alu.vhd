--------------------------------------------------------------------------------
-- Entidad: alu
-- Arquitectura: rtl
-- Descripción: Unidad Lógico Aritmética (ALU) de 8 bits. Realiza operaciones 
--              aritméticas y lógicas básicas, y genera banderas de estado.
-- Referencias: Proyecto/ARCHIVOS_BASE/MICRO_INSTRUCCIONES.md (Códigos de op.)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.procesador_pkg.all;

entity alu is
    port (
        SalA      : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Operando A (desde bus RA)
        SalB      : in  std_logic_vector(DATA_WIDTH-1 downto 0); -- Operando B (desde bus RB)
        ope       : in  std_logic_vector(2 downto 0);            -- Selector de operación
        SalidaALU : out std_logic_vector(DATA_WIDTH-1 downto 0); -- Resultado de la operación
        Z         : out std_logic;                                -- Zero Flag: 1 si resultado es 0
        S         : out std_logic;                                -- Sign Flag: bit MSB del resultado
        C         : out std_logic                                 -- Carry Flag: Acarreo o préstamo
    );
end entity;

architecture rtl of alu is
begin
    ----------------------------------------------------------------------------
    -- Proceso combinacional para el cálculo de la operación
    ----------------------------------------------------------------------------
    process(SalA, SalB, ope)
        -- Variables de 9 bits para capturar el acarreo (Carry) en operaciones aritméticas
        variable res_9bit : unsigned(DATA_WIDTH downto 0);
        variable a_9bit   : unsigned(DATA_WIDTH downto 0);
        variable b_9bit   : unsigned(DATA_WIDTH downto 0);
        variable res_8bit : std_logic_vector(DATA_WIDTH-1 downto 0);
    begin
        -- Preparación de operandos con un bit extra para acarreo
        a_9bit := unsigned('0' & SalA);
        b_9bit := unsigned('0' & SalB);
        res_9bit := (others => '0');

        case ope is
            when "000" => -- PASA A (Bypass): Usado en MOV y STORE
                res_9bit := a_9bit;
            
            when "010" => -- AND: Operación lógica AND bit a bit
                res_9bit := a_9bit and b_9bit;
            
            when "011" => -- NOT A: Inversión lógica bit a bit
                res_9bit := not a_9bit;
                -- Se limpia el bit de acarreo forzadamente para operaciones lógicas
                res_9bit(DATA_WIDTH) := '0';
            
            when "100" => -- DEC A: Decremento (A - 1)
                res_9bit := a_9bit - 1;
            
            when "101" => -- ADD: Suma aritmética (A + B)
                res_9bit := a_9bit + b_9bit;
            
            when "110" => -- SUB: Resta aritmética (A - B)
                res_9bit := a_9bit - b_9bit;
            
            when "111" => -- INC A: Incremento (A + 1)
                res_9bit := a_9bit + 1;
            
            when others =>
                res_9bit := a_9bit;
        end case;

        -- El resultado final son los 8 bits menos significativos
        res_8bit := std_logic_vector(res_9bit(DATA_WIDTH-1 downto 0));
        
        -- Salida de datos hacia el bus interno
        SalidaALU <= res_8bit;

        ------------------------------------------------------------------------
        -- LÓGICA DE GENERACIÓN DE BANDERAS (FLAGS)
        ------------------------------------------------------------------------
        
        -- Flag Zero: Se activa si todos los bits del resultado son cero
        if res_8bit = x"00" then
            Z <= '1';
        else
            Z <= '0';
        end if;

        -- Flag Signo: Refleja el bit más significativo (MSB), indicando negatividad en C2
        S <= res_8bit(DATA_WIDTH-1);

        -- Flag Carry: Se activa en acarreos de suma o préstamos de resta
        if ope = "100" or ope = "110" then
            -- En resta/decremento, el bit extra indica un préstamo (Borrow)
            C <= res_9bit(DATA_WIDTH);
        elsif ope = "101" or ope = "111" then
            -- En suma/incremento, el bit extra indica un desbordamiento (Carry)
            C <= res_9bit(DATA_WIDTH);
        else
            -- Las operaciones lógicas no afectan el acarreo en esta arquitectura
            C <= '0';
        end if;

    end process;
end architecture;
