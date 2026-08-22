set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

set_property PACKAGE_PIN V17 [get_ports btnreset]
set_property IOSTANDARD LVCMOS33 [get_ports btnreset]

set_property PACKAGE_PIN J1 [get_ports echo]
set_property IOSTANDARD LVCMOS33 [get_ports echo]

set_property PACKAGE_PIN L2 [get_ports trigger]
set_property IOSTANDARD LVCMOS33 [get_ports trigger]

set_property PACKAGE_PIN J2 [get_ports servo1]
set_property IOSTANDARD LVCMOS33 [get_ports servo1]

set_property PACKAGE_PIN G2 [get_ports servo2]
set_property IOSTANDARD LVCMOS33 [get_ports servo2]

set_property PACKAGE_PIN A14 [get_ports buzzer]
set_property IOSTANDARD LVCMOS33 [get_ports buzzer]

set_property PACKAGE_PIN K17 [get_ports led1]
set_property IOSTANDARD LVCMOS33 [get_ports led1]

set_property PACKAGE_PIN M18 [get_ports led2]
set_property IOSTANDARD LVCMOS33 [get_ports led2]

set_property PACKAGE_PIN N17 [get_ports led3]
set_property IOSTANDARD LVCMOS33 [get_ports led3]

set_property PACKAGE_PIN A16 [get_ports laser_servo_pan]
set_property IOSTANDARD LVCMOS33 [get_ports laser_servo_pan]

set_property PACKAGE_PIN B15 [get_ports laser_servo_tilt]
set_property IOSTANDARD LVCMOS33 [get_ports laser_servo_tilt]

set_property PACKAGE_PIN B16 [get_ports laser_out]
set_property IOSTANDARD LVCMOS33 [get_ports laser_out]

set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[*]}]

set_property PACKAGE_PIN U2 [get_ports {anode[0]}]
set_property PACKAGE_PIN U4 [get_ports {anode[1]}]
set_property PACKAGE_PIN V4 [get_ports {anode[2]}]
set_property PACKAGE_PIN W4 [get_ports {anode[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode[*]}]
