#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
WORK="$PROJECT_ROOT/validation/work"
REPORT="$PROJECT_ROOT/validation"
mkdir -p "$WORK" "$REPORT"

RTL=(
  "$PROJECT_ROOT/rtl/baud_gen.sv"
  "$PROJECT_ROOT/rtl/uart_rx.sv"
  "$PROJECT_ROOT/rtl/uart_tx.sv"
  "$PROJECT_ROOT/rtl/uart_top.sv"
  "$PROJECT_ROOT/rtl/uart_parser.sv"
  "$PROJECT_ROOT/rtl/uart2bus_top.sv"
)
TB=(
  "$PROJECT_ROOT/tb/reg_file_model.sv"
  "$PROJECT_ROOT/tb/tb_uart2bus_top.sv"
)

"$IVERILOG" -g2012 -Wall -I "$PROJECT_ROOT/include" -I "$PROJECT_ROOT/tb" -s tb_uart2bus_top \
  -o "$WORK/uart2bus.vvp" "${RTL[@]}" "${TB[@]}" \
  >"$REPORT/compile.log" 2>&1
timeout 60s "$VVP" -n "$WORK/uart2bus.vvp" >"$REPORT/simulation.log" 2>&1
grep -q "UART2BUS_SV_PASS" "$REPORT/simulation.log"
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal -I"$PROJECT_ROOT/include" --top-module uart2bus_top \
  "${RTL[@]}" >"$REPORT/lint.log" 2>&1
if grep -q "%Error" "$REPORT/lint.log"; then
  echo "uart2bus: lint failed" >&2
  exit 1
fi

printf '%s\n' \
  '{' \
  '  "project": "uart2bus",' \
  '  "status": "pass",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "test_level": "self_checking_functional",' \
  '  "checks": ["ascii write command", "ascii read-back response", "8N1 115200 serial framing"]' \
  '}' >"$REPORT/result.json"
echo "uart2bus refactored SV: PASS"
