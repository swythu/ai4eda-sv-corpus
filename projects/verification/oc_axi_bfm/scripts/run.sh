#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"; mkdir -p validation
"$IVERILOG" -g2012 -Wall -s tb_oc_axi_lite_master -o validation/tb_oc_axi.vvp rtl/top/new_component.sv tb/tb_oc_axi_lite_master.sv >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_oc_axi.vvp >validation/simulation.log 2>&1
grep -q OC_AXI_BFM_SV_PASS validation/simulation.log
"$VERILATOR" --lint-only -Wall -Wno-fatal --top-module new_component rtl/top/new_component.sv >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then exit 1; fi
echo "oc_axi_bfm: PASS"
