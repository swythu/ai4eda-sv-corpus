#!/usr/bin/env python3
"""Create a deterministic 100-task blind-review assignment without gold data."""

from __future__ import annotations

import json
from hashlib import sha256

from ipgraph_common import ROOT, project_directories, write_json


def main() -> int:
    candidates = []
    for project in project_directories():
        for path in (project / "tasks").glob("*/*.json"):
            task = json.loads(path.read_text(encoding="utf-8"))
            if task["split"] in {"train", "dev"}:
                candidates.append(task)
    candidates.sort(key=lambda task: sha256(("ipgraph-review-v1:" + task["task_id"]).encode()).hexdigest())
    selected = candidates[:100]
    root = ROOT / "reviews/blind_review_v1"
    root.mkdir(parents=True, exist_ok=True)
    assignment = [
        {
            "review_slot": index,
            "task_id": task["task_id"],
            "project_id": task["project_id"],
            "family": task["family"],
            "required_reviewers": 2,
        }
        for index, task in enumerate(selected, start=1)
    ]
    (root / "assignment.jsonl").write_text(
        "".join(json.dumps(row, sort_keys=True) + "\n" for row in assignment), encoding="utf-8"
    )
    write_json(root / "status.json", {
        "schema_version": "ip-review-status/v1",
        "status": "awaiting_two_independent_experts",
        "assigned_tasks": len(assignment),
        "required_reviews": 2 * len(assignment),
        "completed_reviews": 0,
        "responses_location": ".private/reviews/blind_review_v1",
    })
    print(f"[REVIEW] assigned={len(assignment)} required_reviews={2 * len(assignment)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
