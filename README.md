# AI4EDA SystemVerilog Corpus

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

- 19 verified projects; five have unresolved or incomplete license metadata.
- Original copyright and license headers are retained.
- Every project has ORIGIN.yml, refactor metadata/patches, RTL, and tests.
- License-ambiguous projects are included at the dataset owner's request and
  prominently marked; inclusion does not grant redistribution permission.
- This is not a claim of formal equivalence or production sign-off.

## IP catalog

| IP | Category | Function | Validation | License |
|---|---|---|---|---|
| [binary_to_bcd](projects/arithmetic/binary_to_bcd) | Arithmetic | Parameterized binary-to-BCD converter. | Boundary-vector functional checks | `LGPL-2.1-or-later` |
| [fixed_point_arithmetic_parameterized](projects/arithmetic/fixed_point_arithmetic_parameterized) | Arithmetic | Parameterized fixed-point add, multiply, and iterative divide units. | Mathematical reference checks | `LicenseRef-Unknown` |
| [ima_adpcm_enc_dec](projects/arithmetic/ima_adpcm_enc_dec) | Arithmetic | IMA ADPCM audio encoder and decoder with predictor/index state. | 64-sample cycle equivalence | `LicenseRef-OpenCores-Permissive` |
| [tiny_spi](projects/communication/tiny_spi) | Communication | Compact Wishbone-controlled SPI master. | Wishbone and 4-byte SPI loopback | `LGPL-2.1-or-later` |
| [rtfsimpleuart](projects/communication/rtfsimpleuart) | Communication | Wishbone UART with 8N1 TX/RX, baud generation, buffering, and interrupts. | Two-byte 8N1 protocol loopback | `BSD-3-Clause` |
| [xge_mac](projects/communication/xge_mac) | Communication | 10-Gigabit Ethernet MAC datapath with XGMII interfaces. | 18-packet XGMII loopback | `LGPL-2.1-or-later` |
| [pit](projects/control/pit) | Control | Programmable interval timer with prescaler, counters, and flags. | Register, prescaler, and timer checks | `BSD-3-Clause` |
| [simple_gpio](projects/control/simple_gpio) | Control | Wishbone GPIO controller with programmable pin direction. | Wishbone and bidirectional GPIO checks | `LicenseRef-OpenCores-Permissive` |
| [simple_pic](projects/control/simple_pic) | Control | Programmable interrupt controller with masking and level/edge modes. | Register and interrupt-mode checks | `LicenseRef-OpenCores-Permissive` |
| [scalable_arbiter](projects/control/scalable_arbiter) | Control | Parameterized round-robin arbiter with one-hot grant and binary select. | One-hot, masking, and fairness checks | `ISC` |
| [cdc_ufifo](projects/interconnect/cdc_ufifo) | Interconnect/CDC | Dual-clock asynchronous FIFO for ordered clock-domain crossing. | Ordered dual-clock CDC transfer | `Apache-2.0` |
| [dma_axi32](projects/interconnect/dma_axi32) | Interconnect/CDC | Multi-channel AXI DMA integration top with a 32-bit datapath. | Elaboration and reset/idle smoke | `LicenseRef-LGPL-Unspecified-Version` |
| [dma_axi64](projects/interconnect/dma_axi64) | Interconnect/CDC | Multi-channel AXI DMA integration top with a 64-bit datapath. | Elaboration and reset/idle smoke | `LicenseRef-LGPL-Unspecified-Version` |
| [versatile_fifo](projects/interconnect/versatile_fifo) | Interconnect/CDC | Bidirectional asynchronous FIFO with Gray-pointer two-flop CDC. | Bidirectional asynchronous transfer | `LGPL-2.1-or-later` |
| [wb_flash](projects/memory/wb_flash) | Memory | Wishbone-to-flash interface with byte lanes and wait-state acknowledgement. | Byte-lane and wait-state checks | `LGPL-2.1-or-later` |
| [configurable_crc_core](projects/security/configurable_crc_core) | Security | Parameterized serial CRC generator/checker. | Per-bit CRC-7 reference scoreboard | `LicenseRef-Unknown` |
| [sha_core](projects/security/sha_core) | Security | SHA-1 and SHA-256 hashing cores. | SHA-1/SHA-256 known-answer tests | `LicenseRef-OpenCores-Permissive` |
| [logicprobe](projects/verification/logicprobe) | Verification | Embedded logic analyzer with capture, readout mux, and UART output. | Capture, read mux, and UART checks | `BSD-2-Clause` |
| [oc_axi_bfm](projects/verification/oc_axi_bfm) | Verification | AXI4-Lite bus-functional master for read/write transaction generation. | AXI4-Lite handshake scenarios | `LicenseRef-Unknown` |

The validation column reports only checks currently automated in this
repository. In particular, `reset/idle smoke` does not imply complete DMA
functional verification or production sign-off.

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

Five projects use `LicenseRef-Unknown` or
`LicenseRef-LGPL-Unspecified-Version`. Perform a rights-holder and legal review
before making the repository public. Keeping a repository private does not by
itself resolve copyright restrictions.
