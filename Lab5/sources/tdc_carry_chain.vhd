----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 31.03.2026 12:13:55
-- Design Name: 
-- Module Name: tdc_carry_chain - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity tdc_carry_chain is
  generic (
    N_CARRY4 : integer := 64  -- numero di CARRY4 → 256 tap totali
  );
  port (
    hit_i   : in  std_logic;  -- segnale da misurare (START)
    clk_i   : in  std_logic;  -- clock di campionamento (STOP)
    stop_tdl: out std_logic;  -- (STOP)
    tap_o   : out std_logic_vector(N_CARRY4*4 - 1 downto 0)
  );
end entity;

architecture rtl of tdc_carry_chain is

  signal prec_tap_start  : std_logic :='0';
  signal carry : std_logic_vector(N_CARRY4*4 downto 0);
  signal taps  : std_logic_vector(N_CARRY4*4 - 1 downto 0);

  -- Attributi per forzare il placement fisico
  attribute KEEP : string;
  attribute DONT_TOUCH : string;
  attribute KEEP of carry : signal is "TRUE";
  attribute DONT_TOUCH of carry : signal is "TRUE";

begin

  -- Ingresso della catena
  carry(0) <= hit_i;

  -- Generazione della catena di CARRY4
  -- Il segnale semplicemente si propaga nei MUX della slice 
  GEN_CHAIN : for i in 0 to N_CARRY4-1 generate
    U_CARRY4 : CARRY4
      port map (
        CI     => carry(i*4),
        CYINIT => '0',
        DI     => "0000",
        S      => "1111",   -- CO[k] = CI propagato
        CO(0)  => carry(i*4 + 1),
        CO(1)  => carry(i*4 + 2),
        CO(2)  => carry(i*4 + 3),
        CO(3)  => carry(i*4 + 4),
        O      => open		-- non vengono usate le XOR del CARRY4
      );
  end generate;

  -- Registro di campionamento
  REG_TAPS : process(clk_i)
  begin
    if rising_edge(clk_i) then
      taps <= carry(N_CARRY4*4 - 1 downto 0);
    end if;
  end process;

  SAMPLE_REG : process(clk_i)
  begin
    if rising_edge(clk_i) then
      prec_tap_start <= taps(0);
      if (taps(0) = '1' and prec_tap_start = '0') then
        stop_tdl <= '1';
        tap_o <= taps;
      else
        stop_tdl <= '0';
      end if;
    end if;
  end process;

end architecture;
