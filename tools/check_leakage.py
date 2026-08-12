#!/usr/bin/env python3
"""Reject secrets, host paths, and private benchmark content from public assets."""

from __future__ import annotations

import re
from pathlib import Path

from ipgraph_common import ROOT


TEXT_SUFFIXES = {
    ".json", ".jsonl", ".md", ".yml", ".yaml", ".py", ".sh", ".toml",
    ".sv", ".svh", ".v", ".vh", ".txt", ".patch", ".f", ".core",
}
PATTERNS = {
    "api_key": re.compile(r"(?<![A-Za-z0-9_])sk-[A-Za-z0-9]{16,}"),
    "absolute_workspace": re.compile(r"/dataST/users/|/home/[A-Za-z0-9_.-]+/"),
    "private_asset_name": re.compile(r"(?:hidden[_-]?test|private[_-]?reference|frozen[_-]?gold|mutants?)/", re.I),
}


def main() -> int:
    failures = []
    roots = [ROOT]
    ignored_parts = {".git", ".private", "__pycache__", "obj_dir", "work"}
    for base in roots:
        if not base.exists():
            continue
        for path in base.rglob("*"):
            relative = path.relative_to(ROOT)
            if (
                not path.is_file()
                or path.resolve() == Path(__file__).resolve()
                or path.suffix.lower() not in TEXT_SUFFIXES
                or ignored_parts.intersection(relative.parts)
            ):
                continue
            text = path.read_text(encoding="utf-8", errors="replace")
            for label, pattern in PATTERNS.items():
                if pattern.search(text):
                    failures.append((relative.as_posix(), label))
    for path, label in failures:
        print(f"[LEAK] {path}: {label}")
    print(f"[LEAKAGE] failures={len(failures)}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
