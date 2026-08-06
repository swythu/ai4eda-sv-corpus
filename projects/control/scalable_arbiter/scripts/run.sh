#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"

cd "$PROJECT_ROOT"
mkdir -p validation
"$IVERILOG" -g2012 -Wall -Iinclude -s tb_scalable_arbiter \
  -o validation/tb_scalable_arbiter.vvp \
  rtl/blocks/arbiter.sv tb/tb_scalable_arbiter.sv \
  >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_scalable_arbiter.vvp \
  >validation/simulation.log 2>&1
grep -q SCALABLE_ARBITER_SV_PASS validation/simulation.log
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal -Iinclude \
  --top-module arbiter_x2 -Gwidth=16 -Gselect_width=4 rtl/blocks/arbiter.sv \
  >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then
  echo "scalable_arbiter: lint failed" >&2
  exit 1
fi
printf '%s\n' \
  '{' \
  '  "project": "scalable_arbiter",' \
  '  "status": "pass",' \
  '  "strategy": "full_core_refactor",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "simulation_level": "self_checking_functional",' \
  '  "lint_errors": 0,' \
  '  "checks": ["one-hot grant", "grant requires request", "select encoding", "all single requesters", "round-robin progress", "enable masking"]' \
  '}' >validation/result.json
echo "scalable_arbiter: PASS"
