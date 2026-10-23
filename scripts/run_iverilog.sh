#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build

iverilog -g2012 -Wall -s tb_quant_mac -o build/tb_quant_mac.vvp \
  rtl/quant_mac.sv tb/tb_quant_mac.sv
vvp build/tb_quant_mac.vvp

iverilog -g2012 -Wall -s tb_conv_mac_engine -o build/tb_conv_mac_engine.vvp \
  rtl/conv_mac_engine.sv tb/tb_conv_mac_engine.sv
vvp build/tb_conv_mac_engine.vvp

iverilog -g2012 -Wall -s tb_requantize_relu -o build/tb_requantize_relu.vvp \
  rtl/requantize_relu.sv tb/tb_requantize_relu.sv
vvp build/tb_requantize_relu.vvp
