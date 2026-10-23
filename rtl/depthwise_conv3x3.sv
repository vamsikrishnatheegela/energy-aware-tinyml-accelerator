`timescale 1ns/1ps

// Sequential 3x3 depthwise-convolution reduction.
// Supply the nine activation/weight pairs in tap order, one per valid cycle.
// Spatial window generation and line buffers are intentionally outside this block.
module depthwise_conv3x3 (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    start,
    input  logic                    input_valid,
    input  logic                    int8_mode,
    input  logic signed [7:0]       activation,
    input  logic signed [7:0]       weight,
    output logic                    busy,
    output logic                    result_valid,
    output logic signed [31:0]      result
);
    logic [3:0] tap_count;
    logic signed [7:0] activation_eff;
    logic signed [7:0] weight_eff;
    logic signed [15:0] activation_ext;
    logic signed [15:0] weight_ext;
    logic signed [15:0] product;
    logic signed [31:0] accumulator;

    always_comb begin
        if (int8_mode) begin
            activation_eff = activation;
            weight_eff = weight;
        end else begin
            activation_eff = {{4{activation[3]}}, activation[3:0]};
            weight_eff = {{4{weight[3]}}, weight[3:0]};
        end
        activation_ext = {{8{activation_eff[7]}}, activation_eff};
        weight_ext = {{8{weight_eff[7]}}, weight_eff};
        product = activation_ext * weight_ext;
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            tap_count <= 4'd0;
            accumulator <= 32'sd0;
            result <= 32'sd0;
            busy <= 1'b0;
            result_valid <= 1'b0;
        end else begin
            result_valid <= 1'b0;
            if (start && !busy) begin
                tap_count <= 4'd0;
                accumulator <= 32'sd0;
                busy <= 1'b1;
            end else if (busy && input_valid) begin
                if (tap_count == 4'd8) begin
                    result <= accumulator + {{16{product[15]}}, product};
                    result_valid <= 1'b1;
                    accumulator <= 32'sd0;
                    tap_count <= 4'd0;
                    busy <= 1'b0;
                end else begin
                    accumulator <= accumulator + {{16{product[15]}}, product};
                    tap_count <= tap_count + 1'b1;
                end
            end
        end
    end
endmodule
