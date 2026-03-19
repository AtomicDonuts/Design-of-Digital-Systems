library ieee;
use ieee.std_logic_1164.all;

entity halfadder is
  port (
    a, b  : in  std_logic;
    sum, carry : out std_logic -- := '0' to initialize if needed
  );
end halfadder;

architecture behavioral of halfadder is
begin
  process(a, b) -- Il blocco dopo avviene in modo sequenziale nel momento in cui a o b cambia. 
  begin
    sum   <= a xor b after 1 ns; -- after 1ns è la propagazione che chiediamo alla simulazione (richiesta dalla traccia)
    carry <= a and b after 1 ns; -- è buona sintassi aggiungerla, anche se di 1ps, in modo che la simulazione non faccia di testa sua
  end process;
end behavioral;
