# 100MHz 하드웨어 타이밍 클럭 도메인 제약 설정 (Period = 10.00ns)
create_clock -period 10.000 -name sys_clk [get_ports clk]

# 오차 배제를 위한 클럭 입력 전파 고정 지연 모델 적용
set_input_delay -clock sys_clk -max 2.000 [get_ports rst]