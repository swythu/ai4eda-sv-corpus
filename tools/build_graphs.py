#!/usr/bin/env python3
"""Build deterministic project-level IP Engineering Task Graphs with pyslang."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

import pyslang
import yaml

from ipgraph_common import (
    ROOT,
    graph_digest,
    media_type,
    project_directories,
    release_status,
    sha256_file,
    write_json,
)


HDL_SUFFIXES = {".sv", ".svh", ".v", ".vh"}
CLOCK_NAMES = {"clk", "clock", "aclk", "pclk", "hclk", "wb_clk_i", "q_clk", "in_clk"}
RESET_NAMES = {"reset", "resetn", "rst", "rstn", "areset", "aresetn", "preset", "presetn", "hreset", "hresetn"}


def _is_clock_name(name: str) -> bool:
    lowered = name.lower()
    return (
        lowered in CLOCK_NAMES
        or lowered.startswith(("clk_", "clock_"))
        or lowered.endswith(("_clk", "_clock", "_clk_i", "_clock_i"))
    )


def _is_reset_name(name: str) -> bool:
    lowered = name.lower()
    return (
        lowered in RESET_NAMES
        or lowered.startswith(("rst_", "reset_", "areset_", "preset_", "hreset_"))
        or lowered.endswith(("_rst", "_rst_n", "_rst_ni", "_reset", "_reset_n", "_reset_ni"))
    )


def _token_value(value: Any) -> str:
    return str(getattr(value, "value", value)).strip()


def _project_sources(project: Path) -> list[Path]:
    roots = [project / "rtl", project / "include"]
    return sorted(
        path
        for root in roots
        if root.exists()
        for path in root.rglob("*")
        if path.is_file() and path.suffix.lower() in HDL_SUFFIXES
    )


def _semantic_elaboration(project: Path, sources: list[Path]) -> dict[str, Any]:
    """Run pyslang's compilation pipeline and return stable public facts.

    Legacy OpenCores code can use simulator-specific directives that pyslang
    reports as errors even when the project authority (Icarus/Verilator)
    elaborates it. Preserve that distinction instead of silently claiming a
    successful pyslang elaboration.
    """
    compilation_units = [path for path in sources if path.suffix.lower() in {".sv", ".v"}]
    try:
        preprocessor = pyslang.PreprocessorOptions()
        preprocessor.additionalIncludePaths = sorted(
            {path.parent for path in sources} | ({project / "include"} if (project / "include").exists() else set())
        )
        options = pyslang.Bag()
        options.preprocessorOptions = preprocessor
        source_manager = pyslang.SourceManager()
        compilation = pyslang.Compilation()
        for path in compilation_units:
            tree = pyslang.SyntaxTree.fromFile(str(path), source_manager, options)
            compilation.addSyntaxTree(tree)
        root = compilation.getRoot()
        diagnostics = list(compilation.getAllDiagnostics())
        errors = [item for item in diagnostics if item.isError()]
        error_codes = Counter(str(item.code) for item in errors)
        return {
            "attempted": True,
            "status": "pass" if not errors else "partial_with_diagnostics",
            "compilation_units": len(compilation_units),
            "top_instances": sorted({str(item.name) for item in root.topInstances}),
            "diagnostic_count": len(diagnostics),
            "error_count": len(errors),
            "error_codes": dict(sorted(error_codes.items())),
            "authority": "project regression remains authoritative for Q1/Q2",
        }
    except Exception as exc:
        return {
            "attempted": True,
            "status": "failed",
            "compilation_units": len(compilation_units),
            "top_instances": [],
            "diagnostic_count": 1,
            "error_count": 1,
            "error_codes": {type(exc).__name__: 1},
            "authority": "project regression remains authoritative for Q1/Q2",
        }


def _all_artifacts(project: Path) -> list[Path]:
    allowed_roots = ["rtl", "include", "tb", "tbench", "assertions", "filelists", "scripts", "tasks", "validation"]
    generated_or_ephemeral = {".vvp", ".vcd", ".wlf", ".fst", ".log", ".pyc"}
    paths = [
        path
        for name in allowed_roots
        if (project / name).exists()
        for path in (project / name).rglob("*")
        if path.is_file() and path.suffix.lower() not in generated_or_ephemeral
    ]
    paths.extend(
        path for name in ("ORIGIN.yml", "metadata.json", "refactor.patch", "run.sh")
        if (path := project / name).is_file()
    )
    return sorted(set(paths))


def _artifact(path: Path, project: Path, license_expression: str, status: str) -> dict[str, Any]:
    digest = sha256_file(path)
    return {
        "artifact_id": f"sha256:{digest}",
        "path": path.relative_to(project).as_posix(),
        "media_type": media_type(path),
        "sha256": digest,
        "license_expression": license_expression,
        "release_status": status,
    }


def _node(
    node_id: str,
    kind: str,
    label: str,
    *,
    attributes: dict[str, Any] | None = None,
    artifact_refs: list[str] | None = None,
    evidence_refs: list[str] | None = None,
) -> dict[str, Any]:
    return {
        "id": node_id,
        "type": kind,
        "label": label,
        "attributes": attributes or {},
        "artifact_refs": sorted(set(artifact_refs or [])),
        "evidence_refs": sorted(set(evidence_refs or [])),
        "visibility": "public",
    }


def _edge(edge_id: str, kind: str, source: str, target: str, evidence: list[str]) -> dict[str, Any]:
    return {
        "id": edge_id,
        "type": kind,
        "source": source,
        "target": target,
        "evidence_refs": sorted(set(evidence)),
    }


def _port_record(port: Any) -> dict[str, str]:
    text = " ".join(str(port).split())
    name = _token_value(port.declarator.name)
    direction = "inout"
    for candidate in ("input", "output", "inout", "ref"):
        if text.startswith(candidate + " ") or f" {candidate} " in f" {text} ":
            direction = candidate
            break
    return {"name": name, "direction": direction, "declaration": text}


def _extract_file(path: Path, project: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]], list[str]]:
    modules: list[dict[str, Any]] = []
    instances: list[dict[str, Any]] = []
    diagnostics: list[str] = []
    try:
        tree = pyslang.SyntaxTree.fromFile(str(path))
    except Exception as exc:
        return [], [], [f"{path.relative_to(project)}: {exc}"]
    # Diagnostic object reprs contain process-specific addresses in pyslang.
    # Store stable codes so source.json is reproducible as well as ip_etg.json.
    diagnostics.extend(str(item.code) for item in tree.diagnostics)
    for declaration in tree.root.members:
        if declaration.kind != pyslang.SyntaxKind.ModuleDeclaration:
            continue
        header = declaration.header
        module_name = _token_value(header.name)
        ports: list[dict[str, str]] = []
        port_list = getattr(header.ports, "ports", ()) if header.ports is not None else ()
        for item in port_list:
            if getattr(item, "kind", None) == pyslang.SyntaxKind.ImplicitAnsiPort:
                ports.append(_port_record(item))
            elif getattr(item, "kind", None) == pyslang.SyntaxKind.ExplicitAnsiPort:
                ports.append({"name": _token_value(item.name), "direction": "interface", "declaration": " ".join(str(item).split())})
        if getattr(header.ports, "kind", None) == pyslang.SyntaxKind.NonAnsiPortList:
            # Non-ANSI names are declared by direct PortDeclaration members in
            # the module body. This remains AST extraction; no regex fallback.
            for member in declaration.members:
                if getattr(member, "kind", None) != pyslang.SyntaxKind.PortDeclaration:
                    continue
                direction = _token_value(member.header.direction).lower()
                declaration_text = " ".join(str(member).split())
                for declarator in member.declarators:
                    ports.append(
                        {
                            "name": _token_value(declarator.name),
                            "direction": direction,
                            "declaration": declaration_text,
                        }
                    )
        parameters: list[str] = []
        if header.parameters is not None:
            for item in header.parameters.declarations:
                if getattr(item, "kind", None) != pyslang.SyntaxKind.ParameterDeclaration:
                    continue
                for declarator in item.declarators:
                    if hasattr(declarator, "name"):
                        parameters.append(_token_value(declarator.name))
        relative = path.relative_to(project).as_posix()
        modules.append({"name": module_name, "path": relative, "ports": ports, "parameters": sorted(set(parameters))})

        def visitor(node: Any) -> None:
            if node.kind != pyslang.SyntaxKind.HierarchyInstantiation:
                return
            target = _token_value(node.type)
            for instance in node.instances:
                connections: list[dict[str, str]] = []

                def connection_visitor(connection: Any) -> None:
                    if connection.kind == pyslang.SyntaxKind.NamedPortConnection:
                        connections.append(
                            {
                                "kind": "named",
                                "port": _token_value(connection.name),
                                "expression": " ".join(str(connection.expr).split()),
                            }
                        )
                    elif connection.kind == pyslang.SyntaxKind.OrderedPortConnection:
                        connections.append(
                            {
                                "kind": "ordered",
                                "port": "",
                                "expression": " ".join(str(connection.expr).split()),
                            }
                        )

                instance.connections.visit(connection_visitor)
                instances.append(
                    {
                        "parent": module_name,
                        "target": target,
                        "name": _token_value(instance.decl.name),
                        "path": relative,
                        "declaration": " ".join(str(instance).split())[:1000],
                        "connections": connections,
                    }
                )

        declaration.visit(visitor)
    return modules, instances, diagnostics


def _clock_reset_nodes(modules: list[dict[str, Any]]) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    clocks: dict[str, set[str]] = defaultdict(set)
    resets: dict[str, set[str]] = defaultdict(set)
    for module in modules:
        for port in module["ports"]:
            lowered = port["name"].lower()
            if _is_clock_name(lowered):
                clocks[port["name"]].add(module["name"])
            if _is_reset_name(lowered):
                resets[port["name"]].add(module["name"])
    clock_nodes = [
        _node(f"clock_domain:{name}", "clock_domain", name, attributes={"inference": "port-name-candidate", "modules": sorted(owners)})
        for name, owners in sorted(clocks.items())
    ]
    reset_nodes = [
        _node(f"reset_domain:{name}", "reset_domain", name, attributes={"inference": "port-name-candidate", "modules": sorted(owners)})
        for name, owners in sorted(resets.items())
    ]
    return clock_nodes, reset_nodes


def _protocol(metadata: dict[str, Any], modules: list[dict[str, Any]]) -> str:
    corpus = " ".join(
        [metadata.get("project", ""), metadata.get("category", "")]
        + [port["name"] for module in modules for port in module["ports"]]
    ).lower()
    for needle, label in (
        ("wishbone", "Wishbone"), ("wb_", "Wishbone"), ("axi", "AXI"),
        ("apb", "APB"), ("ready", "ready-valid"), ("uart", "UART"),
        ("spi", "SPI"), ("i2c", "I2C"), ("fifo", "FIFO"),
    ):
        if needle in corpus:
            return label
    return "native-module-interface"


def _apply_overrides(graph: dict[str, Any], path: Path) -> dict[str, Any]:
    if not path.exists():
        return graph
    overrides = json.loads(path.read_text(encoding="utf-8"))
    if overrides.get("schema_version") != "ip-etg-overrides/v1":
        raise ValueError(f"unsupported override schema: {path}")
    graph["nodes"].extend(overrides.get("add_nodes", []))
    graph["edges"].extend(overrides.get("add_edges", []))
    remove_nodes = set(overrides.get("remove_node_ids", []))
    remove_edges = set(overrides.get("remove_edge_ids", []))
    graph["nodes"] = [row for row in graph["nodes"] if row["id"] not in remove_nodes]
    graph["edges"] = [row for row in graph["edges"] if row["id"] not in remove_edges]
    return graph


def build_project(project: Path) -> dict[str, Any]:
    metadata = json.loads((project / "metadata.json").read_text(encoding="utf-8"))
    origin_text = (project / "ORIGIN.yml").read_text(encoding="utf-8")
    origin = yaml.safe_load(origin_text) or {}
    project_id = str(metadata.get("project") or project.name)
    license_expression = str(
        metadata.get("license_expression")
        or origin.get("license_expression")
        or "LicenseRef-Unknown"
    )
    status = release_status(license_expression)
    revision = sha256_file(project / "metadata.json")[:16]
    raw_artifacts = [_artifact(path, project, license_expression, status) for path in _all_artifacts(project)]
    artifacts = list({row["artifact_id"]: row for row in raw_artifacts}.values())
    artifact_by_path = {row["path"]: row["artifact_id"] for row in artifacts}
    metadata_evidence = artifact_by_path["metadata.json"]
    origin_evidence = artifact_by_path["ORIGIN.yml"]
    modules: list[dict[str, Any]] = []
    instances: list[dict[str, Any]] = []
    diagnostics: list[str] = []
    project_sources = _project_sources(project)
    for source in project_sources:
        file_modules, file_instances, file_diagnostics = _extract_file(source, project)
        modules.extend(file_modules)
        instances.extend(file_instances)
        diagnostics.extend(file_diagnostics)
    unique_modules = {row["name"]: row for row in modules}
    modules = [unique_modules[name] for name in sorted(unique_modules)]
    instantiated = {row["target"] for row in instances}
    syntax_roots = sorted(set(unique_modules) - instantiated) or sorted(unique_modules)
    elaboration = _semantic_elaboration(project, project_sources)
    elaborated_roots = [name for name in elaboration["top_instances"] if name in unique_modules]
    roots = elaborated_roots or syntax_roots

    nodes = [
        _node(f"project:{project_id}", "project", project_id, attributes={"category": project.parent.name, "top_module_candidates": roots, "compile_order": [path.relative_to(project).as_posix() for path in project_sources], "compile_order_inference": "deterministic source order; project run script is validation authority", "extractor": f"pyslang-{pyslang.__version__}", "pyslang_elaboration_status": elaboration["status"]}),
        _node(f"source_revision:{revision}", "source_revision", revision, attributes={"metadata_sha256": sha256_file(project / "metadata.json")}),
        _node(f"license:{license_expression}", "license", license_expression, attributes={"release_status": status, "origin_evidence_present": bool(origin)}),
    ]
    edges = [
        _edge(f"edge:project-source", "derived_from", f"project:{project_id}", f"source_revision:{revision}", [metadata_evidence]),
        _edge(f"edge:project-license", "constrained_by", f"project:{project_id}", f"license:{license_expression}", [origin_evidence]),
    ]
    for module in modules:
        artifact_ref = artifact_by_path.get(module["path"])
        evidence = [artifact_ref] if artifact_ref else [f"path:{module['path']}"]
        module_id = f"module:{module['name']}"
        nodes.append(_node(module_id, "module", module["name"], attributes={"path": module["path"]}, artifact_refs=[artifact_ref] if artifact_ref else [], evidence_refs=evidence))
        edges.append(_edge(f"edge:project-contains-{module['name']}", "contains", f"project:{project_id}", module_id, evidence))
        for parameter in module["parameters"]:
            parameter_id = f"parameter:{module['name']}.{parameter}"
            nodes.append(_node(parameter_id, "parameter", parameter, attributes={"module": module["name"]}, evidence_refs=evidence))
            edges.append(_edge(f"edge:{module['name']}-parameter-{parameter}", "contains", module_id, parameter_id, evidence))
        for port in module["ports"]:
            port_id = f"port:{module['name']}.{port['name']}"
            nodes.append(_node(port_id, "port", port["name"], attributes={"module": module["name"], "direction": port["direction"], "declaration": port["declaration"]}, evidence_refs=evidence))
            edges.append(_edge(f"edge:{module['name']}-port-{port['name']}", "contains", module_id, port_id, evidence))
    for index, instance in enumerate(sorted(instances, key=lambda row: (row["parent"], row["name"], row["target"]))):
        artifact_ref = artifact_by_path.get(instance["path"])
        evidence = [artifact_ref] if artifact_ref else [f"path:{instance['path']}"]
        instance_id = f"instance:{instance['parent']}.{instance['name']}:{index}"
        nodes.append(_node(instance_id, "instance", instance["name"], attributes={"parent_module": instance["parent"], "target_module": instance["target"], "declaration": instance["declaration"], "connections": instance["connections"]}, evidence_refs=evidence))
        edges.append(_edge(f"edge:instance-{index}-contained", "contains", f"module:{instance['parent']}", instance_id, evidence))
        if instance["target"] in unique_modules:
            edges.append(_edge(f"edge:instance-{index}-target", "instantiates", instance_id, f"module:{instance['target']}", evidence))
            target_ports = [port["name"] for port in unique_modules[instance["target"]]["ports"]]
            for connection_index, connection in enumerate(instance["connections"]):
                port_name = connection["port"]
                if connection["kind"] == "ordered" and connection_index < len(target_ports):
                    port_name = target_ports[connection_index]
                if port_name in target_ports:
                    edges.append(
                        _edge(
                            f"edge:instance-{index}-connection-{connection_index}",
                            "connects_to",
                            instance_id,
                            f"port:{instance['target']}.{port_name}",
                            evidence,
                        )
                    )

    clock_nodes, reset_nodes = _clock_reset_nodes(modules)
    nodes.extend(clock_nodes)
    nodes.extend(reset_nodes)
    for domain in clock_nodes:
        for module_name in domain["attributes"]["modules"]:
            evidence = artifact_by_path[unique_modules[module_name]["path"]]
            edges.append(_edge(f"edge:{module_name}-clock-{domain['label']}", "clocked_by", f"module:{module_name}", domain["id"], [evidence]))
    for domain in reset_nodes:
        for module_name in domain["attributes"]["modules"]:
            evidence = artifact_by_path[unique_modules[module_name]["path"]]
            edges.append(_edge(f"edge:{module_name}-reset-{domain['label']}", "reset_by", f"module:{module_name}", domain["id"], [evidence]))
    protocol = _protocol(metadata, modules)
    nodes.append(_node(f"protocol_contract:{protocol.lower().replace(' ', '_')}", "protocol_contract", protocol, attributes={"inference": "metadata-and-port-name-candidate"}, evidence_refs=[metadata_evidence]))
    obligations = list(metadata.get("verification_checks", [])) or ["project self-checking regression remains passing"]
    for index, obligation in enumerate(obligations):
        node_id = f"verification_obligation:{index:03d}"
        nodes.append(_node(node_id, "verification_obligation", str(obligation), attributes={"source": "metadata"}, evidence_refs=[metadata_evidence]))
        edges.append(_edge(f"edge:project-obligation-{index:03d}", "contains", f"project:{project_id}", node_id, [metadata_evidence]))
    for path in sorted((project / "tb").glob("**/*")) if (project / "tb").exists() else []:
        if not path.is_file() or path.suffix.lower() not in HDL_SUFFIXES:
            continue
        artifact_ref = artifact_by_path.get(path.relative_to(project).as_posix())
        if artifact_ref:
            node_id = f"testbench:{path.relative_to(project).as_posix()}"
            nodes.append(_node(node_id, "testbench", path.name, artifact_refs=[artifact_ref], evidence_refs=[artifact_ref]))
            edges.append(_edge(f"edge:project-testbench-{len(edges)}", "verified_by", f"project:{project_id}", node_id, [artifact_ref]))
    validation_refs = sorted({row["artifact_id"] for row in artifacts if row["path"].startswith("validation/")})
    nodes.append(_node("tool_run:project_regression", "tool_run", "project regression", attributes={"status": "pass" if metadata.get("status") in {"pass", "functional_pass"} else "not_run"}, artifact_refs=validation_refs, evidence_refs=validation_refs or [f"sha256:{sha256_file(project / 'metadata.json')}"]))
    edges.append(_edge("edge:project-regression", "verified_by", f"project:{project_id}", "tool_run:project_regression", validation_refs or [f"sha256:{sha256_file(project / 'metadata.json')}"]))

    task_paths = sorted((project / "tasks").glob("*/*.json")) if (project / "tasks").exists() else []
    tasks = [json.loads(path.read_text(encoding="utf-8")) for path in task_paths]
    task_node_kinds = {
        "functional_timing_understanding": "understand_task",
        "hierarchy_dependency_analysis": "understand_task",
        "hierarchical_rtl_generation": "generation_task",
        "reuse_integration": "reuse_task",
        "interface_modification": "reuse_task",
        "hierarchical_integration": "reuse_task",
        "fault_localization_repair": "repair_task",
        "cross_module_repair": "repair_task",
        "verification_generation": "verification_task",
        "tool_result_analysis": "understand_task",
    }
    for task in tasks:
        task_relative = f"tasks/{task['family']}/{task['task_id'].rsplit(':', 1)[-1]}.json"
        task_evidence = artifact_by_path[task_relative]
        node_id = f"task:{task['task_id']}"
        nodes.append(
            _node(
                node_id,
                task_node_kinds[task["family"]],
                task["task_id"],
                attributes={"family": task["family"], "difficulty": task["difficulty"]},
                evidence_refs=[task_evidence],
            )
        )
        edges.append(
            _edge(
                f"edge:project-task-{task['task_id'].replace(':', '-')}",
                "contains",
                f"project:{project_id}",
                node_id,
                [task_evidence],
            )
        )
    validation_path = project / "validation" / "result.json"
    if not validation_path.exists():
        validation_path = project / "validation" / "baseline_result.json"
    validation_result = json.loads(validation_path.read_text(encoding="utf-8")) if validation_path.exists() else {}
    test_level = str(validation_result.get("test_level") or validation_result.get("simulation_level") or "unspecified")
    compile_pass = validation_result.get("compile") == "pass"
    simulation_pass = validation_result.get("simulation") == "pass"
    lint_pass = validation_result.get("lint_errors") in (None, 0) and validation_result.get("status") == "pass"
    smoke_only = "smoke" in test_level.lower()
    mutation_path = project / "validation/mutation_summary.json"
    mutation_summary = json.loads(mutation_path.read_text(encoding="utf-8")) if mutation_path.exists() else {}
    mutation_pass = (
        mutation_summary.get("status") == "pass"
        and mutation_summary.get("survived") == 0
        and mutation_summary.get("killed", 0) > 0
    )
    q2_pass = compile_pass and simulation_pass and lint_pass and not smoke_only
    quality_level = "Q3" if q2_pass and mutation_pass else ("Q2" if q2_pass else ("Q1" if compile_pass else "Q0"))
    graph = {
        "schema_version": "ip-etg/v1",
        "graph_id": f"ip-etg:{project_id}:{revision}",
        "project_id": project_id,
        "project_revision": revision,
        "release_policy": status,
        "nodes": nodes,
        "edges": edges,
        "artifacts": artifacts,
        "tasks": tasks,
        "validation": {
            "quality_level": quality_level,
            "compile": "pass" if compile_pass else "not_run",
            "elaboration": "pass" if compile_pass else "not_run",
            "lint": "pass" if lint_pass else "not_run",
            "simulation": "smoke_pass" if smoke_only and simulation_pass else ("pass" if simulation_pass else "not_run"),
            "mutation": {
                "status": "pass" if mutation_pass else "not_run",
                "killed": mutation_summary.get("killed", 0) if mutation_pass else 0,
                "total": mutation_summary.get("non_equivalent_total", 0) if mutation_pass else 0,
            },
            "expert_review": {"status": "pending", "reviewers": []},
            "evidence_refs": validation_refs,
        },
        "graph_sha256": "0" * 64,
    }
    graph = _apply_overrides(graph, project / "graph" / "overrides.json")
    graph["nodes"] = sorted(graph["nodes"], key=lambda row: row["id"])
    graph["edges"] = sorted(graph["edges"], key=lambda row: row["id"])
    graph["artifacts"] = sorted(graph["artifacts"], key=lambda row: row["path"])
    graph["tasks"] = sorted(graph["tasks"], key=lambda row: row["task_id"])
    graph["graph_sha256"] = graph_digest(graph)
    source = {
        "schema_version": "ip-etg-source/v1",
        "project_id": project_id,
        "extractor": f"pyslang-{pyslang.__version__}",
        "source_files": [path.relative_to(project).as_posix() for path in _project_sources(project)],
        "parse_diagnostics": diagnostics,
        "semantic_elaboration": elaboration,
        "manual_overrides": "graph/overrides.json",
    }
    lock = {
        "schema_version": "ip-etg-lock/v1",
        "graph_sha256": graph["graph_sha256"],
        "project_revision": revision,
        "task_count": len(tasks),
        "module_count": len(modules),
        "instance_count": len(instances),
    }
    write_json(project / "graph" / "source.json", source)
    override_path = project / "graph" / "overrides.json"
    if not override_path.exists():
        write_json(override_path, {"schema_version": "ip-etg-overrides/v1", "add_nodes": [], "add_edges": [], "remove_node_ids": [], "remove_edge_ids": [], "reviews": []})
    write_json(project / "graph" / "ip_etg.json", graph)
    write_json(project / "graph" / "graph.lock.json", lock)
    return lock


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", action="append", help="build only this project id")
    args = parser.parse_args()
    requested = set(args.project or [])
    results = []
    for project in project_directories():
        if requested and project.name not in requested:
            continue
        lock = build_project(project)
        print(f"[GRAPH] {project.name}: modules={lock['module_count']} instances={lock['instance_count']} tasks={lock['task_count']}")
        results.append(lock)
    if requested and len(results) != len(requested):
        missing = requested - {path.name for path in project_directories()}
        raise SystemExit(f"unknown projects: {sorted(missing)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
