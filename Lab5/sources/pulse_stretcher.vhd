----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.04.2026 17:56:05
-- Design Name: 
-- Module Name: pulse_stretcher - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity pulse_stretcher is
  generic (
    N_CYCLES      : integer := 20_000_000    -- numero di cicli
  );
  port (
    clk_i     : in  std_logic;
    rst_i     : in  std_logic;
    pulse_i   : in  std_logic;  -- impulso breve in ingresso
    level_o   : out std_logic;   -- segnale allungato in uscita
    delay_o   : out std_logic
  );
end entity pulse_stretcher;

architecture rtl of pulse_stretcher is

  signal count    : integer range 0 to N_CYCLES := 0;
  signal active   : std_logic := '0';

begin

  process(clk_i, rst_i)
  begin
    if rst_i = '1' then
      count  <= 0;
      active <= '0';
      delay_o <= '0';
    elsif rising_edge(clk_i) then
      delay_o <= '0';
      if pulse_i = '1' then
        -- Nuovo impulso: ricarica il contatore
        count  <= N_CYCLES;
        active <= '1';
      elsif count > 0 then
        -- Countdown
        count  <= count - 1;
        active <= '1';
      else
        -- Contatore arrivato a zero
        active <= '0';
        delay_o <= '1';
      end if;
    end if;
  end process;

  level_o <= active;

end architecture rtl;
