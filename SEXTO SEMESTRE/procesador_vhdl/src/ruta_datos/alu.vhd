-- ==============================================================================
-- Archivo: alu.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Unidad Aritmético Lógica (ALU) de 8 bits.
--              Realiza operaciones matemáticas y lógicas, y genera banderas
--              de estado (Zero, Sign, Carry).
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity alu is
    Port ( 
        -- ======================================================================
        -- MAPA DE ENTRADAS (Input Map)
        -- ======================================================================
        SalA        : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Operando A (desde BR)
        SalB        : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Operando B (desde BR)
        ope         : in  std_logic_vector(ALU_OP_WIDTH - 1 downto 0); -- Código de operación
        
        -- ======================================================================
        -- MAPA DE SALIDAS (Output Map)
        -- ======================================================================
        SalidaALU   : out std_logic_vector(DATA_WIDTH - 1 downto 0); -- Resultado (8 bits)
        SalidaFlags : out std_logic_vector(7 downto 0) -- Registro de estado (Z, S, C)
    );
end alu;

architecture Comportamiento of alu is
    -- ----------------------------------------------------------------------
    -- SEÑALES INTERNAS
    -- ----------------------------------------------------------------------
    -- Usamos 9 bits (unsigned) para detectar el Carry/Borrow de forma natural
    signal res_temp : unsigned(DATA_WIDTH downto 0); 
    signal a_uns    : unsigned(DATA_WIDTH downto 0);
    signal b_uns    : unsigned(DATA_WIDTH downto 0);
    
    signal flag_z   : std_logic; -- Bandera de Cero
    signal flag_s   : std_logic; -- Bandera de Signo
    signal flag_c   : std_logic; -- Bandera de Acarreo
begin
    -- Preparación de operandos (extensión de signo/cero a 9 bits)
    a_uns <= unsigned('0' & SalA);
    b_uns <= unsigned('0' & SalB);

    -- ----------------------------------------------------------------------
    -- PROCESO COMBINACIONAL: CÁLCULO DE OPERACIONES
    -- ----------------------------------------------------------------------
    process(a_uns, b_uns, ope)
        variable res_var : unsigned(DATA_WIDTH downto 0);
    begin
        res_var := (others => '0');
        flag_c  <= '0'; 

        case ope is
            when OP_TRANS_A => -- Pasa operando A sin cambios
                res_var := a_uns;
            when OP_TRANS_B => -- Pasa operando B sin cambios
                res_var := b_uns;
            when OP_AND     => -- Operación lógica AND
                res_var := a_uns and b_uns;
            when OP_NOT_A   => -- Operación lógica NOT (Inversor)
                res_var := not a_uns;
            when OP_DEC_A   => -- Decremento (A - 1)
                res_var := a_uns - 1;
                flag_c  <= res_var(8); -- Detecta underflow
            when OP_ADD     => -- Suma aritmética
                res_var := a_uns + b_uns;
                flag_c  <= res_var(8); -- Detecta desbordamiento
            when OP_SUB     => -- Resta aritmética
                res_var := a_uns - b_uns;
                flag_c  <= res_var(8); -- Detecta borrow
            when OP_INC_A   => -- Incremento (A + 1)
                res_var := a_uns + 1;
                flag_c  <= res_var(8); -- Detecta desbordamiento
            when others =>
                res_var := (others => '0');
        end case;
        
        res_temp <= res_var;
    end process;

    -- Asignación de salida principal (truncando el bit de acarreo)
    SalidaALU <= std_logic_vector(res_temp(7 downto 0));

    -- Lógica de Banderas
    flag_z <= '1' when res_temp(7 downto 0) = x"00" else '0'; -- Zero si los 8 bits son 0
    flag_s <= res_temp(7); -- Signo es el bit más significativo (MSB)
    
    -- Empaquetado de flags: bit 0=Z, bit 1=S, bit 2=C
    SalidaFlags <= "00000" & flag_c & flag_s & flag_z;

end Comportamiento;
