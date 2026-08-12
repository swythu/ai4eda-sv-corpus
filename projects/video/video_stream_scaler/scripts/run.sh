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
  "$PROJECT_ROOT/rtl/scaler.sv"
)
TB=(
  "$PROJECT_ROOT/tb/tb_scaler.sv"
)

cp "$PROJECT_ROOT/tb/g0.hex" "$PROJECT_ROOT/tb/g1.hex" "$WORK/"

"$IVERILOG" -g2012 -Wall -I "$PROJECT_ROOT/include" -s tb_scaler \
  -o "$WORK/scaler.vvp" "${RTL[@]}" "${TB[@]}" \
  >"$REPORT/compile.log" 2>&1
(cd "$WORK" && timeout 60s "$VVP" -n scaler.vvp) >"$REPORT/simulation.log" 2>&1
grep -q "SCALER_SV_PASS" "$REPORT/simulation.log"
"$VERILATOR" --lint-only --sv -Wall -Wno-fatal -I"$PROJECT_ROOT/include" --top-module streamScaler \
  "${RTL[@]}" >"$REPORT/lint.log" 2>&1
if grep -q "%Error" "$REPORT/lint.log"; then
  echo "video_stream_scaler: lint failed" >&2
  exit 1
fi

printf '%s\n' \
  '{' \
  '  "project": "video_stream_scaler",' \
  '  "status": "pass",' \
  '  "compile": "pass",' \
  '  "simulation": "pass",' \
  '  "test_level": "self_checking_functional",' \
  '  "checks": ["identity scaling bit-exact golden", "2x downsample golden", "input gradient reproduction"]' \
  '}' >"$REPORT/result.json"
echo "video_stream_scaler refactored SV: PASS"
