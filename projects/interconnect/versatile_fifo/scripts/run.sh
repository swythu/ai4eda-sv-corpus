#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"

cd "$PROJECT_ROOT"
mkdir -p validation
RTL=(rtl/blocks/async_fifo_core.sv rtl/blocks/async_fifo_dw_simplex_top.sv)
"$IVERILOG" -g2012 -Wall -s tb_versatile_fifo -o validation/tb_versatile_fifo.vvp \
  "${RTL[@]}" tb/tb_versatile_fifo.sv >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_versatile_fifo.vvp >validation/simulation.log 2>&1
grep -q VERSATILE_FIFO_SV_PASS validation/simulation.log
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal --top-module async_fifo_dw_simplex_top \
  "${RTL[@]}" >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then
  echo "versatile_fifo: lint failed" >&2
  exit 1
fi
printf '%s\n' \
  '{' \
  '  "project": "versatile_fifo",' \
  '  "status": "pass",' \
  '  "strategy": "core_refactor_with_cdc_hardening",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "simulation_level": "asynchronous_bidirectional_protocol",' \
  '  "lint_errors": 0,' \
  '  "checks": ["6 A-to-B words", "5 B-to-A words", "independent clocks", "FIFO ordering", "reset and empty flags", "Gray pointer 2FF CDC"]' \
  '}' >validation/result.json
echo "versatile_fifo: PASS"
