library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity ring_oscillator is
  generic (
    N_CARRY4 : integer := 1  -- numero di CARRY4 in cascata, aumenta per ridurre la frequenza
  );
  port (
    enable_i : in  std_logic;
    osc_o    : out std_logic
  );
end entity;

architecture rtl of ring_oscillator is

  signal co : std_logic_vector(N_CARRY4 * 4 - 1 downto 0);
  signal ci : std_logic_vector(N_CARRY4 - 1 downto 0);
  signal ring_fb : std_logic;

  attribute DONT_TOUCH : string;
  attribute DONT_TOUCH of rtl : architecture is "TRUE";

begin

  -- Feedback: invertitore + gate enable
  -- INIT = 0100 -> O = (NOT I0) AND I1  =  inv(co_last) AND enable
  U_LUT_GATE : LUT2
    generic map (INIT => X"4")
    port map (
      I0 => co(N_CARRY4 * 4 - 1),
      I1 => enable_i,
      O  => ring_fb
    );

  -- Primo CARRY4: CI viene dal feedback
  ci(0) <= ring_fb;

  U_CARRY4_FIRST : CARRY4
    port map (
      CI     => '0',       -- CI del primo stadio a '0'
      CYINIT => ci(0),     -- usiamo CYINIT per iniettare il feedback
      DI     => "0000",
      S      => "1111",    -- S=1 -> CO(i) = CI(i), propaga senza modifiche
      CO     => co(3 downto 0),
      O      => open
    );

  -- Stadi aggiuntivi in cascata (se N_CARRY4 > 1)
  GEN_CARRY : for i in 1 to N_CARRY4 - 1 generate
    attribute DONT_TOUCH of U_CARRY4 : label is "TRUE";
  begin
    U_CARRY4 : CARRY4
      port map (
        CI     => co(i * 4 - 1),
        CYINIT => '0',
        DI     => "0000",
        S      => "1111",
        CO     => co(i * 4 + 3 downto i * 4),
        O      => open
      );
  end generate;

  osc_o <= co(N_CARRY4 * 4 - 1);

end architecture rtl;