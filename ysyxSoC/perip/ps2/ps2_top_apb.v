module ps2_top_apb (
    input         clock,
    input         reset,
    input  [31:0] in_paddr,
    input         in_psel,
    input         in_penable,
    input  [2:0]  in_pprot,
    input         in_pwrite,
    input  [31:0] in_pwdata,
    input  [3:0]  in_pstrb,
    output        in_pready,
    output [31:0] in_prdata,
    output        in_pslverr,

    input         ps2_clk,
    input         ps2_data
);

    // PS/2 clock synchronization
    reg [1:0] ps2_clk_sync;
    always @(posedge clock) begin
        if (reset)
            ps2_clk_sync <= 2'b00;
        else
            ps2_clk_sync <= {ps2_clk_sync[0], ps2_clk};
    end
    wire ps2_clk_negedge = ps2_clk_sync[1] & ~ps2_clk_sync[0];

    // PS/2 receiving state machine
    reg [3:0] bit_cnt;
    reg [10:0] shift_reg;
    reg receiving;
    reg data_valid;

    always @(posedge clock) begin
        if (reset) begin
            bit_cnt <= 4'd0;
            shift_reg <= 11'b0;
            receiving <= 1'b0;
            data_valid <= 1'b0;
        end else begin
            data_valid <= 1'b0;
            if (!receiving) begin
                if (ps2_clk_negedge && ps2_data == 1'b0) begin  // Start bit detected
                    receiving <= 1'b1;
                    bit_cnt <= 4'd0;
                    shift_reg <= 11'b0;
                end
            end else if (ps2_clk_negedge) begin
                shift_reg <= {ps2_data, shift_reg[10:1]};
                bit_cnt <= bit_cnt + 1;
                if (bit_cnt == 4'd10) begin  // Received all 11 bits
                    receiving <= 1'b0;
                    // Simple parity check (odd parity)
                    if (^shift_reg[9:1] == shift_reg[10] && shift_reg[0] == 1'b0 && shift_reg[10] == 1'b1)
                        data_valid <= 1'b1;
                end
            end
        end
    end

    // FIFO for storing scan codes
    parameter FIFO_DEPTH = 16;
    reg [7:0] fifo [0:FIFO_DEPTH-1];
    reg [3:0] wr_ptr, rd_ptr;
    reg [4:0] fifo_cnt;
    reg fifo_read;

    always @(posedge clock) begin
        if (reset) begin
            wr_ptr <= 4'd0;
            rd_ptr <= 4'd0;
            fifo_cnt <= 5'd0;
            fifo_read <= 1'b0;
        end else begin
            fifo_read <= 1'b0;
            // Write to FIFO
            if (data_valid) begin
                if (fifo_cnt < FIFO_DEPTH) begin
                    fifo[wr_ptr] <= shift_reg[8:1];
                    wr_ptr <= wr_ptr + 1;
                    fifo_cnt <= fifo_cnt + 1;
                end
            end
            // Read from FIFO
            if (in_psel && in_penable && !in_pwrite && in_paddr[31:0] == 32'h10011000 && fifo_cnt > 0) begin
                fifo_read <= 1'b1;
                rd_ptr <= rd_ptr + 1;
                fifo_cnt <= fifo_cnt - 1;
            end
        end
    end

    // APB interface
    assign in_pready = 1'b1;  // Always ready
    assign in_pslverr = 1'b0; // No errors

    reg [31:0] in_prdata_reg;
    always @(*) begin
        if (in_psel && in_penable && !in_pwrite && in_paddr[31:0] == 32'h10011000) begin
            if (fifo_cnt > 0)
                in_prdata_reg = {24'b0, fifo[rd_ptr]};
            else
                in_prdata_reg = 32'b0;
        end else begin
            in_prdata_reg = 32'b0;
        end
    end
    assign in_prdata = in_prdata_reg;

endmodule
