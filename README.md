# AI4EDA SystemVerilog Corpus

[English](README.md) | [简体中文](README_zh-CN.md)

A provenance-first collection of OpenCores, fixed-revision OpenTitan-derived,
and repository-authored HDL projects organized as synthesizable SystemVerilog
and validated with self-checking simulations.

The repository is also the canonical data source for project-level IP
Engineering Task Graphs (IP-ETGs). Each graph connects hierarchy, interfaces,
clock/reset candidates, verification obligations, tool evidence, and public
engineering tasks. See the [dataset card](DATASET_CARD.md) and
[schema documentation](docs/schema.md).

## Purpose

This repository is intended to support future AI4EDA research and engineering
by building a standardized, traceable, and executable SystemVerilog dataset.
Its original corpus came from OpenCores and is complemented by license-clear
OpenTitan derivatives and repository-authored capability IP. The dataset preserves provenance
and copyright information while organizing refactored RTL, transformation
patches, metadata, and reproducible verification assets in a consistent form.

Potential uses include RTL code generation and repair, hierarchy and interface
understanding, IP retrieval and reuse, verification generation, model training,
and benchmark evaluation. Here, "standardized" describes this repository's
dataset schema and SystemVerilog normalization goals; it does not imply IEEE,
Accellera, or other official certification.

## Scope

- 40 Q2-or-higher projects with compile, lint, and self-checking simulation evidence.
- 389 answer-free task candidates and 40 reproducible project-level IP-ETGs.
- 28 projects are `source_released`; 12 are metadata-only or pending license review.
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
| [pid_controller](projects/arithmetic/pid_controller) | Arithmetic | Wishbone PID controller with signed P/I/D state and overflow reporting. | Sequential mathematical reference checks | `LicenseRef-Unknown` |
| [pipelined_fft_64](projects/arithmetic/pipelined_fft_64) | Arithmetic | 64-point fully pipelined complex FFT with dual normalization stages. | Bit-exact golden match and spectral peak | `LicenseRef-OpenCores-Permissive` |
| [pipelined_mac](projects/arithmetic/pipelined_mac) | Arithmetic | Signed ready/valid multiply-accumulate pipeline. | Latency, stall, clear, and signed arithmetic checks | `Apache-2.0` |
| [fir_filter](projects/arithmetic/fir_filter) | Arithmetic | Parameterized four-tap streaming FIR filter. | Impulse and sample-sequence reference checks | `Apache-2.0` |
| [tiny_spi](projects/communication/tiny_spi) | Communication | Compact Wishbone-controlled SPI master. | Wishbone and 4-byte SPI loopback | `LGPL-2.1-or-later` |
| [rtfsimpleuart](projects/communication/rtfsimpleuart) | Communication | Wishbone UART with 8N1 TX/RX, baud generation, buffering, and interrupts. | Two-byte 8N1 protocol loopback | `BSD-3-Clause` |
| [xge_mac](projects/communication/xge_mac) | Communication | 10-Gigabit Ethernet MAC datapath with XGMII interfaces. | 18-packet XGMII loopback | `LGPL-2.1-or-later` |
| [i2c](projects/communication/i2c) | Communication | WISHBONE revB.2 multimaster I2C master with byte/bit controllers. | Register, slave write/read-back, and NACK checks | `LicenseRef-OpenCores-Permissive` |
| [uart2bus](projects/communication/uart2bus) | Communication | UART-to-internal-bus bridge with ASCII and binary command parsers. | ASCII write/read-back over 8N1 serial | `BSD-2-Clause` |
| [pit](projects/control/pit) | Control | Programmable interval timer with prescaler, counters, and flags. | Register, prescaler, and timer checks | `BSD-3-Clause` |
| [simple_gpio](projects/control/simple_gpio) | Control | Wishbone GPIO controller with programmable pin direction. | Wishbone and bidirectional GPIO checks | `LicenseRef-OpenCores-Permissive` |
| [simple_pic](projects/control/simple_pic) | Control | Programmable interrupt controller with masking and level/edge modes. | Register and interrupt-mode checks | `LicenseRef-OpenCores-Permissive` |
| [scalable_arbiter](projects/control/scalable_arbiter) | Control | Parameterized round-robin arbiter with one-hot grant and binary select. | One-hot, masking, and fairness checks | `ISC` |
| [reset_synchronizer](projects/cdc/reset_synchronizer) | CDC | Asynchronous-assert, synchronous-release reset synchronizer. | Assertion and staged-release checks | `Apache-2.0` |
| [cdc_handshake](projects/cdc/cdc_handshake) | CDC | Two-phase bundled-data CDC handshake. | Ordered transfer and backpressure checks | `Apache-2.0` |
| [apb_register_bank](projects/interconnect/apb_register_bank) | Interconnect | APB4 register bank with byte strobes and decode errors. | APB read/write and error checks | `Apache-2.0` |
| [axi_lite_slice](projects/interconnect/axi_lite_slice) | Interconnect | Five-channel AXI-Lite elastic register slice. | Stall stability and response checks | `Apache-2.0` |
| [cdc_ufifo](projects/interconnect/cdc_ufifo) | Interconnect/CDC | Dual-clock asynchronous FIFO for ordered clock-domain crossing. | Ordered dual-clock CDC transfer | `Apache-2.0` |
| [dma_axi32](projects/interconnect/dma_axi32) | Interconnect/CDC | Multi-channel AXI DMA integration top with a 32-bit datapath. | APB control-plane oracle and idle AXI checks | `LicenseRef-LGPL-Unspecified-Version` |
| [dma_axi64](projects/interconnect/dma_axi64) | Interconnect/CDC | Multi-channel AXI DMA integration top with a 64-bit datapath. | APB control-plane oracle and idle AXI checks | `LicenseRef-LGPL-Unspecified-Version` |
| [ready_valid_fifo](projects/interconnect/ready_valid_fifo) | Interconnect | Parameterized ready/valid FIFO. | Full/empty, order, stability, and streaming checks | `Apache-2.0` |
| [skid_buffer](projects/interconnect/skid_buffer) | Interconnect | Two-entry elastic skid buffer. | Backpressure and lossless-order checks | `Apache-2.0` |
| [versatile_fifo](projects/interconnect/versatile_fifo) | Interconnect/CDC | Bidirectional asynchronous FIFO with Gray-pointer two-flop CDC. | Bidirectional asynchronous transfer | `LGPL-2.1-or-later` |
| [wishbone_apb_bridge](projects/interconnect/wishbone_apb_bridge) | Interconnect | Single-outstanding Wishbone-to-APB bridge. | Read/write, wait-state, and error checks | `Apache-2.0` |
| [ot_sram_1p](projects/memory/ot_sram_1p) | Memory | Dependency-closed single-port SRAM derivative. | Masked write and read-latency checks | `Apache-2.0` |
| [ot_sram_2p](projects/memory/ot_sram_2p) | Memory | Dependency-closed dual-port SRAM derivative. | Independent-port and collision-policy checks | `Apache-2.0` |
| [register_file](projects/memory/register_file) | Memory | Two-read/one-write register file with optional zero register. | Bypass and hardwired-zero checks | `Apache-2.0` |
| [ecc_ram](projects/memory/ecc_ram) | Memory | 32-bit SECDED RAM with validation fault injection. | Correctable and uncorrectable fault checks | `Apache-2.0` |
| [wb_flash](projects/memory/wb_flash) | Memory | Wishbone-to-flash interface with byte lanes and wait-state acknowledgement. | Byte-lane and wait-state checks | `LGPL-2.1-or-later` |
| [rv32i_microcore](projects/processor/rv32i_microcore) | Processor | Educational multi-cycle RV32I subset core. | Arithmetic, load/store, branch, x0, and trap checks | `Apache-2.0` |
| [configurable_crc_core](projects/security/configurable_crc_core) | Security | Parameterized serial CRC generator/checker. | Per-bit CRC-7 reference scoreboard | `LicenseRef-Unknown` |
| [apbtoaes128](projects/security/apbtoaes128) | Security | APB-connected AES-128 accelerator supporting ECB, CBC, and CTR modes. | Known-answer, suspend, and DMA tests | `LGPL-2.1-or-later` |
| [sha_core](projects/security/sha_core) | Security | SHA-1 and SHA-256 hashing cores. | SHA-1/SHA-256 known-answer tests | `LicenseRef-OpenCores-Permissive` |
| [logicprobe](projects/verification/logicprobe) | Verification | Embedded logic analyzer with capture, readout mux, and UART output. | Capture, read mux, and UART checks | `BSD-2-Clause` |
| [oc_axi_bfm](projects/verification/oc_axi_bfm) | Verification | AXI4-Lite bus-functional master for read/write transaction generation. | AXI4-Lite handshake scenarios | `LicenseRef-Unknown` |
| [ready_valid_checker](projects/verification/ready_valid_checker) | Verification | Synthesizable ready/valid protocol checker. | Stability violation detection and clear checks | `Apache-2.0` |
| [video_stream_scaler](projects/video/video_stream_scaler) | Video | Streaming video scaler with bilinear/nearest modes and runtime resolution control. | Identity and 2x-downsample golden streams | `LGPL-2.1-or-later` |

The validation column reports only checks currently automated in this
repository. The DMA oracle covers control-plane register behavior and idle AXI
invariants, not payload movement, error recovery, or production sign-off.

## Layout

    projects/<category>/<project>/
    LICENSES/
    NOTICE.md
    manifest.json
    EXCLUDED_PROJECTS.json

## Verify

Install Icarus Verilog and Verilator, then run:

    python3 tools/run_all.py

Install the graph-tooling dependencies and validate every IP-ETG:

    python3 -m pip install -r requirements-dev.txt
    python3 tools/run_ipgraph_checks.py

The current local `v0.1.0` release candidate contains 40 schema-valid,
reproducible IP-ETGs and 389 answer-free task candidates. All 40 projects are
at least Q2. Project splits are hash-locked at 24/6/5/5 for train/dev/public/frozen, and
61 frozen task records are excluded from the public pre-experiment export.
One train project currently reaches Q3 through a 10/10 mutation campaign;
the remaining projects and task candidates stay at Q2 unless promoted by evidence.
These records are not Q3/Q4 paper training data: mutation validation and the
required independent expert review remain pending.

### Release-candidate quality and release gates

<!-- BEGIN GENERATED PROJECT STATUS -->
| Project | Category | Quality | Release status | Task candidates |
|---|---|---:|---|---:|
| [apb_register_bank](projects/interconnect/apb_register_bank) | interconnect | Q2 | `source_released` | 7 |
| [apbtoaes128](projects/security/apbtoaes128) | security | Q2 | `source_released` | 16 |
| [axi_lite_slice](projects/interconnect/axi_lite_slice) | interconnect | Q2 | `source_released` | 7 |
| [binary_to_bcd](projects/arithmetic/binary_to_bcd) | arithmetic | Q2 | `source_released` | 11 |
| [cdc_handshake](projects/cdc/cdc_handshake) | cdc | Q2 | `source_released` | 7 |
| [cdc_ufifo](projects/interconnect/cdc_ufifo) | interconnect | Q2 | `source_released` | 7 |
| [configurable_crc_core](projects/security/configurable_crc_core) | security | Q2 | `metadata_only` | 7 |
| [dma_axi32](projects/interconnect/dma_axi32) | interconnect | Q2 | `metadata_only` | 16 |
| [dma_axi64](projects/interconnect/dma_axi64) | interconnect | Q2 | `metadata_only` | 16 |
| [ecc_ram](projects/memory/ecc_ram) | memory | Q2 | `source_released` | 7 |
| [fir_filter](projects/arithmetic/fir_filter) | arithmetic | Q2 | `source_released` | 7 |
| [fixed_point_arithmetic_parameterized](projects/arithmetic/fixed_point_arithmetic_parameterized) | arithmetic | Q2 | `metadata_only` | 11 |
| [i2c](projects/communication/i2c) | communication | Q2 | `metadata_only` | 11 |
| [ima_adpcm_enc_dec](projects/arithmetic/ima_adpcm_enc_dec) | arithmetic | Q2 | `metadata_only` | 11 |
| [logicprobe](projects/verification/logicprobe) | verification | Q2 | `source_released` | 11 |
| [oc_axi_bfm](projects/verification/oc_axi_bfm) | verification | Q2 | `metadata_only` | 7 |
| [ot_sram_1p](projects/memory/ot_sram_1p) | memory | Q2 | `source_released` | 7 |
| [ot_sram_2p](projects/memory/ot_sram_2p) | memory | Q2 | `source_released` | 7 |
| [pid_controller](projects/arithmetic/pid_controller) | arithmetic | Q2 | `metadata_only` | 7 |
| [pipelined_fft_64](projects/arithmetic/pipelined_fft_64) | arithmetic | Q2 | `metadata_only` | 16 |
| [pipelined_mac](projects/arithmetic/pipelined_mac) | arithmetic | Q2 | `source_released` | 15 |
| [pit](projects/control/pit) | control | Q2 | `source_released` | 11 |
| [ready_valid_checker](projects/verification/ready_valid_checker) | verification | Q2 | `source_released` | 7 |
| [ready_valid_fifo](projects/interconnect/ready_valid_fifo) | interconnect | Q3 | `source_released` | 7 |
| [register_file](projects/memory/register_file) | memory | Q2 | `source_released` | 7 |
| [reset_synchronizer](projects/cdc/reset_synchronizer) | cdc | Q2 | `source_released` | 7 |
| [rtfsimpleuart](projects/communication/rtfsimpleuart) | communication | Q2 | `source_released` | 11 |
| [rv32i_microcore](projects/processor/rv32i_microcore) | processor | Q2 | `source_released` | 15 |
| [scalable_arbiter](projects/control/scalable_arbiter) | control | Q2 | `source_released` | 11 |
| [sha_core](projects/security/sha_core) | security | Q2 | `metadata_only` | 11 |
| [simple_gpio](projects/control/simple_gpio) | control | Q2 | `metadata_only` | 7 |
| [simple_pic](projects/control/simple_pic) | control | Q2 | `metadata_only` | 7 |
| [skid_buffer](projects/interconnect/skid_buffer) | interconnect | Q2 | `source_released` | 7 |
| [tiny_spi](projects/communication/tiny_spi) | communication | Q2 | `source_released` | 7 |
| [uart2bus](projects/communication/uart2bus) | communication | Q2 | `source_released` | 11 |
| [versatile_fifo](projects/interconnect/versatile_fifo) | interconnect | Q2 | `source_released` | 11 |
| [video_stream_scaler](projects/video/video_stream_scaler) | video | Q2 | `source_released` | 11 |
| [wb_flash](projects/memory/wb_flash) | memory | Q2 | `source_released` | 7 |
| [wishbone_apb_bridge](projects/interconnect/wishbone_apb_bridge) | interconnect | Q2 | `source_released` | 7 |
| [xge_mac](projects/communication/xge_mac) | communication | Q2 | `source_released` | 16 |
<!-- END GENERATED PROJECT STATUS -->

Generated example views are available for
[scalable_arbiter](docs/generated/scalable_arbiter.html),
[i2c](docs/generated/i2c.html), and
[dma_axi32](docs/generated/dma_axi32.html).

Environment overrides are supported:

    IVERILOG=/path/iverilog VVP=/path/vvp VERILATOR=/path/verilator python3 tools/run_all.py

`run_all.py` discovers tools from `PATH`, the parent workspace's `.tools`
directory, or those absolute environment-variable paths. To stage a
license-gated public tree outside this working repository, run:

    python3 tools/export_release.py --output /tmp/ai4eda-sv-corpus-public

Only `source_released` entries include full project files in that tree.
`pending_review` and `metadata_only` entries retain catalog, graph, and task
metadata but exclude RTL, includes, testbenches, patches, and validation logs.

## Licensing

This is a multi-license repository. The top-level LICENSE only describes the
licensing split; it does not relicense upstream HDL. Read NOTICE.md,
LICENSES/, ORIGIN.yml, and retained file headers.

Release status is tracked per project as `source_released`, `metadata_only`, or
`pending_review`. A disclaimer does not create redistribution rights; consult
[LICENSE_POLICY.md](LICENSE_POLICY.md) and the machine-readable audit before
building a public release artifact.

## Publication warning

Six projects use `LicenseRef-Unknown` or
`LicenseRef-LGPL-Unspecified-Version`, and six additional projects use a custom
OpenCores license reference that still requires file-scope review. Perform a
rights-holder and legal review before releasing those source payloads. Keeping
a repository private does not by itself resolve copyright restrictions.
