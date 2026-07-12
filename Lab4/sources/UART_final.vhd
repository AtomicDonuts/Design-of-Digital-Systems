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
--use IEEE.NUMERIC_STD.ALL;

entity UART_final is
    Port ( sw : in STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0):= (others => '0');
           btn : in STD_LOGIC_VECTOR (3 downto 0);
           UART_rxd : in std_logic;
           UART_txd : out std_logic := '0';
           clk : in std_logic);
end UART_final;

architecture Behavioral of UART_final is

constant N_switches : integer := 16;
constant N_buttons : integer := 4;

signal locked_int : std_logic := '0';
signal reset_int : std_logic := '0';
signal clk_int : std_logic := '0';


signal btn_pressed : std_logic_vector ((N_buttons-1) downto 0):= (others => '0');
signal btn_level : std_logic_vector ((N_buttons-1) downto 0):= (others => '0');
signal sw_level : std_logic_vector ((N_switches-1) downto 0):= (others => '0');

------------------------------------------
--- USE THIS SIGNALS FOR THE TWO FIFOs ---
------------------------------------------

signal fifo_rx_empty : std_logic := '0';
signal fifo_rx_full : std_logic := '0';
signal fifo_rx_wrreq : std_logic := '0';
signal fifo_rx_rdreq : std_logic := '0';
signal fifo_rx_din : std_logic_vector (7 downto 0):= (others => '0');
signal fifo_rx_dout : std_logic_vector (7 downto 0):= (others => '0');

signal fifo_tx_empty : std_logic := '0';
signal fifo_tx_full : std_logic := '0';
signal fifo_tx_wrreq : std_logic := '0';
signal fifo_tx_rdreq : std_logic := '0';
signal fifo_tx_din : std_logic_vector (7 downto 0):= (others => '0');
signal fifo_tx_dout : std_logic_vector (7 downto 0):= (others => '0');


signal UART_rx_done : std_logic := '0';
signal UART_tx_done : std_logic := '0';
signal UART_rx_dout : std_logic_vector (7 downto 0):= (others => '0');
signal UART_tx_din  : std_logic_vector (7 downto 0):= (others => '0');
signal UART_tx_start : std_logic := '0';
signal UART_rxd_stab : std_logic := '0';
signal reset_cipher : std_logic := '0';
signal dummy_word : std_logic_vector (7 downto 0):= (others => '0');

begin

GEN_PB : for i in 1 to N_buttons generate
	PB_Debouncer_i 	: entity work.PB_Debouncer 		port map(clk => clk_int, reset => reset_int, sw => btn(i-1), tick_out => btn_pressed(i-1), db_level => btn_level(i-1));
end generate GEN_PB;

GEN_SW : for i in 1 to N_switches generate
	SW_Debouncer_i 	: entity work.PB_Debouncer 		port map(clk => clk_int, reset => reset_int, sw => sw(i-1), tick_out => open, db_level => sw_level(i-1));
end generate GEN_SW;

clk_0_i : entity work.clk_0	port map(clk_out1 => clk_int, reset => '0', locked => locked_int, clk_in1 => clk);  -- 200 MHz Clock!
reset_int <= not locked_int;

------------------------
-- UART COMMUNICATION --
------------------------

uart_rxd_cdc 	: entity work.simple_cdc port map(clk => clk_int, sig_in => UART_rxd, sig_out => UART_rxd_stab);

UART_com_i : entity work.UART_com
	generic map(
        N => 9, 			-- : integer := 4;   -- number of bits
        M => 326,
        DBIT    => 8,
        SB_TICK => 16
    )
    port map( 
		clk             => clk_int,
		reset           => reset_int,
        UART_rxd        => UART_rxd_stab,
        UART_rx_done 	=> UART_rx_done,
	    UART_rx_dout 	=> UART_rx_dout,
        ----
        UART_txd        => UART_txd,
        UART_tx_start   => UART_tx_start,
        UART_tx_din 	=> UART_tx_din,
        UART_tx_done	=> UART_tx_done
    );

-- INSTANTIATE THE TWO FIFOs HERE! --
fifo_generator_0_rx : entity work.fifo_generator_0
    port map(
        srst        => reset_int,     --: IN STD_LOGIC;
        clk         => clk_int,     --: IN STD_LOGIC;
        empty       => fifo_rx_empty,
        full        => fifo_rx_full,     --: OUT STD_LOGIC;
        wr_en       => fifo_rx_wrreq,    --: IN STD_LOGIC;
        rd_en       => fifo_rx_rdreq,    --: IN STD_LOGIC;
        din         => fifo_rx_din,    --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dout        => fifo_rx_dout     --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        );
fifo_generator_0_tx : entity work.fifo_generator_0
    port map(
        srst        => reset_int,        --: IN STD_LOGIC;
        clk         => clk_int,          --: IN STD_LOGIC;
        din         => fifo_tx_din,      --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        rd_en       => fifo_tx_rdreq,    --: IN STD_LOGIC;
        wr_en       => fifo_tx_wrreq,    --: IN STD_LOGIC;
        empty       => fifo_tx_empty,    --: OUT STD_LOGIC;
        full        => fifo_tx_full,     --: OUT STD_LOGIC;
        dout        => fifo_tx_dout     --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        );
-------------------------------------

UART_tx_start <= not fifo_tx_empty; -- Inizo Trasmissione
fifo_tx_rdreq <= UART_tx_done and not fifo_tx_empty; --  show ahead fifo!  UART TX deve dire a fifo tx di aver preso il dato sull'uscita e può passare al prossimo
fifo_rx_wrreq <= UART_rx_done and not fifo_rx_full; --  show ahead fifo!  UART RX deve dire a fifo rx che il dato in uscita è buono e può prenderselo. 
UART_tx_din   <= fifo_tx_dout; -- Dati da trasmettere
fifo_rx_din   <= UART_rx_dout; -- Dati Ricevuti


cipher_i : entity work.lfsr_cipher
    port map(
        clk             => clk_int,
        rst             => reset_cipher,
        enable          => '1', 

        fifo_in_empty   => fifo_rx_empty, 
        fifo_in_dout    => fifo_rx_dout,
        fifo_in_rd_en   => fifo_rx_rdreq, 

        fifo_out_full   => fifo_tx_full, 
        fifo_out_din    => fifo_tx_din, 
        fifo_out_wr_en  => fifo_tx_wrreq  
    );

reset_cipher <= reset_int or btn_pressed(1);

------------
--  LEDS  --
------------

led(15) <= fifo_rx_wrreq;
led(14) <= fifo_rx_rdreq;
led(13) <= fifo_rx_empty;
led(12) <= fifo_rx_full;
led(11) <= '0';
led(10) <= fifo_tx_wrreq;
led(9)  <= fifo_tx_rdreq;
led(8)  <= fifo_tx_empty;
led(7)  <= fifo_tx_full;
led(6)  <= '0';
led(5)  <= '0';
led(4)  <= '0';
led(3)  <= '0';
led(2)  <= '0';
led(1)  <= '0';
led(0)  <= '0';


end Behavioral;