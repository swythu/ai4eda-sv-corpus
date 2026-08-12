#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."&&pwd)";"$ROOT/../../../tools/run_simple_project.sh" "$ROOT" ready_valid_checker READY_VALID_CHECKER_PASS;printf '%s\n' '{"project":"ready_valid_checker","status":"pass","compile":"pass","simulation":"pass","test_level":"self_checking_functional","lint_errors":0}' >"$ROOT/validation/result.json"
