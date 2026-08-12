# Blind expert review workflow

The public assignment in `blind_review_v1/assignment.jsonl` selects 100
train/dev task candidates deterministically. Each task needs reviews from two
different experts. Gold artifacts, hidden tests, mutants, and reviewer identity
must not be added to this directory.

For each assigned task, each reviewer creates one private JSON file under:

```text
.private/reviews/blind_review_v1/
```

Use a non-identifying reviewer code and the format defined by
`schemas/expert_review.schema.json`, for example:

```json
{
  "schema_version": "ip-expert-review/v1",
  "review_id": "reviewer-a-task-0001",
  "task_id": "ipgraph:project:family:0000",
  "reviewer_id": "reviewer-a",
  "blind": true,
  "decision": "accept",
  "ratings": {
    "correctness": 5,
    "engineering_relevance": 5,
    "oracle_quality": 4,
    "style_quality": 5
  },
  "timestamp": "2026-08-12T00:00:00Z",
  "comment": "Concise evidence-based review note."
}
```

Validate progress without exposing the private responses:

```bash
python3 tools/validate_expert_reviews.py
```

After all 100 tasks have two distinct valid reviewers, enforce completion with:

```bash
python3 tools/validate_expert_reviews.py --require-complete
python3 tools/report_release_gates.py --require-final
```

Decision agreement is reported as an aggregate. A disagreement is not silently
converted into acceptance; it requires adjudication before a task can become a
Q4 canonical generation target.
