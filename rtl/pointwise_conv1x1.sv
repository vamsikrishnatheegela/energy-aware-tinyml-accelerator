`timescale 1ns/1ps

// Pointwise (1x1) convolution reduction for one output channel at one spatial
// position. Feed one activation/weight pair per input channel; assert in_last
// with the final pair. The upstream controller selects the weight set for each
// output channel and repeats the reduction for each output channel.
module pointwise_conv1x1 (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               start,
    input  logic               input_valid,
    input  logic               in_last,
    input  logic               int8_mode,
    input  logic signed [7:0]  activation,
    input  logic signed [7:0]  weight,
    output logic               busy,
    output logic               result_valid,
    output logic signed [31:0] result
);
    conv_mac_engine reduction (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .input_valid(input_valid),
        .in_last(in_last),
        .int8_mode(int8_mode),
        .activation(activation),
        .weight(weight),
        .busy(busy),
        .result_valid(result_valid),
        .result(result)
    );
endmodule
