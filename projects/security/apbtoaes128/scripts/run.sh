#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"; mkdir -p validation
RTL=(rtl/top/aes_ip.sv rtl/legacy/aes_core.v rtl/legacy/control_unit.v \
 rtl/legacy/data_swap.v rtl/legacy/datapath.v rtl/legacy/host_interface.v \
 rtl/legacy/key_expander.v rtl/legacy/mix_columns.v rtl/legacy/sBox.v \
 rtl/legacy/sBox_8.v rtl/legacy/shift_rows.v)
"$IVERILOG" -g2012 -Wall -s tb_aes_ip -o validation/tb_aes_ip.vvp \
  "${RTL[@]}" tb/tb_aes_ip.v >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_aes_ip.vvp >validation/simulation.log 2>&1
for marker in 'ECB TEST PASSED' 'CBC TEST PASSED' 'CTR TEST PASSED' \
              'SUSPEND MODE TEST PASSED' 'DMA TEST PASSED'; do
  grep -q "$marker" validation/simulation.log
done
if grep -q 'TEST FAILED' validation/simulation.log; then exit 1; fi
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal --top-module aes_ip \
  "${RTL[@]}" >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then exit 1; fi
printf '%s\n' '{' '  "project": "apbtoaes128",' '  "status": "pass",' \
 '  "strategy": "top_refactor_verified_legacy_core",' '  "compile": "pass",' \
 '  "simulation": "pass",' '  "simulation_level": "known_answer_and_protocol",' \
 '  "lint_errors": 0,' \
 '  "checks": ["AES-128 ECB", "AES-128 CBC", "AES-128 CTR", "suspend/resume", "APB register interface", "DMA request mode"]' \
 '}' >validation/result.json
echo "apbtoaes128: PASS"
