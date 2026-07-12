
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity simple_cdc is
    Port ( 
    	clk : in std_logic;
    	sig_in : in std_logic;
    	sig_out : out std_logic
    	);
end simple_cdc;

architecture Behavioral of simple_cdc is

 signal sig_met : std_logic := '0';
 
begin

simple_cdc_p : process (clk)
    begin
        if (rising_edge(clk)) then
            sig_met   <= sig_in;
            sig_out <= sig_met;
        end if;
    end process;

end architecture;