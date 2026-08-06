#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"

cd "$PROJECT_ROOT"
mkdir -p validation
RTL=(rtl/blocks/edge_det.sv rtl/blocks/rtfSimpleUartTx.sv \
     rtl/blocks/rtfSimpleUartRx.sv rtl/blocks/rtfSimpleUart.sv)
"$IVERILOG" -g2012 -Wall -s tb_rtfsimpleuart -o validation/tb_rtfsimpleuart.vvp \
  "${RTL[@]}" tb/tb_rtfsimpleuart.sv >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_rtfsimpleuart.vvp >validation/simulation.log 2>&1
grep -q RTFSIMPLEUART_SV_PASS validation/simulation.log
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal --top-module rtfSimpleUart \
  "${RTL[@]}" >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then
  echo "rtfsimpleuart: lint failed" >&2
  exit 1
fi
printf '%s\n' \
  '{' \
  '  "project": "rtfsimpleuart",' \
  '  "status": "pass",' \
  '  "strategy": "full_refactor_with_bug_fixes",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "simulation_level": "protocol_loopback",' \
  '  "lint_errors": 0,' \
  '  "checks": ["UART 8N1 loopback", "back-to-back buffered bytes", "Wishbone acknowledge", "RX status", "TX idle/complete"]' \
  '}' >validation/result.json
echo "rtfsimpleuart: PASS"
