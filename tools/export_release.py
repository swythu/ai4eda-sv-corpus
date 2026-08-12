#!/usr/bin/env python3
"""Create a license-gated public release tree without unresolved RTL sources."""

from __future__ import annotations

import argparse
import json
import os
import shutil
from pathlib import Path

from ipgraph_common import ROOT, sha256_file


ROOT_FILES = (
    "README.md", "README_zh-CN.md", "DATASET_CARD.md", "LICENSE_POLICY.md",
    "CONTRIBUTING.md", "CITATION.cff", "NOTICE.md", "VALIDATION.md",
    "manifest.json", "requirements-dev.txt",
)
ROOT_DIRS = ("schemas", "catalog", "benchmarks", "reviews", "tools", "docs", "LICENSES", ".github")
METADATA_PATHS = ("IP_CARD.md", "ORIGIN.yml", "metadata.json", "graph", "tasks")
EXCLUDED_SUFFIXES = {".vcd", ".vvp", ".fst", ".log", ".pyc"}


def _ignore(_directory: str, names: list[str]) -> set[str]:
    return {
        name for name in names
        if name == "__pycache__" or Path(name).suffix.lower() in EXCLUDED_SUFFIXES
    }


def _copy(source: Path, destination: Path) -> None:
    if source.is_dir():
        shutil.copytree(source, destination, ignore=_ignore)
    elif source.exists():
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)


def _remove_private_tasks(project: Path) -> int:
    removed = 0
    task_root = project / "tasks"
    if not task_root.exists():
        return removed
    for path in task_root.glob("*/*.json"):
        try:
            record = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if record.get("release_tier") == "private_until_release":
            path.unlink()
            removed += 1
    for directory in sorted(task_root.glob("*"), reverse=True):
        if directory.is_dir() and not any(directory.iterdir()):
            directory.rmdir()
    return removed


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if output == ROOT or ROOT in output.parents:
        raise SystemExit("output must be outside the working repository")
    if output.exists() and any(output.iterdir()):
        raise SystemExit(f"output directory is not empty: {output}")
    output.mkdir(parents=True, exist_ok=True)

    manifest = json.loads((ROOT / "catalog/release_manifest.json").read_text(encoding="utf-8"))
    for name in ROOT_FILES:
        _copy(ROOT / name, output / name)
    for name in ROOT_DIRS:
        _copy(ROOT / name, output / name)

    exported: list[dict[str, str]] = []
    private_tasks_removed = 0
    for record in manifest["projects"]:
        source = ROOT / record["project_path"]
        destination = output / record["project_path"]
        if record["release_status"] == "source_released":
            _copy(source, destination)
            payload = "source_and_metadata"
        else:
            destination.mkdir(parents=True, exist_ok=True)
            for relative in METADATA_PATHS:
                _copy(source / relative, destination / relative)
            payload = "metadata_only"
        private_tasks_removed += _remove_private_tasks(destination)
        exported.append(
            {
                "project_id": record["project_id"],
                "release_status": record["release_status"],
                "exported_payload": payload,
            }
        )
    (output / "PUBLIC_EXPORT.json").write_text(
        json.dumps(
            {
                "schema_version": "public-export/v1",
                "source_manifest": "catalog/release_manifest.json",
                "projects": exported,
                "private_tasks_removed": private_tasks_removed,
                "note": "pending_review and metadata_only projects contain no RTL, testbench, include, patch, or validation-log payload",
            },
            indent=2,
            sort_keys=True,
        ) + "\n",
        encoding="utf-8",
    )
    forbidden = {"rtl", "include", "tb", "tbench", "assertions", "validation"}
    for record in exported:
        if record["exported_payload"] != "metadata_only":
            continue
        project = next(row for row in manifest["projects"] if row["project_id"] == record["project_id"])
        destination = output / project["project_path"]
        leaked = [path for path in destination.rglob("*") if forbidden.intersection(path.relative_to(destination).parts)]
        if leaked:
            raise SystemExit(f"release policy violation for {record['project_id']}: {leaked[0]}")

    inventory = [
        path for path in output.rglob("*")
        if path.is_file() and path.name != "CHECKSUMS.sha256"
    ]
    (output / "CHECKSUMS.sha256").write_text(
        "\n".join(
            f"{sha256_file(path)}  {path.relative_to(output).as_posix()}"
            for path in sorted(inventory)
        ) + "\n",
        encoding="utf-8",
    )
    # Prevent accidental ambient group/world write permissions in release staging.
    os.chmod(output, 0o755)
    print(f"[EXPORT] projects={len(exported)} output={output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
