#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"
mkdir -p validation
"${IVERILOG}" -g2012 -Wall  -s tb_tiny_spi -o validation/tb_tiny_spi.vvp "$PROJECT_ROOT/rtl/top/tiny_spi.sv" "$PROJECT_ROOT/tb/tb_tiny_spi.sv" >validation/compile.log 2>&1
timeout 30s "${VVP}" -n validation/tb_tiny_spi.vvp >validation/simulation.log 2>&1
grep -q TINY_SPI_SV_PASS validation/simulation.log
"${VERILATOR}" --lint-only -Wall -Wno-fatal  --top-module tiny_spi "$PROJECT_ROOT/rtl/top/tiny_spi.sv" >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then echo "tiny_spi: lint failed" >&2; exit 1; fi
echo "tiny_spi: PASS"
