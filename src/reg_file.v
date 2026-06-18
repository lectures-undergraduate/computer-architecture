module reg_file (
    input clk,
    input rst,
    input reg_write,
    input [1:0] read_reg1,
    input [1:0] read_reg2,
    input [1:0] write_reg,
    input [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2,
    output [31:0] r0_val,
    output [31:0] r1_val
);
    reg [31:0] rf [3:0];

    // Single-Cycle 구조 달성을 위한 비동기 읽기(Asynchronous Read)
    assign read_data1 = rf[read_reg1];
    assign read_data2 = rf[read_reg2];
    
    // 모니터링 및 로깅용 디버깅 출력 포트
    assign r0_val = rf[2'b00];
    assign r1_val = rf[2'b01];

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                rf[i] <= 32'h00000000;
            end
        end else if (reg_write) begin
            rf[write_reg] <= write_data;
        end
    end
endmodule