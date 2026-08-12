# Contributing

Contributions are welcome when they preserve provenance, validation, and
release boundaries.

An IP contribution must include:

1. a fixed upstream revision and complete license evidence;
2. `ORIGIN.yml`, `metadata.json`, RTL, and a reproducible run script;
3. self-checking simulation and lint evidence;
4. a generated IP-ETG and any human corrections in `graph/overrides.json`;
5. at least six public task definitions;
6. no private answers, secrets, host paths, model weights, or generated waves.

Do not edit `graph/ip_etg.json` directly. Edit source metadata or
`graph/overrides.json`, then rebuild.

```bash
python3 -m pip install -r requirements-dev.txt
python3 tools/build_graphs.py
python3 tools/derive_tasks.py
python3 tools/build_graphs.py
python3 tools/run_ipgraph_checks.py
python3 tools/run_all.py
```

Q3 and Q4 labels require mutation and expert-review evidence; they cannot be
assigned based on code appearance or model judgment.
