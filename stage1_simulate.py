import os
import subprocess
import sys

# 1. 소스 디렉토리 보장 및 COE 파일 생성
os.makedirs("src", exist_ok=True)

current_dir = os.path.abspath(os.getcwd())
current_dir_fixed = current_dir.replace("\\", "/")
coe_absolute_path = f"{current_dir_fixed}/imem.coe"

coe_content = """memory_initialization_radix=16;
memory_initialization_vector=
04400000,
04000000,
1000000a,
14000007,
08400000,
0c000001,
18000002,
18000007;
"""
with open("imem.coe", "w") as f:
    f.write(coe_content)

print("[INFO] ROM Initialization Coefficient File (.coe) Created Successfully.")
print(f"[INFO] COE Target Path: {coe_absolute_path}")

# 2. TCL 스크립트와 데이터 연동을 위한 환경 변수 세팅
os.environ["COE_ABS_PATH"] = coe_absolute_path

# 3. Vivado Simulator 가동 (대화형 프롬프트 교착 원천 차단)
print("[INFO] Launching Vivado Simulator in Batch Mode... Progress logs will be displayed below.\n")

# -mode batch 로 되돌려 대화형 입력 대기 방지
cmd = [r"D:\Vivado\Vivado\2023.2\bin\vivado.bat", "-mode", "batch", "-source", "sim.tcl", "-notrace"]

process = subprocess.Popen(
    cmd,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    stdin=subprocess.DEVNULL, # 키보드 입력을 완전히 차단하여 대기(Hang) 상태 방지
    text=True,
    bufsize=1
)

# 실시간 로그 출력 루프 (iter 방식 적용으로 안전하게 EOF 감지)
for line in iter(process.stdout.readline, ''):
    print(line.strip())

process.stdout.close()
return_code = process.wait()

print(f"\n[INFO] Vivado Simulation Engine Run Finished with Code {return_code}.")

# 4. 아키텍처 내부 데이터패스 결과 및 추적 분석 가동
trace_file_path = "./sim_project/single_cycle_sim.sim/sim_1/behav/xsim/sim_execution_trace.log"

if not os.path.exists(trace_file_path):
    trace_file_path = "./sim_execution_trace.log"

if not os.path.exists(trace_file_path):
    print("[ERROR] Verification log file ('sim_execution_trace.log') was not found.")
    sys.exit(1)

with open(trace_file_path, "r") as f:
    lines = f.readlines()

has_failed = False
loop_ended = False

print("\n" + "="*50)
print("  HARDWARE ARCHITECTURE TRACE AUTONOMOUS ANALYZER  ")
print("="*50)

for line in lines:
    line = line.strip()
    if not line: continue
    
    parts = {k: v for k, v in [item.split(":") for item in line.split("|")]}
    
    cycle = int(parts["CYCLE"])
    pc = int(parts["PC"])
    r0 = int(parts["R0"])
    r1 = int(parts["R1"])
    alu_res = parts["ALU"]
    reg_w = parts["REG_W"]
    br = parts["BR"]
    jmp = parts["JMP"]

    if cycle < 2:
        continue

    if pc == 0:
        if reg_w != '1' or r1 != 0:
            print(f"[BUG FOUND] Cycle {cycle} at PC 0 (MOV R1,#0): Mismatch. RegW={reg_w}, R1={r1}")
            has_failed = True
    elif pc == 1:
        if reg_w != '1' or r0 != 0:
            print(f"[BUG FOUND] Cycle {cycle} at PC 1 (MOV R0,#0): Mismatch. RegW={reg_w}, R0={r0}")
            has_failed = True
    elif pc == 2:
        expected_sub = (r0 - 10) & 0xFFFFFFFF
        if reg_w != '0' or int(alu_res, 16) != expected_sub:
            print(f"[BUG FOUND] Cycle {cycle} at PC 2 (CMP R0,#10): ALU error. Expected={hex(expected_sub)}, Got={alu_res}")
            has_failed = True
    elif pc == 3:
        if br != '1':
            print(f"[BUG FOUND] Cycle {cycle} at PC 3 (BGE): Control Branch Assert Signal Missing.")
            has_failed = True
    elif pc == 7:
        loop_ended = True
        if r1 != 45:
            print(f"[LOGIC CRITICAL FAULT] Arrived at DONE branch, but final Sum R1 is {r1} (Expected 45)")
            has_failed = True
            break

if loop_ended and not has_failed:
    print("\n[SUCCESS] ARCHITECTURAL VERIFICATION PASSED.")
    print(f" -> Final Register Core State: R0 = {r0}, R1 (Result Sum) = {r1}")
    print(" -> Data flow matches assembly rules accurately.\n")
else:
    print("\n[FAILURE] HARDWARE VERIFICATION TIMEOUT OR FAULT ENCOUNTERED.\n")