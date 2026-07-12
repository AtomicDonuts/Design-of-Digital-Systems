----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 19:57:46
-- Design Name: 
-- Module Name: UART_rx - Behavioral
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

entity uart_rx is
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
end uart_rx;

architecture arch of uart_rx is

    type state_type is (st_idle, st_start, st_data, st_stop);
    signal state_reg, state_next : state_type;
    signal s_reg,  s_next        : unsigned(3 downto 0); 			-- counters on the ticks
    signal n_reg,  n_next        : unsigned(2 downto 0); 			-- counters on the words
    signal b_reg,  b_next        : std_logic_vector(7 downto 0); 	-- UART word (registered and next)

begin

    -- FSMD state & data registers
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= st_idle;
            s_reg     <= (others => '0');
            n_reg     <= (others => '0');
            b_reg     <= (others => '0');
        elsif (clk'event and clk = '1') then
            state_reg <= state_next;
            s_reg     <= s_next;
            n_reg     <= n_next;
            b_reg     <= b_next;
        end if;
    end process;

    -- next-state logic & data path functional units/routing
    process(state_reg, s_reg, n_reg, b_reg, s_tick, rx)
    begin
        state_next   <= state_reg;
        s_next       <= s_reg;
        n_next       <= n_reg;
        b_next       <= b_reg;
        rx_done_tick <= '0';

        case state_reg is

            when st_idle =>
                if rx = '0' then
                    state_next <= st_start;
                    s_next     <= (others => '0');
                end if;

            when st_start =>
                if (s_tick = '1') then
                    if s_reg = 7 then
                        state_next <= st_data;
                        s_next     <= (others => '0');
                        n_next     <= (others => '0');
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;

            when st_data =>
                if (s_tick = '1') then
                    if s_reg = 15 then
                        s_next <= (others => '0');
                        b_next <= rx & b_reg(7 downto 1);
                        if n_reg = (DBIT-1) then
                            state_next <= st_stop;
                        else
                            n_next <= n_reg + 1;
                        end if;
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;

            when st_stop =>
                if (s_tick = '1') then
                    if s_reg = (SB_TICK-1) then
                        state_next   <= st_idle;
                        rx_done_tick <= '1';
                    else
                        s_next <= s_reg + 1;
                    end if;
                end if;

        end case;
    end process;

    dout <= b_reg;

    end arch;
