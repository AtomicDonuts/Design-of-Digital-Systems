----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.04.2026 12:18:50
-- Design Name: 
-- Module Name: top_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_tb is
--  Port ( );
end top_tb;



architecture Behavioral of top_tb is

signal CLK100 : std_logic := '0';
signal BTN    : std_logic := '0';
signal ADC_D_OUT : STD_LOGIC_VECTOR (0 to 7);
signal DATAVALID_OUT : STD_LOGIC;
signal ADC_D_IN :  STD_LOGIC_VECTOR (0 to 7);
signal DATAVALID_IN : STD_LOGIC;
signal DATA_OUT :  STD_LOGIC_VECTOR (0 to 15);
signal OUT_VALID : STD_LOGIC;

constant BTN_DELAY       : time := 303 ns;
constant BTN_PULSE_WIDTH : time := 203 ns;

begin

uut : entity work.top
    port map (
      CLK100 => CLK100,
      BTN    => BTN,
      ADC_D_OUT => ADC_D_OUT,
      DATAVALID_OUT => DATAVALID_OUT,
      ADC_D_IN => ADC_D_IN,
      DATAVALID_IN => DATAVALID_IN,
      DATA_OUT => DATA_OUT,
      OUT_VALID => OUT_VALID   
    );


  -- 100 MHz board oscillator
  CLK100 <= not CLK100 after 5 ns;
  
  ADC_D_IN <= ADC_D_OUT;
  DATAVALID_IN <= DATAVALID_OUT;
  
  btnp : process  
  begin
  
  BTN <= '0';
  wait for BTN_DELAY;
  BTN <= '1';
  wait for BTN_PULSE_WIDTH;
  BTN <= '0';
  -- wait;
  end process;
  
  

end Behavioral;
