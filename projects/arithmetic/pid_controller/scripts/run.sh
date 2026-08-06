#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"; mkdir -p validation
"$IVERILOG" -g2012 -Wall -s tb_pid_controller -o validation/tb_pid_controller.vvp \
  rtl/blocks/pid_controller.sv tb/tb_pid_controller.sv >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_pid_controller.vvp >validation/simulation.log 2>&1
grep -q PID_CONTROLLER_SV_PASS validation/simulation.log
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal --top-module pid_controller \
  rtl/blocks/pid_controller.sv >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then exit 1; fi
printf '%s\n' '{' '  "project": "pid_controller",' '  "status": "pass",' \
 '  "strategy": "full_behavioral_refactor",' '  "compile": "pass",' \
 '  "simulation": "pass",' '  "simulation_level": "mathematical_reference",' \
 '  "lint_errors": 0,' \
 '  "checks": ["Wishbone register access", "proportional term", "integral accumulation", "derivative term", "state reset", "overflow status"]' \
 '}' >validation/result.json
echo "pid_controller: PASS"
