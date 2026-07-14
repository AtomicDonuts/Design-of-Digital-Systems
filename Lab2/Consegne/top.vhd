library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    CLK100 : in  std_logic;
    BTN    : in  std_logic;
    SW     : in  std_logic_vector(15 downto 0);
    LED    : out std_logic_vector(15 downto 0)
  );
end top;

architecture rtl of top is

  ------------------------------------------------------------------
  -- Clocking
  ------------------------------------------------------------------
  signal clk_fast : std_logic;
  signal locked   : std_logic;
  signal rst      : std_logic;

  ------------------------------------------------------------------
  -- Button synchronizer outputs
  ------------------------------------------------------------------
  signal btn_sync : std_logic;   -- BTN sampled through 2 FFs
  signal btn_rise : std_logic;   -- 1-cycle pulse on BTN rising edge
  signal capture  : std_logic := '0';  -- btn_rise delayed by 1 cycle

  ------------------------------------------------------------------
  -- Datapath
  ------------------------------------------------------------------
  signal a_reg  : std_logic_vector(7 downto 0)  := (others => '0');
  signal b_reg  : std_logic_vector(7 downto 0)  := (others => '0');
  signal p_comb : std_logic_vector(15 downto 0);
  signal p_reg  : std_logic_vector(15 downto 0) := (others => '0');

  ------------------------------------------------------------------
  -- Mark signals for ILA observation (Vivado proprietary attribute)
  ------------------------------------------------------------------
  attribute MARK_DEBUG : string;
  attribute MARK_DEBUG of btn_sync : signal is "TRUE";
  attribute MARK_DEBUG of btn_rise : signal is "TRUE";
  attribute MARK_DEBUG of capture  : signal is "TRUE";
  attribute MARK_DEBUG of a_reg    : signal is "TRUE";
  attribute MARK_DEBUG of b_reg    : signal is "TRUE";
  attribute MARK_DEBUG of p_comb   : signal is "TRUE";
  attribute MARK_DEBUG of p_reg    : signal is "TRUE";

begin

  ------------------------------------------------------------------
  -- Clocking Wizard (added via IP Catalog, configured 100 MHz in,
  -- clk_out1 = target frequency for the experiment).
  ------------------------------------------------------------------
  u_clk : entity work.clk_wiz_0
    port map (
      clk_in1  => CLK100,
      clk_out1 => clk_fast,
      locked   => locked,
      -- manca il rst qui?
      reset    => '0'
    );

  rst <= not locked;

  ------------------------------------------------------------------
  -- 2-FF synchronizer on BTN with rising-edge pulse (Lesson 4)
  ------------------------------------------------------------------
  u_sync : entity work.synchronizer
    generic map (N => 2)
    port map (
      clk   => clk_fast,
      rst   => rst,
      async => BTN,
      sync  => btn_sync,
      rise  => btn_rise,
      fall  => open
    );

  ------------------------------------------------------------------
  -- Capture strobe: btn_rise delayed by one clock period. This
  -- guarantees that p_reg samples p_comb exactly one clk_fast period
  -- after a_reg / b_reg are updated.
  ------------------------------------------------------------------
  capture_reg : process(clk_fast)
  begin
    if rising_edge(clk_fast) then
      if rst = '1' then
        capture <= '0';
      else
        capture <= btn_rise;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------
  -- Input register: latch SW on button rising edge
  -- TODO 1: complete this process.
  --   - synchronous reset sets a_reg and b_reg to zero
  --   - when btn_rise = '1', capture SW(7 downto 0) into a_reg
  --     and SW(15 downto 8) into b_reg
  --   - otherwise hold the previous values
  ------------------------------------------------------------------
  input_reg : process(clk_fast)
  begin
    -- TODO 1: fill in
    if rising_edge(clk_fast) then 
        if rst = '1' then
            a_reg <= (others => '0');
            b_reg <= (others => '0');
        else
            if btn_rise = '1' then
                a_reg <= SW(7 downto 0);
                b_reg <= SW(15 downto 8);
            end if ;
        end if;
    end if;
  end process;

  ------------------------------------------------------------------
  -- Combinational multiplier (from Lab 0 / Lab 1)
  ------------------------------------------------------------------
  u_mult : entity work.multiplier
    port map (
      a => a_reg,
      b => b_reg,
      p => p_comb
    );

  ------------------------------------------------------------------
  -- Output register: sample the multiplier output one period after
  -- the input register updated.
  -- TODO 2: complete this process.
  --   - synchronous reset clears p_reg
  --   - when capture = '1', p_reg <= p_comb
  --   - otherwise hold the previous value
  ------------------------------------------------------------------
  output_reg : process(clk_fast)
  begin
    -- TODO 2: fill in
    if rising_edge(clk_fast) then
        if rst = '1' then
            p_reg <= (others => '0');
        else
            if capture = '1' then
                p_reg <= p_comb;
            end if;
        end if;
    end if;
  end process;

  LED <= p_reg;

end rtl;
