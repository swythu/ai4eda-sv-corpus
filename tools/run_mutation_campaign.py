#!/usr/bin/env python3
"""Run a private, deterministic mutation campaign and publish only a summary."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import tempfile
from hashlib import sha256
from pathlib import Path

from ipgraph_common import ROOT, sha256_file, write_json


def _tool(env_name: str, executable: str) -> str:
    configured = os.environ.get(env_name)
    candidates = [
        Path(configured) if configured else None,
        Path(shutil.which(executable)) if shutil.which(executable) else None,
        ROOT.parent / ".tools/iverilog-v12/bin" / executable,
        ROOT.parent / ".tools/bin" / executable,
    ]
    for candidate in candidates:
        if candidate and candidate.is_file():
            return str(candidate)
    raise SystemExit(f"missing {executable}; set {env_name}")


def _run_variant(project: Path, source_relative: Path, source_text: str, marker: str, iverilog: str, vvp: str) -> dict:
    with tempfile.TemporaryDirectory(prefix="ipgraph-mutant-") as temp_name:
        temp = Path(temp_name)
        mutant_source = temp / source_relative.name
        mutant_source.write_text(source_text, encoding="utf-8")
        rtl = sorted(path for path in (project / "rtl").rglob("*.sv") if path.relative_to(project) != source_relative)
        tb = sorted((project / "tb").rglob("*.sv"))
        output = temp / "test.vvp"
        compile_run = subprocess.run(
            [iverilog, "-g2012", "-Wall", "-o", str(output), *map(str, rtl), str(mutant_source), *map(str, tb)],
            cwd=project,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=30,
        )
        if compile_run.returncode:
            return {"classification": "invalid", "compile_returncode": compile_run.returncode, "simulation_returncode": None, "marker_seen": False}
        simulation = subprocess.run(
            [vvp, "-n", str(output)], cwd=project, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30,
        )
        marker_seen = marker in simulation.stdout
        return {
            "classification": "survived" if simulation.returncode == 0 and marker_seen else "killed",
            "compile_returncode": 0,
            "simulation_returncode": simulation.returncode,
            "marker_seen": marker_seen,
            "output_sha256": sha256(simulation.stdout.encode()).hexdigest(),
        }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", type=Path, required=True)
    args = parser.parse_args()
    spec_path = args.spec.resolve()
    if ROOT / ".private" not in spec_path.parents:
        raise SystemExit("mutation spec must remain below .private")
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    project = ROOT / spec["project_path"]
    source_relative = Path(spec["source_path"])
    source_path = project / source_relative
    original = source_path.read_text(encoding="utf-8")
    iverilog = _tool("IVERILOG", "iverilog")
    vvp = _tool("VVP", "vvp")
    baseline = _run_variant(project, source_relative, original, spec["pass_marker"], iverilog, vvp)
    if baseline["classification"] != "survived":
        raise SystemExit("baseline failed; mutation campaign aborted")
    results = []
    for mutation in spec["mutations"]:
        old = mutation["old"]
        if original.count(old) != 1:
            raise SystemExit(f"{mutation['mutation_id']}: replacement anchor count is {original.count(old)}, expected 1")
        mutated = original.replace(old, mutation["new"], 1)
        result = _run_variant(project, source_relative, mutated, spec["pass_marker"], iverilog, vvp)
        result.update({
            "mutation_id": mutation["mutation_id"],
            "operator": mutation["operator"],
            "mutant_sha256": sha256(mutated.encode()).hexdigest(),
        })
        results.append(result)
        print(f"[MUTANT] {mutation['mutation_id']} {result['classification']}")
    private_manifest = {
        "schema_version": "ip-private-mutation-manifest/v1",
        "campaign_id": spec["campaign_id"],
        "project_id": spec["project_id"],
        "source_sha256": sha256_file(source_path),
        "baseline": baseline,
        "results": results,
    }
    manifest_path = spec_path.parent / "manifest.json"
    write_json(manifest_path, private_manifest)
    killed = sum(row["classification"] == "killed" for row in results)
    survived = sum(row["classification"] == "survived" for row in results)
    invalid = sum(row["classification"] == "invalid" for row in results)
    summary = {
        "schema_version": "ip-mutation-summary/v1",
        "project_id": spec["project_id"],
        "campaign_id": spec["campaign_id"],
        "baseline_pass": True,
        "non_equivalent_total": killed + survived,
        "killed": killed,
        "survived": survived,
        "equivalent_or_invalid": invalid,
        "status": "pass" if killed > 0 and survived == 0 and invalid == 0 else "fail",
        "private_manifest_sha256": sha256_file(manifest_path),
        "tool_versions": {"iverilog": subprocess.check_output([iverilog, "-V"], text=True, stderr=subprocess.STDOUT).splitlines()[0]},
        "notes": "A killed mutant has an executable behavioral witness and is therefore non-equivalent to the passing baseline for the exercised behavior.",
    }
    write_json(project / "validation/mutation_summary.json", summary)
    print(f"[CAMPAIGN] killed={killed} survived={survived} invalid={invalid} status={summary['status']}")
    return 0 if summary["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
