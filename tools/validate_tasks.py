#!/usr/bin/env python3
"""Validate public task records and protect prompt/oracle separation."""

from __future__ import annotations

import json
import re
from pathlib import Path

from jsonschema import Draft202012Validator

from ipgraph_common import ROOT, SCHEMAS, project_directories


FORBIDDEN_PROMPT_PATTERNS = (
    re.compile(r"\bfrozen[_ -]?gold\b", re.I),
    re.compile(r"\bhidden[_ -]?test\b", re.I),
    re.compile(r"\bprivate[_ -]?reference\b", re.I),
    re.compile(r"\btarget_snippet\b", re.I),
    re.compile(r"\bchosen\s*[:=]", re.I),
)


def main() -> int:
    schema = json.loads((SCHEMAS / "task.schema.json").read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema)
    failures = 0
    count = 0
    lock_path = ROOT / "benchmarks/ipgraph_v1/splits.lock.json"
    lock = json.loads(lock_path.read_text(encoding="utf-8")) if lock_path.exists() else {}
    expected_split = {
        row["project_id"]: split
        for split in ("train", "dev", "public_test", "frozen_test")
        for row in lock.get(split, [])
    }
    for project in project_directories():
        for path in sorted((project / "tasks").glob("*/*.json")):
            count += 1
            record = json.loads(path.read_text(encoding="utf-8"))
            errors = [item.message for item in validator.iter_errors(record)]
            prompt = record.get("prompt", "")
            if any(pattern.search(prompt) for pattern in FORBIDDEN_PROMPT_PATTERNS):
                errors.append("prompt contains a reserved answer/private-evaluation term")
            serialized = json.dumps(record.get("oracle", {}), sort_keys=True).lower()
            if re.search(r"module\s+[a-z_$]", serialized):
                errors.append("public oracle appears to embed RTL source")
            split = record.get("split")
            if project.name in expected_split and split != expected_split[project.name]:
                errors.append(f"task split {split!r} differs from project lock {expected_split[project.name]!r}")
            if split == "frozen_test" and record.get("release_tier") != "private_until_release":
                errors.append("frozen task must be private_until_release")
            if errors:
                failures += 1
                print(f"[FAIL] {path.relative_to(project)}: {'; '.join(errors)}")
    print(f"[TASKS] validated={count} failures={failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
