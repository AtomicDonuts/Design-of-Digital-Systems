library ieee;
use ieee.std_logic_1164.all;

entity adder is
  generic ( 
    n : integer := 8
  );
  port (
    a, b : in  std_logic_vector(n-1 downto 0);
    sum  : out std_logic_vector(n-1 downto 0);
    cout : out std_logic -- := '0' to initialize if needed
  );
end adder;

architecture structural of adder is
  signal c : std_logic_vector(n downto 0); -- definisce un segnale C, per tener conto dei carry(?)

  component fulladder --qui gli spiega la topologia della componente che usa
    port (
      a, b, cin : in  std_logic;
      sum, cout : out std_logic
    );
  end component;

begin

  c(0) <= '0'; -- inizializza il primo carry a 0

  fa_gen: for i in 0 to n-1 generate --fa un loop per linkare tutti i fulladder l'uno all'altro, in modo da non doverli scrivere tutti a mano
    fa: fulladder port map (  --fa è il nome della variabile 
      a    => a(i),  -- collega all' a del fulladder l'iesimo segnale di a dell'adder, che è un vettore
      b    => b(i),  -- come sopra
      cin  => c(i),
      sum  => sum(i),
      cout => c(i+1)
    );
  end generate;

  cout <= c(n) after 1 ns; -- propaga l'ultimo carry a cout
  
end structural;
