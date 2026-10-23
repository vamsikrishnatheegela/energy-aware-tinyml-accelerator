`timescale 1ns/1ps

module tb_quant_mac;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic clear = 1'b0;
    logic mac_en = 1'b0;
    logic int8_mode = 1'b1;
    logic signed [7:0] a = '0;
    logic signed [7:0] b = '0;
    logic signed [31:0] accumulator;

    quant_mac dut (
        .clk(clk), .rst_n(rst_n), .clear(clear), .mac_en(mac_en),
        .int8_mode(int8_mode), .a(a), .b(b), .accumulator(accumulator)
    );

    always #5 clk = ~clk;

    task automatic check(input logic signed [31:0] expected, input string label_text);
        begin
            if (accumulator !== expected) begin
                $error("FAIL %s: expected %0d, got %0d", label_text, expected, accumulator);
                $fatal(1);
            end
            $display("PASS %s: accumulator=%0d", label_text, accumulator);
        end
    endtask

    task automatic tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        // Reset
        tick();
        check(0, "reset");
        rst_n = 1'b1;

        // INT8: 12*3 + (-5*4) = 16
        int8_mode = 1'b1; a = 8'sd12; b = 8'sd3; mac_en = 1'b1;
        tick();
        check(36, "INT8 positive product");
        a = -8'sd5; b = 8'sd4;
        tick();
        check(16, "INT8 signed accumulation");

        // Clear then INT4: (-7*3) + (-8*-8) = 43
        mac_en = 1'b0; clear = 1'b1;
        tick();
        check(0, "clear");
        clear = 1'b0; int8_mode = 1'b0; mac_en = 1'b1;
        a = -8'sd7; b = 8'sd3;
        tick();
        check(-21, "INT4 negative operand");
        a = -8'sd8; b = -8'sd8;
        tick();
        check(43, "INT4 minimum values");

        // INT8 extrema: -128 * 127 = -16256
        clear = 1'b1; mac_en = 1'b0;
        tick();
        clear = 1'b0; int8_mode = 1'b1; mac_en = 1'b1;
        a = 8'sh80; b = 8'sd127;
        tick();
        check(-16256, "INT8 extreme signed product");

        mac_en = 1'b0;
        $display("ALL TESTS PASSED");
        $finish;
    end
endmodule
