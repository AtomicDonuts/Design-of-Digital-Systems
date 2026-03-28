library ieee;
use ieee.std_logic_1164.all;

entity cl_adder is
  generic ( 
    n : integer := 8
  );
  port (
    a, b : in  std_logic_vector(n-1 downto 0);
    sum  : out std_logic_vector(n-1 downto 0);
    cout : out std_logic
  );
end cl_adder;

architecture structural of cl_adder is
    signal c, prop, gen : std_logic_vector(n downto 0); -- definisce un segnale C, per tener conto dei carry(?)
  component cla --qui gli spiega la topologia della componente che usa
    port(
      a, b, cin : in  std_logic;
      sum, prop, gen : out std_logic
    );
  end component;

begin   

  c(0) <= '0'; -- inizializza il primo carry a 0

  cla_gen: for i in 0 to n-1 generate 
    cla: cla port map (
      a    => a(i),  
      b    => b(i),
      prop => prop(i),
      gen  => gen(i),
      sum  => sum(i),
      cin  => gen(i) or (prop(i) and gen(i))
    );
  end generate;

  cout <= c(n) after 1 ns; -- propaga l'ultimo carry a cout
  
end structural;
