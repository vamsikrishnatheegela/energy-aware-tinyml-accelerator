module adaptive_power_manager #(
    parameter integer IDLE_CYCLES_TO_GATE = 4,
    parameter integer IDLE_CYCLES_TO_POWER_OFF = 12,
    parameter integer IDLE_COUNT_WIDTH = 8
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       workload_req,
    input  logic       compute_busy,
    input  logic       power_good,
    input  logic       dvfs_ack,
    input  logic [1:0] requested_op,
    output logic       compute_clk_en,
    output logic       power_switch_en,
    output logic       isolation_en,
    output logic       dvfs_req,
    output logic [1:0] dvfs_op,
    output logic [1:0] active_op,
    output logic       manager_ready,
    output logic [2:0] state_dbg
);

    localparam logic [1:0] OP_LOW     = 2'd0;
    localparam logic [1:0] OP_NOMINAL = 2'd1;
    localparam logic [1:0] OP_HIGH    = 2'd2;

    localparam logic [2:0] ST_RUN          = 3'd0;
    localparam logic [2:0] ST_CLOCK_GATED  = 3'd1;
    localparam logic [2:0] ST_POWER_OFF    = 3'd2;
    localparam logic [2:0] ST_WAKE_POWER   = 3'd3;
    localparam logic [2:0] ST_WAKE_DVFS    = 3'd4;

    logic [2:0] state, next_state;
    logic [IDLE_COUNT_WIDTH-1:0] idle_count;

    // The controller is intended for an always-on domain. compute_clk_en is
    // an enable for a library ICG cell; it is not itself a gated clock.
    // power_switch_en is a control request, not proof of physical power-off.
    always_comb begin
        compute_clk_en = 1'b0;
        power_switch_en = 1'b1;
        isolation_en = 1'b1;
        manager_ready = 1'b0;
        dvfs_req = 1'b0;
        dvfs_op = requested_op;
        state_dbg = state;

        case (state)
            ST_RUN: begin
                compute_clk_en = 1'b1;
                power_switch_en = 1'b1;
                isolation_en = 1'b0;
                manager_ready = (active_op == requested_op);
                dvfs_req = (active_op != requested_op);
            end
            ST_CLOCK_GATED: begin
                power_switch_en = 1'b1;
                isolation_en = 1'b0;
                manager_ready = 1'b1;
            end
            ST_POWER_OFF: begin
                power_switch_en = 1'b0;
                isolation_en = 1'b1;
            end
            ST_WAKE_POWER: begin
                power_switch_en = 1'b1;
                isolation_en = 1'b1;
            end
            ST_WAKE_DVFS: begin
                power_switch_en = 1'b1;
                isolation_en = 1'b1;
                dvfs_req = (active_op != requested_op);
            end
            default: begin
                compute_clk_en = 1'b0;
                power_switch_en = 1'b1;
                isolation_en = 1'b1;
            end
        endcase
    end

    always_comb begin
        next_state = state;
        case (state)
            ST_RUN: begin
                if (!workload_req && !compute_busy &&
                    idle_count >= IDLE_CYCLES_TO_GATE-1)
                    next_state = ST_CLOCK_GATED;
            end
            ST_CLOCK_GATED: begin
                if (workload_req || compute_busy)
                    next_state = ST_RUN;
                else if (idle_count >= IDLE_CYCLES_TO_POWER_OFF-1)
                    next_state = ST_POWER_OFF;
            end
            ST_POWER_OFF: begin
                if (workload_req || compute_busy)
                    next_state = ST_WAKE_POWER;
            end
            ST_WAKE_POWER: begin
                if (power_good)
                    next_state = ST_WAKE_DVFS;
            end
            ST_WAKE_DVFS: begin
                if (active_op == requested_op)
                    next_state = ST_RUN;
            end
            default: next_state = ST_RUN;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_RUN;
            idle_count <= '0;
            active_op <= OP_NOMINAL;
        end else begin
            state <= next_state;

            if (workload_req || compute_busy) begin
                idle_count <= '0;
            end else if (idle_count != {IDLE_COUNT_WIDTH{1'b1}}) begin
                idle_count <= idle_count + 1'b1;
            end

            // Update the active operating point only after the external
            // clock/voltage manager acknowledges the requested transition.
            if (dvfs_req && dvfs_ack)
                active_op <= requested_op;
        end
    end

endmodule
