----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.04.2026 11:51:21
-- Design Name: 
-- Module Name: top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    port ( CLK100 : in  STD_LOGIC;
           BTN    : in  STD_LOGIC;
           ADC_D_OUT : out STD_LOGIC_VECTOR (7 downto 0);
           DATAVALID_OUT : out STD_LOGIC;
           ADC_D_IN : in STD_LOGIC_VECTOR (7 downto 0);
           DATAVALID_IN : in STD_LOGIC;
           DATA_OUT : out STD_LOGIC_VECTOR (15 downto 0);
           OUT_VALID : out STD_LOGIC
         );
end top;

architecture Behavioral of top is

------------------------------------------------------------------
  -- Clocking
  ------------------------------------------------------------------
  signal clk_25   : std_logic;
  signal locked   : std_logic;
  signal rst      : std_logic;
  signal adc_in_latched : signed(7 downto 0);
  signal datavalid_in_latched : std_logic;
  
  constant NSAMPLES        : integer := 256;
  signal idx : integer range 0 to NSAMPLES-1 := 0;
  


  
---- FSM: send in output simulated ADC data---------------------

  type state_t is (
    ST_IDLE,        -- attesa trigger
    ST_DATASEND,     -- send samples
    ST_WAIT_BTN_LOW -- wait button back to 0 
  );
  signal state           : state_t;  
  
 


  -- ==============================================
-- PMT waveform ROM (auto-generated)
-- ==============================================

type rom_t is array (0 to 255) of signed(0 to 7);

constant pmt_wave_8 : rom_t := (
    0 => to_signed(     1, 8),
    1 => to_signed(     8, 8),
    2 => to_signed(    16, 8),
    3 => to_signed(    22, 8),
    4 => to_signed(    30, 8),
    5 => to_signed(    35, 8),
    6 => to_signed(    39, 8),
    7 => to_signed(    41, 8),
    8 => to_signed(    46, 8),
    9 => to_signed(    51, 8),
   10 => to_signed(    57, 8),
   11 => to_signed(    55, 8),
   12 => to_signed(    59, 8),
   13 => to_signed(    63, 8),
   14 => to_signed(    58, 8),
   15 => to_signed(    61, 8),
   16 => to_signed(    58, 8),
   17 => to_signed(    62, 8),
   18 => to_signed(    63, 8),
   19 => to_signed(    64, 8),
   20 => to_signed(    61, 8),
   21 => to_signed(    61, 8),
   22 => to_signed(    65, 8),
   23 => to_signed(    60, 8),
   24 => to_signed(    61, 8),
   25 => to_signed(    58, 8),
   26 => to_signed(    60, 8),
   27 => to_signed(    57, 8),
   28 => to_signed(    55, 8),
   29 => to_signed(    53, 8),
   30 => to_signed(    54, 8),
   31 => to_signed(    52, 8),
   32 => to_signed(    53, 8),
   33 => to_signed(    49, 8),
   34 => to_signed(    54, 8),
   35 => to_signed(    51, 8),
   36 => to_signed(    47, 8),
   37 => to_signed(    46, 8),
   38 => to_signed(    46, 8),
   39 => to_signed(    44, 8),
   40 => to_signed(    48, 8),
   41 => to_signed(    41, 8),
   42 => to_signed(    41, 8),
   43 => to_signed(    40, 8),
   44 => to_signed(    40, 8),
   45 => to_signed(    39, 8),
   46 => to_signed(    36, 8),
   47 => to_signed(    34, 8),
   48 => to_signed(    34, 8),
   49 => to_signed(    33, 8),
   50 => to_signed(    40, 8),
   51 => to_signed(    33, 8),
   52 => to_signed(    33, 8),
   53 => to_signed(    29, 8),
   54 => to_signed(    25, 8),
   55 => to_signed(    30, 8),
   56 => to_signed(    28, 8),
   57 => to_signed(    26, 8),
   58 => to_signed(    27, 8),
   59 => to_signed(    24, 8),
   60 => to_signed(    27, 8),
   61 => to_signed(    29, 8),
   62 => to_signed(    22, 8),
   63 => to_signed(    22, 8),
   64 => to_signed(    22, 8),
   65 => to_signed(    21, 8),
   66 => to_signed(    18, 8),
   67 => to_signed(    18, 8),
   68 => to_signed(    20, 8),
   69 => to_signed(    18, 8),
   70 => to_signed(    18, 8),
   71 => to_signed(    20, 8),
   72 => to_signed(    16, 8),
   73 => to_signed(    15, 8),
   74 => to_signed(    17, 8),
   75 => to_signed(    16, 8),
   76 => to_signed(    18, 8),
   77 => to_signed(    13, 8),
   78 => to_signed(    12, 8),
   79 => to_signed(    16, 8),
   80 => to_signed(    13, 8),
   81 => to_signed(    15, 8),
   82 => to_signed(    15, 8),
   83 => to_signed(    14, 8),
   84 => to_signed(    11, 8),
   85 => to_signed(    12, 8),
   86 => to_signed(    11, 8),
   87 => to_signed(    10, 8),
   88 => to_signed(    11, 8),
   89 => to_signed(     8, 8),
   90 => to_signed(    13, 8),
   91 => to_signed(     9, 8),
   92 => to_signed(    10, 8),
   93 => to_signed(    10, 8),
   94 => to_signed(     7, 8),
   95 => to_signed(     7, 8),
   96 => to_signed(     7, 8),
   97 => to_signed(     9, 8),
   98 => to_signed(     8, 8),
   99 => to_signed(    10, 8),
  100 => to_signed(     4, 8),
  101 => to_signed(     6, 8),
  102 => to_signed(     9, 8),
  103 => to_signed(     7, 8),
  104 => to_signed(     2, 8),
  105 => to_signed(     4, 8),
  106 => to_signed(     8, 8),
  107 => to_signed(     6, 8),
  108 => to_signed(     9, 8),
  109 => to_signed(     7, 8),
  110 => to_signed(     5, 8),
  111 => to_signed(     4, 8),
  112 => to_signed(     6, 8),
  113 => to_signed(     5, 8),
  114 => to_signed(     7, 8),
  115 => to_signed(     6, 8),
  116 => to_signed(     5, 8),
  117 => to_signed(     2, 8),
  118 => to_signed(     2, 8),
  119 => to_signed(     4, 8),
  120 => to_signed(     5, 8),
  121 => to_signed(     6, 8),
  122 => to_signed(     3, 8),
  123 => to_signed(     1, 8),
  124 => to_signed(     0, 8),
  125 => to_signed(     3, 8),
  126 => to_signed(    -1, 8),
  127 => to_signed(     6, 8),
  128 => to_signed(     5, 8),
  129 => to_signed(     3, 8),
  130 => to_signed(     6, 8),
  131 => to_signed(     5, 8),
  132 => to_signed(     0, 8),
  133 => to_signed(    -1, 8),
  134 => to_signed(     1, 8),
  135 => to_signed(     1, 8),
  136 => to_signed(     3, 8),
  137 => to_signed(     5, 8),
  138 => to_signed(     6, 8),
  139 => to_signed(     1, 8),
  140 => to_signed(     2, 8),
  141 => to_signed(     4, 8),
  142 => to_signed(     3, 8),
  143 => to_signed(     5, 8),
  144 => to_signed(     5, 8),
  145 => to_signed(     3, 8),
  146 => to_signed(     2, 8),
  147 => to_signed(     1, 8),
  148 => to_signed(     3, 8),
  149 => to_signed(     0, 8),
  150 => to_signed(    -1, 8),
  151 => to_signed(     1, 8),
  152 => to_signed(     3, 8),
  153 => to_signed(    -1, 8),
  154 => to_signed(     0, 8),
  155 => to_signed(     7, 8),
  156 => to_signed(     1, 8),
  157 => to_signed(    -2, 8),
  158 => to_signed(     1, 8),
  159 => to_signed(    -1, 8),
  160 => to_signed(     1, 8),
  161 => to_signed(     1, 8),
  162 => to_signed(     1, 8),
  163 => to_signed(     0, 8),
  164 => to_signed(     0, 8),
  165 => to_signed(     0, 8),
  166 => to_signed(    -2, 8),
  167 => to_signed(     3, 8),
  168 => to_signed(     0, 8),
  169 => to_signed(     3, 8),
  170 => to_signed(     2, 8),
  171 => to_signed(    -2, 8),
  172 => to_signed(    -1, 8),
  173 => to_signed(     1, 8),
  174 => to_signed(     2, 8),
  175 => to_signed(     2, 8),
  176 => to_signed(    -1, 8),
  177 => to_signed(    -1, 8),
  178 => to_signed(     3, 8),
  179 => to_signed(     1, 8),
  180 => to_signed(     1, 8),
  181 => to_signed(     1, 8),
  182 => to_signed(    -2, 8),
  183 => to_signed(    -2, 8),
  184 => to_signed(    -2, 8),
  185 => to_signed(     4, 8),
  186 => to_signed(     0, 8),
  187 => to_signed(     5, 8),
  188 => to_signed(    -4, 8),
  189 => to_signed(     1, 8),
  190 => to_signed(     0, 8),
  191 => to_signed(    -1, 8),
  192 => to_signed(     0, 8),
  193 => to_signed(     3, 8),
  194 => to_signed(    -1, 8),
  195 => to_signed(    -1, 8),
  196 => to_signed(    -2, 8),
  197 => to_signed(    -4, 8),
  198 => to_signed(     0, 8),
  199 => to_signed(     1, 8),
  200 => to_signed(     1, 8),
  201 => to_signed(    -1, 8),
  202 => to_signed(     2, 8),
  203 => to_signed(     2, 8),
  204 => to_signed(     3, 8),
  205 => to_signed(    -1, 8),
  206 => to_signed(    -1, 8),
  207 => to_signed(    -1, 8),
  208 => to_signed(     2, 8),
  209 => to_signed(     0, 8),
  210 => to_signed(    -6, 8),
  211 => to_signed(     0, 8),
  212 => to_signed(     0, 8),
  213 => to_signed(    -1, 8),
  214 => to_signed(     0, 8),
  215 => to_signed(    -2, 8),
  216 => to_signed(    -1, 8),
  217 => to_signed(    -2, 8),
  218 => to_signed(    -3, 8),
  219 => to_signed(     3, 8),
  220 => to_signed(    -2, 8),
  221 => to_signed(     2, 8),
  222 => to_signed(     2, 8),
  223 => to_signed(    -1, 8),
  224 => to_signed(    -1, 8),
  225 => to_signed(    -2, 8),
  226 => to_signed(    -2, 8),
  227 => to_signed(    -1, 8),
  228 => to_signed(     2, 8),
  229 => to_signed(    -2, 8),
  230 => to_signed(     0, 8),
  231 => to_signed(     0, 8),
  232 => to_signed(     1, 8),
  233 => to_signed(     0, 8),
  234 => to_signed(     2, 8),
  235 => to_signed(     5, 8),
  236 => to_signed(    -3, 8),
  237 => to_signed(    -1, 8),
  238 => to_signed(    -2, 8),
  239 => to_signed(     2, 8),
  240 => to_signed(    -2, 8),
  241 => to_signed(     0, 8),
  242 => to_signed(    -3, 8),
  243 => to_signed(    -2, 8),
  244 => to_signed(    -1, 8),
  245 => to_signed(     1, 8),
  246 => to_signed(     3, 8),
  247 => to_signed(     1, 8),
  248 => to_signed(    -1, 8),
  249 => to_signed(     3, 8),
  250 => to_signed(     0, 8),
  251 => to_signed(    -3, 8),
  252 => to_signed(     0, 8),
  253 => to_signed(    -2, 8),
  254 => to_signed(    -4, 8),
  255 => to_signed(     1, 8)
);
 




begin
-----------------------------------------------------------------------------------------------
-- Define a PLL that generates a clock signal with f = 25 MHz starting from a 100 MHz input.
-- define also the rst starting from locked
-----------------------------------------------------------------------------------------------  

 

  
  
 ---------------------------------------------------
 -- Emulating ADC FSM
 -- when BTN is pressed the 256 samples in  ROM are copied to adc_in_latched at every clk_25 period
 -- also adc_in_latched is sent in output
---------------------------------------------------------------------------------------------------- 
 

end Behavioral;
