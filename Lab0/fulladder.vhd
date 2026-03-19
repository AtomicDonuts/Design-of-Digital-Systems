library ieee;
use ieee.std_logic_1164.all;

entity fulladder is
  port (
    a, b, cin : in  std_logic;
    sum  : out std_logic;
    cout : out std_logic -- := '0' to initialize if needed
  );
end fulladder;

architecture structural of fulladder is  -- Structural serve per collegare le varie parti, senza aggiungere effettivamente un comportamento
                                         -- in questo caso gli halfadder, per definire questo fulladder
  signal s1, c1, c2 : std_logic; -- := '0' to initialize if needed

  component halfadder  -- qui importo il modo in cui è fatto il componente
    port (
      a, b  : in  std_logic;
      sum, carry : out std_logic
    );
  end component;

begin -- mentre qui faccio succedere tutto in maniera concorrenziale e collego i vari pezzi

  ha1: halfadder port map (a => a, b => b,   sum => s1, carry => c1);
  ha2: halfadder port map (a => s1, b => cin, sum => sum, carry => c2);
  cout <= c1 or c2 after 1 ns;
  
end structural;
