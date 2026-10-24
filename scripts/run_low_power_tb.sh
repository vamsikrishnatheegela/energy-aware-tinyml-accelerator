#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
iverilog -g2012 -Wall -s tb_adaptive_power_manager -o build/tb_adaptive_power_manager.vvp \
  rtl/adaptive_power_manager.sv tb/tb_adaptive_power_manager.sv
vvp build/tb_adaptive_power_manager.vvp
