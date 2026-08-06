#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IVERILOG="${IVERILOG:-iverilog}"
VVP="${VVP:-vvp}"
VERILATOR="${VERILATOR:-verilator}"
cd "$PROJECT_ROOT"
mkdir -p validation
: >validation/compile.log
: >validation/simulation.log
: >validation/lint.log
for n in 1 256 512; do
  "$IVERILOG" -g2012 -Wall -s test_sha -o "validation/test_sha${n}.vvp" "rtl/blocks/sha${n}.sv" "tb/test_sha${n}.sv" >>validation/compile.log 2>&1
  timeout 30s "$VVP" -n "validation/test_sha${n}.vvp" >>validation/simulation.log 2>&1
  "$VERILATOR" --lint-only -Wall -Wno-fatal --top-module "sha${n}" "rtl/blocks/sha${n}.sv" >>validation/lint.log 2>&1
done
if grep -q '^ERROR' validation/simulation.log || grep -q '^%Error' validation/lint.log; then exit 1; fi
test "$(grep -c '^OK(SHA-' validation/simulation.log)" -eq 41
echo "SHA_CORE_SV_PASS digest_words=41 sha1=pass sha256=pass sha384=pass sha512=pass" >>validation/simulation.log
echo "sha_core: PASS"
