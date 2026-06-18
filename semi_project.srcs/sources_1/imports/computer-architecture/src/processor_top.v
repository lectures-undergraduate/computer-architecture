module processor_top (
    input clk,
    input rst,
    output [31:0] monitor_pc,
    output [31:0] monitor_instr,
    output [31:0] monitor_r0,
    output [31:0] monitor_r1,
    output [31:0] monitor_alu_res,
    output monitor_reg_write,
    output monitor_alu_src,
    output monitor_branch,
    output monitor_jump
);
    reg [31:0] pc;
    wire [31:0] next_pc;
    wire [31:0] pc_plus_1;
    wire [31:0] instr;

    insn_rom rom_block (
        .a(pc[3:0]),
        .spo(instr)
    );

    wire [5:0] opcode = instr[31:26];
    wire [3:0] rd     = instr[25:22];
    wire [3:0] rn     = instr[21:18];
    wire [31:0] imm   = {{14{instr[17]}}, instr[17:0]};

    wire reg_write;
    wire alu_src;
    wire [2:0] alu_op;
    wire branch;
    wire jump;
    wire flag_write;

    control_unit cu (
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .branch(branch),
        .jump(jump),
        .flag_write(flag_write)
    );

    wire [31:0] rdata1;
    wire [31:0] rdata2;
    wire [31:0] r0_curr;
    wire [31:0] r1_curr;

    reg_file rf (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .read_reg1(rn[1:0]),
        .read_reg2(rd[1:0]),
        .write_reg(rd[1:0]),
        .write_data(alu_res),
        .read_data1(rdata1),
        .read_data2(rdata2),
        .r0_val(r0_curr),
        .r1_val(r1_curr)
    );

    wire [31:0] alu_operand_a = rdata2; 
    wire [31:0] alu_operand_b = alu_src ? imm : rdata1;
    wire [31:0] alu_res;
    wire zero_flag;
    wire neg_flag;

    alu alu_core (
        .a(alu_operand_a),
        .b(alu_operand_b),
        .alu_op(alu_op),
        .result(alu_res),
        .zero(zero_flag),
        .negative(neg_flag)
    );

    // 플래그 레지스터 추가 (CMP 결과 유지)
    reg n_flag_reg;
    reg z_flag_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            n_flag_reg <= 1'b0;
            z_flag_reg <= 1'b0;
        end else if (flag_write) begin
            n_flag_reg <= neg_flag;
            z_flag_reg <= zero_flag;
        end
    end

    assign pc_plus_1 = pc + 32'h00000001;
    
    // BGE 조건: CMP로 갱신된 레지스터 플래그 값 참조
    wire bge_condition_met = branch && (z_flag_reg || (~n_flag_reg));
    assign next_pc = jump ? imm : (bge_condition_met ? imm : pc_plus_1);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'h00000000;
        end else begin
            pc <= next_pc;
        end
    end

    assign monitor_pc        = pc;
    assign monitor_instr     = instr;
    assign monitor_r0        = r0_curr;
    assign monitor_r1        = r1_curr;
    assign monitor_alu_res   = alu_res;
    assign monitor_reg_write = reg_write;
    assign monitor_alu_src   = alu_src;
    assign monitor_branch    = branch;
    assign monitor_jump      = jump;
endmodule