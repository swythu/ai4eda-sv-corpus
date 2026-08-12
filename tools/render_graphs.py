#!/usr/bin/env python3
"""Export selected canonical IP-ETGs to GraphML and standalone HTML."""

from __future__ import annotations

import argparse
import html
import json
import xml.etree.ElementTree as ET
from pathlib import Path

from ipgraph_common import ROOT, project_directories


DEFAULT_PROJECTS = ("scalable_arbiter", "i2c", "dma_axi32")
COLORS = {
    "project": "#0f766e", "module": "#2563eb", "instance": "#7c3aed",
    "port": "#64748b", "parameter": "#64748b", "clock_domain": "#d97706",
    "reset_domain": "#dc2626", "protocol_contract": "#0891b2",
    "verification_obligation": "#16a34a", "testbench": "#16a34a",
    "tool_run": "#16a34a", "understand_task": "#9333ea", "reuse_task": "#9333ea",
    "repair_task": "#9333ea", "verification_task": "#9333ea",
}


def graphml(graph: dict, output: Path) -> None:
    ns = "http://graphml.graphdrawing.org/xmlns"
    ET.register_namespace("", ns)
    root = ET.Element(f"{{{ns}}}graphml")
    for key_id, name in (("type", "type"), ("label", "label")):
        ET.SubElement(root, f"{{{ns}}}key", id=key_id, **{"for": "node", "attr.name": name, "attr.type": "string"})
    body = ET.SubElement(root, f"{{{ns}}}graph", id=graph["graph_id"], edgedefault="directed")
    for node in graph["nodes"]:
        item = ET.SubElement(body, f"{{{ns}}}node", id=node["id"])
        ET.SubElement(item, f"{{{ns}}}data", key="type").text = node["type"]
        ET.SubElement(item, f"{{{ns}}}data", key="label").text = node["label"]
    for edge in graph["edges"]:
        ET.SubElement(body, f"{{{ns}}}edge", id=edge["id"], source=edge["source"], target=edge["target"])
    output.parent.mkdir(parents=True, exist_ok=True)
    ET.indent(root)
    ET.ElementTree(root).write(output, encoding="utf-8", xml_declaration=True)


def standalone_html(graph: dict, output: Path) -> None:
    counts: dict[str, int] = {}
    for node in graph["nodes"]:
        counts[node["type"]] = counts.get(node["type"], 0) + 1
    node_rows = "".join(
        f"<tr><td><span class='dot' style='background:{COLORS.get(node['type'], '#334155')}'></span>{html.escape(node['type'])}</td><td>{html.escape(node['label'])}</td><td><code>{html.escape(node['id'])}</code></td></tr>"
        for node in graph["nodes"]
    )
    summary = "".join(f"<li><b>{html.escape(kind)}</b>: {count}</li>" for kind, count in sorted(counts.items()))
    document = f"""<!doctype html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>{html.escape(graph['project_id'])} IP-ETG</title><style>body{{font:15px system-ui;margin:2rem;color:#172033}}header{{max-width:80rem}}code{{font-size:12px}}table{{border-collapse:collapse;width:100%}}th,td{{padding:.5rem;border-bottom:1px solid #ddd;text-align:left}}.dot{{display:inline-block;width:.7rem;height:.7rem;border-radius:50%;margin-right:.4rem}}ul{{columns:3}}</style></head><body><header><h1>{html.escape(graph['project_id'])} IP Engineering Task Graph</h1><p>Canonical hash: <code>{graph['graph_sha256']}</code>. This is a generated view; <code>ip_etg.json</code> is the source of truth.</p><ul>{summary}</ul></header><table><thead><tr><th>Type</th><th>Label</th><th>ID</th></tr></thead><tbody>{node_rows}</tbody></table></body></html>"""
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(document, encoding="utf-8")


def index_html(projects: list[dict], output: Path) -> None:
    links = "".join(
        f"<li><a href='{html.escape(graph['project_id'])}.html'>{html.escape(graph['project_id'])}</a> "
        f"<code>{html.escape(graph['graph_sha256'][:16])}</code></li>"
        for graph in sorted(projects, key=lambda item: item["project_id"])
    )
    document = f"""<!doctype html><html lang='en'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>AI4EDA IP-ETG previews</title><style>body{{font:16px system-ui;margin:2rem;max-width:60rem;color:#172033}}li{{margin:.7rem 0}}code{{font-size:12px}}</style></head><body><h1>AI4EDA IP Engineering Task Graphs</h1><p>Generated previews for three alpha examples. Canonical JSON remains under each project's <code>graph/</code> directory.</p><ul>{links}</ul></body></html>"""
    output.write_text(document, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", action="append")
    args = parser.parse_args()
    selected = set(args.project or DEFAULT_PROJECTS)
    generated = ROOT / "docs" / "generated"
    rendered: list[dict] = []
    for project in project_directories():
        if project.name not in selected:
            continue
        graph = json.loads((project / "graph" / "ip_etg.json").read_text(encoding="utf-8"))
        graphml(graph, generated / f"{project.name}.graphml")
        standalone_html(graph, generated / f"{project.name}.html")
        rendered.append(graph)
        print(f"[RENDER] {project.name}")
    missing = selected - {path.name for path in project_directories()}
    if missing:
        raise SystemExit(f"unknown projects: {sorted(missing)}")
    index_html(rendered, generated / "index.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
