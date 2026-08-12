# Validation snapshot

- Date: 2026-08-08
- Result: 40/40 projects passed locally
- Simulator: Icarus Verilog 12.0 stable
- Linter: Verilator 4.038
- Checks: compilation, project self-checking simulation, and zero lint errors
- IP-ETG quality: 39 Q2 and 1 Q3 (`ready_valid_fifo`, 10/10 mutants killed)
- DMA scope: APB control-plane oracle plus idle AXI invariants; payload movement remains unverified
- Task candidates: 389, with 61 frozen records withheld from pre-experiment public export

This snapshot is regression evidence, not formal equivalence, synthesis sign-off,
timing closure, CDC sign-off, or production qualification. Generated binaries and
machine-specific logs are intentionally excluded from Git.
