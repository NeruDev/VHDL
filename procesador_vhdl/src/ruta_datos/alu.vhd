-- ==============================================================================
-- Archivo: alu.vhd
-- Ubicación: src/ruta_datos/
-- Descripción: Unidad Aritmético Lógica (ALU) - VERSIÓN CORREGIDA.
-- ==============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.procesador_pkg.all;

entity alu is
    Port ( 
        SalA        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        SalB        : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        ope         : in  std_logic_vector(ALU_OP_WIDTH - 1 downto 0);
        
        SalidaALU   : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        SalidaFlags : out std_logic_vector(7 downto 0) 
    );
end alu;

architecture Comportamiento of alu is
    signal res_temp : unsigned(DATA_WIDTH downto 0); 
    signal a_uns    : unsigned(DATA_WIDTH downto 0);
    signal b_uns    : unsigned(DATA_WIDTH downto 0);
    
    signal flag_z   : std_logic;
    signal flag_s   : std_logic;
    signal flag_c   : std_logic;
begin
    -- Expansión a 9 bits para capturar Carry/Borrow
    a_uns <= unsigned('0' & SalA);
    b_uns <= unsigned('0' & SalB);

    process(a_uns, b_uns, ope)
        variable res_var : unsigned(DATA_WIDTH downto 0);
    begin
        res_var := (others => '0');
        flag_c  <= '0'; 

        case ope is
            when "000" => -- OP_TRANS_A
                res_var := a_uns;
            when "001" => -- OP_TRANS_B
                res_var := b_uns;
            when "010" => -- OP_AND
                res_var := a_uns and b_uns;
            when "011" => -- OP_NOT_A
                res_var := not a_uns;
            when "100" => -- OP_DEC_A
                res_var := a_uns - 1;
                flag_c  <= res_var(8);
            when "101" => -- OP_ADD
                res_var := a_uns + b_uns;
                flag_c  <= res_var(8);
            when "110" => -- OP_SUB
                res_var := a_uns - b_uns;
                flag_c  <= res_var(8);
            when "111" => -- OP_INC_A
                res_var := a_uns + 1;
                flag_c  <= res_var(8);
            when others =>
                res_var := (others => '0');
        end case;
        
        res_temp <= res_var;
    end process;

    SalidaALU <= std_logic_vector(res_temp(7 downto 0));

    flag_z <= '1' when res_temp(7 downto 0) = x"00" else '0';
    flag_s <= res_temp(7);
    SalidaFlags <= "00000" & flag_c & flag_s & flag_z;

end Comportamiento;
