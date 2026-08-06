# SystemVerilog Refactor Dataset

[English](README.md) | [简体中文](README_zh-CN.md)

A provenance-first collection of OpenCores HDL projects refactored toward
synthesizable SystemVerilog and validated with self-checking simulations.

## Purpose

This repository is intended to support future AI4EDA research and engineering
by building a standardized, traceable, and executable SystemVerilog dataset.
Its IP source material comes from OpenCores. The dataset preserves provenance
and copyright information while organizing refactored RTL, transformation
patches, metadata, and reproducible verification assets in a consistent form.

Potential uses include RTL code generation and repair, hierarchy and interface
understanding, IP retrieval and reuse, verification generation, model training,
and benchmark evaluation. Here, "standardized" describes this repository's
dataset schema and SystemVerilog normalization goals; it does not imply IEEE,
Accellera, or other official certification.

## Scope

- 14 verified projects; four have unresolved or incomplete license metadata.
- Original copyright and license headers are retained.
- Every project has ORIGIN.yml, refactor metadata/patches, RTL, and tests.
- License-ambiguous projects are included at the dataset owner's request and
  prominently marked; inclusion does not grant redistribution permission.
- This is not a claim of formal equivalence or production sign-off.

## Layout

    projects/<category>/<project>/
    LICENSES/
    NOTICE.md
    manifest.json
    EXCLUDED_PROJECTS.json

## Verify

Install Icarus Verilog and Verilator, then run:

    python3 tools/run_all.py

Environment overrides are supported:

    IVERILOG=/path/iverilog VVP=/path/vvp VERILATOR=/path/verilator python3 tools/run_all.py

## Licensing

This is a multi-license repository. The top-level LICENSE only describes the
licensing split; it does not relicense upstream HDL. Read NOTICE.md,
LICENSES/, ORIGIN.yml, and retained file headers.

## Publication warning

Four projects use `LicenseRef-Unknown` or
`LicenseRef-LGPL-Unspecified-Version`. Perform a rights-holder and legal review
before making the repository public. Keeping a repository private does not by
itself resolve copyright restrictions.
