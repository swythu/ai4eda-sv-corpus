#!/usr/bin/env python3
"""Build public split indices and commitments without releasing frozen tasks."""

from __future__ import annotations

import json
from collections import Counter
from hashlib import sha256
from pathlib import Path

from ipgraph_common import ROOT, project_directories, sha256_file, write_json


BENCHMARK = ROOT / "benchmarks/ipgraph_v1"
PUBLIC_SPLITS = ("train", "dev", "public_test")


def _digest_rows(rows: list[dict]) -> str:
    payload = json.dumps(rows, sort_keys=True, separators=(",", ":")).encode()
    return sha256(payload).hexdigest()


def main() -> int:
    lock = json.loads((BENCHMARK / "splits.lock.json").read_text(encoding="utf-8"))
    by_split: dict[str, list[dict]] = {split: [] for split in (*PUBLIC_SPLITS, "frozen_test")}
    for project in project_directories():
        for path in sorted((project / "tasks").glob("*/*.json")):
            task = json.loads(path.read_text(encoding="utf-8"))
            by_split[task["split"]].append({
                "task_id": task["task_id"],
                "project_id": task["project_id"],
                "family": task["family"],
                "difficulty": task["difficulty"],
                "task_path": path.relative_to(ROOT).as_posix(),
                "task_sha256": sha256_file(path),
            })
    for split in PUBLIC_SPLITS:
        rows = sorted(by_split[split], key=lambda row: row["task_id"])
        target = BENCHMARK / split / "index.jsonl"
        target.write_text("".join(json.dumps(row, sort_keys=True) + "\n" for row in rows), encoding="utf-8")
    frozen_rows = sorted(by_split["frozen_test"], key=lambda row: row["task_id"])
    frozen_public = {
        "schema_version": "ipgraph-frozen-commitment/v1",
        "status": "withheld_until_post_evaluation",
        "project_count": lock["counts"]["frozen_test"],
        "task_count": len(frozen_rows),
        "family_counts": dict(sorted(Counter(row["family"] for row in frozen_rows).items())),
        "task_set_sha256": _digest_rows(frozen_rows),
        "project_commitment_sha256": lock["frozen_project_commitment_sha256"],
    }
    write_json(BENCHMARK / "frozen_test/commitment.json", frozen_public)
    manifest = {
        "schema_version": "ipgraph-benchmark/v1",
        "release_target": "v0.1.0",
        "status": "release_candidate_human_review_pending",
        "project_count": sum(lock["counts"].values()),
        "task_count": sum(len(rows) for rows in by_split.values()),
        "public_task_count": sum(len(by_split[split]) for split in PUBLIC_SPLITS),
        "withheld_frozen_task_count": len(frozen_rows),
        "split_counts": lock["counts"],
        "split_commitment_sha256": lock["split_commitment_sha256"],
        "frozen_task_set_sha256": frozen_public["task_set_sha256"],
        "splits_locked": True,
        "training_approval": "not_granted_q3_and_expert_review_pending",
        "warning": "Task candidates are Q2-derived and answer-free; they are not Q3/Q4 paper training records.",
    }
    write_json(BENCHMARK / "manifest.json", manifest)
    print(f"[BENCHMARK] projects={manifest['project_count']} tasks={manifest['task_count']} frozen={len(frozen_rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
