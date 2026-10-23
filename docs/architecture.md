# Architecture and implementation plan

## Implemented RTL blocks

### Configurable signed MAC
`rtl/quant_mac.sv` accepts two 8-bit buses. When `int8_mode=1`, each operand is signed INT8. When `int8_mode=0`, only bits [3:0] are used and sign-extended as signed INT4. On each enabled rising edge, the signed product is added to a 32-bit accumulator. `clear` synchronously clears the accumulator; active-low `rst_n` resets it synchronously.

### Sequential convolution MAC engine
`rtl/conv_mac_engine.sv` accumulates one product per valid cycle. Assert `start` for one clock to clear the reduction and enter the busy state. Then present activation/weight pairs with `input_valid=1`; assert `in_last` alongside the final valid pair. The final sum is captured in `result` and `result_valid` pulses for one cycle. The controller must not issue a new `start` while a reduction is in progress.

### Requantization and activation
`rtl/requantize_relu.sv` applies signed rounding, arithmetic right shift, optional ReLU, and saturation to signed INT8 or INT4 range. The current interface uses a shift amount as the fixed-point scale. It is a building block; the exact scale and rounding behavior must be matched to the software golden model.

INT4 range: -8 to +7. INT8 range: -128 to +127. The 32-bit accumulator is a baseline width, not a claim that every possible layer is overflow-proof. Layer-level range analysis is required before CNN deployment.

## Depthwise 3x3 reduction
`rtl/depthwise_conv3x3.sv` accepts nine activation/weight pairs for one channel and one spatial output, in tap order. It accumulates one valid pair per cycle and asserts `result_valid` on the ninth valid tap. It supports signed INT4 and INT8 operands. It does not yet generate sliding windows or contain line buffers; those belong in the next integration layer.

## Planned hierarchy
1. Configurable MAC and generic reduction engine — RTL implemented and simulation-tested.
2. Depthwise 3x3 tap reduction — RTL implemented; run `make sim` to verify locally.
3. Sliding-window generator and line buffers.
4. Pointwise convolution channel-mixing controller.
5. Layer configuration, memory interface, and Python golden model.
6. End-to-end verification, synthesis and physical design on a supported open PDK.

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
