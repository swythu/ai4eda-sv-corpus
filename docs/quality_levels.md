# Quality levels

| Level | Required evidence | Allowed use |
|---|---|---|
| Q0 | Provenance and files registered | Catalog only |
| Q1 | Compile and elaboration pass | Understanding candidate |
| Q2 | Q1 plus lint and self-checking simulation | General task candidate |
| Q3 | Q2 plus mutation validation | Training and benchmark candidate |
| Q4 | Q3 plus independent two-expert review | Canonical generation target |

Smoke simulation does not establish functional Q2 coverage for the behaviors it
does not exercise. Quality labels describe recorded evidence, not production
readiness, formal verification, or silicon signoff.
