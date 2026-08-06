#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"

cd "$PROJECT_ROOT"
mkdir -p validation
"$IVERILOG" -g2012 -Wall -s tb_ima_adpcm_equiv \
  -o validation/tb_ima_adpcm_equiv.vvp \
  rtl/blocks/ima_adpcm_enc.sv rtl/blocks/ima_adpcm_dec.sv \
  tb/legacy/ima_adpcm_enc_legacy.v tb/legacy/ima_adpcm_dec_legacy.v \
  tb/tb_ima_adpcm_equiv.sv >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_ima_adpcm_equiv.vvp \
  >validation/simulation.log 2>&1
grep -q IMA_ADPCM_SV_PASS validation/simulation.log
for top in ima_adpcm_enc ima_adpcm_dec; do
  "$VERILATOR" --lint-only --sv -Wall -Wno-fatal --top-module "$top" \
    "rtl/blocks/${top}.sv" >"validation/lint_${top}.log" 2>&1
  if grep -q '^%Error' "validation/lint_${top}.log"; then
    echo "ima_adpcm_enc_dec: lint failed for $top" >&2
    exit 1
  fi
done
printf '%s\n' \
  '{' \
  '  "project": "ima_adpcm_enc_dec",' \
  '  "status": "pass",' \
  '  "strategy": "full_refactor",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "simulation_level": "cycle_equivalence",' \
  '  "lint_errors": 0,' \
  '  "checks": ["64 encoder transactions", "cycle-accurate legacy equivalence", "encoder state", "decoded samples", "ready/valid timing"]' \
  '}' >validation/result.json
echo "ima_adpcm_enc_dec: PASS"
