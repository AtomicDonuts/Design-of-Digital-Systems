library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr_cipher is
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        enable : in  std_logic;

        fifo_in_empty  : in  std_logic;
        fifo_in_dout   : in  std_logic_vector(7 downto 0);
        fifo_in_rd_en  : out std_logic;

        fifo_out_full  : in  std_logic;
        fifo_out_din   : out std_logic_vector(7 downto 0);
        fifo_out_wr_en : out std_logic
    );
end entity lfsr_cipher;

architecture rtl of lfsr_cipher is

    constant SEED : std_logic_vector(7 downto 0) := x"A5";
    constant POLY : std_logic_vector(7 downto 0) := "10111000";

    type t_state is (ST_WAIT, ST_PROCESS, ST_WRITE);
    signal state      : t_state;

    signal lfsr_reg   : std_logic_vector(7 downto 0);
    signal data_latch : std_logic_vector(7 downto 0);
    signal xor_result : std_logic_vector(7 downto 0);

    function lfsr_next(reg  : std_logic_vector(7 downto 0);
                       poly : std_logic_vector(7 downto 0))
        return std_logic_vector is
        variable feedback : std_logic;
        variable nxt      : std_logic_vector(7 downto 0);
    begin
        feedback := reg(0);
        nxt      := '0' & reg(7 downto 1);
        for i in 0 to 7 loop
            if poly(i) = '1' then
                nxt(i) := nxt(i) xor feedback;
            end if;
        end loop;
        return nxt;
    end function;

begin

    process(clk, rst)
        variable v_lfsr      : std_logic_vector(7 downto 0);
        variable v_keystream : std_logic_vector(7 downto 0);
    begin
        if rst = '1' then
            state          <= ST_WAIT;
            lfsr_reg       <= SEED;
            data_latch     <= (others => '0');
            xor_result     <= (others => '0');
            fifo_in_rd_en  <= '0';
            fifo_out_wr_en <= '0';
            fifo_out_din   <= (others => '0');

        elsif rising_edge(clk) then
            fifo_in_rd_en  <= '0';
            fifo_out_wr_en <= '0';

            case state is

                when ST_WAIT =>
                    if enable = '1' and fifo_in_empty = '0' then
                        data_latch    <= fifo_in_dout;
                        fifo_in_rd_en <= '1';
                        state         <= ST_PROCESS;
                    end if;

                when ST_PROCESS =>
                    v_lfsr := lfsr_reg;
                    for i in 0 to 7 loop
                        v_keystream(i) := v_lfsr(0);
                        v_lfsr         := lfsr_next(v_lfsr, POLY);
                    end loop;
                    xor_result <= data_latch xor v_keystream;
                    lfsr_reg   <= v_lfsr;
                    state      <= ST_WRITE;

                when ST_WRITE =>
                    if fifo_out_full = '0' then
                        fifo_out_din   <= xor_result;
                        fifo_out_wr_en <= '1';
                        state          <= ST_WAIT;
                    end if;

            end case;
        end if;
    end process;

end architecture rtl;
