#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
VERILATOR_ARGS=()
VERILATOR_MAJOR="$("$VERILATOR" --version | sed -E 's/^Verilator ([0-9]+).*/\1/')"
if [[ "$VERILATOR_MAJOR" =~ ^[0-9]+$ ]] && (( VERILATOR_MAJOR >= 5 )); then
  VERILATOR_ARGS+=(--no-timing)
fi
cd "$PROJECT_ROOT"
"$IVERILOG" -g2012 -Wall -s tb_dma_axi32 -o validation/tb_dma_axi32.vvp -f filelists/mixed.f >validation/compile.log 2>&1
timeout 30s "$VVP" -n validation/tb_dma_axi32.vvp >validation/simulation.log 2>&1
grep -q DMA_AXI32_FUNCTIONAL_PASS validation/simulation.log
"$VERILATOR" --lint-only -Wall -Wno-fatal "${VERILATOR_ARGS[@]}" -Irtl/legacy --top-module dma_axi32 rtl/top/dma_axi32.sv rtl/legacy/*.v >validation/lint.log 2>&1
if grep -q '^%Error' validation/lint.log; then
  echo "dma_axi32: lint failed" >&2
  exit 1
fi
printf '%s\n' \
  '{' \
  '  "project": "dma_axi32",' \
  '  "status": "pass",' \
  '  "strategy": "top_only",' \
  '  "top_language": "systemverilog",' \
  '  "internal_language": "verilog",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "simulation_level": "self_checking_control_plane_functional",' \
  '  "lint_errors": 0,' \
  '  "checks": ["mixed-language elaboration", "reset convergence", "APB global register read/write", "APB channel register read/write", "APB access-policy errors", "no unexpected AXI request while idle"]' \
  '}' >validation/result.json
echo "dma_axi32 top-only SV: PASS"
