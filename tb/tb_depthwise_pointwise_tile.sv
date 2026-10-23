`timescale 1ns/1ps

module tb_depthwise_pointwise_tile;
    localparam integer IC_W = 1;
    localparam integer OC_W = 1;
    logic clk = 1'b0, rst_n = 1'b0, start = 1'b0, int8_mode = 1'b1;
    logic [4:0] shift_amount = 0;
    logic relu_enable = 1'b0;
    logic load_dw_weight = 1'b0;
    logic [IC_W-1:0] load_dw_channel = 0;
    logic [3:0] load_dw_tap = 0;
    logic signed [7:0] load_dw_weight_data = 0;
    logic load_pw_weight = 1'b0;
    logic [OC_W-1:0] load_pw_out_channel = 0;
    logic [IC_W-1:0] load_pw_in_channel = 0;
    logic signed [7:0] load_pw_weight_data = 0;
    logic window_valid = 1'b0;
    logic signed [71:0] window_pixels = {9{8'd1}};
    logic window_ready, busy, out_valid, pixel_done;
    logic [OC_W-1:0] out_channel;
    logic signed [7:0] out_data;
    integer c, t, seen;

    depthwise_pointwise_tile #(.IN_CHANNELS(2), .OUT_CHANNELS(1)) dut (
        .clk(clk), .rst_n(rst_n), .start(start), .int8_mode(int8_mode),
        .shift_amount(shift_amount), .relu_enable(relu_enable),
        .load_dw_weight(load_dw_weight), .load_dw_channel(load_dw_channel),
        .load_dw_tap(load_dw_tap), .load_dw_weight_data(load_dw_weight_data),
        .load_pw_weight(load_pw_weight), .load_pw_out_channel(load_pw_out_channel),
        .load_pw_in_channel(load_pw_in_channel), .load_pw_weight_data(load_pw_weight_data),
        .window_valid(window_valid), .window_pixels(window_pixels),
        .window_ready(window_ready), .busy(busy), .out_valid(out_valid),
        .out_channel(out_channel), .out_data(out_data), .pixel_done(pixel_done)
    );
    always #5 clk = ~clk;

    task automatic tick;
        begin @(posedge clk); #1; end
    endtask

    task automatic write_dw(input integer ch, input integer tap, input integer value);
        begin
            @(negedge clk);
            load_dw_weight = 1'b1;
            load_dw_channel = ch;
            load_dw_tap = tap;
            load_dw_weight_data = value;
            tick();
            @(negedge clk); load_dw_weight = 1'b0;
        end
    endtask

    task automatic write_pw(input integer och, input integer ich, input integer value);
        begin
            @(negedge clk);
            load_pw_weight = 1'b1;
            load_pw_out_channel = och;
            load_pw_in_channel = ich;
            load_pw_weight_data = value;
            tick();
            @(negedge clk); load_pw_weight = 1'b0;
        end
    endtask

    task automatic send_window;
        begin
            wait(window_ready);
            @(negedge clk); window_valid = 1'b1;
            tick();
            @(negedge clk); window_valid = 1'b0;
        end
    endtask

    initial begin
        seen = 0;
        repeat (2) @(posedge clk);
        @(negedge clk); rst_n = 1'b1;

        for (c = 0; c < 2; c = c + 1)
            for (t = 0; t < 9; t = t + 1)
                write_dw(c, t, 1);
        write_pw(0, 0, 2);
        write_pw(0, 1, 3);

        @(negedge clk); start = 1'b1;
        tick();
        @(negedge clk); start = 1'b0;

        send_window();
        send_window();

        while (!pixel_done) begin
            @(posedge clk); #1;
            if (out_valid) begin
                if (out_channel !== 0) $fatal(1, "Unexpected output channel");
                if (out_data !== 45) $fatal(1, "Expected output 45, got %0d", out_data);
                seen = seen + 1;
            end
        end
        if (seen != 1) $fatal(1, "Expected one output, saw %0d", seen);
        if (busy !== 1'b0) $fatal(1, "Tile did not return idle");
        $display("ALL DEPTHWISE-POINTWISE TILE TESTS PASSED");
        $finish;
    end
endmodule
