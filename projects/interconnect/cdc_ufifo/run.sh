#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
WORK="$SCRIPT_DIR/validation/work"
REPORT="$SCRIPT_DIR/validation"
mkdir -p "$WORK" "$REPORT"

RTL="$SCRIPT_DIR/rtl/cdc_ufifo.sv"
TB="$SCRIPT_DIR/tb/tb_cdc_ufifo.sv"
: >"$REPORT/compile.log"
: >"$REPORT/simulation.log"
for mode in registered combinational; do
  define_args=()
  if [[ "$mode" == "combinational" ]]; then
    define_args=(-DCOMB_OUTPUT)
  fi
  echo "=== mode=$mode ===" >>"$REPORT/compile.log"
  "$IVERILOG" -g2012 -Wall "${define_args[@]}" -s tb_cdc_ufifo \
    -o "$WORK/tb_cdc_ufifo_$mode.vvp" "$RTL" "$TB" \
    >>"$REPORT/compile.log" 2>&1
  echo "=== mode=$mode ===" >>"$REPORT/simulation.log"
  timeout 30s "$VVP" -n "$WORK/tb_cdc_ufifo_$mode.vvp" \
    >>"$REPORT/simulation.log" 2>&1
done
[[ "$(grep -c CDC_UFIFO_PASS "$REPORT/simulation.log")" -eq 2 ]]
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal \
  --top-module cdc_ufifo "$RTL" >"$REPORT/lint.log" 2>&1
if grep -q "%Error" "$REPORT/lint.log"; then
  echo "cdc_ufifo: lint failed" >&2
  exit 1
fi
printf '%s\n' \
  '{' \
  '  "project": "cdc_ufifo",' \
  '  "status": "pass",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "lint_errors": 0,' \
  '  "test_level": "self_checking_functional",' \
  '  "checks": ["clock crossing", "ordered data", "qenable backpressure", "shadowed TRUE registered output", "shadowed FALSE combinational output"]' \
  '}' >"$REPORT/result.json"
echo "cdc_ufifo refactored SV: PASS"
