`timescale 1ns/1ps

module tb_requantize_relu;
    logic signed [31:0] accumulator;
    logic [4:0] shift_amount;
    logic relu_enable;
    logic int8_mode;
    logic signed [7:0] quantized;
    integer checks;

    requantize_relu dut (
        .accumulator(accumulator), .shift_amount(shift_amount),
        .relu_enable(relu_enable), .int8_mode(int8_mode), .quantized(quantized)
    );

    task automatic check(input integer expected, input string label_text);
        begin
            #1;
            checks = checks + 1;
            if (quantized !== expected)
                $fatal(1, "%s: expected %0d, got %0d (acc=%0d shift=%0d int8=%0b relu=%0b)",
                       label_text, expected, quantized, accumulator,
                       shift_amount, int8_mode, relu_enable);
        end
    endtask

    initial begin
        checks = 0;
        int8_mode = 1'b1;
        relu_enable = 1'b0;
        shift_amount = 0;

        accumulator = 32'sd42; check(42, "shift zero");
        accumulator = 32'sd1000; check(127, "INT8 positive saturation");
        accumulator = -32'sd1000; check(-128, "INT8 negative saturation");

        shift_amount = 2;
        accumulator = 32'sd10; check(3, "positive tie rounds away");
        accumulator = -32'sd10; check(-3, "negative tie rounds away");
        accumulator = 32'sd9; check(2, "positive non-tie");
        accumulator = -32'sd9; check(-2, "negative non-tie");
        accumulator = 32'sd6; check(2, "positive half tie");
        accumulator = -32'sd6; check(-2, "negative half tie");
        accumulator = 32'sd5; check(1, "positive below half");
        accumulator = -32'sd5; check(-1, "negative below half");

        int8_mode = 1'b0;
        shift_amount = 0;
        accumulator = 32'sd100; check(7, "INT4 positive saturation");
        accumulator = -32'sd100; check(-8, "INT4 negative saturation");
        accumulator = 32'sd7; check(7, "INT4 positive endpoint");
        accumulator = -32'sd8; check(-8, "INT4 negative endpoint");

        relu_enable = 1'b1;
        accumulator = -32'sd3; check(0, "ReLU clamps negative");
        accumulator = 32'sd3; check(3, "ReLU preserves positive");

        relu_enable = 1'b0;
        int8_mode = 1'b1;
        shift_amount = 31;
        accumulator = 32'sh7fffffff; check(1, "maximum accumulator shift 31");
        accumulator = -32'sh80000000; check(-1, "minimum accumulator shift 31");

        $display("ALL REQUANTIZE TESTS PASSED (%0d checks)", checks);
        $finish;
    end
endmodule
