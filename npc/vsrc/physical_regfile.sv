// Physical Register File for Out-of-Order Processor
// 64 physical registers (p0-p63) with multi-port support
// p0 is hardwired to 0 (RISC-V x0 convention)

module physical_regfile #(
    parameter int NUM_PHYS_REGS = 64,
    parameter int DATA_WIDTH = 32,
    parameter int READ_PORTS = 2,      // 2 源操作数（rs1, rs2）
    parameter int WRITE_PORTS = 2      // 2 写端口（ALU, LSU）
) (
    input  logic                                clk,
    input  logic                                rst_n,
    
    // 读端口（组合逻辑）
    input  logic [READ_PORTS-1:0][5:0]          read_addr_i,
    output logic [READ_PORTS-1:0][DATA_WIDTH-1:0] read_data_o,
    
    // 写端口（时序逻辑）
    input  logic [WRITE_PORTS-1:0]              write_en_i,
    input  logic [WRITE_PORTS-1:0][5:0]         write_addr_i,
    input  logic [WRITE_PORTS-1:0][DATA_WIDTH-1:0] write_data_i
);

    // 寄存器数组
    logic [DATA_WIDTH-1:0] regs [NUM_PHYS_REGS];
    
    // ========== 读逻辑（组合逻辑，用 assign）==========
    // p0 硬连线为 0，其他寄存器正常读取
    genvar i;
    generate
        for (i = 0; i < READ_PORTS; i++) begin : gen_read_ports
            assign read_data_o[i] = (read_addr_i[i] == 6'd0) ? '0 : regs[read_addr_i[i]];
        end
    endgenerate
    
    // ========== 写逻辑（时序逻辑，用 always_ff）==========
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位时清零所有寄存器
            for (int j = 0; j < NUM_PHYS_REGS; j++) begin
                regs[j] <= '0;
            end
        end else begin
            // 支持多端口同时写入
            for (int j = 0; j < WRITE_PORTS; j++) begin
                if (write_en_i[j] && write_addr_i[j] != 6'd0) begin
                    regs[write_addr_i[j]] <= write_data_i[j];
                end
            end
        end
    end
    
    // ========== 写后读旁路（组合逻辑，可选优化）==========
    // 如果同一周期写入和读取同一寄存器，读取到新值
    // 这里为了保持简洁，先不实现，后续可以优化

endmodule
