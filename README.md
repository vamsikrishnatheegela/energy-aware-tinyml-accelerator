# Energy-Aware INT4/INT8 TinyML Accelerator

A reproducible RTL-to-GDSII learning project for an energy-aware accelerator targeting depthwise-separable CNN inference. The initial milestone is a verified signed INT4/INT8 multiply-accumulate (MAC) datapath; convolution control, quantization, synthesis, physical design, and power analysis will be added incrementally.

> **Status:** Initial RTL scaffold. No PPA, power, CNN-accuracy, DRC/LVS, or signoff results are claimed yet.

## Goals
- Implement signed two's-complement INT4 and INT8 MAC operations.
- Build and verify reusable datapath blocks for depthwise and pointwise convolution.
- Compare INT8 against INT4/mixed-precision configurations using identical test vectors.
- Establish a repeatable RTL → simulation → synthesis → floorplan → placement → CTS → routing → extraction/STA → physical verification flow.
- Report measured area, timing, and power only from reproducible tool runs.

## Repository layout
- `rtl/` — synthesizable SystemVerilog
- `tb/` — self-checking simulation testbenches
- `scripts/` — local simulation and flow helpers
- `constraints/` — timing constraints (initial template; must be tuned)
- `docs/` — architecture, verification, and PPA methodology
- `reports/` — generated reports (not source-of-truth; large artifacts ignored)

## First milestone
1. Run `make sim` (requires Icarus Verilog).
2. Confirm the self-checking MAC test prints `ALL TESTS PASSED`.
3. Extend verification for overflow, signed extrema, reset, and precision switching.
4. Add the convolution datapath and golden-model comparison before physical design.

## RTL-to-GDSII flow
The intended educational flow uses open-source tools such as Yosys, OpenROAD/OpenROAD-flow-scripts, OpenSTA, KLayout, Magic, and Netgen, with a supported PDK/platform (for example, SKY130). Exact commands and configuration depend on the installed flow and PDK.

**A generated GDSII file is not automatically signoff-ready.** Signoff requires the relevant foundry/PDK-qualified DRC/LVS decks, extraction, timing corners, antenna/density checks, and other platform-specific checks to pass. This project will label results as educational/open-source-flow results unless the required signoff conditions are demonstrably met.

## Reproducibility
Record tool versions, PDK/platform, configuration, timing constraints, and commands alongside every reported result. Do not publish placeholder numbers as measured PPA.

## License
MIT (see `LICENSE`).