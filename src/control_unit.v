module control_unit (
    input [5:0] opcode,
    output reg reg_write,
    output reg alu_src,
    output reg [2:0] alu_op,
    output reg branch,
    output reg jump,
    output reg flag_write
);
    always @(*) begin
        // 기본값 초기화
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        alu_op     = 3'b000;
        branch     = 1'b0;
        jump       = 1'b0;
        flag_write = 1'b0;

        case (opcode)
            6'b000001: begin // MOV_IMM
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 3'b011; // PASS_B
            end
            6'b000010: begin // ADD_REG
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 3'b000; // ADD
            end
            6'b000011: begin // ADD_IMM
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 3'b000; // ADD
            end
            6'b000100: begin // CMP_IMM
                reg_write  = 1'b0;
                alu_src    = 1'b1;
                alu_op     = 3'b001; // SUB
                flag_write = 1'b1;   // BGE 분기를 위해 플래그 상태 저장 지시
            end
            6'b000101: begin // BGE
                branch    = 1'b1;
            end
            6'b000110: begin // B (Unconditional Jump)
                jump      = 1'b1;
            end
            default: begin
                reg_write  = 1'b0;
                alu_src    = 1'b0;
                alu_op     = 3'b000;
                branch     = 1'b0;
                jump       = 1'b0;
                flag_write = 1'b0;
            end
        endcase
    end
endmodule