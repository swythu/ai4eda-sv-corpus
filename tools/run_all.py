#!/usr/bin/env python3
"""Run every project-owned HDL regression with stable tool paths."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def _resolve_tool(env_name: str, executable: str, local_candidates: list[Path]) -> str:
    configured = os.environ.get(env_name)
    if configured:
        path = Path(configured).expanduser()
        if not path.is_absolute():
            path = (Path.cwd() / path).resolve()
        if path.is_file():
            return str(path)
        raise SystemExit(f"{env_name} points to a missing executable: {path}")
    discovered = shutil.which(executable)
    if discovered:
        return str(Path(discovered).resolve())
    for candidate in local_candidates:
        if candidate.is_file():
            return str(candidate.resolve())
    raise SystemExit(
        f"cannot find {executable}; install it or set {env_name} to an absolute path"
    )


def main() -> int:
    tool_root = ROOT.parent / ".tools"
    environment = os.environ.copy()
    environment["IVERILOG"] = _resolve_tool(
        "IVERILOG",
        "iverilog",
        [tool_root / "iverilog-v12/bin/iverilog"],
    )
    environment["VVP"] = _resolve_tool(
        "VVP",
        "vvp",
        [tool_root / "iverilog-v12/bin/vvp"],
    )
    environment["VERILATOR"] = _resolve_tool(
        "VERILATOR",
        "verilator",
        [tool_root / "bin/verilator"],
    )

    items = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))["projects"]
    results: list[dict[str, str]] = []
    for item in items:
        project = ROOT / item["path"]
        candidates = [project / "run.sh", project / "scripts/run.sh"]
        script = next((path for path in candidates if path.exists()), None)
        if script is None:
            print(f"[FAIL] {item['category']}/{item['name']} (missing run script)", flush=True)
            results.append({"project": item["name"], "status": "fail", "detail": "missing run script"})
            continue
        print(f"[RUN ] {item['category']}/{item['name']}", flush=True)
        completed = subprocess.run(
            [str(script)],
            cwd=project,
            text=True,
            capture_output=True,
            env=environment,
            check=False,
        )
        status = "pass" if completed.returncode == 0 else "fail"
        print(f"[{status.upper():4s}] {item['category']}/{item['name']}", flush=True)
        if completed.returncode != 0:
            for log in sorted((project / "validation").rglob("*.log")):
                print(f"--- {log.relative_to(ROOT)} ---", flush=True)
                print(log.read_text(errors="replace")[-12_000:], flush=True)
        results.append(
            {
                "project": item["name"],
                "status": status,
                "detail": (completed.stdout + completed.stderr)[-4_000:],
            }
        )
    (ROOT / "validation_summary.json").write_text(
        json.dumps(results, indent=2) + "\n", encoding="utf-8"
    )
    return 0 if all(result["status"] == "pass" for result in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
