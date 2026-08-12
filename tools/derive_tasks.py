#!/usr/bin/env python3
"""Derive public, answer-free IP-ETG alpha tasks from project graphs."""

from __future__ import annotations

import argparse
import json
from functools import lru_cache
from pathlib import Path
from typing import Any

from ipgraph_common import ROOT, project_directories, write_json


BASE_FAMILIES = (
    "functional_timing_understanding",
    "hierarchy_dependency_analysis",
    "hierarchical_rtl_generation",
    "reuse_integration",
    "fault_localization_repair",
    "verification_generation",
    "tool_result_analysis",
)


@lru_cache(maxsize=1)
def _split_membership() -> dict[str, str]:
    path = ROOT / "benchmarks/ipgraph_v1/splits.lock.json"
    if not path.exists():
        return {}
    lock = json.loads(path.read_text(encoding="utf-8"))
    if lock.get("status") != "project_splits_locked":
        return {}
    return {
        row["project_id"]: split
        for split in ("train", "dev", "public_test", "frozen_test")
        for row in lock.get(split, [])
    }


def _prompt(family: str, project_id: str, modules: list[str], obligations: list[str]) -> str:
    module_text = ", ".join(modules[:12]) or "the project modules"
    obligation_text = obligations[0] if obligations else "the documented project behavior"
    prompts = {
        "functional_timing_understanding": f"Explain the synthesizable function, state evolution, latency, clock/reset behavior, and externally visible protocol of {project_id}. Ground every claim in the provided graph and permitted artifacts.",
        "hierarchy_dependency_analysis": f"Recover and explain the module dependency and instantiation hierarchy of {project_id}, including the roles of {module_text}. Identify graph evidence for each dependency.",
        "hierarchical_rtl_generation": f"Generate or complete synthesizable SystemVerilog for {project_id} from its released design contracts. Preserve the hierarchy and interfaces of {module_text}, reuse existing modules, and require the project regression as the oracle.",
        "reuse_integration": f"Design a minimal wrapper plan to reuse {project_id} in a larger SystemVerilog subsystem. Preserve the existing IP and describe parameter, clock, reset, and interface adaptation requirements.",
        "fault_localization_repair": f"Given a future failing regression for {project_id}, rank likely fault modules from graph evidence, request the minimum missing diagnostic evidence, and propose a constrained patch protocol that preserves all existing regressions.",
        "verification_generation": f"Generate a self-checking verification plan and synthesizable-interface testbench strategy for {project_id}. It must exercise the obligation: {obligation_text} and define explicit failure checks.",
        "tool_result_analysis": f"Interpret the compile, lint, elaboration, and simulation evidence for {project_id}. State exactly what is established, what remains unverified, and which next deterministic check has the highest value.",
        "interface_modification": f"Plan a cross-module interface modification for {project_id}. Enumerate every affected module, instance, port, connection, test, and regression obligation before proposing edits.",
        "hierarchical_integration": f"Create a DesignGraph integration plan for {project_id} that reuses its existing hierarchy instead of flattening or rewriting it. Include compile order and per-module verification obligations.",
        "cross_module_repair": f"Localize and repair a hypothetical cross-module protocol failure in {project_id}. Restrict modifications to the fault module and direct adapter, and require the complete project regression after the patch.",
    }
    return prompts[family]


def _task(
    project_id: str,
    family: str,
    index: int,
    modules: list[str],
    obligations: list[str],
    project_revision: str,
    *,
    difficulty: str,
    split: str,
    mutation_validated: bool,
) -> dict[str, Any]:
    task_id = f"ipgraph:{project_id}:{family}:{index:04d}"
    project_node = f"project:{project_id}"
    module_nodes = [f"module:{name}" for name in modules[:12]]
    return {
        "schema_version": "ip-task/v1",
        "task_id": task_id,
        "project_id": project_id,
        "family": family,
        "difficulty": difficulty,
        "prompt": _prompt(family, project_id, modules, obligations),
        "input_nodes": [project_node, *module_nodes],
        "target_nodes": module_nodes,
        "allowed_context": ["project_metadata", "released_graph", "released_rtl", "public_validation_summary"],
        "output_contract": {
            "format": "structured_json_or_systemverilog_as_requested",
            "must_cite_graph_node_ids": True,
            "must_not_modify_tests": True,
        },
        "oracle": {
            "kind": "graph_and_tool_contract",
            "required_checks": ["schema", "compile_if_code", "lint_if_code", "project_regression_if_patch"],
            "gold_release": "not_in_alpha",
        },
        "split": split,
        "release_tier": "private_until_release" if split == "frozen_test" else "public",
        "quality": {
            "tool_validated": mutation_validated,
            "mutation_validated": mutation_validated,
            "expert_reviewed": False,
        },
        "provenance": {
            # Use the stable project revision rather than the final graph hash.
            # The final graph embeds tasks, so referencing it here would create
            # a circular hash that changes on every derive/build cycle.
            "project_revision": project_revision,
            "derivation": "deterministic-v0.1-template",
            "review_status": "pending",
        },
    }


def derive(project: Path) -> int:
    graph_path = project / "graph" / "ip_etg.json"
    if not graph_path.exists():
        raise FileNotFoundError(f"build graph before deriving tasks: {graph_path}")
    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    project_id = graph["project_id"]
    split = _split_membership().get(project_id, "train")
    mutation_path = project / "validation/mutation_summary.json"
    mutation_summary = json.loads(mutation_path.read_text(encoding="utf-8")) if mutation_path.exists() else {}
    project_mutation_validated = mutation_summary.get("status") == "pass"
    modules = [row["label"] for row in graph["nodes"] if row["type"] == "module"]
    obligations = [row["label"] for row in graph["nodes"] if row["type"] == "verification_obligation"]
    families = list(BASE_FAMILIES)
    if len(modules) > 1:
        families.extend(("interface_modification", "hierarchical_integration", "cross_module_repair", "cross_module_repair"))
    complex_project = (
        len(modules) >= 8
        or project.parent.name == "processor"
        or any(token in project_id for token in ("dma", "mac", "processor", "cpu"))
    )
    if complex_project:
        families.extend(("interface_modification", "hierarchical_integration", "cross_module_repair", "verification_generation", "fault_localization_repair"))
        # The public contract requires at least 15 tasks for processors, DMA,
        # MAC, and similarly complex projects, including single-module IPs.
        # Repeat engineering families with distinct deterministic indices;
        # do not pad the set with unrelated task types.
        complex_cycle = (
            "functional_timing_understanding",
            "reuse_integration",
            "verification_generation",
            "fault_localization_repair",
            "tool_result_analysis",
        )
        while len(families) < 15:
            families.append(complex_cycle[len(families) % len(complex_cycle)])
    task_root = project / "tasks"
    task_root.mkdir(parents=True, exist_ok=True)
    # Remove only records owned by this deterministic generator. Hand-authored
    # or post-evaluation tasks are never deleted by a rebuild.
    for old_path in task_root.glob("*/*.json"):
        old_record = json.loads(old_path.read_text(encoding="utf-8"))
        if old_record.get("provenance", {}).get("derivation") in {
            "deterministic-alpha-template",
            "deterministic-v0.1-template",
        }:
            old_path.unlink()
    family_counts: dict[str, int] = {}
    for family in families:
        index = family_counts.get(family, 0)
        family_counts[family] = index + 1
        difficulty = "hard" if family in {"cross_module_repair", "hierarchical_integration"} else ("medium" if len(modules) > 1 else "easy")
        task_mutation_validated = project_mutation_validated and family not in {
            "functional_timing_understanding",
            "hierarchy_dependency_analysis",
            "tool_result_analysis",
        }
        task = _task(
            project_id,
            family,
            index,
            modules,
            obligations,
            graph["project_revision"],
            difficulty=difficulty,
            split=split,
            mutation_validated=task_mutation_validated,
        )
        path = project / "tasks" / family / f"{index:04d}.json"
        write_json(path, task)
    return len(families)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", action="append")
    args = parser.parse_args()
    requested = set(args.project or [])
    total = 0
    for project in project_directories():
        if requested and project.name not in requested:
            continue
        count = derive(project)
        total += count
        print(f"[TASKS] {project.name}: {count}")
    print(f"[TASKS] total={total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
