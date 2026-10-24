# Implementation Roadmap

## M0 — Baseline and reproducibility
- [ ] Confirm existing MAC RTL and testbench pass on the documented simulator.
- [ ] Record tool versions and baseline source revision.
- [ ] Preserve baseline before low-power changes.

## M1 — Datapath baseline
- [ ] Parameterized signed MAC / tiled matrix engine.
- [ ] Independent reference model and self-checking tests.
- [ ] Signed extrema, precision switching, reset, and accumulator-boundary tests.

## M2 — Clock gating
- [ ] Add idle detection and a clock-enable output.
- [ ] Integrate with a supported ICG cell or use a clearly labeled simulation abstraction.
- [ ] Compare switching activity for identical workloads.

## M3 — Power-domain sequencing
- [ ] Add power-state FSM in the always-on domain.
- [ ] Add power-switch request, power-good, and isolation handshake.
- [ ] Define retention/reset behavior for compute state.
- [ ] Add transition assertions and randomized wake-up tests.
- [ ] Integrate actual UPF/cells only if the selected flow supports them.

## M4 — DVFS control
- [ ] Add low/nominal/high operating-point requests.
- [ ] Hold request stable until acknowledgement.
- [ ] Define transition ordering and failure/timeout behavior.
- [ ] Test changes in requested performance during an outstanding transition.
- [ ] Keep physical voltage/frequency claims separate from RTL protocol simulation.

## M5 — Integration and verification
- [ ] Integrate datapath and power manager.
- [ ] Add randomized regression, coverage, assertions, and mutation tests.
- [ ] Compare outputs against the reference model in all power modes.

## M6 — RTL-to-GDSII and results
- [ ] Run synthesis and inspect inferred cells.
- [ ] Run floorplan, placement, CTS, routing, and timing analysis on a supported platform.
- [ ] Verify whether ICG and multi-power-domain cells are actually supported.
- [ ] Generate activity-based power estimates where possible.
- [ ] Publish reproducible scripts, logs, and results without invented metrics.
