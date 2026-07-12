----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2026 03:17:40 PM
-- Design Name: 
-- Module Name: top - rtl
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
    port (
        CLK100 : in  std_logic;
        SW     : in  std_logic_vector(15 downto 0);
        LED    : out std_logic_vector(15 downto 0)
    );
end top;

architecture rtl of top is
    signal a_in : std_logic_vector(7 downto 0);
    signal b_in : std_logic_vector(7 downto 0);
    signal p_out : std_logic_vector(15 downto 0);
begin
    a_in <= SW(7 downto 0);
    b_in <= SW(15 downto 8);

    u_mult : entity work.multiplier
        port map (
            a => a_in,
            b => b_in,
            p => p_out
        );

    LED <= p_out;
end rtl;