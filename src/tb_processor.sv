`timescale 1ns / 1ps

module tb_processor;
    logic clk;
    logic rst;

    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] r0;
    logic [31:0] r1;
    logic [31:0] alu_res;
    logic reg_write;
    logic alu_src;
    logic branch;
    logic jump;

    processor_top uut (
        .clk(clk),
        .rst(rst),
        .monitor_pc(pc),
        .monitor_instr(instr),
        .monitor_r0(r0),
        .monitor_r1(r1),
        .monitor_alu_res(alu_res),
        .monitor_reg_write(reg_write),
        .monitor_alu_src(alu_src),
        .monitor_branch(branch),
        .monitor_jump(jump)
    );

    int log_file;
    int cycle_count;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        log_file = $fopen("sim_execution_trace.log", "w");
        if (log_file == 0) begin
            $display("[CRITICAL ERROR] Host system denied file creation");
            $finish;
        end
        
        rst = 1;
        // 클럭 에지에 정확히 동기화하여 리셋 해제
        @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;
        
        // 데이터가 확정된 주기 중간(negedge)에서 로깅하여 PC 0 증발 방지
        for (cycle_count = 0; cycle_count < 150; cycle_count++) begin
            @(negedge clk); 
            $fwrite(log_file, "CYCLE:%0d|PC:%0d|INSTR:%h|R0:%0d|R1:%0d|ALU:%h|REG_W:%b|ALU_S:%b|BR:%b|JMP:%b\n",
                    cycle_count, pc, instr, r0, r1, alu_res, reg_write, alu_src, branch, jump);
        end
        
        $fclose(log_file);
        $display("[SV_TB] Simulation Trace Data Successfully Dumped to Local Disk.");
        $finish;
    end
endmodule