----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 16.03.2026 19:24:41
-- Design Name: 
-- Module Name: Deb_main - Behavioral
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

entity PB_Debouncer is
port(
        clk		   : in  std_logic;
        reset      : in  std_logic;
        sw         : in  std_logic;
        tick_out   : out std_logic;
        db_level   : out std_logic);
end PB_Debouncer;

architecture imp_fsmd_arch of PB_Debouncer is

    constant N : integer := 2;                                     -- filter of 2^N * 20ns = 40ms

    type state_type is (zero, wait0, one, wait1);
    signal state_reg, state_next : state_type;
    signal q_reg, q_next : unsigned(N-1 downto 0);
    signal tick_next : std_logic := '0';

    signal sig_met, sig_stab: std_logic := '0';

begin
    
    simple_cdc_p : process (clk)
    begin
        if (rising_edge(clk)) then
            sig_met   <= sw;
            sig_stab <= sig_met;
        end if;
    end process;

    -- FSMD state & data registers
    process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= zero;
            q_reg     <= (others => '0');
            tick_out  <= '0';
        elsif (clk'event and clk = '1') then
            state_reg <= state_next;
            q_reg     <= q_next;
            tick_out  <= tick_next;
        end if;
    end process;

    -- next-state logic & data path functional units/routing
    process(state_reg, q_reg, sig_stab, q_next)
    begin
        state_next <= state_reg;
        q_next     <= q_reg;
        tick_next   <= '0';
        case state_reg is

            when zero =>
                db_level <= '0';
                if (sig_stab = '1') then
                    state_next <= wait1;
                    q_next     <= (others => '1');
                end if;

            when wait1 =>
                db_level <= '0';
                if (sig_stab = '1') then
                    q_next <= q_reg - 1;
                    if (q_next = 0) then
                        state_next <= one;
                        tick_next   <= '1';
                    end if;
                else  -- sig_stab = '0'
                    state_next <= zero;
                end if;

            when one =>
                db_level <= '1';
                if (sig_stab = '0') then
                    state_next <= wait0;
                    q_next     <= (others => '1');
                end if;

            when wait0 =>
                db_level <= '1';
                if (sig_stab = '0') then
                    q_next <= q_reg - 1;
                    if (q_next = 0) then
                        state_next <= zero;
                    end if;
                else  -- sig_stab = '1'
                    state_next <= one;
                end if;

        end case;
    end process;

end imp_fsmd_arch;