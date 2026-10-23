`timescale 1ns/1ps

module tb_conv_mac_engine;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start = 1'b0;
    logic input_valid = 1'b0;
    logic in_last = 1'b0;
    logic int8_mode = 1'b1;
    logic signed [7:0] activation = '0;
    logic signed [7:0] weight = '0;
    logic busy;
    logic result_valid;
    logic signed [31:0] result;

    conv_mac_engine dut (
        .clk(clk), .rst_n(rst_n), .start(start), .input_valid(input_valid),
        .in_last(in_last), .int8_mode(int8_mode), .activation(activation),
        .weight(weight), .busy(busy), .result_valid(result_valid), .result(result)
    );
    always #5 clk = ~clk;

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    initial begin
        tick();
        if (busy !== 1'b0) $fatal(1, "Reset failed");
        rst_n = 1'b1;
        start = 1'b1; tick(); start = 1'b0;
        if (busy !== 1'b1) $fatal(1, "Engine did not enter busy state");

        // 3*4 + (-2*5) + 7*1 = 9
        input_valid = 1'b1; activation = 3; weight = 4; in_last = 1'b0; tick();
        activation = -2; weight = 5; in_last = 1'b0; tick();
        activation = 7; weight = 1; in_last = 1'b1; tick();
        input_valid = 1'b0; in_last = 1'b0;
        if (result_valid !== 1'b1) $fatal(1, "result_valid was not asserted");
        if (result !== 9) $fatal(1, "Expected 9, got %0d", result);
        if (busy !== 1'b0) $fatal(1, "Engine did not leave busy state");
        tick();
        if (result_valid !== 1'b0) $fatal(1, "result_valid should be a one-cycle pulse");
        $display("ALL CONV MAC ENGINE TESTS PASSED");
        $finish;
    end
endmodule
