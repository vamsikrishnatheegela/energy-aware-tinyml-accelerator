# TEMPLATE ONLY — replace the clock period and I/O delays for your target.
# These constraints are not technology signoff constraints.
create_clock -name core_clk -period 20.000 [get_ports clk]
set_clock_uncertainty 0.200 [get_clocks core_clk]
# Constrain data inputs relative to the clock. Tune for the intended interface.
set_input_delay  1.000 -clock core_clk [get_ports {clear mac_en int8_mode a[*] b[*] rst_n}]
set_output_delay 1.000 -clock core_clk [get_ports accumulator[*]]
