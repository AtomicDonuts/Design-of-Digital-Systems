----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 17:42:13
-- Design Name: 
-- Module Name: tdl_main - Behavioral
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
library UNISIM;
use UNISIM.VComponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

entity UART_top_1 is
    Port ( sw : in STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0):= (others => '0');
           btn : in STD_LOGIC_VECTOR (3 downto 0);
           UART_rxd : in std_logic;
           UART_txd : out std_logic := '0';
           clk : in std_logic);
end UART_top_1;

architecture Behavioral of UART_top_1 is

constant N_switches : integer := 16;
constant N_buttons : integer := 4;

signal locked_int : std_logic := '0';
signal reset_int : std_logic := '0';
signal clk_int : std_logic := '0';


signal btn_pressed : std_logic_vector ((N_buttons-1) downto 0):= (others => '0');
signal btn_level : std_logic_vector ((N_buttons-1) downto 0):= (others => '0');
signal sw_level : std_logic_vector ((N_switches-1) downto 0):= (others => '0');


signal UART_rx_done : std_logic := '0';
signal UART_tx_done : std_logic := '0';
signal UART_rx_dout : std_logic_vector (7 downto 0):= (others => '0');
signal UART_tx_din  : std_logic_vector (7 downto 0):= (others => '0');
signal UART_tx_start : std_logic := '0';
signal UART_rxd_stab : std_logic := '0';


begin

GEN_PB : for i in 1 to N_buttons generate
	PB_Debouncer_i 	: entity work.PB_Debouncer 		port map(clk => clk_int, reset => reset_int, sw => btn(i-1), tick_out => btn_pressed(i-1), db_level => btn_level(i-1));
end generate GEN_PB;

GEN_SW : for i in 1 to N_switches generate
	SW_Debouncer_i 	: entity work.PB_Debouncer 		port map(clk => clk_int, reset => reset_int, sw => sw(i-1), tick_out => open, db_level => sw_level(i-1));
end generate GEN_SW;

clk_0_i : entity work.clk_0	port map(clk_out1 => clk_int, reset => '0', locked => locked_int, clk_in1 => clk);  -- 200 MHz Clock
reset_int <= not locked_int;

------------------------
-- UART COMMUNICATION --
------------------------

uart_rxd_cdc 	: entity work.simple_cdc port map(clk => clk_int, sig_in => UART_rxd, sig_out => UART_rxd_stab);

UART_com_i : entity work.UART_com
	generic map(
        N => 9, 			-- : integer := 4;   -- number of bits (Data bits + stop bits)
        M => 326, 			-- 38400 Baud rate with 200 MHz clock
        DBIT    => 8,  		--: integer := 8;   -- # data bits
        SB_TICK => 16  		--: integer := 16   -- # ticks for stop bits
    )
    port map( 
	  clk 			=> clk_int,
	  reset 		=> reset_int,
      UART_rxd 		=> UART_rxd_stab,
      UART_rx_done 	=> UART_rx_done,
	  UART_rx_dout 	=> UART_rx_dout,
      --
      UART_txd 		=> UART_txd,
      UART_tx_start => UART_tx_start,
      UART_tx_din 	=> UART_tx_din,
      UART_tx_done	=> UART_tx_done
    );

-- UART_txd <= '0';
----------------
--  SWITCHES  --
----------------

UART_tx_din <= sw_level(15 downto 8);
UART_tx_start <= btn_pressed(0);

------------
--  LEDS  --
------------

led (7 downto 0) <=  UART_rx_dout;
led(15 downto 8) <=  sw_level(15 downto 8);




end Behavioral;