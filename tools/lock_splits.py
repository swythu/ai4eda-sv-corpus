#!/usr/bin/env python3
"""Validate and hash-lock project-level benchmark splits."""

from __future__ import annotations

import json
from hashlib import sha256
from pathlib import Path
from urllib.parse import urlsplit

from ipgraph_common import ROOT, project_directories, write_json


ASSIGNMENT = ROOT / "benchmarks/ipgraph_v1/split_assignment.json"
LOCK = ROOT / "benchmarks/ipgraph_v1/splits.lock.json"
SPLITS = ("train", "dev", "public_test", "frozen_test")


def _upstream_group(project: Path) -> str:
    origin = (project / "ORIGIN.yml").read_text(encoding="utf-8")
    # Avoid adding a YAML dependency to this intentional release-boundary tool.
    row = next((line for line in origin.splitlines() if line.startswith("upstream_project:")), "")
    value = row.split(":", 1)[1].strip().strip('"\'') if ":" in row else ""
    if value == "repository-authored":
        return f"repository-authored:{project.name}"
    if value.startswith("http"):
        parsed = urlsplit(value)
        path = parsed.path.rstrip("/")
        return f"{parsed.netloc.lower()}{path}"
    return value or f"unresolved:{project.name}"


def _digest(value: object) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":")).encode()
    return sha256(payload).hexdigest()


def main() -> int:
    assignment = json.loads(ASSIGNMENT.read_text(encoding="utf-8"))
    projects = {path.name: path for path in project_directories()}
    membership: dict[str, str] = {}
    groups: dict[str, set[str]] = {}
    locked: dict[str, list[dict[str, str]]] = {}
    for split in SPLITS:
        rows = []
        for project_id in assignment[split]:
            if project_id not in projects:
                raise SystemExit(f"unknown project in {split}: {project_id}")
            if project_id in membership:
                raise SystemExit(f"project assigned twice: {project_id}")
            membership[project_id] = split
            project = projects[project_id]
            graph = json.loads((project / "graph/ip_etg.json").read_text(encoding="utf-8"))
            group = _upstream_group(project)
            groups.setdefault(group, set()).add(split)
            rows.append({
                "project_id": project_id,
                "project_revision": graph["project_revision"],
                "upstream_group": group,
            })
        locked[split] = sorted(rows, key=lambda row: row["project_id"])
    missing = sorted(set(projects) - set(membership))
    if missing:
        raise SystemExit(f"unassigned projects: {', '.join(missing)}")
    crossing = {group: sorted(splits) for group, splits in groups.items() if len(splits) > 1}
    if crossing:
        raise SystemExit(f"upstream groups cross splits: {crossing}")
    commitment_payload = {split: locked[split] for split in SPLITS}
    result = {
        "schema_version": "ipgraph-splits-lock/v1",
        "release_target": "v0.1.0",
        "status": "project_splits_locked",
        "assignment_sha256": _digest(assignment),
        "split_commitment_sha256": _digest(commitment_payload),
        "frozen_project_commitment_sha256": _digest(locked["frozen_test"]),
        "counts": {split: len(locked[split]) for split in SPLITS},
        **locked,
        "prohibitions": [
            "do not train on dev, public_test, or frozen_test projects",
            "do not publish frozen prompts, gold artifacts, tests, or mutants before confirmatory evaluation",
        ],
    }
    write_json(LOCK, result)
    print(f"[SPLITS] counts={result['counts']} commitment={result['split_commitment_sha256'][:16]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
