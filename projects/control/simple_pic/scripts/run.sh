#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"
mkdir -p validation
"${IVERILOG}" -g2012 -Wall -I"$PROJECT_ROOT/include" -s tb_simple_pic -o validation/tb_simple_pic.vvp "$PROJECT_ROOT/rtl/top/simple_pic.sv" "$PROJECT_ROOT/tb/tb_simple_pic.sv" >validation/compile.log 2>&1
timeout 30s "${VVP}" -n validation/tb_simple_pic.vvp >validation/simulation.log 2>&1
grep -q SIMPLE_PIC_SV_PASS validation/simulation.log
"${VERILATOR}" --lint-only -Wall -Wno-fatal -I"$PROJECT_ROOT/include" --top-module simple_pic "$PROJECT_ROOT/rtl/top/simple_pic.sv" >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then echo "simple_pic: lint failed" >&2; exit 1; fi
echo "simple_pic: PASS"
