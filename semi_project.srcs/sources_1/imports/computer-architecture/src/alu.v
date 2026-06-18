module alu (
    input [31:0] a,
    input [31:0] b,
    input [2:0] alu_op,
    output reg [31:0] result,
    output zero,
    output negative
);
    always @(*) begin
        case (alu_op)
            3'b000:  result = a + b;       // ADD
            3'b001:  result = a - b;       // SUB / CMP
            3'b011:  result = b;           // PASS_IMM (MOV)
            default: result = 32'h00000000;
        endcase
    end

    assign zero     = (result == 32'h00000000);
    assign negative = result[31];
endmodule