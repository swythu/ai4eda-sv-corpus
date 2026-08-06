#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"
mkdir -p validation
"${IVERILOG}" -g2012 -Wall  -s tb_cfg_crc -o validation/tb_cfg_crc.vvp "$PROJECT_ROOT/rtl/top/cfg_crc.sv" "$PROJECT_ROOT/tb/crc_7.sv" "$PROJECT_ROOT/tb/tb_cfg_crc.sv" >validation/compile.log 2>&1
timeout 30s "${VVP}" -n validation/tb_cfg_crc.vvp >validation/simulation.log 2>&1
grep -q CFG_CRC_SV_PASS validation/simulation.log
"${VERILATOR}" --lint-only -Wall -Wno-fatal  --top-module cfg_crc "$PROJECT_ROOT/rtl/top/cfg_crc.sv" >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then echo "configurable_crc_core: lint failed" >&2; exit 1; fi
echo "configurable_crc_core: PASS"
