library ieee;
use ieee.std_logic_1164.all;

entity unidad_control is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        Flags    : in  std_logic_vector(7 downto 0);
        CO       : in  std_logic_vector(7 downto 0);
        clear    : out std_logic;
        Lpc      : out std_logic;
        Ipc      : out std_logic;
        SelDir   : out std_logic;
        inicia   : out std_logic;
        cs       : out std_logic;
        oe       : out std_logic;
        we       : out std_logic;
        LH       : out std_logic;
        LL       : out std_logic;
        Lri      : out std_logic;
        SelRegW  : out std_logic_vector(2 downto 0);
        SelRegRA : out std_logic_vector(2 downto 0);
        SelRegRB : out std_logic_vector(2 downto 0);
        wr       : out std_logic;
        ope      : out std_logic_vector(2 downto 0);
        SalAlu   : out std_logic;
        LF       : out std_logic;
        fin      : out std_logic
    );
end entity;

architecture rtl of unidad_control is

    type state_type is (S00, S01, S02, S03, S04, S05, S06, S07, S08, 
                        S09, S10, S11, S12, S13, S14, S15, S16, S17, S18, S19);
    signal current_state, next_state : state_type;

    -- Flags mapping
    alias FZ : std_logic is Flags(0);
    alias FS : std_logic is Flags(1);
    alias FC : std_logic is Flags(2);

begin

    -- Proceso secuencial
    process(clk, rst)
    begin
        if rst = '1' then
            current_state <= S00;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;

    -- Proceso combinacional de estado siguiente y salidas
    process(current_state, CO, FZ, FS, FC)
    begin
        -- Valores por defecto (Salidas a 0, cs y oe a 1 por ser activas en bajo)
        clear    <= '0';
        Lpc      <= '0';
        Ipc      <= '0';
        SelDir   <= '0';
        inicia   <= '0';
        cs       <= '1';
        oe       <= '1';
        we       <= '0';
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
            when S00 =>
                clear  <= '1';
                inicia <= '1';
                next_state <= S01;

            when S01 => -- FETCH0: RI <- M(PC)
                cs  <= '0';
                oe  <= '0';
                Lri <= '1';
                next_state <= S02;

            when S02 => -- FETCH1: PC <- PC + 1, Decode
                Ipc <= '1';
                case CO is
                    when x"70" | x"71" | x"80" | x"81" | x"82" | x"83" => next_state <= S03;
                    when x"40" => next_state <= S15;
                    when x"41" => next_state <= S16;
                    when x"42" => next_state <= S17;
                    when x"43" => next_state <= S18;
                    when x"44" => next_state <= S19;
                    when x"45" => next_state <= S09;
                    when x"46" => next_state <= S10;
                    when x"47" => next_state <= S12;
                    when x"FF" => next_state <= S11;
                    when others => next_state <= S01;
                end case;

            when S03 => -- L <- M(PC)
                cs <= '0';
                oe <= '0';
                LL <= '1';
                next_state <= S04;

            when S04 => -- PC <- PC + 1
                Ipc <= '1';
                next_state <= S05;

            when S05 => -- H <- M(PC)
                cs <= '0';
                oe <= '0';
                LH <= '1';
                next_state <= S06;

            when S06 => -- PC <- PC + 1, Decode for Complex
                Ipc <= '1';
                case CO is
                    when x"70" => next_state <= S07;
                    when x"71" => next_state <= S08;
                    when x"80" => next_state <= S14;
                    when x"81" =>
                        if FZ = '1' then next_state <= S14; else next_state <= S01; end if;
                    when x"82" =>
                        if FC = '1' then next_state <= S14; else next_state <= S01; end if;
                    when x"83" =>
                        if FS = '1' then next_state <= S14; else next_state <= S01; end if;
                    when others => next_state <= S01;
                end case;

            when S07 => -- LOAD4: R1 <- M(HL)
                SelDir  <= '1';
                cs      <= '0';
                oe      <= '0';
                SelRegW <= "001";
                wr      <= '1';
                next_state <= S01;

            when S08 => -- STORE5: M(HL) <- ALU(A), A=R1
                SelDir   <= '1';
                cs       <= '0';
                we       <= '1';
                SelRegRA <= "001";
                ope      <= "000";
                SalAlu   <= '1';
                next_state <= S01;

            when S09 => -- ADD0: R1 <- R0 + R1
                SelRegW  <= "001";
                SelRegRA <= "000";
                SelRegRB <= "001";
                ope      <= "101";
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            when S10 => -- MOV0: R0 <- R1
                SelRegW  <= "000";
                SelRegRA <= "001";
                ope      <= "000";
                SalAlu   <= '1';
                wr       <= '1';
                -- LF no se actualiza en MOV (ver MICRO_INSTRUCCIONES)
                next_state <= S01;

            when S11 => -- FIN0: Halt
                fin <= '1';
                next_state <= S11;

            when S12 => -- MOVI0: R1 <- M(PC)
                cs      <= '0';
                oe      <= '0';
                SelRegW <= "001";
                wr      <= '1';
                next_state <= S13;

            when S13 => -- MOVI1: PC <- PC + 1
                Ipc <= '1';
                next_state <= S01;

            when S14 => -- STORE5 (Jumps): PC <- HL
                -- Este estado solo se alcanza si el salto es incondicional o la condición se cumplió.
                Lpc <= '1';
                next_state <= S01;

            when S15 => -- NOT0: R1 <- not R1
                SelRegW  <= "001";
                SelRegRA <= "001";
                ope      <= "011";
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            when S16 => -- AND0: R1 <- R0 and R1
                SelRegW  <= "001";
                SelRegRA <= "000";
                SelRegRB <= "001";
                ope      <= "010";
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            when S17 => -- DEC0: R1 <- R1 - 1
                SelRegW  <= "001";
                SelRegRA <= "001";
                ope      <= "100";
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            when S18 => -- INC0: R1 <- R1 + 1
                SelRegW  <= "001";
                SelRegRA <= "001";
                ope      <= "111";
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            when S19 => -- SUB0: R1 <- R0 - R1
                SelRegW  <= "001";
                SelRegRA <= "000";
                SelRegRB <= "001";
                ope      <= "110";
                SalAlu   <= '1';
                wr       <= '1';
                LF       <= '1';
                next_state <= S01;

            when others =>
                next_state <= S00;
        end case;
    end process;

end architecture;
