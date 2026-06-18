import os
import subprocess
import sys

# 제약조건 디렉토리 자동 확보 및 셋업
os.makedirs("synth", exist_ok=True)

print("[INFO] Commencing Logic Synthesis and Implementation Routing on Vivado Compiler Engine...")
print("[INFO] Launching Vivado Implementation... Progress logs will be displayed below in real-time.\n")

# 배치 모드에서 -notrace 옵션을 주어 터미널로 실시간 출력을 유도합니다.
cmd = [r"D:\Vivado\Vivado\2023.2\bin\vivado.bat", "-mode", "batch", "-source", "impl.tcl", "-notrace"]

process = subprocess.Popen(
    cmd,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    stdin=subprocess.DEVNULL,
    text=True,
    bufsize=1
)

# Vivado 합성/구현 로그를 실시간으로 한 줄씩 긁어서 터미널에 인쇄
for line in iter(process.stdout.readline, ''):
    print(line.strip())

process.stdout.close()
return_code = process.wait()

if return_code != 0:
    print(f"\n[FATAL ERROR] Vivado Synthesis/Implementation Process Exited Abnormally with Code {return_code}")
    print("[TIP] Check the error logs above to trace if there are pin assignment or logic optimization issues.")
    sys.exit(1)

print("\n[INFO] Vivado Implementation Engine Run Finished Successfully.")

# 추출된 하드웨어 리포트 계측 파싱 분석 엔진 가동
util_file = "utilization_report.txt"
timing_file = "timing_summary_report.txt"

print("\n" + "="*50)
print("   FPGA HARDWARE METRICS IMPLEMENTATION REPORT   ")
print("="*50)

# 1. 리소스 사용량 레포트 정밀 분석
if os.path.exists(util_file):
    print("[DEVICE UTILIZATION ANALYSIS]")
    with open(util_file, "r", errors='ignore') as f:
        content = f.read()
    for line in content.split("\n"):
        if "Slice LUTs" in line or "Register as Flip Flop" in line or "Block RAM" in line or "DSPs" in line:
            print(f"  > {line.strip()}")
else:
    print("[ERROR] Utilization report parsing failed. File 'utilization_report.txt' not generated.")

print("-"*50)

# 2. 타이밍 마진 적합성 판별 분석 (100MHz 만족 여부 점검)
if os.path.exists(timing_file):
    print("[TIMING ANALYTICAL RESULT]")
    with open(timing_file, "r", errors='ignore') as f:
        lines = f.readlines()
    wns_found = False
    for line in lines:
        if "Worst Negative Slack (WNS)" in line:
            print(f"  > {line.strip()}")
            wns_found = True
            try:
                # 라인 안에서 WNS 수치 파싱 및 슬랙 적합성 자동 판정
                tokens = line.split()
                # Vivado 레포트 스타일에 따라 WNS 값이 위치하는 인덱스를 유연하게 추적
                wns_val = None
                for token in tokens:
                    if 'ns' not in token and ('-' in token or token.replace('.','',1).isdigit()):
                        try:
                            wns_val = float(token)
                            break
                        except:
                            continue
                
                if wns_val is not None:
                    if wns_val >= 0.0:
                        print(f"  > [STATUS] TIMING PASSED! Setup slack is positive ({wns_val}ns). Target 100MHz achieved.")
                    else:
                        print(f"  > [STATUS] TIMING VIOLATION! Slack is negative ({wns_val}ns). Single-cycle critical path is too long.")
            except Exception as e:
                print(f"  > [NOTE] Could not auto-evaluate slack value numerically: {e}")
            break
    if not wns_found:
        print("  > WNS metrics not found directly in summary header. Please review 'timing_summary_report.txt' manually.")
else:
    print("[ERROR] Timing report parsing failed. File 'timing_summary_report.txt' not generated.")
print("="*50 + "\n")