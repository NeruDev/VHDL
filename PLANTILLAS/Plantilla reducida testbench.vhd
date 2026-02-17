---------------------------------------------------------------------
-- PLANTILLA REDUCIDA DE TESTBENCH
---------------------------------------------------------------------

---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
--USE ieee.numeric_std.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
ENTITY tb_plantilla_design_testbench IS
END ENTITY tb_plantilla_design_testbench;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
ARCHITECTURE testbench OF tb_plantilla_design_testbench IS

   -------------------------------------------------------------------
   -- CONSTANTES
   -------------------------------------------------------------------
   --CONSTANT C_CLK_PERIOD : TIME := 10 ns;
   CONSTANT C_DATA_WIDTH : INTEGER := 8;

   -------------------------------------------------------------------
   -- COMPONENTE (DUT)
   -------------------------------------------------------------------
   COMPONENT plantilla_design_testbench IS
      GENERIC (
         G_DATA_WIDTH  : INTEGER
      );
      PORT (
         i_data_a : IN  STD_LOGIC_VECTOR(G_DATA_WIDTH-1 DOWNTO 0);
         i_data_b : IN  STD_LOGIC_VECTOR(G_DATA_WIDTH-1 DOWNTO 0);
         i_sel    : IN  STD_LOGIC;
         o_data   : OUT STD_LOGIC_VECTOR(G_DATA_WIDTH-1 DOWNTO 0)
      );
   END COMPONENT plantilla_design_testbench;

   -------------------------------------------------------------------
   -- SEÑALES
   -------------------------------------------------------------------
   --SIGNAL s_clk      : STD_LOGIC := '0';
   SIGNAL s_data_a   : STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
   SIGNAL s_data_b   : STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);
   SIGNAL s_sel      : STD_LOGIC;
   SIGNAL s_data_out : STD_LOGIC_VECTOR(C_DATA_WIDTH-1 DOWNTO 0);

BEGIN

   -------------------------------------------------------------------
   -- INSTANCIACION DEL DUT
   -------------------------------------------------------------------
   DUT : COMPONENT plantilla_design_testbench
      GENERIC MAP (
         G_DATA_WIDTH  => C_DATA_WIDTH
      )
      PORT MAP (
         i_data_a => s_data_a,
         i_data_b => s_data_b,
         i_sel    => s_sel,
         o_data   => s_data_out
      );

   -------------------------------------------------------------------
   -- GENERADOR DE RELOJ (si es necesario)
   -------------------------------------------------------------------
   --p_clk_gen : PROCESS
   --BEGIN
   --  LOOP
   --    s_clk <= NOT s_clk;
   --    WAIT FOR C_CLK_PERIOD / 2;
   --  END LOOP;
   --END PROCESS p_clk_gen;

   -------------------------------------------------------------------
   -- PROCESO DE ESTIMULOS
   -------------------------------------------------------------------
   p_stimulus : PROCESS
   BEGIN
      -- Secuencia de prueba aquí

      WAIT; -- Detiene la simulación
   END PROCESS p_stimulus;

END ARCHITECTURE testbench;