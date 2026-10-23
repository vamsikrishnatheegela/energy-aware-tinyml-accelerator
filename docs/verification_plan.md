# Verification checklist

## Current testbench
- [x] Synchronous reset
- [x] Synchronous clear
- [x] Positive INT8 multiply
- [x] Signed INT8 accumulation
- [x] Negative INT4 operand
- [x] INT4 minimum representable values
- [x] INT8 negative extreme product

## Add next
- [ ] INT4 +7, -8, and nibble sign-extension boundary tests
- [ ] INT8 -128, -1, 0, +1, +127 operand cross-product tests
- [ ] Randomized sequences against a software reference model
- [ ] Confirm accumulator hold when `mac_en=0`
- [ ] Confirm reset and clear priority
- [ ] Long reduction tests and accumulator overflow policy
- [ ] Precision changes while enabled (document whether permitted during an accumulation)
- [ ] Requantization rounding/saturation tests
- [ ] Depthwise and pointwise convolution end-to-end comparison against Python

For the reference model, explicitly mask/sign-extend INT4 operands before multiplication and emulate the chosen fixed-width accumulator behavior.
