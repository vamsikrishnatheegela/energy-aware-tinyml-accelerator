#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
iverilog -g2012 -Wall -s tb_quant_mac -o build/tb_quant_mac.vvp \
  rtl/quant_mac.sv tb/tb_quant_mac.sv
vvp build/tb_quant_mac.vvp
