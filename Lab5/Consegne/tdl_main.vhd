----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.03.2026 17:42:13
-- Design Name: 
-- Module Name: tdl_main - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.UART_lib.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;


entity tdl_main is
    generic (
        TDC_ENABLE : boolean := true  -- false = solo UART, true = UART + TDC
      );
    Port ( sw : in STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0):= (others => '0');
           btn : in STD_LOGIC_VECTOR (3 downto 0);
           UART_rxd : in std_logic;
           UART_txd : out std_logic := '0';
           trig_in  : in std_logic;
           trig_out : out std_logic;
           clk : in std_logic);
end tdl_main;

architecture Behavioral of tdl_main is

constant N_switches : integer := 16;
constant N_buttons : integer := 2;

signal locked_int : std_logic := '0';
signal clk_int : std_logic := '0';
signal clk_fast : std_logic := '0';
signal reset_int : std_logic := '0';
signal tick_int : std_logic := '0';


signal btn_pressed : std_logic_vector ((N_buttons-1) downto 0):= (others => '0');
signal btn_level : std_logic_vector ((N_buttons-1) downto 0):= (others => '0');

signal sw_active : std_logic_vector ((N_switches-1) downto 0):= (others => '0');

signal fifo_empty : std_logic := '0';
signal fifo_full : std_logic := '0';
signal fifo_wrreq : std_logic := '0';
signal fifo_rdreq : std_logic := '0';
signal fifo_din : std_logic_vector (7 downto 0):= (others => '0');
signal fifo_dout : std_logic_vector (7 downto 0):= (others => '0');

signal uart_rx_done : std_logic := '0';
signal uart_tx_done : std_logic := '0';
signal uart_tx_start : std_logic := '0';

signal tap_out_reg     : std_logic_vector (511 downto 0):= (others => '0');
signal tdc_event_valid : std_logic := '0';
signal tdc_event       : std_logic_vector (11 downto 0):= (others => '0');

signal start_tdl 	: std_logic := '0';
signal start_tdl_reg  : std_logic := '0';
signal start_tdl_reg2 : std_logic := '0';
signal stop_tdl  : std_logic := '0';
signal reset_tdl  : std_logic := '0';

signal coarse_time    : std_logic_vector (8 downto 0):= (others => '0');

signal start_sync_out : std_logic := '0';
signal start_rand_out : std_logic := '0';
signal ring_osc_out : std_logic := '0';
signal ring_osc_out1 : std_logic := '0';
signal pulse_gen_out : std_logic := '0';
signal pulse_gen_out1 : std_logic := '0';
signal pulse_out : std_logic := '0';

signal histogram_overflow : std_logic := '0';
signal histogram_reset : std_logic := '0';
signal ram_rd_addr : std_logic_vector (11 downto 0):= (others => '0');
signal ram_rd_data : std_logic_vector (7 downto 0):= (others => '0');

signal enable_calibration  : std_logic := '0';
signal enable_measurement  : std_logic := '0';
signal enable_datatransfer : std_logic := '0';
signal disable_tdcwrapper  : std_logic := '0';
signal busy_datatransfer : std_logic := '0';

signal tdc_histogram_event : std_logic := '0';
signal tdc_histogram_address : std_logic_vector(11 downto 0);
signal tdc_histogram_rdaddress : std_logic_vector(11 downto 0);

--attribute DONT_TOUCH : string;
--attribute DONT_TOUCH of ring_osc_out : signal is "TRUE";


begin

reset_int <= not locked_int after 1 ns;

GEN_PB : for i in 1 to N_buttons generate
	PB_Debouncer_i 	: entity work.PB_Debouncer 		port map(clk => clk_fast, reset => reset_int, sw => btn(i-1), tick_out => btn_pressed(i-1), db_level => btn_level(i-1));
end generate GEN_PB;

GEN_SW : for i in 1 to N_switches generate
	SW_Debouncer_i 	: entity work.PB_Debouncer 		port map(clk => clk_fast, reset => reset_int, sw => sw(i-1), tick_out => open, db_level => sw_active(i-1));
end generate GEN_SW;

clk_0_i : entity work.clk_0	port map(clk_out1 => clk_int, clk_out2 => clk_fast, reset => '0', locked => locked_int, clk_in1 => clk);  

------------------------
-- UART COMMUNICATION --
------------------------

-- THIS IS THE PART FOR THE COMMIUNICATION WITH THE PC, THIS PART IS ALREADY COMPLETED AND WORKING

UART_com_i : UART_com
	generic map(
        N => 9, 			-- : integer := 4;   -- number of bits
        M => 326, 			-- 38400 Baud rate with 200 MHz clk  -- : integer := 10   -- mod-M
        DBIT    => 8,  		--: integer := 8;   -- # data bits
        SB_TICK => 16  		--: integer := 16   -- # ticks for stop bits
    )
    port map( 
		  clk 			    => clk_int, --: in std_logic;
		  reset 			  => reset_int,  --: in std_logic;
      UART_rxd 		  => '1', --: in std_logic;
      UART_rx_done 	=> open, --: out std_logic;
		  UART_rx_dout 	=> open, --: out std_logic_vector(7 downto 0);
      UART_txd 		  => UART_txd, --: out std_logic := '0';
      UART_tx_start => uart_tx_start, --: in std_logic;
      UART_tx_din 	=> fifo_dout, --: in std_logic_vector(7 downto 0);
      UART_tx_done	=> uart_tx_done  --: out std_logic := '0'
    );

uart_tx_start <= (not fifo_empty);
fifo_rdreq    <= uart_tx_done;-- show ahead fifo!

fifo_generator_0_i : entity work.fifo_generator_0 port map(
    rst         => reset_int,     --: IN STD_LOGIC;
    wr_clk      => clk_fast,     --: IN STD_LOGIC;
    rd_clk      => clk_int,     --: IN STD_LOGIC;
    din         => fifo_din,    --: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en       => fifo_wrreq,    --: IN STD_LOGIC;
    rd_en       => fifo_rdreq,    --: IN STD_LOGIC;
    dout        => fifo_dout,     --: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full        => fifo_full,     --: OUT STD_LOGIC;
    empty       => fifo_empty,
    prog_full   => open           --: OUT STD_LOGIC     --: OUT STD_LOGIC
  );

ram_dump_i : entity work.ram_to_fifo
  generic map(
    N_WORDS    => 4096,
    DATA_WIDTH => 8
  )
  port map(
    clk_i       => clk_fast,
    rst_i       => reset_int,
    enable_i    => enable_datatransfer,   -- bottone per avviare il dump
    ram_addr_o  => ram_rd_addr,      -- indirizzo di lettura della RAM
    ram_data_i  => ram_rd_data,      -- dato letto dalla RAM
    fifo_full_i => fifo_full,
    fifo_din_o  => fifo_din,
    fifo_wr_o   => fifo_wrreq,
    busy_o      => busy_datatransfer,
    done_o      => open              
  );

----------------------------
-- FE SIGNAL CONDITIONING --
----------------------------

--TODO: Instantiate a FDCE primitive named U_FF_INPUT for the signal conditioning here!


--  <-----Cut code below this line and paste into the architecture body---->

   -- FDCE: Single Data Rate D Flip-Flop with Asynchronous Clear and
   --       Clock Enable (posedge clk).  
   --       Artix-7
   -- Xilinx HDL Language Template, version 2025.2
  reset_tdl <= stop_tdl or reset_int;

  U_FF_INPUT : FDCE
   generic map (
      INIT => '0') -- Initial value of register ('0' or '1')  
   port map (
      Q => start_tdl,      -- Data output
      C => trig_in,      -- Clock input
      CE => '1',    -- Clock enable input
      CLR => reset_tdl,  -- Asynchronous clear input
      D => '1'       -- Data input
   );


---------
-- TDC --
---------

tdc_carry_chain_i : entity work.tdc_carry_chain
  generic map(
    N_CARRY4 => 128  --: integer := 64  -- numero di CARRY4 → 512 tap totali
  ) port map(
    hit_i   => start_tdl, 	-- : in  std_logic;  -- segnale da misurare (START)
    clk_i   => clk_fast, 		-- : in  std_logic;  -- clock di campionamento (STOP)
    stop_tdl=> stop_tdl, --: out  std_logic;  -- (STOP)
    tap_o   => tap_out_reg  		-- : out std_logic_vector(N_CARRY4*4 - 1 downto 0)
  );

coarse_counter_i : entity work.pulse_counter 
  generic map(COUNTER_WIDTH => 9, MAX_COUNT => (2**6), COUNT_RISING => false) 
  port map(clk_i => clk_fast, rst_i => reset_int, pulse_i => '1', count_o => coarse_time, overflow_o => pulse_gen_out1);


-- THE OVERFLOW OF THE COARSE COUNTER IS USED AS TRIG_OUT TO GENERATE A SIGNAL SYNC TO CLK_FAST
U_STRETCH_PULSE : entity work.pulse_stretcher
  generic map(N_CYCLES => 4)
  port map(clk_i => clk_fast, rst_i => reset_int, pulse_i => pulse_gen_out1, level_o => pulse_gen_out, delay_o => open);

tdc_event_wrapper_i : entity work.tdc_event_wrapper
  generic map(
      N_TAP => 128
    )
  Port map( 
    clk             => clk_fast, --: in std_logic;
    reset           => reset_int, --disable_tdcwrapper, --: in std_logic;
    trig_tdl        => stop_tdl, --: in std_logic;
    tap_in          => tap_out_reg, --: in std_logic_vector ((N_TAP*4-1) downto 0):= (others => '0');
    coarse_time     => coarse_time(3 downto 0), --: in std_logic_vector (7 downto 0):= (others => '0');
    data_valid_out  => tdc_event_valid, --: out std_logic;
    data_out        => tdc_event  --: out std_logic_vector (11 downto 0):= (others => '0')
    );
disable_tdcwrapper <= reset_int or enable_datatransfer or histogram_overflow;

-------------------------------------
-- RING OSCILLATOR FOR CALIBRATION --
-------------------------------------

ring_osc_i : entity work.ring_oscillator generic map(N_CARRY4 => 157) port map(enable_i => enable_calibration, osc_o => ring_osc_out1);
osc_counter_i : entity work.pulse_counter 
  generic map(COUNTER_WIDTH => 16, MAX_COUNT => 97, COUNT_RISING => false) 
  port map(clk_i => ring_osc_out1, rst_i => reset_int, pulse_i => '1', count_o => open, overflow_o => ring_osc_out);

-----------------------
-- histogram of data --
-----------------------

histogram : entity work.tdc_histogram port map(
    clk_i        => clk_fast,            -- : in  std_logic;
    rst_i        => histogram_reset,    -- : in  std_logic;
    hit_valid_i  => tdc_histogram_event,    -- : in  std_logic;  -- evento valido in ingresso
    addr_i       => tdc_histogram_address,          -- : in  std_logic_vector(11 downto 0);  -- tap colpito
    rd_en_i      => busy_datatransfer,
    rd_addr_i    => tdc_histogram_rdaddress,                   -- : in  std_logic_vector(11 downto 0);  -- indirizzo di lettura
    rd_data_o    => ram_rd_data,                   -- : out std_logic_vector(7 downto 0);  -- dato letto
    overflow_o   => histogram_overflow  -- : out std_logic   -- almeno un contatore ha saturato
  );
histogram_reset <= btn_pressed(1);
tdc_histogram_event <= tdc_event_valid;
tdc_histogram_address <= tdc_event;
tdc_histogram_rdaddress <= ram_rd_addr;



------------------------
-- PROCESS MANAGEMENT --
------------------------



proc_man : process(clk_fast, reset_int)
begin
  if reset_int = '1' then
    enable_calibration  <= '0';
    enable_measurement  <= '0';
    enable_datatransfer <= '0';
  elsif rising_edge(clk_fast) then
    -- TODO:

    -- enable_calibration should be activated with when switch(0) is active
    if sw_active(0) = '1' then
      enable_calibration  <= '1';
      enable_measurement  <= '0';
      enable_datatransfer <= '0';

    -- enable_measurement should be activated with when switch(1) is active
    else 
      if sw_active(1) = '1' then
        enable_calibration  <= '0';
        enable_measurement  <= '1';
        enable_datatransfer <= '0';
      else
        -- enable_datatransfer should be activated with when switch(2) is active
        if sw_active(2) = '1' then
          enable_calibration  <= '0';
          enable_measurement  <= '0';
          enable_datatransfer <= '1';
        else
          enable_calibration  <= '0';
          enable_measurement  <= '0';
          enable_datatransfer <= '0';
        end if;
      end if;
    end if ;
    -- if more than one switch is active at the same time do not enable any function.

  end if;
end process;

pulse_out   <=  ring_osc_out          when enable_calibration = '1'  
          else  pulse_gen_out         when enable_measurement = '1'
          else '0';
trig_out    <= pulse_out when histogram_overflow = '0' else '0';

------------
--  LEDS  --
------------

led(15) <= fifo_full;
led(14) <= fifo_empty;
led(13) <= histogram_overflow;
led(12) <= busy_datatransfer;
led(11) <= disable_tdcwrapper;
led(8) <= '0';
led(5) <= '0';
led(4) <= '0';
led(3) <= '0';
led(2) <= '0';
led(1) <= '0';
led(0) <= '0';



U_STRETCH_STOP : entity work.pulse_stretcher
  generic map(N_CYCLES => 20_000_000)
  port map(clk_i   => clk_fast, rst_i   => reset_int, pulse_i => trig_in, level_o => led(9), delay_o => open);

U_STRETCH_PULSE_OUT : entity work.pulse_stretcher
  generic map(N_CYCLES => 20_000_000)
  port map(clk_i   => clk_fast, rst_i   => reset_int, pulse_i => pulse_out, level_o => led(10), delay_o => open);

U_STRETCH_start_tdl : entity work.pulse_stretcher
  generic map(N_CYCLES => 20_000_000)
  port map(clk_i   => clk_fast, rst_i   => reset_int, pulse_i => start_tdl, level_o => led(7), delay_o => open);

U_STRETCH_STOP_TDL : entity work.pulse_stretcher
  generic map(N_CYCLES => 20_000_000)
  port map(clk_i   => clk_fast, rst_i   => reset_int, pulse_i => stop_tdl, level_o => led(6), delay_o => open);


end Behavioral;