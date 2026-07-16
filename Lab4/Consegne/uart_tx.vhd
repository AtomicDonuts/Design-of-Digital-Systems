----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.03.2026 10:57:25
-- Design Name: 
-- Module Name: uart_tx - Behavioral
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

entity uart_tx is
    generic (
        DBIT    : integer := 8;   -- # data bits
        SB_TICK : integer := 16   -- # ticks for stop bits
    );
    port (
        clk 		 : in  std_logic;
        reset   	 : in  std_logic;
        tx_start     : in  std_logic;
        s_tick       : in  std_logic;
        din          : in  std_logic_vector(7 downto 0); -- dovrebbe essere DBIT downto 0 ma non voglio cambiare e distruggere tutto
        tx_done_tick : out std_logic;
        tx           : out std_logic
    );
end uart_tx;

architecture arch of uart_tx is

    type state_type is (st_idle, st_start, st_data, st_stop);
    signal state_reg,  state_next : state_type;
    signal s_reg,  s_next  : unsigned(3 downto 0);			--s counters on the ticks	
    signal n_reg,  n_next  : unsigned(2 downto 0);			--n counters on the words	
    signal b_reg,  b_next  : std_logic_vector(7 downto 0);	-- UART word (registered and next)			
    signal tx_reg, tx_next : std_logic;

begin

    -- FSMD state & data registers
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= st_idle;
            s_reg     <= (others => '0');
            n_reg     <= (others => '0');
            b_reg     <= (others => '0');
            tx_reg    <= '1';
        elsif (clk'event and clk = '1') then
            state_reg <= state_next;
            s_reg     <= s_next;
            n_reg     <= n_next;
            b_reg     <= b_next;
            tx_reg    <= tx_next;
        end if;
    end process;

    -- next-state logic & data path functional units/routing
    process(state_reg, s_reg, n_reg, b_reg, s_tick, tx_start, din)
    begin
        state_next   <= state_reg;
        s_next       <= s_reg;
        n_next       <= n_reg;
        b_next       <= b_reg;
        tx_next      <= tx_reg;
        tx_done_tick <= '0';

        case state_reg is
            -- REMEMBER: 
            -- YOU ASSIGN THE VALUES TO THE xxx_next SIGNALS
            -- YOU CHECKS THE xxx_reg VALUES

            when st_idle =>
                tx_next <= '1';
                if tx_start = '1' then
                    state_next <= st_start;
                    s_next     <= (others => '0');
                    -- TODO: collect the input UART word
                    n_next     <= (others => '0');
                    b_next <= din;

                end if;

            when st_start =>
                -- TX OUTPUT MUST BE SET TO '0'
                -- COUNTS 15 TICKS WITH "s". AFTER THAT, RESET "s_next", "n_next" and go to the next state
                tx_next <= '0';
                if (s_tick = '1') then
                    if s_reg = 15 then
                        state_next <= st_data;
                        s_next <= (others => '0');
                    else
                        s_next <= s_reg + 1;
                    end if ;
                end if;

            when st_data =>
                tx_next <= b_reg(0);
                if (s_tick = '1') then
                    if s_reg = 15 then 
                        s_next <= (others => '0');
                        b_next <= '0' & b_reg(DBIT-1 downto 1); -- bitshift of b_reg
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
                -- TX OUTPUT MUST BE SET TO '1'
                -- COUNTS (SB_TICK-1) TICKS WITH "s". AFTER THAT, assert the "tx_done_tick" and go back to idle
                tx_next <= '1';
                if (s_tick = '1') then
                    if s_reg = (SB_TICK - 1) then
                        s_next <= (others => '0');
                        tx_done_tick <= '1';
                        state_next <= st_idle;
                    end if;
                else
                    s_next <= s_reg + 1;
                end if;

        end case;
    end process;

    tx <= tx_reg;

end arch;
