#!/usr/bin/env python3
"""Write an evidence-based release-gate report without fabricating approvals."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict

from jsonschema import Draft202012Validator

from ipgraph_common import ROOT, SCHEMAS, project_directories, task_files, write_json


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-final", action="store_true")
    args = parser.parse_args()
    graphs = [json.loads((p / "graph/ip_etg.json").read_text(encoding="utf-8")) for p in project_directories()]
    releases = Counter(graph["release_policy"] for graph in graphs)
    qualities = Counter(graph["validation"]["quality_level"] for graph in graphs)
    mutation_pass = 0
    for project in project_directories():
        mutation_path = project / "validation/mutation_summary.json"
        if mutation_path.exists() and json.loads(mutation_path.read_text(encoding="utf-8")).get("status") == "pass":
            mutation_pass += 1
    assignments = {
        row["task_id"]
        for row in (
            json.loads(line)
            for line in (ROOT / "reviews/blind_review_v1/assignment.jsonl").read_text(encoding="utf-8").splitlines()
            if line
        )
    }
    review_schema = json.loads((SCHEMAS / "expert_review.schema.json").read_text(encoding="utf-8"))
    review_validator = Draft202012Validator(review_schema)
    response_root = ROOT / ".private/reviews/blind_review_v1"
    reviews_by_task: dict[str, set[str]] = defaultdict(set)
    valid_review_records = 0
    for path in sorted(response_root.glob("*.json")) if response_root.exists() else []:
        record = json.loads(path.read_text(encoding="utf-8"))
        if record.get("task_id") not in assignments or list(review_validator.iter_errors(record)):
            continue
        valid_review_records += 1
        reviews_by_task[record["task_id"]].add(record["reviewer_id"])
    completed_review_tasks = sum(len(reviewers) >= 2 for reviewers in reviews_by_task.values())

    train_tasks = []
    for project in project_directories():
        for path in task_files(project):
            task = json.loads(path.read_text(encoding="utf-8"))
            if task["split"] == "train":
                train_tasks.append(task)
    q3_train_tasks = sum(task["quality"]["mutation_validated"] for task in train_tasks)
    benchmark = json.loads((ROOT / "benchmarks/ipgraph_v1/manifest.json").read_text(encoding="utf-8"))
    rank = {"Q0": 0, "Q1": 1, "Q2": 2, "Q3": 3, "Q4": 4}
    automated_pass = (
        len(graphs) == 40
        and all(rank[graph["validation"]["quality_level"]] >= 2 for graph in graphs)
        and benchmark["splits_locked"]
    )
    human_pass = completed_review_tasks == len(assignments)
    license_gate = releases.get("pending_review", 0) == 0
    paper_training_gate = bool(train_tasks) and q3_train_tasks == len(train_tasks) and human_pass
    final_pass = automated_pass and human_pass and license_gate
    report = {
        "schema_version": "ipgraph-release-gates/v1",
        "release_target": "v0.1.0",
        "overall_status": "ready" if final_pass else "blocked",
        "automated_engineering_gate": {
            "status": "pass" if automated_pass else "fail",
            "projects": len(graphs),
            "quality_counts": dict(qualities),
            "task_candidates": benchmark["task_count"],
            "splits_locked": benchmark["splits_locked"],
        },
        "license_gate": {
            "status": "pass" if license_gate else "blocked",
            "release_status_counts": dict(releases),
            "note": "metadata_only entries may remain catalogued, but pending_review source cannot enter a final public source release.",
        },
        "mutation_gate": {
            "status": "pass" if mutation_pass else "pending",
            "projects_with_summary": mutation_pass,
            "q3_train_tasks": q3_train_tasks,
            "train_tasks": len(train_tasks),
            "note": "Only task records backed by a passing campaign may be promoted to Q3.",
        },
        "expert_review_gate": {
            "status": "pass" if human_pass else "pending",
            "valid_review_records": valid_review_records,
            "required_review_records": 200,
            "tasks_with_two_independent_reviewers": completed_review_tasks,
            "required_tasks": len(assignments),
        },
        "paper_training_approved": paper_training_gate,
    }
    write_json(ROOT / "catalog/gate_status.json", report)
    print(
        f"[GATES] automated={'pass' if automated_pass else 'fail'} "
        f"license={'pass' if license_gate else 'blocked'} mutation={mutation_pass} "
        f"reviewed_tasks={completed_review_tasks}/{len(assignments)} "
        f"q3_train_tasks={q3_train_tasks}/{len(train_tasks)}"
    )
    return 1 if args.require_final and not final_pass else 0


if __name__ == "__main__":
    raise SystemExit(main())
