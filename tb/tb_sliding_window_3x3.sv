`timescale 1ns/1ps

module tb_sliding_window_3x3;
    localparam integer W = 4;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic frame_start = 1'b0;
    logic pixel_valid = 1'b0;
    logic signed [7:0] pixel_data = '0;
    logic window_valid;
    logic signed [7:0] win00, win01, win02;
    logic signed [7:0] win10, win11, win12;
    logic signed [7:0] win20, win21, win22;
    integer row, col, windows_seen;

    sliding_window_3x3 #(.IMAGE_WIDTH(W)) dut (
        .clk(clk), .rst_n(rst_n), .frame_start(frame_start),
        .pixel_valid(pixel_valid), .pixel_data(pixel_data),
        .window_valid(window_valid),
        .win00(win00), .win01(win01), .win02(win02),
        .win10(win10), .win11(win11), .win12(win12),
        .win20(win20), .win21(win21), .win22(win22)
    );
    always #5 clk = ~clk;

    task automatic send_pixel(input integer value);
        begin
            @(negedge clk);
            pixel_data = value;
            pixel_valid = 1'b1;
            @(posedge clk); #1;
            if (window_valid) begin
                case (windows_seen)
                    0: begin
                        if ({win00,win01,win02,win10,win11,win12,win20,win21,win22}
                            !== {8'd1,8'd2,8'd3,8'd5,8'd6,8'd7,8'd9,8'd10,8'd11})
                            $fatal(1, "Window 0 mismatch");
                    end
                    1: begin
                        if ({win00,win01,win02,win10,win11,win12,win20,win21,win22}
                            !== {8'd2,8'd3,8'd4,8'd6,8'd7,8'd8,8'd10,8'd11,8'd12})
                            $fatal(1, "Window 1 mismatch");
                    end
                    2: begin
                        if ({win00,win01,win02,win10,win11,win12,win20,win21,win22}
                            !== {8'd5,8'd6,8'd7,8'd9,8'd10,8'd11,8'd13,8'd14,8'd15})
                            $fatal(1, "Window 2 mismatch");
                    end
                    3: begin
                        if ({win00,win01,win02,win10,win11,win12,win20,win21,win22}
                            !== {8'd6,8'd7,8'd8,8'd10,8'd11,8'd12,8'd14,8'd15,8'd16})
                            $fatal(1, "Window 3 mismatch");
                    end
                    default: $fatal(1, "Unexpected extra window");
                endcase
                windows_seen = windows_seen + 1;
            end
        end
    endtask

    initial begin
        windows_seen = 0;
        repeat (2) @(posedge clk);
        @(negedge clk); rst_n = 1'b1; frame_start = 1'b1;
        @(posedge clk); #1;
        @(negedge clk); frame_start = 1'b0;
        for (row = 0; row < W; row = row + 1)
            for (col = 0; col < W; col = col + 1)
                send_pixel(row*W + col + 1);
        @(negedge clk); pixel_valid = 1'b0;
        if (windows_seen != 4)
            $fatal(1, "Expected 4 windows, got %0d", windows_seen);
        $display("ALL SLIDING WINDOW TESTS PASSED");
        $finish;
    end
endmodule
