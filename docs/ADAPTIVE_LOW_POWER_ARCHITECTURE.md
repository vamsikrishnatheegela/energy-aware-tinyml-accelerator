# Adaptive Low-Power Matrix-Multiplication Accelerator

## Objective
Extend the INT4/INT8 TinyML accelerator into a reproducible low-power RTL-to-GDSII study. Evaluate clock gating, a power-domain control protocol, and DVFS operating-point requests while preserving matrix-operation correctness.

## Scope and implementation boundary
This is an educational RTL project. It distinguishes:
- RTL-functional behavior: synthesizable controller and datapath verified in simulation.
- Power-intent implementation: isolation, retention, and switchable-domain cells only when supported by the selected library, UPF flow, and implementation tools.
- DVFS physical realization: voltage/frequency changes are represented by a request/acknowledge interface in RTL. A real regulator, programmable clock source, characterized operating points, and multi-voltage timing signoff are outside the RTL model unless separately implemented.

A successful RTL simulation or GDSII export alone does not prove silicon power-gating or DVFS signoff.

## Proposed blocks
1. Command interface: operation start, matrix/tile dimensions, precision mode, requested performance class.
2. Tile controller: schedules tiles and tracks outstanding operations.
3. MAC processing array: parameterized signed INT4/INT8 multiply-accumulate datapath.
4. Local operand/result buffers: initially synthesizable register arrays; replace with SRAM macros only when a compatible macro and flow are available.
5. Always-on power manager: remains powered while compute logic is off.
6. Clock-enable interface: drives an integrated clock-gating (ICG) cell enable. Do not use a combinational AND gate on a clock in ASIC implementation.
7. Power-domain handshake: isolation, power-switch request, power-good wait, and wake-up.
8. DVFS handshake: requests a characterized operating-point ID and waits for acknowledgement.
9. Verification environment: independent arithmetic reference model, assertions, directed/random tests, coverage, and regression scripts.

## Power-management policy
- Keep compute active while a command or outstanding transaction exists.
- Request a low operating point for low-performance workloads and a high operating point when throughput requires it.
- Gate the compute clock after a configurable idle timeout.
- Request power-down only after the design is idle, no operation is outstanding, and clock gating is active.
- On wake-up: request power on, wait for power_good, release isolation in the correct sequence, request the required DVFS point, then enable compute clock and accept work.
- A low RTL control bit does not prove the compute domain is physically off; physical power switching must be mapped and verified in the implementation flow.

## Operating-point abstraction
Use an operating-point ID instead of hardcoding voltages in the datapath: OP_LOW, OP_NOMINAL, OP_HIGH. Voltage and frequency values must be documented from a real library/platform before making physical timing or power claims.

## Evaluation plan
Run the same matrix workloads for: (1) baseline always-on clock/power model, (2) clock-gated, (3) clock plus power gating, and (4) adaptive clock/power gating plus workload-driven DVFS requests.

Report measured values only: output correctness, cycles/latency/throughput, clock-enable duty cycle or switching activity, synthesized area and critical-path delay, power estimates when supported by activity data, wake-up latency and energy break-even idle duration, functional coverage, assertion results, and mutation-test detection rate.

## Initial assumptions
- Signed two's-complement INT4 and INT8 arithmetic.
- Accumulator width is explicit and overflow behavior is checked.
- Start with a small 2x2 or 4x4 tiled array.
- Never discard an accepted command during sleep or wake-up.
- Reset returns the controller to a known safe state with compute isolated until power-good is established.
