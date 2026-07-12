library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pulse_counter is
  generic (
    COUNTER_WIDTH : integer := 8;
    MAX_COUNT     : integer := 255;
    COUNT_RISING  : boolean := true
  );
  port (
    clk_i      : in  std_logic;
    rst_i      : in  std_logic;
    pulse_i    : in  std_logic;
    count_o    : out std_logic_vector(COUNTER_WIDTH - 1 downto 0);
    overflow_o : out std_logic
  );
end entity pulse_counter;

architecture rtl of pulse_counter is

  signal count      : unsigned(COUNTER_WIDTH - 1 downto 0);
  signal pulse_prev : std_logic;
  signal count_en   : std_logic;
  signal overflow   : std_logic;

begin

  -- Verifica a compile time
  assert MAX_COUNT > 0
    report "MAX_COUNT deve essere maggiore di 0"
    severity FAILURE;

  assert MAX_COUNT <= 2**COUNTER_WIDTH
    report "MAX_COUNT e' maggiore del valore massimo del contatore, overflow non verra' mai generato"
    severity WARNING;  -- solo warning, non blocca la sintesi

  -- Selezione modalita'
  GEN_RISING : if COUNT_RISING = true generate
    count_en <= pulse_i and (not pulse_prev);
  end generate;

  GEN_LEVEL : if COUNT_RISING = false generate
    count_en <= pulse_i;
  end generate;

  process(clk_i, rst_i)
  begin
    if rst_i = '1' then
      count      <= (others => '0');
      pulse_prev <= '0';
      overflow   <= '0';
    elsif rising_edge(clk_i) then
      pulse_prev <= pulse_i;
      overflow   <= '0';

      if count_en = '1' then
        if count = to_unsigned(MAX_COUNT - 1, COUNTER_WIDTH) then
          count    <= (others => '0');
          overflow <= '1';
        else
          count <= count + 1;
        end if;
      end if;
    end if;
  end process;

  count_o    <= std_logic_vector(count);
  overflow_o <= overflow;

end architecture rtl;