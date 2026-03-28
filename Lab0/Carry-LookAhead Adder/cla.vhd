library ieee;
use ieee.std_logic_1164.all;

entity cla is
port(
  a, b, cin : in  std_logic;
  sum, cout : out std_logic;
);

end cla;

architecture behavioral of cla is
  signal xor1: std_logic;
begin
  process(a,b,cin)
  begin
    xor1  <= a    xor b   after 1 ns;
    sum   <= xor1 xor cin after 1 ns;
    prop  <= a    or  b   after 1 ns;
    gen   <= a    and b   after 1 ns;
    cout  <= gen  or  (prop and cin)
    end process;

end behavioral ; -- behavioral