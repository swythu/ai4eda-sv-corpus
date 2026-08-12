#!/usr/bin/env python3
"""Run the deterministic IP-ETG alpha acceptance checks."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    scripts = (
        "sync_manifest.py",
        "build_graphs.py",
        "lock_splits.py",
        "derive_tasks.py",
        "build_graphs.py",
        "build_catalog.py",
        "audit_licenses.py",
        "validate_graphs.py",
        "validate_tasks.py",
        "build_benchmark.py",
        "validate_mutations.py",
        "prepare_expert_review.py",
        "validate_expert_reviews.py",
        "check_leakage.py",
        "check_reproducibility.py",
        "render_graphs.py",
        "build_ip_cards.py",
        "update_readme_status.py",
        "report_release_gates.py",
        "validate_release_export.py",
        "update_checksums.py",
    )
    for script in scripts:
        print(f"[CHECK] {script}", flush=True)
        subprocess.run([sys.executable, str(ROOT / "tools" / script)], cwd=ROOT, check=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
