`timescale 1ns/1ps

module tb_requantize_random;
    logic signed [31:0] accumulator;
    logic [4:0] shift_amount;
    logic relu_enable;
    logic int8_mode;
    logic signed [7:0] quantized;
    integer expected;
    integer fd;
    integer scan_result;
    integer checks;

    requantize_relu dut (
        .accumulator(accumulator),
        .shift_amount(shift_amount),
        .relu_enable(relu_enable),
        .int8_mode(int8_mode),
        .quantized(quantized)
    );

    initial begin
        checks = 0;
        fd = $fopen("build/requantize_vectors.txt", "r");
        if (fd == 0)
            $fatal(1, "Could not open build/requantize_vectors.txt; run the Python golden model first");

        while (!$feof(fd)) begin
            scan_result = $fscanf(fd, "%d %d %d %d %d\n",
                                  accumulator, shift_amount, relu_enable,
                                  int8_mode, expected);
            if (scan_result == 5) begin
                #1;
                checks = checks + 1;
                if (quantized !== expected)
                    $fatal(1, "Mismatch vector %0d: acc=%0d shift=%0d relu=%0b int8=%0b expected=%0d got=%0d",
                           checks, accumulator, shift_amount, relu_enable,
                           int8_mode, expected, quantized);
            end
        end
        $fclose(fd);
        if (checks == 0)
            $fatal(1, "No vectors were checked");
        $display("PYTHON/RTL REQUANTIZATION MATCH: %0d vectors", checks);
        $finish;
    end
endmodule
