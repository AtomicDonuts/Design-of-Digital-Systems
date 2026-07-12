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
  process(a, b)
  begin
    sum   <= a xor b after 1 ns;
    carry <= a and b after 1 ns;
  end process;
end behavioral;
