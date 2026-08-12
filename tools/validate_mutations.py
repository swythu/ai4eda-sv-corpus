#!/usr/bin/env python3
"""Validate public mutation summaries; private mutants never enter the release tree."""

from __future__ import annotations

import argparse
import json

from jsonschema import Draft202012Validator

from ipgraph_common import SCHEMAS, project_directories


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-q3", action="store_true")
    args = parser.parse_args()
    schema = json.loads((SCHEMAS / "mutation_summary.schema.json").read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema)
    passed = pending = failures = 0
    for project in project_directories():
        path = project / "validation/mutation_summary.json"
        if not path.exists():
            pending += 1
            continue
        record = json.loads(path.read_text(encoding="utf-8"))
        errors = [error.message for error in validator.iter_errors(record)]
        if record.get("project_id") != project.name:
            errors.append("project_id does not match directory")
        if record.get("killed", 0) + record.get("survived", 0) != record.get("non_equivalent_total"):
            errors.append("killed + survived must equal non_equivalent_total")
        if record.get("status") == "pass" and (not record.get("baseline_pass") or record.get("survived") != 0):
            errors.append("pass requires a passing baseline and zero surviving non-equivalent mutants")
        if errors:
            failures += 1
            print(f"[FAIL] {project.name}: {'; '.join(errors)}")
        elif record["status"] == "pass":
            passed += 1
        else:
            failures += 1
            print(f"[FAIL] {project.name}: mutation campaign status is fail")
    print(f"[MUTATION] q3={passed} pending={pending} failures={failures}")
    return 1 if failures or (args.require_q3 and pending) else 0


if __name__ == "__main__":
    raise SystemExit(main())
