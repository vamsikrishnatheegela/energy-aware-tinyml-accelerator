`timescale 1ns/1ps

// Raster-stream 3x3 window generator for signed 8-bit feature-map values.
// Pulse frame_start for one cycle before the first pixel of each frame.
// Pixels are accepted only when pixel_valid is high. The image width is fixed
// at elaboration; this block emits one window for each pixel at row>=2,col>=2.
// Padding/stride handling and downstream backpressure are intentionally external.
module sliding_window_3x3 #(
    parameter integer IMAGE_WIDTH = 28
) (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               frame_start,
    input  logic               pixel_valid,
    input  logic signed [7:0]  pixel_data,
    output logic               window_valid,
    output logic signed [7:0]  win00, win01, win02,
    output logic signed [7:0]  win10, win11, win12,
    output logic signed [7:0]  win20, win21, win22
);
    localparam integer COL_W = (IMAGE_WIDTH <= 2) ? 1 : $clog2(IMAGE_WIDTH);

    logic [COL_W-1:0] col_count;
    logic [15:0] row_count;
    logic signed [7:0] line1_mem [0:IMAGE_WIDTH-1];
    logic signed [7:0] line2_mem [0:IMAGE_WIDTH-1];
    logic signed [7:0] prev_row1, prev_row2;

    // Two horizontal delay elements for each of the three rows.
    logic signed [7:0] top_d1, top_d2;
    logic signed [7:0] mid_d1, mid_d2;
    logic signed [7:0] bot_d1, bot_d2;

    always_comb begin
        prev_row1 = line1_mem[col_count];
        prev_row2 = line2_mem[col_count];
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            col_count    <= '0;
            row_count    <= '0;
            window_valid <= 1'b0;
            win00 <= '0; win01 <= '0; win02 <= '0;
            win10 <= '0; win11 <= '0; win12 <= '0;
            win20 <= '0; win21 <= '0; win22 <= '0;
            top_d1 <= '0; top_d2 <= '0;
            mid_d1 <= '0; mid_d2 <= '0;
            bot_d1 <= '0; bot_d2 <= '0;
        end else begin
            window_valid <= 1'b0;
            if (frame_start) begin
                col_count <= '0;
                row_count <= '0;
                top_d1 <= '0; top_d2 <= '0;
                mid_d1 <= '0; mid_d2 <= '0;
                bot_d1 <= '0; bot_d2 <= '0;
            end else if (pixel_valid) begin
                // Capture a window ending at the current raster pixel.
                if ((row_count >= 2) && (col_count >= 2)) begin
                    win00 <= top_d2; win01 <= top_d1; win02 <= prev_row2;
                    win10 <= mid_d2; win11 <= mid_d1; win12 <= prev_row1;
                    win20 <= bot_d2; win21 <= bot_d1; win22 <= pixel_data;
                    window_valid <= 1'b1;
                end

                top_d2 <= top_d1; top_d1 <= prev_row2;
                mid_d2 <= mid_d1; mid_d1 <= prev_row1;
                bot_d2 <= bot_d1; bot_d1 <= pixel_data;

                // Nonblocking assignment semantics preserve the prior row.
                line2_mem[col_count] <= prev_row1;
                line1_mem[col_count] <= pixel_data;

                if (col_count == IMAGE_WIDTH-1) begin
                    col_count <= '0;
                    row_count <= row_count + 1'b1;
                    top_d1 <= '0; top_d2 <= '0;
                    mid_d1 <= '0; mid_d2 <= '0;
                    bot_d1 <= '0; bot_d2 <= '0;
                end else begin
                    col_count <= col_count + 1'b1;
                end
            end
        end
    end

    initial begin
        if (IMAGE_WIDTH < 3)
            $error("sliding_window_3x3 requires IMAGE_WIDTH >= 3");
    end
endmodule
