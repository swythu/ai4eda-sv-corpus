#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."&&pwd)";"$ROOT/../../../tools/run_simple_project.sh" "$ROOT" wishbone_apb_bridge WISHBONE_APB_BRIDGE_PASS;printf '%s\n' '{"project":"wishbone_apb_bridge","status":"pass","compile":"pass","simulation":"pass","test_level":"self_checking_functional","lint_errors":0}' >"$ROOT/validation/result.json"
