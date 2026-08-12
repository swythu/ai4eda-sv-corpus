#!/usr/bin/env python3
"""Exercise the public exporter and verify its license boundary and checksums."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

from ipgraph_common import ROOT, sha256_file


FORBIDDEN_METADATA_DIRS = {"rtl", "include", "tb", "tbench", "assertions", "validation"}


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="ai4eda-release-") as directory:
        output = Path(directory)
        subprocess.run(
            [sys.executable, str(ROOT / "tools/export_release.py"), "--output", str(output)],
            cwd=ROOT,
            check=True,
        )
        export = json.loads((output / "PUBLIC_EXPORT.json").read_text(encoding="utf-8"))
        release_manifest = json.loads((output / "catalog/release_manifest.json").read_text(encoding="utf-8"))
        by_id = {row["project_id"]: row for row in release_manifest["projects"]}
        frozen_commitment = json.loads((output / "benchmarks/ipgraph_v1/frozen_test/commitment.json").read_text(encoding="utf-8"))
        if export.get("private_tasks_removed") != frozen_commitment["task_count"]:
            raise SystemExit(
                f"private task removal mismatch: {export.get('private_tasks_removed')} != {frozen_commitment['task_count']}"
            )
        for row in export["projects"]:
            project = output / by_id[row["project_id"]]["project_path"]
            if row["exported_payload"] == "metadata_only":
                forbidden = [name for name in FORBIDDEN_METADATA_DIRS if (project / name).exists()]
                if forbidden:
                    raise SystemExit(f"blocked payload exported for {row['project_id']}: {forbidden}")
            elif not (project / "rtl").exists():
                raise SystemExit(f"released source payload lacks rtl/: {row['project_id']}")
        for task_path in output.glob("projects/*/*/tasks/*/*.json"):
            task = json.loads(task_path.read_text(encoding="utf-8"))
            if task.get("release_tier") == "private_until_release" or task.get("split") == "frozen_test":
                raise SystemExit(f"private frozen task leaked into release: {task_path.relative_to(output)}")
        checksum_lines = (output / "CHECKSUMS.sha256").read_text(encoding="utf-8").splitlines()
        for line in checksum_lines:
            digest, relative = line.split("  ", 1)
            path = output / relative
            if not path.is_file() or sha256_file(path) != digest:
                raise SystemExit(f"bad release checksum: {relative}")
        print(f"[EXPORT-VALID] projects={len(export['projects'])} files={len(checksum_lines)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
