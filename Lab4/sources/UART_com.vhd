----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 17:42:13
-- Design Name: 
-- Module Name: UART_main - Behavioral
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
use work.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_com is
	generic (
        N : integer := 9; 			-- : integer := 4;   -- number of bits
        M : integer := 64; 			
        DBIT    : integer :=  8;  		--: integer := 8;   -- # data bits
        SB_TICK : integer :=  16  		--: integer := 16   -- # ticks for stop bits
    );
    port ( 
    	-- General Interface
		clk : in std_logic;
		reset : in std_logic;

		-- UART Interface
        UART_rxd 	: in std_logic;
        UART_rx_done : out std_logic;
		UART_rx_dout : out std_logic_vector(7 downto 0);
        UART_txd : out std_logic := '0';
        UART_tx_start : in std_logic;
        UART_tx_din : in std_logic_vector(7 downto 0);
        UART_tx_done: out std_logic := '0'
    );
end UART_com;

architecture Behavioral of UART_com is

signal tick : std_logic := '0';

begin

mod_m_counter_i : entity work.mod_m_counter
    generic map(
        N => N, -- : integer := 4;   -- number of bits
        M => M 
    ) port map(
        clk 	   => clk,  -- : in  std_logic;
        reset      => reset,-- : in  std_logic;
        max_tick   => tick, -- : out std_logic;
        q          => open      -- : out std_logic_vector(N-1 downto 0)
    );

uart_rx_i : entity work.uart_rx 
    generic map(
        DBIT    => DBIT, -- : integer := 8;   -- # data bits
        SB_TICK => SB_TICK  -- : integer := 16   -- # ticks for stop bits
    ) port map(
        clk    		 => clk, --: in  std_logic;
        reset 		 => reset, --: in  std_logic;
        rx           => UART_rxd, --: in  std_logic;
        s_tick       => tick, --: in  std_logic;
        rx_done_tick => UART_rx_done, --: out std_logic;
        dout         => UART_rx_dout  --: out std_logic_vector(7 downto 0)
    );

-- Questa parte l'ho aggiunta io!
-- ho anche eliminato un UART_tx_done settato a '0'

uart_tx_i : entity work.uart_tx 
    generic map(
        DBIT    => DBIT, -- : integer := 8;   -- # data bits
        SB_TICK => SB_TICK  -- : integer := 16   -- # ticks for stop bits
    ) port map(
        clk    		 => clk, --: in  std_logic;
        reset 		 => reset, --: in  std_logic;
        tx_start     => UART_tx_start, --: in  std_logic;
        s_tick       => tick, --: in  std_logic;
        din          => UART_tx_din,  --: in std_logic_vector(7 downto 0)
        tx_done_tick => UART_tx_done, --: out std_logic;
        tx           => UART_txd --: out  std_logic;
);


end Behavioral;