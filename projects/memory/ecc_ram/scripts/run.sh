#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)";IVERILOG="${IVERILOG:-iverilog}";VVP="${VVP:-vvp}";VERILATOR="${VERILATOR:-verilator}";cd "$ROOT"
"$IVERILOG" -g2012 -Wall -s tb_ecc_ram -o validation/test.vvp rtl/ecc_ram.sv tb/tb_ecc_ram.sv >validation/compile.log 2>&1
"$VVP" -n validation/test.vvp >validation/simulation.log 2>&1
grep -q ECC_RAM_PASS validation/simulation.log
"$VERILATOR" --lint-only -Wall -Wno-fatal --top-module ecc_ram rtl/ecc_ram.sv >validation/lint.log 2>&1
! grep -q '^%Error' validation/lint.log
printf '%s\n' '{"project":"ecc_ram","status":"pass","compile":"pass","simulation":"pass","test_level":"self_checking_functional","lint_errors":0,"checks":["SECDED clean","single correction","double detection"]}' >validation/result.json
