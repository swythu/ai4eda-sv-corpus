#!/usr/bin/env python3
"""Shared deterministic helpers for the public IP-ETG tooling."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
PROJECTS = ROOT / "projects"
SCHEMAS = ROOT / "schemas"
RELEASE_STATES = {
    "source_released",
    "metadata_only",
    "pending_review",
    "private_until_release",
}
AMBIGUOUS_LICENSES = {
    # The OpenCores project pages describe these files as permissive, but the
    # repository does not yet carry file-scope, independently reviewed
    # redistribution evidence.  Keep their graphs and metadata public while
    # conservatively withholding source payloads from release exports.
    "LicenseRef-OpenCores-Permissive",
    "LicenseRef-Unknown",
    "LicenseRef-LGPL-Unspecified-Version",
}


def canonical_bytes(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode()


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def graph_digest(graph: dict[str, Any]) -> str:
    payload = {key: value for key, value in graph.items() if key != "graph_sha256"}
    return sha256_bytes(canonical_bytes(payload))


def load_manifest() -> dict[str, Any]:
    return json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))


def project_directories() -> list[Path]:
    return sorted(path.parent for path in PROJECTS.glob("*/*/metadata.json"))


def release_status(license_expression: str) -> str:
    if license_expression in AMBIGUOUS_LICENSES:
        return "metadata_only"
    if license_expression.startswith("LicenseRef-"):
        return "pending_review"
    return "source_released"


def media_type(path: Path) -> str:
    return {
        ".sv": "text/x-systemverilog",
        ".svh": "text/x-systemverilog",
        ".v": "text/x-verilog",
        ".vh": "text/x-verilog",
        ".json": "application/json",
        ".yml": "application/yaml",
        ".yaml": "application/yaml",
        ".md": "text/markdown",
        ".patch": "text/x-diff",
        ".log": "text/plain",
    }.get(path.suffix.lower(), "application/octet-stream")


def task_files(project: Path) -> list[Path]:
    return sorted((project / "tasks").glob("*/*.json"))
