#!/usr/bin/env python3
"""Build the public project catalog and release manifests."""

from __future__ import annotations

import json
from collections import Counter, defaultdict

import yaml

from ipgraph_common import ROOT, project_directories, write_json


def main() -> int:
    records = []
    licenses = []
    capabilities: dict[str, list[str]] = defaultdict(list)
    for project in project_directories():
        graph = json.loads((project / "graph" / "ip_etg.json").read_text(encoding="utf-8"))
        metadata = json.loads((project / "metadata.json").read_text(encoding="utf-8"))
        origin = yaml.safe_load((project / "ORIGIN.yml").read_text(encoding="utf-8")) or {}
        project_node = next(row for row in graph["nodes"] if row["type"] == "project")
        protocol_nodes = [row["label"] for row in graph["nodes"] if row["type"] == "protocol_contract"]
        record = {
            "schema_version": "ip-project/v1",
            "project_id": graph["project_id"],
            "category": project.parent.name,
            "upstream": str(origin["upstream_project"]),
            "revision": graph["project_revision"],
            "license_expression": str(metadata.get("license_expression") or origin.get("license_expression") or "LicenseRef-Unknown"),
            "release_status": graph["release_policy"],
            "project_path": project.relative_to(ROOT).as_posix(),
            "graph_path": (project / "graph" / "ip_etg.json").relative_to(ROOT).as_posix(),
            "quality_level": graph["validation"]["quality_level"],
        }
        records.append(record)
        licenses.append({"project_id": graph["project_id"], "license_expression": record["license_expression"], "release_status": graph["release_policy"]})
        capabilities[project.parent.name].append(graph["project_id"])
        for protocol in protocol_nodes:
            capabilities[f"protocol:{protocol}"].append(graph["project_id"])
    catalog = ROOT / "catalog"
    catalog.mkdir(exist_ok=True)
    (catalog / "projects.jsonl").write_text("".join(json.dumps(row, sort_keys=True) + "\n" for row in sorted(records, key=lambda row: row["project_id"])), encoding="utf-8")
    write_json(catalog / "capabilities.json", {key: sorted(value) for key, value in sorted(capabilities.items())})
    write_json(catalog / "license_matrix.json", {"schema_version": "license-matrix/v1", "projects": sorted(licenses, key=lambda row: row["project_id"])})
    write_json(catalog / "release_manifest.json", {
        "schema_version": "release-manifest/v1",
        "release": "v0.1.0-rc1",
        "project_count": len(records),
        "status_counts": dict(sorted(Counter(row["release_status"] for row in records).items())),
        "projects": sorted(records, key=lambda row: row["project_id"]),
        "warning": "release candidate: human review remains pending; metadata_only and pending_review entries are not asserted to have resolved redistribution rights",
    })
    print(f"[CATALOG] projects={len(records)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
