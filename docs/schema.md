# IP Engineering Task Graph schema

The IP-ETG is a typed, project-level engineering graph. It is not a bag of code
chunks and not a scheduling DAG. `schemas/ip_etg.schema.json` is normative.

The canonical graph contains design entities, intent, verification evidence,
failures, patches, and task records. Every edge carries evidence references.
Files are content-addressed with SHA-256. `graph_sha256` is calculated over the
canonical JSON object with that field omitted.

`graph/source.json` records extraction inputs and diagnostics.
`graph/overrides.json` is the only location for reviewed human corrections.
`graph/ip_etg.json` and `graph/graph.lock.json` are generated outputs.

The current extractor uses pyslang for HDL syntax and hierarchy. Clock/reset and
protocol annotations inferred from names are explicitly marked as candidates;
they are not expert facts until reviewed.

Mutation campaign summaries and anonymized expert decisions are separately
validated by `mutation_summary.schema.json` and `expert_review.schema.json`.
Private mutants, withheld checks, references, and reviewer responses are never
embedded in the public IP-ETG or pre-experiment release tree.
