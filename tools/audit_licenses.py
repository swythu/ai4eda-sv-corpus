#!/usr/bin/env python3
"""Audit declared license evidence and flag unresolved redistribution risk."""

from __future__ import annotations

import json

import yaml

from ipgraph_common import ROOT, project_directories, write_json


def main() -> int:
    findings = []
    for project in project_directories():
        graph = json.loads((project / "graph" / "ip_etg.json").read_text(encoding="utf-8"))
        metadata = json.loads((project / "metadata.json").read_text(encoding="utf-8"))
        origin = yaml.safe_load((project / "ORIGIN.yml").read_text(encoding="utf-8")) or {}
        license_expression = str(metadata.get("license_expression") or origin.get("license_expression") or "LicenseRef-Unknown")
        status = graph["release_policy"]
        origin_decision = str(origin.get("public_export_decision", "unspecified"))
        source_present = any((project / name).exists() and any((project / name).rglob("*")) for name in ("rtl", "include"))
        severity = "ok"
        messages = []
        if status != "source_released":
            severity = "warning"
            messages.append("redistribution evidence is not fully resolved")
        if source_present and status in {"metadata_only", "pending_review"}:
            severity = "warning"
            messages.append("source is present in the working repository and must be excluded from a license-clean release artifact unless rights are resolved")
        if origin_decision == "included" and status != "source_released":
            severity = "warning"
            messages.append("legacy ORIGIN.yml says included; release_manifest status takes precedence")
        findings.append({"project_id": project.name, "license_expression": license_expression, "release_status": status, "legacy_origin_decision": origin_decision, "source_present": source_present, "severity": severity, "messages": messages})
    summary = {
        "schema_version": "license-audit/v1",
        "policy": "warnings identify release blockers; a disclaimer does not create redistribution rights",
        "findings": findings,
        "release_blockers": [row["project_id"] for row in findings if row["severity"] != "ok"],
    }
    write_json(ROOT / "catalog" / "license_audit.json", summary)
    print(f"[LICENSE] projects={len(findings)} release_blockers={len(summary['release_blockers'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
