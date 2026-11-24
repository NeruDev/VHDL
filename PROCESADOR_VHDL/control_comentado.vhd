-- ############################################################################
-- #  UNIDAD DE CONTROL (FSM TIPO MOORE) - MICROPROCESADOR BASICO DE 8 BITS   #
-- #  Solo comentarios: la logica original no fue modificada ni optimizada.   #
-- #  Teoria, tablas y guias de modificacion: guia_microprocesador.md        #
-- ############################################################################
--
-- ============================================================================
--  CONVENCIONES (necesarias para modificar el codigo)
-- ============================================================================
--   cs, oe : activos en '0'     we : activo en '1'     demas salidas : '1'
--   Leer memoria  = cs <= '0'; oe <= '0';
--   Escribir      = cs <= '0'; we <= '1';   (oe se queda en '1')
--   VHDL no distingue mayusculas: "lF" y "LF" son la MISMA senal.
--   Cada estado dura 1 ciclo: lo que se activa en el estado N se captura en
--   el flanco que cierra N y se ve en N+1 (Lri en S01 -> CO valido en S02).
--   Regla del bus: nunca SalAlu='1' junto con oe='0' (dos emisores en BusDatos).
--   Regla del PC: un Ipc por cada byte de la instruccion (S02, S04, S06, S13).
--   Registros: R0 = "000", R1 = "001". Casi todo escribe su resultado en R1.
--
-- ============================================================================
--  MAPA RAPIDO DE OPCODES (CO -> estados)
-- ============================================================================
--   40 NOT S15 | 41 AND S16 | 42 DEC S17 | 43 INC S18 | 44 SUB S19 | 45 ADD S09
--   46 MOV S10 | 47 MOVI S12,S13 | FF FIN S11
--   70 LOAD  : S03..S07          71 STORE : S03..S06,S08
--   80 JMP, 81 JZ (Flags(0)=Z), 82 JC (Flags(1)=C), 83 JS (Flags(2)=S):
--      S03..S06 y luego S14 (si la condicion se cumple) o S01 (si no)
--   Los opcodes aparecen SOLO en S02 y (los de 3 bytes) en S06.
--
-- ============================================================================
--  CODIGOS ope DE LA ALU (la ALU de Logisim decide que hace cada uno)
-- ============================================================================
--   000 A (paso directo) | 010 A and B | 011 not A | 100 A-1
--   101 A+B | 110 A-B | 111 A+1 | 001 LIBRE (no usado)
--
-- ============================================================================
--  PARA AGREGAR UNA INSTRUCCION / ESTADO (detalle en guia_microprocesador.md)
-- ============================================================================
--   1) type ESTADOS [2.1]: declarar el estado nuevo.
--   2) PROCESO 2 [4]: "when Sxx => edo_sig <= ...". Si se olvida, "others"
--      manda a S00 y la CPU se reinicia.
--   3) S02 [4.2]: nueva rama "elsif CO = x"xx" then edo_sig <= Sxx;"
--      (si lleva direccion: enviarlo a S03 y agregar su rama en S06).
--   4) PROCESO 3 [5]: "when Sxx" con idEstado unico (5 bits, maximo 31) y las
--      senales necesarias.
--   5) Si usa un ope nuevo, implementarlo en la ALU de Logisim.
--
-- ============================================================================
--  INDICE
-- ============================================================================
--   [0] Librerias   [1] Entidad   [2] Declaraciones   [3] Proceso 1 (estado)
--   [4] Proceso 2 (estado siguiente)   [5] Proceso 3 (salidas)
-- ============================================================================


-- ############################################################################
-- [0] LIBRERIAS
-- ############################################################################
library ieee;
use ieee.std_logic_1164.all;   -- tipos std_logic y std_logic_vector
use ieee.numeric_std.all;      -- no se usa directamente, queda disponible


-- ############################################################################
-- [1] ENTIDAD: PUERTOS DE LA UNIDAD DE CONTROL
-- ############################################################################
entity control is
  port (
    -- ------------------------------------------------------------------
    -- 1.1 RELOJ Y REINICIO
    -- ------------------------------------------------------------------
    clk: in std_logic;                 -- Reloj: la FSM cambia de estado en el flanco de subida
    rst: in std_logic;                 -- Reset asincrono, activo en '1': fuerza S00

    -- ------------------------------------------------------------------
    -- 1.2 ENTRADAS DE ESTADO DEL PROCESADOR
    -- ------------------------------------------------------------------
    Flags: in std_logic_vector (7 downto 0);  -- Banderas de la ALU; solo bits 0 (Z), 1 (C) y 2 (S)
    CO: in std_logic_vector (7 downto 0);     -- Codigo de operacion: salida del Registro de Instruccion

    -- ------------------------------------------------------------------
    -- 1.3 PC Y DIRECCIONAMIENTO
    -- ------------------------------------------------------------------
    clear: out std_logic;              -- Limpia la ruta de datos (solo en S00)
    Lpc, Ipc, SelDir: out std_logic;   -- Lpc: PC <- HL | Ipc: PC <- PC + 1
                                       -- SelDir: 0 = memoria direccionada por PC, 1 = por HL

    -- ------------------------------------------------------------------
    -- 1.4 MEMORIA
    -- ------------------------------------------------------------------
    inicia, cs, oe, we: out std_logic; -- inicia: arranque (S00; destino exacto no documentado)
                                       -- cs: chip select (activo en '0')
                                       -- oe: salida de memoria al bus (activo en '0')
                                       -- we: escritura en memoria (activo en '1')

    -- ------------------------------------------------------------------
    -- 1.5 REGISTROS H, L Y RI
    -- ------------------------------------------------------------------
    LH, LL, Lri: out std_logic;        -- Cargan H, L y RI desde el bus de datos

    -- ------------------------------------------------------------------
    -- 1.6 BANCO DE REGISTROS
    -- ------------------------------------------------------------------
    SelRegW, SelRegRA, SelRegRB: out std_logic_vector (2 downto 0);
                                       -- SelRegW: destino | SelRegRA: puerto A | SelRegRB: puerto B
    wr: out std_logic;                 -- Habilita la escritura en el registro SelRegW

    -- ------------------------------------------------------------------
    -- 1.7 ALU Y BANDERAS
    -- ------------------------------------------------------------------
    ope: out std_logic_vector (2 downto 0);  -- Operacion de la ALU (ver tabla de codigos arriba)
    SalAlu, LF: out std_logic;         -- SalAlu: buffer de la ALU hacia el bus | LF: carga las banderas

    -- ------------------------------------------------------------------
    -- 1.8 SUPERVISION
    -- ------------------------------------------------------------------
    fin: out std_logic;                -- '1' cuando el procesador se detuvo (FIN, S11)
    idEstado: out std_logic_vector (4 downto 0)  -- Numero del estado actual (sondas/displays)
  );
end entity control;


-- ############################################################################
-- [2] ARQUITECTURA: DECLARACIONES
-- ############################################################################
architecture una of control is
  -- 2.1 Estados. S00 reset | S01-S02 busqueda | S03-S06 lectura de HL |
  --     S07-S08 memoria | S09,S15-S19 ALU | S10,S12,S13 transferencia |
  --     S11 FIN | S14 salto.
  type ESTADOS is (S00, S01, S02, S03, S04, S05, S06, S07, 
              S08, S09, S10, S11, S12, S13, S14, S15, 
              S16, S17, S18, S19);

  -- 2.2 edo_pre = estado presente (flip-flops) | edo_sig = estado siguiente
  signal edo_pre, edo_sig: ESTADOS; 
begin

  -- ##########################################################################
  -- [3] PROCESO 1: REGISTRO DE ESTADO (unica parte con reloj)
  --     rst='1' -> reset asincrono a S00. Solo afecta a la FSM: la ruta de
  --     datos se limpia con la salida clear que genera S00.
  -- ##########################################################################
  -- Controladora Actualizar Registros
  process(clk, rst)
  begin
    if (rst='1') then
      edo_pre <= S00;                  -- Reset: vuelve al estado inicial
    elsif (clk'event and clk='1') then -- Flanco de subida del reloj
      edo_pre <= edo_sig;              -- Avanza al estado calculado
    end if;
  end process;  

  -- ##########################################################################
  -- [4] PROCESO 2: ESTADO SIGUIENTE (combinacional)
  --     Depende de edo_pre, CO y Flags (Flags debe estar en la lista de
  --     sensibilidad por los saltos condicionales).
  -- ##########################################################################
  -- Controladora Estado siguiente  
  process (edo_pre, CO, Flags)
  begin
    -- buenas practicas
    -- Por defecto la FSM retiene su estado (evita latches).
    edo_sig <= edo_pre;
    
    case (edo_pre) is

    -- ======================================================================
    -- 4.1 ARRANQUE Y BUSQUEDA
    -- ======================================================================
    when S00 =>                        -- Reset -> siempre a buscar instruccion
      edo_sig <= S01;
    when S01 =>                        -- Busqueda (RI <- M(PC))
      edo_sig <= S02;

    -- ======================================================================
    -- 4.2 S02: DECODIFICACION (unico lugar que asocia opcode -> ejecucion)
    --     CO ya es valido (Lri se activo en S01). Ipc se activa en este mismo
    --     estado: el PC cambia al FINAL de S02, por eso en S03 y S12 ya
    --     apunta al byte que sigue al opcode.
    -- ======================================================================
    when S02 =>
      -- Instrucciones de 3 bytes (codigo + L + H): LOAD, STORE, JMP, JZ, JC, JS
      if (CO = x"70") or (CO = x"71") or (CO = x"80")
        or (CO = x"81") or (CO = x"82") or (CO = x"83") then
        edo_sig <= S03;
      -- Instrucciones de 1 byte: un solo estado de ejecucion
      elsif CO = x"40" then            -- NOT R1
        edo_sig <= S15;
      elsif CO = x"41" then            -- AND (R1 <- R0 and R1)
        edo_sig <= S16;
      elsif CO = x"42" then            -- DEC R1
        edo_sig <= S17;
      elsif CO = x"43" then            -- INC R1
        edo_sig <= S18;
      elsif CO = x"44" then            -- SUB (R1 <- R0 - R1)
        edo_sig <= S19;
      elsif CO = x"45" then            -- ADD (R1 <- R0 + R1)
        edo_sig <= S09;
      elsif CO = x"46" then            -- MOV (R0 <- R1)
        edo_sig <= S10;
      elsif CO = x"47" then            -- MOVI (2 bytes: codigo + dato inmediato)
        edo_sig <= S12;
      elsif CO = x"FF" then            -- FIN
        edo_sig <= S11;
      else                             -- Opcode desconocido: NOP (el PC ya avanzo en S02)
        edo_sig <= S01;
      end if;

    -- ======================================================================
    -- 4.3 LECTURA DE LA DIRECCION (instrucciones de 3 bytes)
    --     S03: L <- M(PC) | S04: PC+1 | S05: H <- M(PC) | S06: PC+1
    -- ======================================================================
    when S03 => 
        edo_sig <= S04;
    when S04 => 
        edo_sig <= S05;
    when S05 => 
        edo_sig <= S06;

    -- S06: segundo bifurcador. La decision del salto condicional se toma AQUI
    -- con las banderas vigentes; S14 no vuelve a revisarlas. Si la condicion no
    -- se cumple se vuelve a S01 (el PC ya apunta a la instruccion siguiente,
    -- 6 ciclos en total). No hay "else" final: solo se llega con estos 6 CO.
    when S06 =>
      if CO = x"70" then               -- LOAD
        edo_sig <= S07;
      elsif CO = x"71" then            -- STORE
        edo_sig <= S08;
      elsif CO = x"80" then            -- JMP (incondicional)
        edo_sig <= S14;
      elsif CO = x"81" and Flags(0) = '1' then
        edo_sig <= S14;                -- JZ salta (Z=1)
      elsif CO = x"81" and Flags(0) = '0' then
        edo_sig <= S01;                -- JZ no salta
      elsif CO = x"82" and Flags(1) = '1' then
        edo_sig <= S14;                -- JC salta (C=1)
      elsif CO = x"82" and Flags(1) = '0' then
        edo_sig <= S01;                -- JC no salta
      elsif CO = x"83" and Flags(2) = '1' then
        edo_sig <= S14;                -- JS salta (S=1)
      elsif CO = x"83" and Flags(2) = '0' then
        edo_sig <= S01;                -- JS no salta
      end if;  

    -- ======================================================================
    -- 4.4 EJECUCION (casi todos regresan a S01)
    -- ======================================================================
    when S07 =>                        -- Fin de LOAD
      edo_sig <= S01;
    when S08 =>                        -- Fin de STORE
      edo_sig <= S01;
    when S09 =>                        -- Fin de ADD
      edo_sig <= S01;
    when S10 =>                        -- Fin de MOV
      edo_sig <= S01;
    when S11 =>                        -- FIN: se queda aqui; solo un reset sale
      edo_sig <= S11;
    when S12 =>                        -- MOVI: tras leer el inmediato, S13 avanza el PC
      edo_sig <= S13;                  -- (S13 es reutilizable por otras instrucciones con inmediato)
    when S13 =>                        -- Fin de MOVI
      edo_sig <= S01;
    when S14 =>                        -- Fin de salto (PC <- HL ya hecho)
      edo_sig <= S01;
    when S15 =>                        -- Fin de NOT
      edo_sig <= S01;
    when S16 =>                        -- Fin de AND
      edo_sig <= S01;
    when S17 =>                        -- Fin de DEC
      edo_sig <= S01;
    when S18 =>                        -- Fin de INC
      edo_sig <= S01;
    when S19 =>                        -- Fin de SUB
      edo_sig <= S01;

    -- Proteccion: estado ilegal -> S00 (reinicia la CPU y reactiva clear).
    -- Tambien es lo que ocurre si se agrega un estado y se olvida su "when".
    when others =>
      edo_sig <= S00;
    end case;
  end process;

  -- ##########################################################################
  -- [5] PROCESO 3: SALIDAS (combinacional, FSM tipo Moore: solo edo_pre)
  --     Receta de un estado de ALU: orígenes (SelRegRA/RB), operacion (ope),
  --     buffer (SalAlu), destino (SelRegW + wr) y banderas (LF).
  -- ##########################################################################
  -- Controladora Salidas
  process (edo_pre)
  begin
    -- ----------------------------------------------------------------------
    -- 5.1 VALORES POR DEFECTO ("buenas practicas")
    --     Todo inactivo; cada estado solo escribe lo que necesita. Memoria
    --     deshabilitada (cs='1', oe='1', we='0').
    -- ----------------------------------------------------------------------
    -- buenas practicas
    idEstado <= "00000";
    clear <= '0';
    Lpc <= '0';
    Ipc <= '0';
    SelDir <= '0';                     -- 0 = la memoria se direcciona con PC
    inicia <= '0';
    cs <= '1';                         -- memoria NO seleccionada (activo en bajo)
    oe <= '1';                         -- salida de memoria deshabilitada (activo en bajo)
    we <= '0';                         -- escritura deshabilitada
    LH <= '0';
    LL <= '0';
    Lri <= '0';
    SelRegW <= "000";
    SelRegRA <= "000";
    SelRegRB <= "000";                 -- OJO: si no se asigna, el puerto B lee R0
    wr <= '0';
    ope <= "000";
    SalAlu <= '0';                     -- la ALU no maneja el bus de datos
    LF <= '0';
    fin <= '0';
    
    case (edo_pre) is

    -- ======================================================================
    -- 5.2 SALIDAS POR ESTADO
    -- ======================================================================

    -- ---------------- S00: REINICIO ----------------
    when S00 =>            -- Reset
      idEstado <= "00000";
      clear <= '1';                    -- Limpia la ruta de datos (PC, HL, RI, BR, FLAGS)
      inicia <= '1';                   -- Senal de arranque

    -- ---------------- BUSQUEDA (S01 - S02) ----------------
    when S01 =>            -- RI <- M(PC)
      idEstado <= "00001";
      cs <= '0';                       -- Selecciona la memoria
      oe <= '0';                       -- La memoria pone el dato en el bus (SelDir=0 -> PC)
      Lri <= '1';                      -- El RI captura el opcode
    when S02 =>            -- PC <- PC + 1
      idEstado <= "00010";
      Ipc <= '1';

    -- ---------------- LECTURA DE HL (S03 - S06) ----------------
    when S03 =>           -- L <- M(PC)
      idEstado <= "00011";
      cs <= '0';
      oe <= '0';
      LL <= '1';                       -- Primer byte tras el opcode = L
    when S04 =>            -- PC <- PC + 1
      idEstado <= "00100";
      Ipc <= '1';
    when S05 =>           -- H <- M(PC)
      idEstado <= "00101";
      cs <= '0';
      oe <= '0';
      LH <= '1';                       -- Segundo byte = H
    when S06 =>            -- PC <- PC + 1
      idEstado <= "00110";
      Ipc <= '1';                      -- PC queda apuntando a la instruccion siguiente

    -- ---------------- MEMORIA (S07 - S08) ----------------
    when S07 =>            -- R1 <- M(HL)   (LOAD)
      idEstado <= "00111";
      SelDir <= '1';                   -- Direcciona con HL (no con PC)
      cs <= '0';
      oe <= '0';                       -- La memoria pone el dato en el bus
      SelRegW <= "001";                -- Destino: R1
      wr <= '1';                       -- Sin LF: LOAD no actualiza banderas
    when S08 =>            -- SalA <- R1; M(HL) <- ALU(A)   (STORE)
      idEstado <= "01000";
      SelDir <= '1';                   -- Direcciona con HL
      cs <= '0';
      we <= '1';                       -- ESCRITURA (oe queda en '1'). La tabla del profesor muestra
                                       -- [we, L]: verificar la polaridad de we en la RAM de Logisim.
      SelRegRA <= "001";               -- Puerto A <- R1
      ope <= "000";                    -- ALU: paso directo
      SalAlu <= '1';                   -- La ALU pone R1 en el bus

    -- ---------------- ALU Y TRANSFERENCIA ----------------
    when S09 =>           -- SalA <- R0; SalB <- R1; R1 <- ALU(A+B)
      idEstado <= "01001";             -- ADD
      SelRegW <= "001";
      wr <= '1';
      SelRegRA <= "000";               -- A = R0
      SelRegRB <= "001";               -- B = R1
      ope <= "101";                    -- Suma
      SalAlu <= '1';
      lF <= '1';                       -- Actualiza banderas
    when S10 =>            -- SalA <- R1; R0 <- ALUA(A)
      idEstado <= "01010";             -- MOV R0 <- R1
      SelRegW <= "000";                -- Destino: R0
      wr <= '1';
      SelRegRA <= "001";               -- A = R1
      ope <= "000";                    -- Paso directo
      SalAlu <= '1';                   -- Sin LF: MOV no cambia las banderas

    -- ---------------- FIN ----------------
    when S11 =>            -- Fin
      idEstado <= "01011";
      fin <= '1';

    -- ---------------- CARGA INMEDIATA (S12 - S13) ----------------
    when S12 =>            -- R1 <- M(PC)   (MOVI)
      idEstado <= "01100";
      cs <= '0';
      oe <= '0';                       -- Lee el byte inmediato (direcciona con PC)
      SelRegW <= "001";
      wr <= '1';                       -- Sin LF: MOVI no actualiza banderas
    when S13 =>            -- PC <- PC + 1
      idEstado <= "01101";
      Ipc <= '1';                      -- Salta el inmediato para no ejecutarlo como opcode

    -- ---------------- SALTO ----------------
    when S14 =>           -- PC <- HL
      idEstado <= "01110";
      Lpc <= '1';                      -- Carga el PC con HL
                                       -- SelDir NO se activa: la carga del PC sale directo de HL.

    -- ---------------- MAS ALU ----------------
    when S15 =>           -- SalA <- R1; R1 <- ALU(notA)
      idEstado <= "01111";             -- NOT R1
      SelRegW <= "001";
      wr <= '1';
      SelRegRA <= "001";
      ope <= "011";
      SalAlu <= '1';
      lF <= '1';
    when S16 =>           -- SalA <- R0; SalB <- R1; R1 <- ALU(AandB)
      idEstado <= "10000";             -- AND
      SelRegW <= "001";
      wr <= '1';
      SelRegRA <= "000";               -- A = R0
      SelRegRB <= "001";               -- B = R1
      ope <= "010";
      SalAlu <= '1';
      lF <= '1';
    when S17 =>           -- SalA <- R1; R1 <- ALU(A-1)
      idEstado <= "10001";             -- DEC R1
      SelRegW <= "001";
      wr <= '1';
      SelRegRA <= "001";
      ope <= "100";
      SalAlu <= '1';
      lF <= '1';
    when S18 =>           -- SalA <- R1; R1 <- ALU(A+1)
      idEstado <= "10010";             -- INC R1
      SelRegW <= "001";
      wr <= '1';
      SelRegRA <= "001";
      ope <= "111";
      SalAlu <= '1';
      lF <= '1';
    when S19 =>           -- SalA <- R0; SalB <- R1; R1 <- ALU(A-B)
      idEstado <= "10011";             -- SUB
      SelRegW <= "001";
      wr <= '1';
      SelRegRA <= "000";               -- A = R0
      SelRegRB <= "001";               -- B = R1
      ope <= "110";                    -- Resta (R0 - R1)
      SalAlu <= '1';
      lF <= '1';

    -- ---------------- ESTADO ILEGAL ----------------
    when others =>
--      null;
      idEstado <= "11111";             -- Codigo de error (solo con un edo_pre invalido)
    end case;
  end process;
end architecture una;
