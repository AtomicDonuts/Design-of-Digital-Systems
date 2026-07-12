library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tdc_histogram is
  port (
    clk_i        : in  std_logic;
    rst_i        : in  std_logic;
    hit_valid_i  : in  std_logic;
    addr_i       : in  std_logic_vector(11 downto 0);
    rd_en_i      : in  std_logic;
    rd_addr_i    : in  std_logic_vector(11 downto 0);
    rd_data_o    : out std_logic_vector(7 downto 0);
    overflow_o   : out std_logic
  );
end entity tdc_histogram;

architecture rtl of tdc_histogram is

  component blk_mem_gen_0 is
    port (
      clka  : in  std_logic;
      ena   : in  std_logic;
      wea   : in  std_logic_vector(0 downto 0);
      addra : in  std_logic_vector(11 downto 0);
      dina  : in  std_logic_vector(15 downto 0);
      douta : out std_logic_vector(15 downto 0)
    );
  end component;

  constant N_WORDS : integer := 2**12;

  -- Interfaccia BRAM
  signal bram_we   : std_logic_vector(0 downto 0) := "0";
  signal bram_addr : std_logic_vector(11 downto 0) := (others => '0');
  signal bram_din  : std_logic_vector(15 downto 0)  := (others => '0');
  signal bram_dout : std_logic_vector(15 downto 0)  := (others => '0');

  -- Macchina a stati
  type state_type is (RESETTING, IDLE, READ1, READ2, READ3, SWRITE, SWRITE2, SWRITE3);
  signal state : state_type := RESETTING;

  signal rst_addr        : unsigned(11 downto 0) := (others => '0');
  signal overflow        : std_logic := '0';

  -- Registro interno per evitare read-modify-write non atomico
  signal current_val : unsigned(15 downto 0) := (others => '0');
  
begin

  U_BRAM : blk_mem_gen_0
    port map (
      clka  => clk_i,
      ena   => '1',
      wea   => bram_we,
      addra => bram_addr,
      dina  => bram_din,
      douta => bram_dout
    );

  process(clk_i, rst_i)
  begin
    if rst_i = '1' then
      state          <= RESETTING;
      rst_addr       <= (others => '0');
      overflow       <= '0';
      bram_we        <= "0";
      bram_addr      <= (others => '0');
      bram_din       <= (others => '0');
      current_val    <= (others => '0');

    elsif rising_edge(clk_i) then
      bram_we <= "0";  -- default

      case state is

        -- Reset: azzera tutta la BRAM
        when RESETTING =>
          bram_we   <= "1";
          bram_addr <= std_logic_vector(rst_addr);
          bram_din  <= (others => '0');
          overflow  <= '0';
          if rst_addr = N_WORDS - 1 then
            rst_addr  <= (others => '0');
            state     <= IDLE;
          else
            rst_addr <= rst_addr + 1;
          end if;

        -- Idle: aspetta un evento
        when IDLE =>
        if hit_valid_i = '1' then
          bram_addr <= addr_i;
          state     <= READ1;
        else 
          bram_addr <= rd_addr_i;
        end if;

      when READ1 =>
        state <= READ2;

      when READ2 =>
        state <= READ3;
      
      when READ3 => 
        current_val <= unsigned(bram_dout);
        if current_val = x"FFFF" then
          overflow <= '1';
          state <= SWRITE2;
        else
          bram_din <= std_logic_vector(current_val + 1);
          state <= SWRITE;
        end if;

      when SWRITE =>
        bram_we     <= "1";
        current_val <= current_val + 1;
        state <= SWRITE2;

      when SWRITE2 =>
        state <= SWRITE3;

      when SWRITE3 =>
        state <= IDLE;

    end case;
  end if;
end process;

rd_data_o  <= bram_dout(15 downto 8);
overflow_o <= overflow;

end architecture rtl;