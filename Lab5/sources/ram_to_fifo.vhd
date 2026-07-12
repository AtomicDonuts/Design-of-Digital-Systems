library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ram_to_fifo is
  generic (
    N_WORDS    : integer := 4096;  -- numero di parole della RAM
    DATA_WIDTH : integer := 8
  );
  port (
    clk_i       : in  std_logic;
    rst_i       : in  std_logic;
    -- Segnale di avvio trasferimento
    enable_i    : in  std_logic;  -- impulso che avvia il dump
    -- Interfaccia RAM (lettura)
    ram_addr_o  : out std_logic_vector(11 downto 0);
    ram_data_i  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    -- Interfaccia FIFO (scrittura)
    fifo_full_i : in  std_logic;
    fifo_din_o  : out std_logic_vector(DATA_WIDTH - 1 downto 0);
    fifo_wr_o   : out std_logic;
    -- Status
    busy_o      : out std_logic;  -- '1' durante il trasferimento
    done_o      : out std_logic   -- impulso a fine trasferimento
  );
end entity ram_to_fifo;

architecture rtl of ram_to_fifo is

  type state_type is (IDLE, READ_RAM, WAIT_DATA, WAIT_FIFO, WRITE_FIFO, DONE, WAIT_LOW);
  signal state : state_type := IDLE;

  signal addr : unsigned(11 downto 0) := (others => '0');

begin

  process(clk_i, rst_i)
  begin
    if rst_i = '1' then
      state      <= IDLE;
      addr       <= (others => '0');
      ram_addr_o <= (others => '0');
      fifo_din_o <= (others => '0');
      fifo_wr_o  <= '0';
      busy_o     <= '0';
      done_o     <= '0';

    elsif rising_edge(clk_i) then

      -- Default
      fifo_wr_o <= '0';
      done_o    <= '0';

      case state is

        when IDLE =>
          busy_o <= '0';
          if enable_i = '1' then
            addr       <= (others => '0');
            ram_addr_o <= (others => '0');
            busy_o     <= '1';
            state      <= READ_RAM;
          end if;

        -- Presenta l'indirizzo alla RAM e aspetta un ciclo
        when READ_RAM =>
		  ram_addr_o <= std_logic_vector(addr);
		  state      <= WAIT_DATA;  -- ciclo extra

		when WAIT_DATA =>
		  state <= WAIT_FIFO;       -- ora il dato è disponibile

		when WAIT_FIFO =>
		  if fifo_full_i = '0' then
		    state <= WRITE_FIFO;
		  end if;

        -- Scrive il dato nella FIFO
        when WRITE_FIFO =>
          fifo_din_o <= ram_data_i;
          fifo_wr_o  <= '1';
          if addr = (N_WORDS - 1) then
            state <= DONE;
          else
            addr       <= addr + 1;
            ram_addr_o <= std_logic_vector(addr + 1);
            state      <= WAIT_DATA;  -- salta READ_RAM: indirizzo già presentato
          end if;

        when DONE =>
          busy_o <= '0';
          done_o <= '1';  -- impulso per un ciclo
          state  <= WAIT_LOW;

      	when WAIT_LOW =>
		  busy_o <= '0';
		  if enable_i = '0' then
		    state <= IDLE;     -- solo ora è pronto per un nuovo dump
		  end if;

      end case;
    end if;
  end process;

end architecture rtl;