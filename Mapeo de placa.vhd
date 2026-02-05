---------------------------------------------------------------------
-- DISEÑO: Mapeo de Periféricos Placa Cyclone II
-- AUTOR: Gemini Code Assist
-- PROPOSITO: Realizar una conexión directa enya funcionontre los switches (SW)
--            y los LEDs rojos (LEDR) para verificar el
--            funcionamiento y la correcta asignación de pines.
-- PLACA: Cyclone II EP2C20F484C7
---------------------------------------------------------------------

---------------------------------------------------------------------
-- LIBRERIAS
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

---------------------------------------------------------------------
-- ENTIDAD
---------------------------------------------------------------------
entity MapeoPlaca is
  port (
    SW   : in std_logic_vector(9 downto 0); -- 10 Interruptores (Switches)
    KEY  : in std_logic_vector(3 downto 0); -- 4 Botones (Push Buttons)
    LEDR : out std_logic_vector(9 downto 0); -- 10 LEDs Rojos
    LEDG : out std_logic_vector(7 downto 0); -- 8 LEDs Verdes
    HEX0 : out std_logic_vector(6 downto 0); -- Display 7-seg 0
    HEX1 : out std_logic_vector(6 downto 0); -- Display 7-seg 1
    HEX2 : out std_logic_vector(6 downto 0); -- Display 7-seg 2
    HEX3 : out std_logic_vector(6 downto 0) -- Display 7-seg 3
  );

  -- Asignación de pines para la placa Cyclone II EP2C20F484C7
  -- según el archivo README.md
  attribute CHIP_PIN : string;
  -- Entradas
  -- El orden de los pines corresponde a SW(9), SW(8), ..., SW(0)
  attribute CHIP_PIN of SW : signal is "L2, M1, M2, U11, U12, W12, V12, M22, L21, L22"; -- SW9..SW0
  -- El orden de los pines corresponde a KEY(3), KEY(2), KEY(1), KEY(0)
  attribute CHIP_PIN of KEY : signal is "T21, T22, R21, R22";
  -- Salidas
  attribute CHIP_PIN of LEDR : signal is "R17, R18, U18, Y18, V19, T18, Y19, U19, R19, R20";
  attribute CHIP_PIN of LEDG : signal is "Y21, Y22, W21, W22, V21, V22, U21, U22";
  -- El orden de los pines corresponde a los segmentos g,f,e,d,c,b,a
  attribute CHIP_PIN of HEX0 : signal is "E2, F1, F2, H1, H2, J1, J2";
  attribute CHIP_PIN of HEX1 : signal is "D1, D2, G3, H4, H5, H6, E1";
  attribute CHIP_PIN of HEX2 : signal is "D3, E4, E3, C1, C2, G6, G5";
  attribute CHIP_PIN of HEX3 : signal is "D4, F3, L8, J4, D6, D5, F4";

end entity MapeoPlaca;

---------------------------------------------------------------------
-- ARQUITECTURA
---------------------------------------------------------------------
-- Esta arquitectura implementa una lógica concurrente simple.
-- Cada LED rojo se enciende si su interruptor correspondiente está
-- en la posición de '1' (activado).
---------------------------------------------------------------------
architecture rtl of MapeoPlaca is
  -- Señal interna para almacenar el valor del display de 7 segmentos.
  -- Esto evita el error de leer un puerto de salida (OUT).
  signal s_hex_val : std_logic_vector(6 downto 0);
begin
  -- Conexión directa de los switches a los LEDs.
  -- SW(0) controla LEDR(0)
  -- SW(1) controla LEDR(1)
  -- ... y así sucesivamente hasta el 9.
  LEDR <= SW;

  -- Conexión de los switches a los LEDs verdes en nivel bajo (activo en '0').
  -- SW(9) controla LEDG(7)
  -- SW(8) controla LEDG(6) ... hasta SW(2) que controla LEDG(0)
  LEDG <= not SW(9 downto 2);

  -- Decodificador de 4 bits a 7 segmentos para los displays HEX0 y HEX1.
  -- La entrada son los 4 botones (KEY).
  -- La lógica es para displays de ánodo común (activo en bajo, '0' enciende).
  -- Formato de salida: (segmento g, f, e, d, c, b, a)
  with KEY select
    s_hex_val <= "1000000" when "0000", -- 0
    "1111001" when "0001", -- 1
    "0100100" when "0010", -- 2
    "0110000" when "0011", -- 3
    "0011001" when "0100", -- 4
    "0010010" when "0101", -- 5
    "0000010" when "0110", -- 6
    "1111000" when "0111", -- 7
    "0000000" when "1000", -- 8
    "0010000" when "1001", -- 9
    "0001000" when "1010", -- A
    "0000011" when "1011", -- b
    "1000110" when "1100", -- C
    "0100001" when "1101", -- d
    "0000110" when "1110", -- E
    "0001110" when "1111", -- F
    "1111111" when others; -- Apagado

  -- Asignar el valor de la señal interna a los puertos de salida.
  HEX0 <= s_hex_val;
  HEX1 <= s_hex_val;
  HEX2 <= s_hex_val;
  HEX3 <= s_hex_val;

end architecture rtl;