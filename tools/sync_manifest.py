#!/usr/bin/env python3
"""Synchronize the legacy root manifest with project directories."""

from __future__ import annotations

import json

import yaml

from ipgraph_common import ROOT, project_directories


def main() -> int:
    path = ROOT / "manifest.json"
    document = json.loads(path.read_text(encoding="utf-8"))
    existing = {row["name"]: row for row in document.get("projects", [])}
    records = []
    for project in project_directories():
        origin = yaml.safe_load((project / "ORIGIN.yml").read_text(encoding="utf-8")) or {}
        record = existing.get(project.name, {})
        record.update(
            {
                "name": project.name,
                "category": project.parent.name,
                "upstream_project": str(origin.get("upstream_project", "")),
                "license_expression": str(origin.get("license_expression", "LicenseRef-Unknown")),
                "license_evidence": str(origin.get("license_evidence", "")),
                "modification_status": str(origin.get("modification_status", "")),
                "public_export_decision": str(origin.get("public_export_decision", "pending_review")),
                "path": project.relative_to(ROOT).as_posix(),
            }
        )
        if revision := origin.get("upstream_revision"):
            record["upstream_revision"] = str(revision)
        records.append(record)
    document["included"] = len(records)
    document["projects"] = sorted(records, key=lambda row: (row["category"], row["name"]))
    path.write_text(json.dumps(document, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[MANIFEST] projects={len(records)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
