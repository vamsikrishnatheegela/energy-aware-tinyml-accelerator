// Signed INT4/INT8 multiply-accumulate datapath.
// INT4 operands are encoded in the low nibble using two's complement.
// The 32-bit accumulator is intentionally wider than the product.
module quant_mac (
    input  logic               clk,
    input  logic               rst_n,
    input  logic               clear,
    input  logic               mac_en,
    input  logic               int8_mode, // 1: signed INT8, 0: signed INT4
    input  logic signed [7:0]  a,
    input  logic signed [7:0]  b,
    output logic signed [31:0] accumulator
);
    logic signed [7:0]  a_eff;
    logic signed [7:0]  b_eff;
    logic signed [15:0] a_ext;
    logic signed [15:0] b_ext;
    logic signed [15:0] product;

    always_comb begin
        if (int8_mode) begin
            a_eff = a;
            b_eff = b;
        end else begin
            a_eff = {{4{a[3]}}, a[3:0]};
            b_eff = {{4{b[3]}}, b[3:0]};
        end

        // Explicit sign extension makes the signed product width unambiguous.
        a_ext = {{8{a_eff[7]}}, a_eff};
        b_ext = {{8{b_eff[7]}}, b_eff};
        product = a_ext * b_ext;
    end

    always_ff @(posedge clk) begin
        if (!rst_n)
            accumulator <= '0;
        else if (clear)
            accumulator <= '0;
        else if (mac_en)
            accumulator <= accumulator + {{16{product[15]}}, product};
    end
endmodule
