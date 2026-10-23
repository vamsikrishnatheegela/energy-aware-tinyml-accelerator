#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v yosys >/dev/null || { echo "ERROR: yosys not found in PATH"; exit 1; }
mkdir -p build reports/generated
yosys -p "read_verilog -sv rtl/quant_mac.sv; hierarchy -check -top quant_mac; proc; opt; check; synth -top quant_mac; stat" \
  | tee reports/generated/yosys_quant_mac.log
