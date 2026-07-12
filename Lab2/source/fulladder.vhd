library ieee;
use ieee.std_logic_1164.all;

entity fulladder is
  port (
    a, b, cin : in  std_logic;
    sum       : out std_logic;
    cout      : out std_logic
  );
end fulladder;

architecture structural of fulladder is
  signal s1, c1, c2 : std_logic;

  component halfadder
    port (
      a, b       : in  std_logic;
      sum, carry : out std_logic
    );
  end component;
begin
  ha1: halfadder port map (a => a,  b => b,   sum => s1,  carry => c1);
  ha2: halfadder port map (a => s1, b => cin, sum => sum, carry => c2);
  cout <= c1 or c2;
end structural;
