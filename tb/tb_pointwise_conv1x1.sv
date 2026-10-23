`timescale 1ns/1ps

module tb_pointwise_conv1x1;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start = 1'b0;
    logic input_valid = 1'b0;
    logic in_last = 1'b0;
    logic int8_mode = 1'b1;
    logic signed [7:0] activation = '0, weight = '0;
    logic busy, result_valid;
    logic signed [31:0] result;
    integer i;

    pointwise_conv1x1 dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .input_valid(input_valid), .in_last(in_last),
        .int8_mode(int8_mode), .activation(activation), .weight(weight),
        .busy(busy), .result_valid(result_valid), .result(result)
    );
    always #5 clk = ~clk;

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    initial begin
        tick();
        @(negedge clk); rst_n = 1'b1; start = 1'b1;
        tick();
        @(negedge clk); start = 1'b0;
        for (i = 1; i <= 4; i = i + 1) begin
            @(negedge clk);
            activation = i;
            weight = 2;
            input_valid = 1'b1;
            in_last = (i == 4);
            tick();
        end
        @(negedge clk); input_valid = 1'b0; in_last = 1'b0;
        if (result_valid !== 1'b1) $fatal(1, "Pointwise result_valid missing");
        if (result !== 20) $fatal(1, "Expected pointwise result 20, got %0d", result);
        if (busy !== 1'b0) $fatal(1, "Pointwise engine remained busy");
        $display("ALL POINTWISE CONV TESTS PASSED");
        $finish;
    end
endmodule
