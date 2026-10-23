// Fixed-point requantization stage with rounding, optional ReLU, and saturation.
// shift_amount is expected to be 0..31. int8_mode selects signed INT8 or INT4 output.
module requantize_relu (
    input  logic signed [31:0] accumulator,
    input  logic        [4:0]  shift_amount,
    input  logic               relu_enable,
    input  logic               int8_mode,
    output logic signed [7:0]  quantized
);
    logic signed [32:0] rounded_wide;
    logic signed [31:0] rounded_value;
    logic signed [31:0] shifted_value;
    logic signed [31:0] lower_bound;
    logic signed [31:0] upper_bound;

    always_comb begin
        rounded_wide = {accumulator[31], accumulator};
        if (shift_amount != 0) begin
            if (accumulator >= 0)
                rounded_wide = {accumulator[31], accumulator}
                             + (33'sd1 <<< (shift_amount - 1));
            else
                rounded_wide = {accumulator[31], accumulator}
                             - (33'sd1 <<< (shift_amount - 1));
        end
        rounded_value = rounded_wide[31:0];
        shifted_value = rounded_value >>> shift_amount;

        if (relu_enable && shifted_value < 0)
            shifted_value = 0;

        if (int8_mode) begin
            lower_bound = -32'sd128;
            upper_bound =  32'sd127;
        end else begin
            lower_bound = -32'sd8;
            upper_bound =  32'sd7;
        end

        if (shifted_value < lower_bound)
            quantized = lower_bound[7:0];
        else if (shifted_value > upper_bound)
            quantized = upper_bound[7:0];
        else
            quantized = shifted_value[7:0];
    end
endmodule
