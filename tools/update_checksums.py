#!/usr/bin/env python3
"""Regenerate the repository content checksum inventory deterministically."""

from __future__ import annotations

from ipgraph_common import ROOT, sha256_file


IGNORED_PARTS = {".git", ".private", "__pycache__", ".pytest_cache", "obj_dir", "work"}
IGNORED_SUFFIXES = {".pyc", ".log", ".vcd", ".vvp", ".fst", ".wlf"}
IGNORED_FILES = {"CHECKSUMS.sha256", "validation_summary.json"}


def main() -> int:
    paths = [
        path for path in ROOT.rglob("*")
        if path.is_file()
        and path.name not in IGNORED_FILES
        and path.suffix.lower() not in IGNORED_SUFFIXES
        and not (set(path.relative_to(ROOT).parts) & IGNORED_PARTS)
    ]
    lines = [
        f"{sha256_file(path)}  {path.relative_to(ROOT).as_posix()}"
        for path in sorted(paths)
    ]
    (ROOT / "CHECKSUMS.sha256").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[CHECKSUMS] files={len(lines)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
