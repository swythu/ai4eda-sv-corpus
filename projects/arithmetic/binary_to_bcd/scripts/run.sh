#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"
mkdir -p validation
"${IVERILOG}" -g2012 -Wall  -s tb_binary_bcd -o validation/tb_binary_bcd.vvp "$PROJECT_ROOT/rtl/top/binary_to_bcd.sv" "$PROJECT_ROOT/rtl/top/bcd_to_binary.sv" "$PROJECT_ROOT/tb/tb_binary_bcd.sv" >validation/compile.log 2>&1
timeout 30s "${VVP}" -n validation/tb_binary_bcd.vvp >validation/simulation.log 2>&1
grep -q BINARY_BCD_SV_PASS validation/simulation.log
"${VERILATOR}" --lint-only -Wall -Wno-fatal  --top-module binary_to_bcd "$PROJECT_ROOT/rtl/top/binary_to_bcd.sv" "$PROJECT_ROOT/rtl/top/bcd_to_binary.sv" >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then echo "binary_to_bcd: lint failed" >&2; exit 1; fi
echo "binary_to_bcd: PASS"
