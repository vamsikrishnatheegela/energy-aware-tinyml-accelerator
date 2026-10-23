// Fixed-point requantization with round-to-nearest, ties away from zero,
// optional ReLU, and signed INT4/INT8 saturation.
// shift_amount is in the range 0..31.
module requantize_relu (
    input  logic signed [31:0] accumulator,
    input  logic        [4:0]  shift_amount,
    input  logic               relu_enable,
    input  logic               int8_mode,
    output logic signed [7:0]  quantized
);
    logic signed [32:0] accumulator_wide;
    logic signed [32:0] shifted_wide;
    logic        [32:0] magnitude;
    logic        [32:0] rounded_magnitude;
    logic signed [32:0] lower_bound;
    logic signed [32:0] upper_bound;

    always_comb begin
        accumulator_wide = {accumulator[31], accumulator};
        shifted_wide = accumulator_wide;
        magnitude = 33'd0;
        rounded_magnitude = 33'd0;
        lower_bound = -33'sd8;
        upper_bound = 33'sd7;

        if (shift_amount != 0) begin
            if (accumulator >= 0) begin
                // Positive values: add half an LSB before shifting.
                shifted_wide =
                    (accumulator_wide + (33'sd1 <<< (shift_amount - 1)))
                    >>> shift_amount;
            end else begin
                // Round the magnitude to avoid bias from arithmetic right shift.
                // 33 bits safely represent abs(INT32_MIN).
                magnitude = $unsigned(-accumulator_wide);
                rounded_magnitude =
                    (magnitude + (33'd1 << (shift_amount - 1)))
                    >> shift_amount;
                shifted_wide = -$signed(rounded_magnitude);
            end
        end

        if (relu_enable && shifted_wide < 0)
            shifted_wide = 33'sd0;

        if (int8_mode) begin
            lower_bound = -33'sd128;
            upper_bound = 33'sd127;
        end else begin
            lower_bound = -33'sd8;
            upper_bound = 33'sd7;
        end

        if (shifted_wide < lower_bound)
            quantized = lower_bound[7:0];
        else if (shifted_wide > upper_bound)
            quantized = upper_bound[7:0];
        else
            quantized = shifted_wide[7:0];
    end
endmodule
