#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"
mkdir -p validation
"$IVERILOG" -g2012 -Wall -s tb_wb_flash -o validation/tb_wb_flash.vvp rtl/top/wb_flash.sv tb/tb_wb_flash.sv >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_wb_flash.vvp >validation/simulation.log 2>&1
grep -q WB_FLASH_SV_PASS validation/simulation.log
"$VERILATOR" --lint-only -Wall -Wno-fatal --top-module wb_flash rtl/top/wb_flash.sv >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then exit 1; fi
echo "wb_flash: PASS"
