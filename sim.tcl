# sim.tcl - Vivado Simulation Automation Script
create_project -force single_cycle_sim ./sim_project -part xc7a35tcsg324-1

add_files [glob -nocomplain ./src/*.v]
add_files [glob -nocomplain ./src/*.sv]
update_compile_order -fileset sources_1

set coe_path $env(COE_ABS_PATH)

create_ip -name dist_mem_gen -vendor xilinx.com -library ip -version 8.0 -module_name insn_rom
set_property -dict [list \
    CONFIG.depth {16} \
    CONFIG.data_width {32} \
    CONFIG.memory_type {rom} \
    CONFIG.coefficient_file $coe_path \
] [get_ips insn_rom]

generate_target all [get_ips insn_rom]

set_property top tb_processor [get_filesets sim_1]
set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]

# ... (앞부분 동일) ...
launch_simulation
run all

# 시뮬레이션 종료 및 Vivado 프로세스 해제 보장
close_sim
quit