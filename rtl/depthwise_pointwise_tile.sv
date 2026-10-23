`timescale 1ns/1ps

// One-spatial-position depthwise-separable compute tile.
// The upstream controller supplies one 3x3 window per input channel, in channel
// order. The tile performs a 3x3 depthwise reduction per channel, requantizes
// each result to signed INT4/INT8, then performs pointwise reductions for each
// output channel. Pulse start for each spatial position after the previous
// pixel_done. Load weights while idle. window_pixels packs tap 0 in bits [7:0].
module depthwise_pointwise_tile #(
    parameter integer IN_CHANNELS = 2,
    parameter integer OUT_CHANNELS = 2,
    parameter integer IC_W = (IN_CHANNELS <= 1) ? 1 : $clog2(IN_CHANNELS),
    parameter integer OC_W = (OUT_CHANNELS <= 1) ? 1 : $clog2(OUT_CHANNELS)
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 start,
    input  logic                 int8_mode,
    input  logic [4:0]           shift_amount,
    input  logic                 relu_enable,

    input  logic                 load_dw_weight,
    input  logic [IC_W-1:0]      load_dw_channel,
    input  logic [3:0]           load_dw_tap,
    input  logic signed [7:0]    load_dw_weight_data,

    input  logic                 load_pw_weight,
    input  logic [OC_W-1:0]      load_pw_out_channel,
    input  logic [IC_W-1:0]      load_pw_in_channel,
    input  logic signed [7:0]    load_pw_weight_data,

    input  logic                 window_valid,
    input  logic signed [71:0]   window_pixels,
    output logic                 window_ready,

    output logic                 busy,
    output logic                 out_valid,
    output logic [OC_W-1:0]      out_channel,
    output logic signed [7:0]    out_data,
    output logic                 pixel_done
);
    typedef enum logic [3:0] {
        S_IDLE, S_WAIT_WINDOW, S_DW_START, S_DW_FEED, S_DW_WAIT,
        S_PW_START, S_PW_FEED, S_PW_WAIT
    } state_t;
    state_t state;

    logic mode_q;
    logic [4:0] shift_q;
    logic relu_q;
    logic [IC_W-1:0] ic_index;
    logic [OC_W-1:0] oc_index;
    logic [3:0] tap_index;

    logic signed [7:0] dw_weights [0:IN_CHANNELS-1][0:8];
    logic signed [7:0] pw_weights [0:OUT_CHANNELS-1][0:IN_CHANNELS-1];
    logic signed [7:0] dw_features [0:IN_CHANNELS-1];
    logic signed [71:0] window_q;

    logic dw_start, dw_input_valid, dw_busy, dw_result_valid;
    logic signed [7:0] dw_activation, dw_weight;
    logic signed [31:0] dw_result;
    logic signed [7:0] dw_quantized;

    logic pw_start, pw_input_valid, pw_in_last, pw_busy, pw_result_valid;
    logic signed [7:0] pw_activation, pw_weight;
    logic signed [31:0] pw_result;
    logic signed [7:0] pw_quantized;

    assign busy = (state != S_IDLE);
    assign window_ready = (state == S_WAIT_WINDOW);
    assign dw_start = (state == S_DW_START);
    assign dw_input_valid = (state == S_DW_FEED);
    assign dw_activation = $signed(window_q[tap_index*8 +: 8]);
    assign dw_weight = dw_weights[ic_index][tap_index];

    assign pw_start = (state == S_PW_START);
    assign pw_input_valid = (state == S_PW_FEED);
    assign pw_in_last = (state == S_PW_FEED) && (ic_index == IN_CHANNELS-1);
    assign pw_activation = dw_features[ic_index];
    assign pw_weight = pw_weights[oc_index][ic_index];

    depthwise_conv3x3 u_depthwise (
        .clk(clk), .rst_n(rst_n), .start(dw_start),
        .input_valid(dw_input_valid), .int8_mode(mode_q),
        .activation(dw_activation), .weight(dw_weight),
        .busy(dw_busy), .result_valid(dw_result_valid), .result(dw_result)
    );

    conv_mac_engine u_pointwise (
        .clk(clk), .rst_n(rst_n), .start(pw_start),
        .input_valid(pw_input_valid), .in_last(pw_in_last),
        .int8_mode(mode_q), .activation(pw_activation), .weight(pw_weight),
        .busy(pw_busy), .result_valid(pw_result_valid), .result(pw_result)
    );

    requantize_relu u_dw_quant (
        .accumulator(dw_result), .shift_amount(shift_q),
        .relu_enable(relu_q), .int8_mode(mode_q), .quantized(dw_quantized)
    );

    requantize_relu u_pw_quant (
        .accumulator(pw_result), .shift_amount(shift_q),
        .relu_enable(relu_q), .int8_mode(mode_q), .quantized(pw_quantized)
    );

    integer c, t, o;
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state <= S_IDLE;
            mode_q <= 1'b1;
            shift_q <= '0;
            relu_q <= 1'b0;
            ic_index <= '0;
            oc_index <= '0;
            tap_index <= '0;
            window_q <= '0;
            out_valid <= 1'b0;
            out_channel <= '0;
            out_data <= '0;
            pixel_done <= 1'b0;
            for (c = 0; c < IN_CHANNELS; c = c + 1)
                dw_features[c] <= '0;
            for (c = 0; c < IN_CHANNELS; c = c + 1)
                for (t = 0; t < 9; t = t + 1)
                    dw_weights[c][t] <= '0;
            for (o = 0; o < OUT_CHANNELS; o = o + 1)
                for (c = 0; c < IN_CHANNELS; c = c + 1)
                    pw_weights[o][c] <= '0;
        end else begin
            out_valid <= 1'b0;
            pixel_done <= 1'b0;

            if (state == S_IDLE) begin
                if (load_dw_weight && (load_dw_channel < IN_CHANNELS) &&
                    (load_dw_tap < 9))
                    dw_weights[load_dw_channel][load_dw_tap] <= load_dw_weight_data;
                if (load_pw_weight && (load_pw_out_channel < OUT_CHANNELS) &&
                    (load_pw_in_channel < IN_CHANNELS))
                    pw_weights[load_pw_out_channel][load_pw_in_channel] <= load_pw_weight_data;

                if (start) begin
                    mode_q <= int8_mode;
                    shift_q <= shift_amount;
                    relu_q <= relu_enable;
                    ic_index <= '0;
                    oc_index <= '0;
                    tap_index <= '0;
                    state <= S_WAIT_WINDOW;
                end
            end else begin
                // Weight programming is intentionally restricted to idle cycles.
                case (state)
                    S_WAIT_WINDOW: begin
                        if (window_valid) begin
                            window_q <= window_pixels;
                            tap_index <= 0;
                            state <= S_DW_START;
                        end
                    end
                    S_DW_START: begin
                        tap_index <= 0;
                        state <= S_DW_FEED;
                    end
                    S_DW_FEED: begin
                        if (tap_index == 8) begin
                            state <= S_DW_WAIT;
                        end else begin
                            tap_index <= tap_index + 1'b1;
                        end
                    end
                    S_DW_WAIT: begin
                        if (dw_result_valid) begin
                            dw_features[ic_index] <= dw_quantized;
                            if (ic_index == IN_CHANNELS-1) begin
                                ic_index <= '0;
                                oc_index <= '0;
                                state <= S_PW_START;
                            end else begin
                                ic_index <= ic_index + 1'b1;
                                state <= S_WAIT_WINDOW;
                            end
                        end
                    end
                    S_PW_START: begin
                        ic_index <= '0;
                        state <= S_PW_FEED;
                    end
                    S_PW_FEED: begin
                        if (ic_index == IN_CHANNELS-1) begin
                            state <= S_PW_WAIT;
                        end else begin
                            ic_index <= ic_index + 1'b1;
                        end
                    end
                    S_PW_WAIT: begin
                        if (pw_result_valid) begin
                            out_valid <= 1'b1;
                            out_channel <= oc_index;
                            out_data <= pw_quantized;
                            if (oc_index == OUT_CHANNELS-1) begin
                                pixel_done <= 1'b1;
                                state <= S_IDLE;
                            end else begin
                                oc_index <= oc_index + 1'b1;
                                state <= S_PW_START;
                            end
                        end
                    end
                    default: state <= S_IDLE;
                endcase
            end
        end
    end

    initial begin
        if (IN_CHANNELS < 1 || OUT_CHANNELS < 1)
            $error("IN_CHANNELS and OUT_CHANNELS must be >= 1");
    end
endmodule
