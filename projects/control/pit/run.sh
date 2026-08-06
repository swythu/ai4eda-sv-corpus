#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
WORK="$SCRIPT_DIR/validation/work"
REPORT="$SCRIPT_DIR/validation"
mkdir -p "$WORK" "$REPORT"

RTL=(
  "$SCRIPT_DIR/rtl/pit_count.sv"
  "$SCRIPT_DIR/rtl/pit_prescale.sv"
  "$SCRIPT_DIR/rtl/pit_regs.sv"
  "$SCRIPT_DIR/rtl/pit_wb_bus.sv"
  "$SCRIPT_DIR/rtl/pit_top.sv"
)
TB=(
  "$SCRIPT_DIR/tb/wb_master_model.sv"
  "$SCRIPT_DIR/tb/tst_bench_top.sv"
)

"$IVERILOG" -g2012 -Wall -I "$SCRIPT_DIR/tb" -s tst_bench_top \
  -o "$WORK/pit.vvp" "${RTL[@]}" "${TB[@]}" \
  >"$REPORT/compile.log" 2>&1
timeout 30s "$VVP" -n "$WORK/pit.vvp" >"$REPORT/simulation.log" 2>&1
grep -q "Simulation Passed" "$REPORT/simulation.log"
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal --top-module pit_top \
  "${RTL[@]}" >"$REPORT/lint.log" 2>&1
if grep -q "%Error" "$REPORT/lint.log"; then
  echo "pit: lint failed" >&2
  exit 1
fi

printf '%s\n' \
  '{' \
  '  "project": "pit",' \
  '  "status": "pass",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "test_level": "self_checking_functional",' \
  '  "checks": ["16-bit registers", "8-bit registers", "timer flags", "prescaler"]' \
  '}' >"$REPORT/result.json"
echo "pit refactored SV: PASS"
