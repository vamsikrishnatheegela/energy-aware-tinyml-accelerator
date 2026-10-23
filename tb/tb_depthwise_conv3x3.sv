`timescale 1ns/1ps

module tb_depthwise_conv3x3;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic start = 1'b0;
    logic input_valid = 1'b0;
    logic int8_mode = 1'b1;
    logic signed [7:0] activation = '0;
    logic signed [7:0] weight = '0;
    logic busy;
    logic result_valid;
    logic signed [31:0] result;

    depthwise_conv3x3 dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .input_valid(input_valid), .int8_mode(int8_mode),
        .activation(activation), .weight(weight), .busy(busy),
        .result_valid(result_valid), .result(result)
    );
    always #5 clk = ~clk;

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    task automatic send_tap(input logic signed [7:0] a,
                            input logic signed [7:0] w);
        begin
            activation = a;
            weight = w;
            input_valid = 1'b1;
            tick();
        end
    endtask

    integer i;
    initial begin
        tick();
        if (busy !== 1'b0) $fatal(1, "Reset failed");
        rst_n = 1'b1;
        start = 1'b1; tick(); start = 1'b0;
        if (busy !== 1'b1) $fatal(1, "Engine did not start");

        // Nine INT8 products sum to 1*1 + 2*1 + ... + 9*1 = 45.
        for (i = 1; i <= 9; i = i + 1)
            send_tap(i, 1);
        input_valid = 1'b0;
        if (result_valid !== 1'b1) $fatal(1, "INT8 result_valid missing");
        if (result !== 45) $fatal(1, "Expected INT8 result 45, got %0d", result);
        if (busy !== 1'b0) $fatal(1, "Engine remained busy after ninth tap");
        tick();
        if (result_valid !== 1'b0) $fatal(1, "result_valid must be one cycle");

        // INT4: (-2*3) + (1*2) + seven zero products = -4.
        int8_mode = 1'b0;
        start = 1'b1; tick(); start = 1'b0;
        send_tap(-2, 3);
        send_tap(1, 2);
        for (i = 0; i < 7; i = i + 1)
            send_tap(0, 0);
        input_valid = 1'b0;
        if (result_valid !== 1'b1) $fatal(1, "INT4 result_valid missing");
        if (result !== -4) $fatal(1, "Expected INT4 result -4, got %0d", result);

        $display("ALL DEPTHWISE CONV 3x3 TESTS PASSED");
        $finish;
    end
endmodule
