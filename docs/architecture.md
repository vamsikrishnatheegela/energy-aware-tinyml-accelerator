# Architecture and implementation plan

## Current block: configurable signed MAC
`rtl/quant_mac.sv` accepts two 8-bit buses. When `int8_mode=1`, each operand is interpreted as signed INT8. When `int8_mode=0`, only bits [3:0] are used and sign-extended as signed INT4. On each enabled rising edge, the signed product is added to a 32-bit accumulator. `clear` synchronously clears the accumulator; active-low `rst_n` resets it synchronously.

INT4 range: -8 to +7. INT8 range: -128 to +127. The 32-bit accumulator is a baseline width, not a claim that every possible layer is overflow-proof. Layer-level range analysis and requantization must be added before CNN deployment.

## Planned hierarchy
1. **Quantized MAC** — current milestone.
2. **Line/window and coefficient buffers** — provide input and weight reuse.
3. **Depthwise convolution** — independent spatial filtering per input channel.
4. **Pointwise convolution** — 1x1 channel mixing.
5. **Requantization/activation** — configurable shift/rounding, saturation, ReLU.
6. **Controller and memory interface** — layer configuration, buffer sequencing, done/valid.
7. **Verification** — self-checking directed/random tests and Python golden model.
8. **Synthesis/physical design** — target a supported open PDK, compare equivalent configurations.

## Energy-aware experiments
Measure rather than assume benefits:
- INT8 baseline vs INT4 and mixed precision.
- Operand isolation when the datapath is idle.
- Reuse of weights/activations and reduced memory traffic.
- Optional parallelism changes, normalized by the same workload and constraints.

For each experiment record functional equivalence, cell area, critical path, frequency, estimated power, energy per inference, and workload/precision settings. Include tool and PDK versions. Do not compare power reports from unmatched constraints or activity assumptions.

## RTL design cautions
- Specify signedness explicitly at arithmetic boundaries.
- Derive accumulator width from reduction length and operand range.
- Define rounding, saturation, and quantization semantics before connecting a framework model.
- Avoid inferred latches and unconstrained asynchronous crossings.
- Treat clock gating as a later implementation step; use a supported integrated clock-gating methodology rather than gating clocks with arbitrary RTL logic.
