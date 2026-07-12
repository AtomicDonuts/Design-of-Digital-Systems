# clk input is from the 100 MHz oscillator on Boolean board
# create_clock -period 10.000 -name gclk [get_ports CLK100]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports CLK100]

# Set Bank 0 voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# ADC EMULATOR
set_property -dict {PACKAGE_PIN T6 IOSTANDARD LVCMOS33} [get_ports {ADC_D_OUT[0]}]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports {ADC_D_OUT[1]}]
set_property -dict {PACKAGE_PIN R5 IOSTANDARD LVCMOS33} [get_ports {ADC_D_OUT[2]}]
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS33} [get_ports {ADC_D_OUT[3]}]
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports {ADC_D_OUT[4]}]
set_property -dict {PACKAGE_PIN T3 IOSTANDARD LVCMOS33} [get_ports {ADC_D_OUT[5]}]
set_property -dict {PACKAGE_PIN N5 IOSTANDARD LVCMOS33} [get_ports {ADC_D_OUT[6]}]
set_property -dict {PACKAGE_PIN N4 IOSTANDARD LVCMOS33} [get_ports {ADC_D_OUT[7]}]

set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports DATAVALID_OUT]

set_property -dict {PACKAGE_PIN R7 IOSTANDARD LVCMOS33} [get_ports {ADC_D_IN[0]}]
set_property -dict {PACKAGE_PIN R6 IOSTANDARD LVCMOS33} [get_ports {ADC_D_IN[1]}]
set_property -dict {PACKAGE_PIN P6 IOSTANDARD LVCMOS33} [get_ports {ADC_D_IN[2]}]
set_property -dict {PACKAGE_PIN P5 IOSTANDARD LVCMOS33} [get_ports {ADC_D_IN[3]}]
set_property -dict {PACKAGE_PIN L5 IOSTANDARD LVCMOS33} [get_ports {ADC_D_IN[4]}]
set_property -dict {PACKAGE_PIN M4 IOSTANDARD LVCMOS33} [get_ports {ADC_D_IN[5]}]
set_property -dict {PACKAGE_PIN K4 IOSTANDARD LVCMOS33} [get_ports {ADC_D_IN[6]}]
set_property -dict {PACKAGE_PIN L4 IOSTANDARD LVCMOS33} [get_ports {ADC_D_IN[7]}]

set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports DATAVALID_IN]

# OUTPUT

set_property -dict {PACKAGE_PIN B13 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[0]}]
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[1]}]
set_property -dict {PACKAGE_PIN B14 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[2]}]
set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[3]}]
set_property -dict {PACKAGE_PIN E12 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[4]}]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[5]}]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[6]}]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[7]}]
set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[8]}]
set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[9]}]
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[10]}]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[11]}]
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[12]}]
set_property -dict {PACKAGE_PIN A16 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[13]}]
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[14]}]
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {DATA_OUT[15]}]

set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports OUT_VALID]




# On-board Buttons
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports BTN]






