# Release roadmap and current gate state

This file separates tool-established evidence from human or legal approvals.

## v0.1.0 release candidate (implemented locally)

- Seven JSON Schemas define projects, IP-ETGs, tasks, validation, mutation summaries, expert reviews, and release policy.
- 40/40 projects have schema-valid, deterministically rebuilt IP-ETGs.
- 389 answer-free task candidates validate against `ip-task/v1`.
- Quality distribution is 39 Q2 and 1 Q3; `ready_valid_fifo` kills 10/10 witnessed non-equivalent mutants. Both DMA variants have self-checking APB control-plane oracles, while payload movement remains out of scope.
- 28 projects are `source_released` and 12 are conservatively retained as
  `metadata_only`; the latter remain catalogued without source payloads in the
  public export until file-scope redistribution evidence is independently
  reviewed.
- The release exporter omits source payloads for all 12 source-withheld projects
  and omits 61 frozen task records.
- Project splits are locked at 24 train, 6 dev, 5 public test, and 5 frozen test without shared-upstream crossing.
- Three generated GraphML/HTML examples and a Pages index are available.

## Remaining v0.1.0 publication gates

1. Run mutation campaigns for records intended as Q3 training or benchmark data.
2. Obtain two independent expert reviews for Q4 canonical generation targets.
3. Complete the required blind review of at least 100 samples and report agreement.
4. Publish only the license-gated export tree; do not publish the unrestricted working tree.
5. Create the GitHub release and immutable archive only after the release manifest and checksums are reviewed.

## Paper-data gate

Only tasks that kill non-equivalent mutants become Q3. Canonical generation
targets additionally require two independent expert approvals and become Q4.
The split and frozen commitments are already locked; confirmatory training must
not begin until its selected training records reach Q3 and the release candidate
commit is fixed.
