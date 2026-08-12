#!/usr/bin/env python3
"""Validate IP-ETG schemas, references, hashes, and minimum graph content."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from jsonschema import Draft202012Validator
from referencing import Registry, Resource

from ipgraph_common import SCHEMAS, graph_digest, project_directories, sha256_file


def _validator(name: str) -> Draft202012Validator:
    schema = json.loads((SCHEMAS / name).read_text(encoding="utf-8"))
    registry = Registry()
    for path in SCHEMAS.glob("*.json"):
        document = json.loads(path.read_text(encoding="utf-8"))
        resource = Resource.from_contents(document)
        registry = registry.with_resource(path.as_uri(), resource)
        if identifier := document.get("$id"):
            registry = registry.with_resource(identifier, resource)
    return Draft202012Validator(schema, registry=registry)


def validate_project(project: Path) -> list[str]:
    errors: list[str] = []
    graph_path = project / "graph" / "ip_etg.json"
    if not graph_path.exists():
        return [f"missing {graph_path}"]
    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    for item in _validator("ip_etg.schema.json").iter_errors(graph):
        errors.append(f"schema {list(item.absolute_path)}: {item.message}")
    if graph.get("graph_sha256") != graph_digest(graph):
        errors.append("graph_sha256 does not match canonical content")
    node_ids = [row["id"] for row in graph.get("nodes", [])]
    edge_ids = [row["id"] for row in graph.get("edges", [])]
    artifact_ids = [row["artifact_id"] for row in graph.get("artifacts", [])]
    task_ids = [row["task_id"] for row in graph.get("tasks", [])]
    for label, values in (("node", node_ids), ("edge", edge_ids), ("artifact", artifact_ids), ("task", task_ids)):
        if len(values) != len(set(values)):
            errors.append(f"duplicate {label} id")
    nodes = set(node_ids)
    artifacts = set(artifact_ids)
    for artifact in graph.get("artifacts", []):
        expected_id = f"sha256:{artifact['sha256']}"
        if artifact["artifact_id"] != expected_id:
            errors.append(f"artifact id/hash mismatch for {artifact['path']}")
        artifact_path = project / artifact["path"]
        if graph.get("release_policy") == "source_released":
            if not artifact_path.is_file():
                errors.append(f"released artifact is missing: {artifact['path']}")
            elif sha256_file(artifact_path) != artifact["sha256"]:
                errors.append(f"artifact content hash mismatch: {artifact['path']}")
    for edge in graph.get("edges", []):
        if edge["source"] not in nodes:
            errors.append(f"edge {edge['id']} has unknown source {edge['source']}")
        if edge["target"] not in nodes:
            errors.append(f"edge {edge['id']} has unknown target {edge['target']}")
    for node in graph.get("nodes", []):
        for ref in [*node["artifact_refs"], *node["evidence_refs"]]:
            if ref not in artifacts:
                errors.append(f"node {node['id']} has unknown artifact {ref}")
    for edge in graph.get("edges", []):
        for ref in edge["evidence_refs"]:
            if ref not in artifacts:
                errors.append(f"edge {edge['id']} has unknown artifact evidence {ref}")
    for task in graph.get("tasks", []):
        for ref in [*task["input_nodes"], *task["target_nodes"]]:
            if ref not in nodes:
                errors.append(f"task {task['task_id']} has unknown node {ref}")
    required_types = {"project", "source_revision", "license", "module", "protocol_contract", "verification_obligation", "tool_run"}
    types = {row["type"] for row in graph.get("nodes", [])}
    if missing := required_types - types:
        errors.append(f"missing required node types: {sorted(missing)}")
    module_count = sum(row["type"] == "module" for row in graph.get("nodes", []))
    minimum_tasks = 10 if module_count > 1 else 6
    if module_count >= 8 or any(token in project.name for token in ("dma", "mac", "processor", "cpu")):
        minimum_tasks = 15
    if len(task_ids) < minimum_tasks:
        errors.append(f"task count {len(task_ids)} is below minimum {minimum_tasks}")
    lock_path = project / "graph" / "graph.lock.json"
    if not lock_path.exists():
        errors.append("missing graph.lock.json")
    else:
        lock = json.loads(lock_path.read_text(encoding="utf-8"))
        if lock.get("graph_sha256") != graph.get("graph_sha256"):
            errors.append("graph lock hash mismatch")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", action="append")
    args = parser.parse_args()
    requested = set(args.project or [])
    failures = 0
    for project in project_directories():
        if requested and project.name not in requested:
            continue
        errors = validate_project(project)
        if errors:
            failures += 1
            print(f"[FAIL] {project.name}")
            for error in errors:
                print(f"  - {error}")
        else:
            print(f"[PASS] {project.name}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
