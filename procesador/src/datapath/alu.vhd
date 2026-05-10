library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.procesador_pkg.all;

entity alu is
    port (
        SalA      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        SalB      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        ope       : in  std_logic_vector(2 downto 0);
        SalidaALU : out std_logic_vector(DATA_WIDTH-1 downto 0);
        Z         : out std_logic;
        S         : out std_logic;
        C         : out std_logic
    );
end entity;

architecture rtl of alu is
begin
    process(SalA, SalB, ope)
        variable res_9bit : unsigned(DATA_WIDTH downto 0);
        variable a_9bit   : unsigned(DATA_WIDTH downto 0);
        variable b_9bit   : unsigned(DATA_WIDTH downto 0);
        variable res_8bit : std_logic_vector(DATA_WIDTH-1 downto 0);
    begin
        a_9bit := unsigned('0' & SalA);
        b_9bit := unsigned('0' & SalB);
        res_9bit := (others => '0');

        case ope is
            when "000" => -- Pasa A
                res_9bit := a_9bit;
            when "010" => -- AND
                res_9bit := a_9bit and b_9bit;
            when "011" => -- NOT A
                res_9bit := not a_9bit;
                -- Para el NOT lógico, res_9bit(8) (el carry bit 9) sería '1' debido a la negación de '0'.
                -- Lo forzamos a 0 porque es operación lógica.
                res_9bit(DATA_WIDTH) := '0';
            when "100" => -- DEC A
                res_9bit := a_9bit - 1;
            when "101" => -- ADD
                res_9bit := a_9bit + b_9bit;
            when "110" => -- SUB
                res_9bit := a_9bit - b_9bit;
            when "111" => -- INC A
                res_9bit := a_9bit + 1;
            when others =>
                res_9bit := a_9bit;
        end case;

        res_8bit := std_logic_vector(res_9bit(DATA_WIDTH-1 downto 0));
        
        -- Salida de datos
        SalidaALU <= res_8bit;

        -- Flags
        -- Flag Zero
        if res_8bit = x"00" then
            Z <= '1';
        else
            Z <= '0';
        end if;

        -- Flag Signo (Bit más significativo)
        S <= res_8bit(DATA_WIDTH-1);

        -- Flag Carry
        if ope = "100" or ope = "110" then
            -- Para restas, si el bit 8 es 1, hubo préstamo (Borrow). Lo reflejamos en C.
            C <= res_9bit(DATA_WIDTH);
        elsif ope = "101" or ope = "111" then
            -- Para sumas, acarreo.
            C <= res_9bit(DATA_WIDTH);
        else
            -- Para lógicas y pasabajas, carry es 0
            C <= '0';
        end if;

    end process;
end architecture;
