# impl.tcl - Implementation and Timing Extraction Script
open_project ./sim_project/single_cycle_sim.xpr

# 1. 물리 합성 대상인 진짜 하드웨어 탑 모듈을 명시적으로 지정
set_property top processor_top [current_fileset]
update_compile_order -fileset sources_1

# 2. XDC 파일 중복 추가로 인한 런타임 경고 및 꼬임 예방 방어 코드
set xdc_file "./synth/timing.xdc"
if {[lsearch [get_files -of_objects [get_filesets constrs_1]] [file normalize $xdc_file]] == -1} {
    add_files -fileset constrs_1 -norecurse $xdc_file
}
update_compile_order -fileset sources_1

# 3. 기존에 실패했거나 정체되어 있는 Runs 상태를 완전히 리셋 (대괄호 버그 수정)
puts "--- Resetting previous compilation runs to unlock Vivado build engine ---"
reset_run synth_1
reset_run impl_1

# 4. Run Synthesis (논리 합성 진행)
puts "--- Launching Synthesis (synth_1) ---"
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# 5. Run Implementation (물리 배치 및 배선 진행)
puts "--- Launching Implementation (impl_1) ---"
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# 6. 결과 분석을 위한 물리 디자인 세션 오픈 및 레포트 추출
open_run impl_1

report_utilization -file utilization_report.txt
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -file timing_summary_report.txt

exit