----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 19:53:10
-- Design Name: 
-- Module Name: UART_lib - Behavioral
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
--library UNISIM;
--use UNISIM.VComponents.all;


package UART_lib is

component UART_com is
    generic (
        N : integer := 9;             -- : integer := 4;   -- number of bits
        M : integer := 326;           -- 19200 Baud rate with 100 MHz clk  -- : integer := 10   -- mod-M
        DBIT    : integer := 8;       --: integer := 8;   -- # data bits
        SB_TICK : integer := 16       --: integer := 16   -- # ticks for stop bits
    );
    port ( 
        -- General Interface
        clk : in std_logic;
        reset : in std_logic;

        -- UART Interface
        UART_rxd    : in std_logic;
        UART_rx_done : out std_logic;
        UART_rx_dout : out std_logic_vector(7 downto 0);
        UART_txd : out std_logic := '0';
        UART_tx_start : in std_logic;
        UART_tx_din : in std_logic_vector(7 downto 0);
        UART_tx_done: out std_logic := '0'
    );
end component;

component mod_m_counter is
    generic (
        N : integer := 4;   -- number of bits
        M : integer := 10   -- mod-M
    );
    port (
        clk        : in  std_logic; 
        reset      : in  std_logic;
        max_tick   : out std_logic;
        q          : out std_logic_vector(N-1 downto 0)
    );
end component;

component uart_rx is
    generic (
        DBIT    : integer := 8;   -- # data bits
        SB_TICK : integer := 16   -- # ticks for stop bits
    );
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        rx           : in  std_logic;
        s_tick       : in  std_logic;
        rx_done_tick : out std_logic;
        dout         : out std_logic_vector(7 downto 0)
    );
end component;

component uart_tx is
    generic (
        DBIT    : integer := 8;   -- # data bits
        SB_TICK : integer := 16   -- # ticks for stop bits
    );
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        tx_start     : in  std_logic;
        s_tick       : in  std_logic;
        din          : in  std_logic_vector(7 downto 0);
        tx_done_tick : out std_logic;
        tx           : out std_logic
    );
end component;



end UART_lib;
