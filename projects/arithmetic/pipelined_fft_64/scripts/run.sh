#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
WORK="$PROJECT_ROOT/validation/work"
REPORT="$PROJECT_ROOT/validation"
mkdir -p "$WORK" "$REPORT"

RTL=(
  "$PROJECT_ROOT/rtl/mpu707.sv"
  "$PROJECT_ROOT/rtl/ram64.sv"
  "$PROJECT_ROOT/rtl/ram2x64c_1.sv"
  "$PROJECT_ROOT/rtl/bufram64c1.sv"
  "$PROJECT_ROOT/rtl/WROM64.sv"
  "$PROJECT_ROOT/rtl/rotator64.sv"
  "$PROJECT_ROOT/rtl/fft8.sv"
  "$PROJECT_ROOT/rtl/cnorm.sv"
  "$PROJECT_ROOT/rtl/usfft64_2b.sv"
)
TB=(
  "$PROJECT_ROOT/tb/tb_usfft64_2b.sv"
)

cp "$PROJECT_ROOT/tb/sine.hex" "$PROJECT_ROOT/tb/golden.txt" "$WORK/"

"$IVERILOG" -g2012 -Wall -I "$PROJECT_ROOT/include" -s tb_usfft64_2b \
  -o "$WORK/fft64.vvp" "${RTL[@]}" "${TB[@]}" \
  >"$REPORT/compile.log" 2>&1
(cd "$WORK" && timeout 60s "$VVP" -n fft64.vvp) >"$REPORT/simulation.log" 2>&1
grep -q "FFT64_SV_PASS" "$REPORT/simulation.log"
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal -I"$PROJECT_ROOT/include" --top-module USFFT64_2B \
  "${RTL[@]}" >"$REPORT/lint.log" 2>&1
if grep -q "%Error" "$REPORT/lint.log"; then
  echo "pipelined_fft_64: lint failed" >&2
  exit 1
fi

printf '%s\n' \
  '{' \
  '  "project": "pipelined_fft_64",' \
  '  "status": "pass",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "test_level": "self_checking_functional",' \
  '  "checks": ["full output frame", "spectral peak at stimulus bin", "spurious-free response", "no overflow"]' \
  '}' >"$REPORT/result.json"
echo "pipelined_fft_64 refactored SV: PASS"
