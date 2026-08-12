# AI4EDA SystemVerilog IP and IP-ETG Dataset Card

## Summary

This repository is a provenance-tracked, quality-gated collection of reusable
SystemVerilog IP projects and project-level IP Engineering Task Graphs
(IP-ETGs). The graph connects design hierarchy, interfaces, clock/reset
domains, verification obligations, tool evidence, and public task definitions.

The local `v0.1.0` release candidate contains 40 projects, 40 schema-valid and
reproducible IP-ETGs, and 389 answer-free task candidates. All 40 projects are
Q2 or higher. One train project has a passing 10/10 mutation campaign and is
Q3. The 24/6/5/5 project-level train/dev/public/frozen assignment and frozen
task set are hash-committed. This is not yet the paper training release because
broader mutation validation and the required independent expert review are pending.

## Intended uses

- Project-level RTL understanding and hierarchy recovery.
- IP retrieval, reuse, adaptation, and integration research.
- Fault localization and regression-preserving RTL repair.
- Testbench and assertion generation.
- Tool-grounded RTL agent training and evaluation.

## Quality levels

- **Q0**: provenance and files registered.
- **Q1**: compilation and elaboration pass.
- **Q2**: lint and self-checking simulation pass in addition to Q1.
- **Q3**: mutation validation in addition to Q2.
- **Q4**: two-expert review in addition to Q3.

Task candidates are not automatically training-approved. Their `mutation_validated`
and `expert_reviewed` fields remain false until evidence exists.

## Limitations

- Open-source simulation is not industrial signoff or formal equivalence.
- DMA control-plane tests do not establish payload movement or full functional proof.
- Automatically inferred clock, reset, and protocol annotations are candidates
  until reviewed through `graph/overrides.json`.
- Projects with unresolved redistribution evidence remain catalogued but are
  not asserted to be license-clean open-source training artifacts.
- No public task candidate contains released gold answers; frozen tasks are withheld.

## Privacy and contamination

No model weights, API keys, IEEE standard text, internal RTL, private references,
hidden tests, or mutants belong in pre-experiment public artifacts. The locked
split must remain unchanged throughout confirmatory model training and evaluation.

## Licensing

Repository-authored schema, metadata, and tools are Apache-2.0. Each third-party
IP retains its upstream license. See [LICENSE_POLICY.md](LICENSE_POLICY.md),
[NOTICE.md](NOTICE.md), and per-project `ORIGIN.yml` files.
