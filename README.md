# Energy-Aware INT4/INT8 TinyML Accelerator

A reproducible RTL-to-GDSII learning and research project targeting quantized depthwise-separable CNN inference.

> **Status:** Foundational arithmetic and convolution blocks are under active development. Individual simulation tests exist for the configurable MAC, sequential MAC, requantization, depthwise 3x3 reduction, streaming window generation, and pointwise 1x1 reduction. The complete layer controller, end-to-end inference verification, and physical-design results are not yet complete. No PPA, power, CNN-accuracy, DRC/LVS, or signoff results are claimed.

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
- `constraints/` — timing constraints (templates must be tuned for the integrated top)
- `docs/` — architecture, verification, and PPA methodology
- `reports/` — generated reports (not source-of-truth; large artifacts ignored)

## Simulation
Run `make sim` with Icarus Verilog installed. The script runs the individual self-checking testbenches. Treat any failed assertion as a blocker before integrating or synthesizing.

## RTL-to-GDSII flow
The intended educational flow uses open-source tools such as Yosys, OpenROAD/OpenROAD-flow-scripts, OpenSTA, KLayout, Magic, and Netgen, with a supported PDK/platform (for example, SKY130). Exact commands and configuration depend on the installed flow and PDK.

**A generated GDSII file is not automatically signoff-ready.** Signoff requires the relevant foundry/PDK-qualified DRC/LVS decks, extraction, timing corners, antenna/density checks, and other platform-specific checks to pass. This project will label results as educational/open-source-flow results unless the required signoff conditions are demonstrably met.

## Reproducibility
Record tool versions, PDK/platform, configuration, timing constraints, and commands alongside every reported result. Do not publish placeholder numbers as measured PPA.

## License
MIT (see `LICENSE`).
