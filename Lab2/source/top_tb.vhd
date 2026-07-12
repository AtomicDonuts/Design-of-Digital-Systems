library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_tb is
end top_tb;

architecture sim of top_tb is
  signal CLK100 : std_logic := '0';
  signal BTN    : std_logic := '0';
  signal SW     : std_logic_vector(15 downto 0) := (others => '0');
  signal LED    : std_logic_vector(15 downto 0);

  -- Help the tester: keep track of expected product
  signal expected_p : std_logic_vector(15 downto 0) := (others => '0');

  procedure press_button (
    signal btn_s   : out std_logic;
    signal sw_s    : out std_logic_vector(15 downto 0);
    signal exp_s   : out std_logic_vector(15 downto 0);
    constant a_val : in  integer;
    constant b_val : in  integer
  ) is
  begin
    sw_s  <= std_logic_vector(to_unsigned(b_val, 8)) &
             std_logic_vector(to_unsigned(a_val, 8));
    exp_s <= std_logic_vector(to_unsigned(a_val * b_val, 16));
    wait for 200 ns;
    btn_s <= '1';
    wait for 200 ns;
    btn_s <= '0';
    wait for 600 ns;
  end procedure;

begin

  uut : entity work.top
    port map (
      CLK100 => CLK100,
      BTN    => BTN,
      SW     => SW,
      LED    => LED
    );

  -- 100 MHz board oscillator
  CLK100 <= not CLK100 after 5 ns;

  stim : process
  begin
    -- Allow the Clocking Wizard MMCM to lock. In behavioural simulation
    -- this takes a few hundred ns; in post-implementation timing
    -- simulation it can take longer, so wait generously.
    wait for 10 us;

    -- A small set of test vectors covering easy and stressful cases
    press_button(BTN, SW, expected_p,   5,   3);  --   15
    press_button(BTN, SW, expected_p,  12,  14);  --  168
    press_button(BTN, SW, expected_p, 200, 200);  -- 40000
    press_button(BTN, SW, expected_p, 255, 255);  -- 65025
    press_button(BTN, SW, expected_p, 170,  85);  -- 14450 (alternating bits)

    report "Simulation finished." severity note;
    wait;
  end process;

end sim;
