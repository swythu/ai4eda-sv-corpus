#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="${1:?project root}"; TOP="${2:?top module}"; MARKER="${3:?pass marker}"
IVERILOG="${IVERILOG:-iverilog}"; VVP="${VVP:-vvp}"; VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"
mapfile -t RTL < <(find rtl -type f -name '*.sv' | sort)
mapfile -t TB < <(find tb -type f -name '*.sv' | sort)
"$IVERILOG" -g2012 -Wall -s "tb_${TOP}" -o validation/test.vvp "${RTL[@]}" "${TB[@]}" >validation/compile.log 2>&1
"$VVP" -n validation/test.vvp >validation/simulation.log 2>&1
grep -q "$MARKER" validation/simulation.log
"$VERILATOR" --lint-only -Wall -Wno-fatal --top-module "$TOP" "${RTL[@]}" >validation/lint.log 2>&1
! grep -q '^%Error' validation/lint.log
