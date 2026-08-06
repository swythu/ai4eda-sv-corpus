#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"
mkdir -p validation
"${IVERILOG}" -g2012 -Wall -I"$PROJECT_ROOT/include" -s tb_simple_gpio -o validation/tb_simple_gpio.vvp "$PROJECT_ROOT/rtl/top/simple_gpio.sv" "$PROJECT_ROOT/tb/tb_simple_gpio.sv" >validation/compile.log 2>&1
timeout 30s "${VVP}" -n validation/tb_simple_gpio.vvp >validation/simulation.log 2>&1
grep -q SIMPLE_GPIO_SV_PASS validation/simulation.log
"${VERILATOR}" --lint-only -Wall -Wno-fatal -I"$PROJECT_ROOT/include" --top-module simple_gpio "$PROJECT_ROOT/rtl/top/simple_gpio.sv" >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then echo "simple_gpio: lint failed" >&2; exit 1; fi
echo "simple_gpio: PASS"
