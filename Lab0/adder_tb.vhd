library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder_tb is
end adder_tb;

architecture arch of adder_tb is
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
  signal a, b : std_logic_vector(7 downto 0) := (others => '0');
  signal sum : std_logic_vector(7 downto 0) := (others => '0');
  signal cout : std_logic := '0';

  constant TARGET_FREQ : real := 100.0e6;
  constant TARGET_PERIOD : time := 1 sec / TARGET_FREQ;

begin
  uut: adder port map (a => a, b => b,sum => sum, cout=> cout);
  process
    variable ref : integer;
    variable errors : integer := 0;
  begin
    report "Testing adder at " & real'image(TARGET_FREQ / 1.0e6) & " MHz (" &
           integer'image(TARGET_PERIOD/1 ps) & " ps per operation)..." severity note;

    wait for 30 ns;

    for i in 0 to 255 loop
      for j in 0 to 255 loop
        a <= std_logic_vector(to_unsigned(i, 8));
        b <= std_logic_vector(to_unsigned(j, 8));

        wait for TARGET_PERIOD;

        ref := i + j;
        -- qui al posto di di sum, c'è la concatenazione di cout e sum e si
        -- compara con un numero a 9 bit, al posto di 8 bit
        if cout & sum /= (std_logic_vector(to_unsigned(ref, 9))) then
          report "FAILED: " & integer'image(i) & " + " &
                 integer'image(j) & " = " & integer'image(ref) &
                 ", got " & integer'image(to_integer(unsigned(sum)))
            severity error;
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
