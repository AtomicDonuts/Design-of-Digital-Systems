library ieee;
use ieee.std_logic_1164.all;

entity multiplier is
  port (
    a, b : in  std_logic_vector(7 downto 0);
    p    : out std_logic_vector(15 downto 0) -- := (others => '0') to initialize if needed
  );
end multiplier;

architecture structural of multiplier is
  component adder
    generic (
      n : integer := 8
    );
    port (
      a, b : in  std_logic_vector(n-1 downto 0);
      sum  : out std_logic_vector(n-1 downto 0);
      cout : out std_logic
    );
  end component;

  type std_logic_matrix is array (natural range <>) of std_logic_vector(7 downto 0);

  signal t : std_logic_matrix(1 to 7); -- := (others => (others => '0')) to initialize if needed
  signal s : std_logic_matrix(0 to 7); -- := (others => (others => '0')) to initialize if needed
  signal c : std_logic_vector(7 downto 0);

begin

  -- Create partial product: replicate b(0) across all bits and AND with a
  s(0) <= a and (7 downto 0 => b(0)) after 1 ns;
  p(0) <= s(0)(0);
  c(0) <= '0';

  gen_mult: for i in 1 to 7 generate
    t(i) <= a and (7 downto 0 => b(i)) after 1 ns;
    add: adder generic map (n => 8)
      port map (
        a    => c(i-1) & s(i-1)(7 downto 1),
        b    => t(i),
        sum  => s(i),
        cout => c(i)
      );
    p(i) <= s(i)(0);
  end generate;

  p(15 downto 7) <= c(7) & s(7);
  
end structural;
