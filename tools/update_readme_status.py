#!/usr/bin/env python3
"""Refresh bilingual README quality/release tables from canonical IP-ETGs."""

from __future__ import annotations

import json

from ipgraph_common import ROOT, project_directories


BEGIN = "<!-- BEGIN GENERATED PROJECT STATUS -->"
END = "<!-- END GENERATED PROJECT STATUS -->"


def records() -> list[dict[str, object]]:
    result = []
    for project in project_directories():
        graph = json.loads((project / "graph/ip_etg.json").read_text(encoding="utf-8"))
        result.append(
            {
                "id": graph["project_id"],
                "path": project.relative_to(ROOT).as_posix(),
                "category": project.parent.name,
                "quality": graph["validation"]["quality_level"],
                "release": graph["release_policy"],
                "tasks": len(graph["tasks"]),
            }
        )
    return sorted(result, key=lambda row: str(row["id"]))


def replace(path, table: str) -> None:
    text = path.read_text(encoding="utf-8")
    if text.count(BEGIN) != 1 or text.count(END) != 1:
        raise SystemExit(f"missing or duplicate generated markers: {path}")
    prefix, remainder = text.split(BEGIN, 1)
    _old, suffix = remainder.split(END, 1)
    path.write_text(f"{prefix}{BEGIN}\n{table}\n{END}{suffix}", encoding="utf-8")


def main() -> int:
    rows = records()
    body = "\n".join(
        f"| [{row['id']}]({row['path']}) | {row['category']} | {row['quality']} | `{row['release']}` | {row['tasks']} |"
        for row in rows
    )
    replace(
        ROOT / "README.md",
        "| Project | Category | Quality | Release status | Task candidates |\n"
        "|---|---|---:|---|---:|\n" + body,
    )
    replace(
        ROOT / "README_zh-CN.md",
        "| 项目 | 分类 | 质量等级 | 发布状态 | 候选任务数 |\n"
        "|---|---|---:|---|---:|\n" + body,
    )
    print(f"[README-STATUS] projects={len(rows)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
