#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"; VVP="${VVP:-vvp}"; VERILATOR="${VERILATOR:-verilator}"
cd "$ROOT"
"$IVERILOG" -g2012 -Wall -s tb_ot_sram_1p -o validation/test.vvp rtl/ot_sram_1p.sv tb/tb_ot_sram_1p.sv >validation/compile.log 2>&1
"$VVP" -n validation/test.vvp >validation/simulation.log 2>&1
grep -q OT_SRAM_1P_PASS validation/simulation.log
"$VERILATOR" --lint-only -Wall -Wno-fatal --top-module ot_sram_1p rtl/ot_sram_1p.sv >validation/lint.log 2>&1
! grep -q '^%Error' validation/lint.log
printf '%s\n' '{"project":"ot_sram_1p","status":"pass","compile":"pass","simulation":"pass","test_level":"self_checking_functional","lint_errors":0,"checks":["synchronous read","masked write","request gating"]}' >validation/result.json
