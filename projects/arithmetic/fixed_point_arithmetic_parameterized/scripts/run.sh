#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"

cd "$PROJECT_ROOT"
mkdir -p validation
"$IVERILOG" -g2012 -Wall -s tb_fixed_point -o validation/tb_fixed_point.vvp \
  rtl/blocks/qadd.sv rtl/blocks/qmult.sv rtl/blocks/qdiv.sv tb/tb_fixed_point.sv \
  >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_fixed_point.vvp >validation/simulation.log 2>&1
grep -q FIXED_POINT_SV_PASS validation/simulation.log
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal \
  rtl/blocks/qadd.sv rtl/blocks/qmult.sv rtl/blocks/qdiv.sv \
  >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then
  echo "fixed_point_arithmetic_parameterized: lint failed" >&2
  exit 1
fi
printf '%s\n' \
  '{' \
  '  "project": "fixed_point_arithmetic_parameterized",' \
  '  "status": "pass",' \
  '  "strategy": "full_refactor_with_bug_fixes",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "simulation_level": "mathematical_reference",' \
  '  "lint_errors": 0,' \
  '  "checks": ["same-sign addition", "mixed-sign addition", "signed multiplication", "iterative division", "divide-by-zero"]' \
  '}' >validation/result.json
echo "fixed_point_arithmetic_parameterized: PASS"
