#!/usr/bin/env python3
"""Validate private blind-review responses and report completion/agreement."""

from __future__ import annotations

import argparse
import json
from collections import defaultdict

from jsonschema import Draft202012Validator

from ipgraph_common import ROOT, SCHEMAS, write_json


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-complete", action="store_true")
    args = parser.parse_args()
    assignment_path = ROOT / "reviews/blind_review_v1/assignment.jsonl"
    assignments = [json.loads(line) for line in assignment_path.read_text(encoding="utf-8").splitlines() if line]
    expected = {row["task_id"] for row in assignments}
    schema = json.loads((SCHEMAS / "expert_review.schema.json").read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema)
    response_root = ROOT / ".private/reviews/blind_review_v1"
    reviews: dict[str, list[dict]] = defaultdict(list)
    failures = 0
    for path in sorted(response_root.glob("*.json")) if response_root.exists() else []:
        record = json.loads(path.read_text(encoding="utf-8"))
        errors = [error.message for error in validator.iter_errors(record)]
        if record.get("task_id") not in expected:
            errors.append("task is not in the blind-review assignment")
        if errors:
            failures += 1
            print(f"[FAIL] {path.name}: {'; '.join(errors)}")
        else:
            reviews[record["task_id"]].append(record)
    complete = 0
    agreements = 0
    valid_review_records = 0
    for task_id in expected:
        rows = reviews[task_id]
        valid_review_records += len(rows)
        reviewers = {row["reviewer_id"] for row in rows}
        if len(reviewers) >= 2:
            complete += 1
            first_by_reviewer = {}
            for row in rows:
                first_by_reviewer.setdefault(row["reviewer_id"], row)
            decisions = [row["decision"] for row in list(first_by_reviewer.values())[:2]]
            agreements += decisions[0] == decisions[1]
    agreement = agreements / complete if complete else 0.0
    write_json(ROOT / "reviews/blind_review_v1/status.json", {
        "schema_version": "ip-review-status/v1",
        "status": "complete" if complete == len(expected) and failures == 0 else "awaiting_two_independent_experts",
        "assigned_tasks": len(expected),
        "required_reviews": 2 * len(expected),
        "valid_review_records": valid_review_records,
        "completed_tasks": complete,
        "decision_agreement": agreement,
        "validation_failures": failures,
        "responses_location": ".private/reviews/blind_review_v1",
    })
    print(f"[EXPERT-REVIEW] tasks_complete={complete}/100 agreement={agreement:.3f} failures={failures}")
    return 1 if failures or (args.require_complete and complete < 100) else 0


if __name__ == "__main__":
    raise SystemExit(main())
