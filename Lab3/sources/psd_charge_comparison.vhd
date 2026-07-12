-------------------------------------------------------------------------------
-- Pulse Shape Discrimination (PSD) - Charge Comparison Method
--
-- Scopo:
--   Distinguere fotoni (gamma) da neutroni nei segnali di uno scintillatore
--   tramite il rapporto:
--       PSD_ratio = Q_tail / Q_total
--
--   I fotoni producono impulsi con coda corta  → PSD_ratio basso
--   I neutroni producono impulsi con coda lunga → PSD_ratio alto
--
-- Architettura interna:
--   1. Sottrazione della baseline (media mobile su campioni pre-trigger)
--   2. Rilevamento del fronte di salita (trigger con soglia programmabile)
--   3. Integrazione Q_total  [t_trig  .. t_trig + WIN_LONG  - 1]
--   4. Integrazione Q_tail   [t_trig + WIN_TAIL_START .. t_trig + WIN_LONG - 1]
--   5. Calcolo del rapporto PSD = Q_tail / Q_total  (divisore intero)
--   6. Comparazione con soglia → classificazione GAMMA / NEUTRONE
--
-- Parametri generici:
--   DATA_WIDTH      : larghezza campione ADC            (default 14 bit)
--   ACC_WIDTH       : larghezza accumulatori integrali   (default 28 bit)
--   WIN_LONG        : durata finestra integrazione totale (campioni, default 200)
--   WIN_TAIL_START  : inizio finestra coda dopo trigger   (campioni, default 30)
--   BASELINE_SAMPLES: campioni usati per stima baseline   (default 32)
--   THRESHOLD_TRIG  : soglia trigger sul segnale          (default 100 LSB)
--   PSD_THRESHOLD   : soglia confronto PSD × 1024         (default 340 → ~0.33)
--
-- Interfaccia:
--   clk        : clock di sistema
--   rst        : reset sincrono, attivo alto
--   adc_data   : campione ADC corrente (ingresso)
--   adc_valid  : strobe dato ADC valido
--   particle   : '0' = fotone/gamma, '1' = neutrone
--   psd_valid  : impulso di un ciclo clock: risultato pronto
--   q_total    : valore integrale totale (debug/monitoraggio)
--   q_tail     : valore integrale coda   (debug/monitoraggio)
--   psd_ratio  : rapporto PSD × 1024 (debug/monitoraggio)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity psd_charge_comparison is
  generic (
    DATA_WIDTH       : positive := 14;
    ACC_WIDTH        : positive := 28;
    WIN_LONG         : positive := 200;
    WIN_TAIL_START   : positive := 30;
    BASELINE_SAMPLES : positive := 32;
    THRESHOLD_TRIG   : positive := 100;
    PSD_THRESHOLD    : positive := 340    -- soglia × 1024 (≈ 0.33)
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    -- Interfaccia ADC
    adc_data  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    adc_valid : in  std_logic;
    -- Risultati
    particle  : out std_logic;            -- '0' gamma, '1' neutrone
    psd_valid : out std_logic;
    q_total   : out unsigned(ACC_WIDTH - 1 downto 0);
    q_tail    : out unsigned(ACC_WIDTH - 1 downto 0);
    psd_ratio : out unsigned(ACC_WIDTH - 1 downto 0)
  );
end entity psd_charge_comparison;

architecture rtl of psd_charge_comparison is

  -- -------------------------------------------------------------------------
  -- Costanti locali
  -- -------------------------------------------------------------------------
  constant BL_LOG2 : natural := 5;   -- log2(BASELINE_SAMPLES) = 5 per 32
  -- Se BASELINE_SAMPLES non è potenza di 2, usare un divisore diverso.
  -- In questa implementazione assumiamo BASELINE_SAMPLES = 32.

  -- -------------------------------------------------------------------------
  -- Tipi e segnali interni
  -- -------------------------------------------------------------------------

  -- Campione con segno (per sottrazione baseline)
  signal sample_raw      : unsigned(DATA_WIDTH - 1 downto 0);
  signal sample_sub      : unsigned(DATA_WIDTH - 1 downto 0);

  -- Stima baseline
  signal bl_accum        : unsigned(ACC_WIDTH - 1 downto 0);
  signal bl_value        : unsigned(DATA_WIDTH - 1 downto 0);
  signal bl_count        : unsigned(5 downto 0);          -- fino a 32
  signal bl_ready        : std_logic;

  -- Stato FSM
  type state_t is (
    ST_BASELINE,    -- acquisizione campioni per baseline
    ST_IDLE,        -- attesa trigger
    ST_INTEGRATE,   -- integrazione attiva
    ST_DIVIDE,      -- calcolo rapporto (divisione seriale)
    ST_OUTPUT       -- presentazione risultato
  );
  signal state           : state_t;

  -- Contatore campioni all'interno della finestra
  signal win_count       : unsigned(8 downto 0);          -- 0..511

  -- Accumulatori integrali
  signal acc_total       : unsigned(ACC_WIDTH - 1 downto 0);
  signal acc_tail        : unsigned(ACC_WIDTH - 1 downto 0);
  signal dbg             : unsigned(8 downto 0);
  -- Divisore: calcola q_tail × 1024 / q_total  (shift-and-subtract)
  constant DIV_STEPS     : positive := ACC_WIDTH + 10;    -- 10 bit frazionari
  signal div_step        : unsigned(5 downto 0);
  signal div_num         : unsigned(2 * ACC_WIDTH - 1 downto 0);
  signal div_den         : unsigned(ACC_WIDTH - 1 downto 0);
  signal div_quot        : unsigned(ACC_WIDTH - 1 downto 0);
  signal div_busy        : std_logic;

  -- Segnali di uscita interni
  signal psd_ratio_int   : unsigned(ACC_WIDTH - 1 downto 0);
  signal q_total_int     : unsigned(ACC_WIDTH - 1 downto 0);
  signal q_tail_int      : unsigned(ACC_WIDTH - 1 downto 0);

begin

  -- =========================================================================
  -- PROCESSO PRINCIPALE - FSM + datapath
  -- =========================================================================
  process(clk)
    variable partial : unsigned(ACC_WIDTH downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        -- Reset di tutti i segnali
        state          <= ST_BASELINE;
        bl_accum       <= (others => '0');
        bl_value       <= (others => '0');
        bl_count       <= (others => '0');
        bl_ready       <= '0';
        win_count      <= (others => '0');
        acc_total      <= (others => '0');
        acc_tail       <= (others => '0');
        div_step       <= (others => '0');
        div_num        <= (others => '0');
        div_den        <= (others => '0');
        div_quot       <= (others => '0');
        div_busy       <= '0';
        psd_ratio_int  <= (others => '0');
        q_total_int    <= (others => '0');
        q_tail_int     <= (others => '0');
        psd_valid      <= '0';
        particle       <= '0';
        q_total   <= (others => '0');
        q_tail    <= (others => '0');
        psd_ratio <= (others => '0');
      else
        -- Default: abbassa il valid di uscita ogni ciclo
        psd_valid <= '0';

        case state is

          -- ------------------------------------------------------------------
          -- ST_BASELINE: accumula i primi BASELINE_SAMPLES campioni
          -- ------------------------------------------------------------------
          when ST_BASELINE =>
            if adc_valid = '1' then
              sample_raw <= unsigned(adc_data);
              bl_accum   <= bl_accum + unsigned(adc_data);
              bl_count   <= bl_count + 1;
              if bl_count = to_unsigned(BASELINE_SAMPLES - 1, 6) then
                -- Divisione per BASELINE_SAMPLES (shift di BL_LOG2 = 5)
                bl_value  <= resize(
                               shift_right(bl_accum + unsigned(adc_data),
                                           BL_LOG2),
                               DATA_WIDTH);
                bl_ready  <= '1';
                state     <= ST_IDLE;
              end if;
            end if;

          -- ------------------------------------------------------------------
          -- ST_IDLE: attesa fronte di salita del segnale
          -- ------------------------------------------------------------------
          when ST_IDLE =>
            if adc_valid = '1' then
              sample_raw <= unsigned(adc_data);
              -- Sottrazione baseline (clip a zero per evitare underflow)
              if unsigned(adc_data) >= bl_value then
                sample_sub <= unsigned(adc_data) - bl_value;
              else
                sample_sub <= (others => '0');
              end if;

              -- Trigger: segnale sopra soglia
              if unsigned(adc_data) >= bl_value + THRESHOLD_TRIG then
                acc_total  <= (others => '0');
                acc_tail   <= (others => '0');
                win_count  <= (others => '0');
                state      <= ST_INTEGRATE;
              end if;
            end if;

          -- ------------------------------------------------------------------
          -- ST_INTEGRATE: integra Q_total e Q_tail
          -- ------------------------------------------------------------------
              when ST_INTEGRATE =>
                if adc_valid = '1' then
                  -- Sottrazione baseline
                  if unsigned(adc_data) >= bl_value then
                    sample_sub <= unsigned(adc_data) - bl_value;
                  else
                    sample_sub <= (others => '0');
                  end if;
    
                  -- Accumulo totale
                  acc_total <= acc_total + sample_sub;
    
                  -- Accumulo coda (solo dopo WIN_TAIL_START campioni)
                  if win_count >= WIN_TAIL_START then
                    acc_tail <= acc_tail + sample_sub;
                  end if;
    
                  win_count <= win_count + 1;
                  dbg <= to_unsigned(WIN_LONG - 1,9);
                  -- Fine finestra
                  if win_count = dbg then -- to_unsigned(WIN_LONG - 1, 9) then
                    q_total_int <= acc_total + sample_sub;
                    
                    -- q_tail_int  <= acc_tail  + (sample_sub when win_count >= WIN_TAIL_START else to_unsigned(0, DATA_WIDTH));
                    
                    if win_count >= WIN_TAIL_START then
                       q_tail_int <= acc_tail + sample_sub;
                    else
                       q_tail_int <= acc_tail + to_unsigned(0, DATA_WIDTH);
                    end if;
                    
                    -- Avvio divisione: calc (q_tail × 1024) / q_total
                    -- numeratore: q_tail_int << 10
                    div_num  <= shift_left(
                                  resize(acc_tail + sample_sub, 2 * ACC_WIDTH),
                                  10);
                    div_den  <= acc_total + sample_sub;
                    div_quot <= (others => '0');
                    div_step <= to_unsigned(ACC_WIDTH - 1, 6);
                    div_busy <= '1';
                    state    <= ST_DIVIDE;
                  end if;
                end if;

          -- ------------------------------------------------------------------
          -- ST_DIVIDE: divisione seriale non-restoring (shift-subtract)
          -- Calcola quoziente = (q_tail << 10) / q_total
          -- per ottenere il rapporto PSD con 10 bit frazionari
          -- ------------------------------------------------------------------
          when ST_DIVIDE =>
            -- Un passo di divisione per ciclo di clock
            
            
            
              partial := resize(
                           shift_right(div_num,
                                       to_integer(div_step))(ACC_WIDTH downto 0),
                           ACC_WIDTH + 1);
              if partial >= resize(div_den, ACC_WIDTH + 1) then
                div_quot(to_integer(div_step)) <= '1';
              else
                div_quot(to_integer(div_step)) <= '0';
              end if;

              if div_step = 0 then
                div_busy      <= '0';
                psd_ratio_int <= div_quot;
                state         <= ST_OUTPUT;
              else
                div_step <= div_step - 1;
              end if;
            

          -- ------------------------------------------------------------------
          -- ST_OUTPUT: presenta il risultato per un ciclo, poi torna a IDLE
          -- ------------------------------------------------------------------
          when ST_OUTPUT =>
            q_total   <= q_total_int;
            q_tail    <= q_tail_int;
            psd_ratio <= psd_ratio_int;

            -- Classificazione: neutrone se PSD_ratio > PSD_THRESHOLD
            if psd_ratio_int > PSD_THRESHOLD then
              particle <= '1';   -- neutrone
            else
              particle <= '0';   -- fotone / gamma
            end if;

            psd_valid <= '1';
            state     <= ST_IDLE;

          when others =>
            state <= ST_BASELINE;

        end case;
      end if;
    end if;
  end process;

  -- =========================================================================
  -- Assegnamenti combinatori ausiliari
  -- =========================================================================
  -- sample_raw e sample_sub sono aggiornati dentro il processo,
  -- nessun altro output combinatorio necessario.

end architecture rtl;

