#!/usr/bin/env python3
"""Rebuild graphs twice and require identical canonical graph hashes."""

from __future__ import annotations

import json
import subprocess
import sys

from ipgraph_common import ROOT, project_directories


def hashes() -> dict[str, str]:
    return {
        project.name: json.loads((project / "graph" / "ip_etg.json").read_text())["graph_sha256"]
        for project in project_directories()
    }


def main() -> int:
    command = [sys.executable, str(ROOT / "tools" / "build_graphs.py")]
    subprocess.run(command, cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    first = hashes()
    subprocess.run(command, cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    second = hashes()
    if first != second:
        for project in sorted(first.keys() | second.keys()):
            if first.get(project) != second.get(project):
                print(f"[NONDETERMINISTIC] {project}: {first.get(project)} != {second.get(project)}")
        return 1
    print(f"[REPRODUCIBLE] projects={len(first)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
