// Sequential MAC engine reusable for depthwise and pointwise convolution.
// Each input_valid cycle contributes one signed INT4 or INT8 product.
// start clears the running sum. in_last marks the final product of a reduction.
module conv_mac_engine (
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
    logic signed [7:0] activation_eff, weight_eff;
    logic signed [15:0] activation_ext, weight_ext;
    logic signed [15:0] product;
    logic signed [31:0] accumulator;
    logic signed [31:0] next_sum;

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
        next_sum = accumulator + {{16{product[15]}}, product};
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            accumulator  <= '0;
            result       <= '0;
            result_valid <= 1'b0;
            busy         <= 1'b0;
        end else begin
            result_valid <= 1'b0;
            if (start) begin
                accumulator <= '0;
                result      <= '0;
                busy        <= 1'b1;
            end else if (busy && input_valid) begin
                accumulator <= next_sum;
                if (in_last) begin
                    result       <= next_sum;
                    result_valid <= 1'b1;
                    busy         <= 1'b0;
                end
            end
        end
    end
endmodule
