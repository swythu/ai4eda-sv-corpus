#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)";IVERILOG="${IVERILOG:-iverilog}";VVP="${VVP:-vvp}";VERILATOR="${VERILATOR:-verilator}";cd "$ROOT"
"$IVERILOG" -g2012 -Wall -s tb_register_file -o validation/test.vvp rtl/register_file.sv tb/tb_register_file.sv >validation/compile.log 2>&1
"$VVP" -n validation/test.vvp >validation/simulation.log 2>&1
grep -q REGISTER_FILE_PASS validation/simulation.log
"$VERILATOR" --lint-only -Wall -Wno-fatal --top-module register_file rtl/register_file.sv >validation/lint.log 2>&1
! grep -q '^%Error' validation/lint.log
printf '%s\n' '{"project":"register_file","status":"pass","compile":"pass","simulation":"pass","test_level":"self_checking_functional","lint_errors":0,"checks":["dual read","write bypass","zero register"]}' >validation/result.json
