`timescale 1ns/1ps
module tb_adaptive_power_manager;
    logic clk = 0;
    logic rst_n = 0;
    logic workload_req = 0;
    logic compute_busy = 0;
    logic power_good = 1;
    logic dvfs_ack = 0;
    logic [1:0] requested_op = 2'd1;
    wire compute_clk_en, power_switch_en, isolation_en, dvfs_req, manager_ready;
    wire [1:0] dvfs_op, active_op;
    wire [2:0] state_dbg;

    always #5 clk = ~clk;

    adaptive_power_manager #(
        .IDLE_CYCLES_TO_GATE(3),
        .IDLE_CYCLES_TO_POWER_OFF(6),
        .IDLE_COUNT_WIDTH(4)
    ) dut (.*);

    task automatic step;
        begin @(posedge clk); #1; end
    endtask

    initial begin
        repeat (2) step();
        rst_n = 1;
        step();
        if (!compute_clk_en || isolation_en || !power_switch_en)
            $fatal(1, "Reset exit should enter active RUN state");

        // Request a low operating point; the request must persist until ACK.
        requested_op = 2'd0;
        #1;
        if (!dvfs_req) $fatal(1, "Expected DVFS request for OP_LOW");
        repeat (2) begin step(); if (!dvfs_req) $fatal(1, "DVFS request dropped before ACK"); end
        dvfs_ack = 1;
        step();
        dvfs_ack = 0;
        step();
        if (active_op != 2'd0 || dvfs_req) $fatal(1, "DVFS ACK did not update active operating point");

        // Idle long enough to gate the clock and request power-down.
        repeat (7) step();
        if (state_dbg != 3'd2 || power_switch_en || !isolation_en || compute_clk_en)
            $fatal(1, "Expected safe POWER_OFF state after idle timeout");

        // Wake-up must power on first and keep isolation asserted until power-good.
        workload_req = 1;
        power_good = 0;
        step();
        if (state_dbg != 3'd3 || !power_switch_en || !isolation_en || compute_clk_en)
            $fatal(1, "Expected WAKE_POWER with isolation asserted");
        step();
        if (state_dbg != 3'd3) $fatal(1, "Wake-up advanced before power-good");

        power_good = 1;
        requested_op = 2'd2;
        step();
        #1;
        if (state_dbg != 3'd4 || !isolation_en || compute_clk_en || !dvfs_req)
            $fatal(1, "Expected isolated wake-up DVFS transition");
        dvfs_ack = 1;
        step();
        dvfs_ack = 0;
        step();
        if (state_dbg != 3'd0 || !compute_clk_en || isolation_en || active_op != 2'd2)
            $fatal(1, "Wake-up did not safely return to RUN");

        $display("PASS: adaptive power manager directed tests passed");
        $finish;
    end
endmodule
