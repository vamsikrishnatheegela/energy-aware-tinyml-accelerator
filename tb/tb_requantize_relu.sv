`timescale 1ns/1ps

module tb_requantize_relu;
    logic signed [31:0] accumulator;
    logic [4:0] shift_amount;
    logic relu_enable;
    logic int8_mode;
    logic signed [7:0] quantized;

    requantize_relu dut (
        .accumulator(accumulator), .shift_amount(shift_amount),
        .relu_enable(relu_enable), .int8_mode(int8_mode), .quantized(quantized)
    );

    initial begin
        int8_mode = 1'b1; relu_enable = 1'b0; shift_amount = 0;
        accumulator = 32'sd42; #1;
        if (quantized !== 42) $fatal(1, "Expected 42, got %0d", quantized);

        shift_amount = 2; accumulator = 32'sd10; #1;
        if (quantized !== 3) $fatal(1, "Expected rounded 3, got %0d", quantized);

        accumulator = -32'sd10; #1;
        if (quantized !== -3) $fatal(1, "Expected rounded -3, got %0d", quantized);

        shift_amount = 0; accumulator = 32'sd1000; #1;
        if (quantized !== 127) $fatal(1, "Expected INT8 saturation 127, got %0d", quantized);

        int8_mode = 1'b0; accumulator = -32'sd100; #1;
        if (quantized !== -8) $fatal(1, "Expected INT4 saturation -8, got %0d", quantized);

        relu_enable = 1'b1; accumulator = -32'sd3; #1;
        if (quantized !== 0) $fatal(1, "Expected ReLU zero, got %0d", quantized);

        $display("ALL REQUANTIZE TESTS PASSED");
        $finish;
    end
endmodule
