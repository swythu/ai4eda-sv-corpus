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
  "$PROJECT_ROOT/rtl/i2c_master_bit_ctrl.sv"
  "$PROJECT_ROOT/rtl/i2c_master_byte_ctrl.sv"
  "$PROJECT_ROOT/rtl/i2c_master_top.sv"
)
TB=(
  "$PROJECT_ROOT/tb/wb_master_model.sv"
  "$PROJECT_ROOT/tb/i2c_slave_model.sv"
  "$PROJECT_ROOT/tb/tst_bench_top.sv"
)

"$IVERILOG" -g2012 -Wall -I "$PROJECT_ROOT/include" -I "$PROJECT_ROOT/tb" -s tst_bench_top \
  -o "$WORK/i2c.vvp" "${RTL[@]}" "${TB[@]}" \
  >"$REPORT/compile.log" 2>&1
timeout 60s "$VVP" -n "$WORK/i2c.vvp" >"$REPORT/simulation.log" 2>&1
grep -q "I2C_SV_PASS" "$REPORT/simulation.log"
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal -I"$PROJECT_ROOT/include" --top-module i2c_master_top \
  "${RTL[@]}" >"$REPORT/lint.log" 2>&1
if grep -q "%Error" "$REPORT/lint.log"; then
  echo "i2c: lint failed" >&2
  exit 1
fi

printf '%s\n' \
  '{' \
  '  "project": "i2c",' \
  '  "status": "pass",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "test_level": "self_checking_functional",' \
  '  "checks": ["prescaler registers", "slave write and read-back", "invalid-address nack"]' \
  '}' >"$REPORT/result.json"
echo "i2c refactored SV: PASS"
