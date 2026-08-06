#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"
mkdir -p validation
"$IVERILOG" -g2012 -Wall -s tb_logicprobe -o validation/tb_logicprobe.vvp rtl/top/LogicProbe.sv tb/tb_logicprobe.sv >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_logicprobe.vvp >validation/simulation.log 2>&1
grep -q LOGICPROBE_SV_PASS validation/simulation.log
"$VERILATOR" --lint-only -Wall -Wno-fatal --top-module LogicProbe rtl/top/LogicProbe.sv >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then exit 1; fi
echo "logicprobe: PASS"
