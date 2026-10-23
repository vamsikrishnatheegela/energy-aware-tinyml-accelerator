# Architecture and implementation plan

## Implemented RTL blocks

### Configurable signed MAC
`rtl/quant_mac.sv` accepts two 8-bit buses. When `int8_mode=1`, each operand is signed INT8. When `int8_mode=0`, only bits [3:0] are used and sign-extended as signed INT4. On each enabled rising edge, the signed product is added to a 32-bit accumulator. `clear` synchronously clears the accumulator; active-low `rst_n` resets it synchronously.

### Sequential convolution MAC engine
`rtl/conv_mac_engine.sv` accumulates one product per valid cycle. Assert `start` for one clock to clear the reduction and enter the busy state. Then present activation/weight pairs with `input_valid=1`; assert `in_last` alongside the final valid pair. The final sum is captured in `result` and `result_valid` pulses for one cycle. The controller must not issue a new `start` while a reduction is in progress.

### Requantization and activation
`rtl/requantize_relu.sv` applies signed rounding, arithmetic right shift, optional ReLU, and saturation to signed INT8 or INT4 range. The current interface uses a shift amount as the fixed-point scale. The exact scale and rounding behavior must match the software golden model.

INT4 range: -8 to +7. INT8 range: -128 to +127. The 32-bit accumulator is a baseline width, not a claim that every possible layer is overflow-proof. Layer-level range analysis is required before CNN deployment.

### Depthwise 3x3 reduction
`rtl/depthwise_conv3x3.sv` accepts nine activation/weight pairs for one channel and one spatial output, in tap order. It accumulates one valid pair per cycle and asserts `result_valid` on the ninth valid tap. It supports signed INT4 and INT8 operands.

### Streaming 3x3 window generator
`rtl/sliding_window_3x3.sv` accepts a raster-ordered stream of signed 8-bit pixels and uses two line memories plus horizontal delay registers to emit 3x3 windows. `IMAGE_WIDTH` is an elaboration-time parameter. Pulse `frame_start` before each frame; the block emits valid windows only when row and column indices are at least two. It currently assumes a continuous raster stream with no backpressure, no padding, and stride one. Line-memory read style and implementation mapping must be checked against the chosen synthesis tool and SRAM strategy.

### Pointwise 1x1 reduction
`rtl/pointwise_conv1x1.sv` wraps the generic reduction engine for one output channel at one spatial position. Supply one activation/weight pair per input channel and assert `in_last` on the final pair. An outer controller must select each output channel's weights and repeat the reduction for each output channel. This is a functional building block, not yet a multi-channel layer controller.

## Current integration status
The project has individually testable arithmetic, depthwise-reduction, window-generation, and pointwise-reduction blocks. A complete layer-level top module, memory/weight interface, and end-to-end image inference test are still pending. The current window generator produces signed 8-bit pixels; INT4 mode is applied in the compute engines by interpreting the low nibbles of their input buses.

## Planned hierarchy
1. Integrate a layer controller around the window generator and depthwise compute.
2. Add explicit channel/weight storage and pointwise output-channel sequencing.
3. Define layer configuration, output buffering, quantization scales, and the external input/output protocol.
4. Add a Python golden model and end-to-end test vectors.
5. Synthesize the integrated top, then run floorplanning, placement, CTS, routing, extraction/STA and physical verification on a supported open PDK.

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


## Integrated depthwise-pointwise tile
`rtl/depthwise_pointwise_tile.sv` is the first controller-level integration. For one spatial position, the upstream controller supplies one 3x3 window per input channel, sequentially. The tile performs a nine-tap depthwise reduction per channel, requantizes each result, stores the quantized depthwise features, then performs one pointwise reduction per output channel and emits `out_valid`, `out_channel`, and `out_data`. `pixel_done` pulses after the final output channel; the tile returns to idle and expects a new `start` for the next spatial position.

Weights are programmed through the depthwise and pointwise weight-load ports while idle. The window is packed with tap 0 in bits [7:0], tap 1 in [15:8], and so on. The current tile processes one spatial position at a time and expects the upstream window generator/controller to handle image raster scheduling and channel ordering. This is not yet a full image-level accelerator top or a complete CNN inference engine. Validate the controller and data ordering with the integrated testbench before synthesis.
