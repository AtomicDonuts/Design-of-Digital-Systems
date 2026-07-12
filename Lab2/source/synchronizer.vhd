library ieee;
use ieee.std_logic_1164.all;

-- N-stage synchronizer with one-cycle rising/falling-edge pulses on the
-- synchronized output. Matches the block presented in Lesson 4.
entity synchronizer is
  generic (
    N : integer := 2  -- number of synchronizer stages (>= 2)
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    async : in  std_logic;
    sync  : out std_logic;   -- async sampled through N flip-flops
    rise  : out std_logic;   -- 1-cycle pulse on sync rising edge
    fall  : out std_logic    -- 1-cycle pulse on sync falling edge
  );
end entity;

architecture behavioral of synchronizer is
  signal ff     : std_logic_vector(N-1 downto 0) := (others => '0');
  signal sync_d : std_logic := '0';

  -- Xilinx-specific: prevent the synthesizer from merging or optimising
  -- these flip-flops and tell it that the first one can legally sample
  -- an asynchronous signal.
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of ff : signal is "TRUE";
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        ff     <= (others => '0');
        sync_d <= '0';
      else
        ff     <= ff(N-2 downto 0) & async;
        sync_d <= ff(N-1);
      end if;
    end if;
  end process;

  sync <= ff(N-1);
  rise <=     ff(N-1) and not sync_d;
  fall <= not ff(N-1) and     sync_d;
end architecture;
