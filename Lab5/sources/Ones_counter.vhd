library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Ones_counter is
  port ( 
    vec_in    : in  std_logic_vector(511 downto 0);
    clk       : in  std_logic;
    count_out : out std_logic_vector(9 downto 0)
  );
end Ones_counter;

architecture Behavioral of Ones_counter is

  function count_ones_8(data : std_logic_vector(7 downto 0)) return unsigned is
    variable count : unsigned(3 downto 0) := (others => '0');
  begin
    count := (others => '0');
    for i in 0 to 7 loop
      if data(i) = '1' then
        count := count + 1;
      end if;
    end loop;
    return count;
  end function;

  -- Stadio 0: 64 elementi da 4 bit (0..8, conta gli 1 in gruppi da 8)
  type stage0_array is array (0 to 63) of unsigned(3 downto 0);
  signal stage0 : stage0_array;

  -- Stadio 1: 32 elementi da 5 bit
  type stage1_array is array (0 to 31) of unsigned(4 downto 0);
  signal stage1 : stage1_array;

  -- Stadio 2: 16 elementi da 6 bit
  type stage2_array is array (0 to 15) of unsigned(5 downto 0);
  signal stage2 : stage2_array;

  -- Stadio 3: 8 elementi da 7 bit
  type stage3_array is array (0 to 7) of unsigned(6 downto 0);
  signal stage3 : stage3_array;

  -- Stadio 4: 4 elementi da 8 bit
  type stage4_array is array (0 to 3) of unsigned(7 downto 0);
  signal stage4 : stage4_array;

  -- Stadio 5: 2 elementi da 9 bit
  type stage5_array is array (0 to 1) of unsigned(8 downto 0);
  signal stage5 : stage5_array;

  -- Stadio 6: risultato finale da 10 bit
  signal stage6 : unsigned(9 downto 0);

  signal vec_in_reg : std_logic_vector(511 downto 0);

begin

	-- Registro di ingresso
	process(clk)
	begin
	  if rising_edge(clk) then
	    vec_in_reg <= vec_in;
	  end if;
	end process;

  -- Stadio 0: combinatorio, conta gli 1 in gruppi da 8
  gen_s0 : for i in 0 to 63 generate
    stage0(i) <= count_ones_8(vec_in_reg(i*8+7 downto i*8));
  end generate;

  -- Stadio 1: registrato
  gen_s1 : for i in 0 to 31 generate
    process(clk)
    begin
      if rising_edge(clk) then
        stage1(i) <= ('0' & stage0(2*i)) + ('0' & stage0(2*i+1));
      end if;
    end process;
  end generate;

  -- Stadio 2: registrato
  gen_s2 : for i in 0 to 15 generate
    process(clk)
    begin
      if rising_edge(clk) then
        stage2(i) <= ('0' & stage1(2*i)) + ('0' & stage1(2*i+1));
      end if;
    end process;
  end generate;

  -- Stadio 3: registrato
  gen_s3 : for i in 0 to 7 generate
    process(clk)
    begin
      if rising_edge(clk) then
        stage3(i) <= ('0' & stage2(2*i)) + ('0' & stage2(2*i+1));
      end if;
    end process;
  end generate;

  -- Stadio 4: registrato
  gen_s4 : for i in 0 to 3 generate
    process(clk)
    begin
      if rising_edge(clk) then
        stage4(i) <= ('0' & stage3(2*i)) + ('0' & stage3(2*i+1));
      end if;
    end process;
  end generate;

  -- Stadio 5: registrato
  gen_s5 : for i in 0 to 1 generate
    process(clk)
    begin
      if rising_edge(clk) then
        stage5(i) <= ('0' & stage4(2*i)) + ('0' & stage4(2*i+1));
      end if;
    end process;
  end generate;

  -- Stadio 6: risultato finale registrato
  process(clk)
  begin
    if rising_edge(clk) then
      stage6 <= ('0' & stage5(0)) + ('0' & stage5(1));
    end if;
  end process;

  count_out <= std_logic_vector(stage6);

end architecture Behavioral;