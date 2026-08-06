#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"
"$IVERILOG" -g2012 -Wall -s tb_dma_axi64 -o validation/tb_dma_axi64.vvp -f filelists/mixed.f >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_dma_axi64.vvp >validation/simulation.log 2>&1
grep -q DMA_AXI64_TOP_SV_PASS validation/simulation.log
"$VERILATOR" --lint-only -Wall -Wno-fatal -Irtl/legacy --top-module dma_axi64 rtl/top/dma_axi64.sv rtl/legacy/*.v >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then
  echo "dma_axi64: lint failed" >&2
  exit 1
fi
printf '%s\n' \
  '{' \
  '  "project": "dma_axi64",' \
  '  "status": "pass",' \
  '  "strategy": "top_only",' \
  '  "top_language": "systemverilog",' \
  '  "internal_language": "verilog",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "simulation_level": "reset_idle_smoke",' \
  '  "lint_errors": 0,' \
  '  "checks": ["mixed-language elaboration", "reset convergence", "no unknown top outputs", "no unexpected AXI request while idle"]' \
  '}' >validation/result.json
echo "dma_axi64 top-only SV: PASS"
