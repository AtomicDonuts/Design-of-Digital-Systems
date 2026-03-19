library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Basic testbench for 8x8 multiplier
-- Vuoto, giusto
entity multiplier_tb is
end multiplier_tb;

architecture arch of multiplier_tb is
  component multiplier is
    port (
      a, b : in  std_logic_vector(7 downto 0);
      p    : out std_logic_vector(15 downto 0)
    );
  end component;
  -- "simuliamo" i segnali, li inizzializzamo a 0
  signal a, b : std_logic_vector(7 downto 0) := (others => '0');
  signal p    : std_logic_vector(15 downto 0) := (others => '0');

  -- Ho definito 100MHz di frequenza
  constant TARGET_FREQ : real := 100.0e6;
  -- Tipo time, molto figo
  constant TARGET_PERIOD : time := 1 sec / TARGET_FREQ;

begin
  --uut sta per unit under test, collega le porte del multiplier ai nostri segnali simulati
  uut: multiplier port map (a => a, b => b, p => p);
  -- inizia la simulazione con un process -> quindi una cosa sequenziale
  process
  -- definizione di variabili, non segnali, intere
    variable ref : integer;
    variable errors : integer := 0;
  begin
    -- report è logger, e severity è il tipo di log, equivalente a logger.info() in python 
    report "Testing multiplier at " & real'image(TARGET_FREQ / 1.0e6) & " MHz (" &
           integer'image(TARGET_PERIOD/1 ps) & " ps per operation)..." severity note;

    --Qui aggiungo qualcosa, però mi sa he l'ho scritto male.
    -- a <= (others  => '0');
    --  b <= (others  => '0');
    --  wait for 50 ns;

    -- Test subset of cases (16×16 = 256 tests) 
    -- Complete coverage of all 8-bit inputs would require 65536 tests, which 
    -- is more computationally intensive
    
    -- prendiamo un subset 16x16  perchè per prenderli tutti ci vuole una vita.

    
    -- iniziamo 2 loop, in cui sostanzialmente incrementiamo i fattori da moltiplicare. 
    for i in 0 to 15 loop
      for j in 0 to 15 loop
        a <= std_logic_vector(to_unsigned(i, 8));
        b <= std_logic_vector(to_unsigned(j, 8));

        -- Wait for target period

        -- simulazione fenomeno clockato
        wait for TARGET_PERIOD;

        -- Check result

        -- facciamo il prodotto "normale" tra i e j, che poi sono i numeri che 
        -- stiamo considerando e lo mettiamo nella variabile ref
        ref := i * j;
        -- controlliamo che in p ci sia il valore di ref, in binario, quindi 
        -- c'è questa mostrosità che converte l'intero in un valore a 16 bit 
        -- unsigned e poi in un vettore di segnali, per poterlo confrontare
        -- con p, che è un segnale 
        if p /= std_logic_vector(to_unsigned(ref, 16)) then
          -- Se non sono uguali, diciamo "ao,vedi che non sono uguali"
          -- dato che la severity è "error", il programma continua
          report "FAILED: " & integer'image(i) & " x " &
                 integer'image(j) & " = " & integer'image(ref) &
                 ", got " & integer'image(to_integer(unsigned(p)))
            severity error;
          -- aumenta error, per vedere quanto facciamo cacare
          errors := errors + 1;
        end if;
      end loop;
    end loop;
    -- riporta i risultati
    report "========================================" severity note;
    report "Results: " & integer'image(errors) & " failures out of 256 tests" severity note;
    report "========================================" severity note;

    wait;
  end process;
end arch;
