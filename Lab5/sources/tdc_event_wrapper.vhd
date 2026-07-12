----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.04.2026 16:45:24
-- Design Name: 
-- Module Name: tdc_event_wrapper - Behavioral
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

entity tdc_event_wrapper is
	generic (
	    N_TAP : integer := 64
	  );
	Port ( 
		clk 				    : in std_logic;
		reset				    : in std_logic;
    trig_tdl        : in std_logic;
		tap_in				  : in std_logic_vector ((N_TAP*4-1) downto 0):= (others => '0');
		coarse_time			: in std_logic_vector (3 downto 0):= (others => '0');
		data_valid_out  : out std_logic;
		data_out    		: out std_logic_vector (11 downto 0):= (others => '0')
		);
end tdc_event_wrapper;

architecture Behavioral of tdc_event_wrapper is

signal hit_valid  : std_logic := '0';

signal bin_pos  : std_logic_vector (9 downto 0):= (others => '0');
signal bin_pos_reg  : std_logic_vector (9 downto 0):= (others => '0');
signal coarse_time_reg: std_logic_vector (3 downto 0):= (others => '0');


begin



-- contatore di '1' nella TDL (INTRODUCE UNA LATENZA DI 7 CICLI)
one_cnt : entity work.Ones_counter port map( 
    vec_in    => tap_in, --: in  std_logic_vector(255 downto 0);
    clk       => clk, --: in  std_logic;
    count_out => bin_pos  --: out std_logic_vector(8 downto 0)
  );

-- hit_valid ritardato di 8 cicli
delay_counter: process(clk, reset)
  variable count : integer range 0 to 9 := 0;
begin
  if reset = '1' then
    count     := 0;
    hit_valid <= '0';
  elsif rising_edge(clk) then
    hit_valid <= '0';  -- default

    if count = 9 then
      hit_valid <= '1';
      count := 0;
    elsif count > 0 then
      count := count + 1;
    elsif trig_tdl = '1' then
      count := 1;
    end if;
  end if;
end process;



-- registro dati per inserirli in FIFO
process(clk,reset)
begin
  if reset = '1' then
  	data_valid_out <= '0';
  	bin_pos_reg     <= (others => '0');
  	coarse_time_reg <= (others => '0');
  elsif rising_edge(clk) then
    data_valid_out <= hit_valid;
    if hit_valid = '1' then
      bin_pos_reg     <= bin_pos;
      coarse_time_reg <= coarse_time;
    end if;
  end if;
end process;

data_out(9  downto 0 ) <= bin_pos_reg(9 downto 0);
data_out(11 downto 10 ) <= coarse_time_reg(1 downto 0);

end Behavioral;
