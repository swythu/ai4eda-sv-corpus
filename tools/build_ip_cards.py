#!/usr/bin/env python3
"""Generate concise per-project IP cards from canonical graph facts."""

from __future__ import annotations

import json

from ipgraph_common import project_directories


def main() -> int:
    for project in project_directories():
        graph = json.loads((project / "graph" / "ip_etg.json").read_text())
        modules = [row["label"] for row in graph["nodes"] if row["type"] == "module"]
        clocks = [row["label"] for row in graph["nodes"] if row["type"] == "clock_domain"]
        resets = [row["label"] for row in graph["nodes"] if row["type"] == "reset_domain"]
        protocols = [row["label"] for row in graph["nodes"] if row["type"] == "protocol_contract"]
        text = f"""# {graph['project_id']} IP Card

Generated from the canonical IP-ETG. Review `ORIGIN.yml` and retained source
headers before reuse.

| Field | Value |
|---|---|
| Category | `{project.parent.name}` |
| Release status | `{graph['release_policy']}` |
| Quality level | `{graph['validation']['quality_level']}` |
| Modules | {len(modules)} |
| Instances | {sum(row['type'] == 'instance' for row in graph['nodes'])} |
| Task candidates | {len(graph['tasks'])} |
| Protocol candidate | {', '.join(protocols) or 'unclassified'} |
| Clock candidates | {', '.join(clocks) or 'none extracted'} |
| Reset candidates | {', '.join(resets) or 'none extracted'} |
| Graph SHA-256 | `{graph['graph_sha256']}` |

## Modules

{chr(10).join(f'- `{name}`' for name in modules)}

## Evidence boundary

This card summarizes open-source compile/lint/simulation evidence. It does not
claim formal equivalence, PPA signoff, CDC signoff, or production readiness.
Automatically inferred semantic annotations remain review candidates.
"""
        (project / "IP_CARD.md").write_text(text, encoding="utf-8")
        print(f"[CARD] {project.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
