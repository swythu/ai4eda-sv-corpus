# versatile_fifo IP Card

Generated from the canonical IP-ETG. Review `ORIGIN.yml` and retained source
headers before reuse.

| Field | Value |
|---|---|
| Category | `interconnect` |
| Release status | `source_released` |
| Quality level | `Q2` |
| Modules | 2 |
| Instances | 2 |
| Task candidates | 11 |
| Protocol candidate | FIFO |
| Clock candidates | a_clk, b_clk, read_clk, write_clk |
| Reset candidates | a_rst, b_rst, read_reset, write_reset |
| Graph SHA-256 | `44749d88878b9fd933cfe77c220af201ff378f7f7ba14344c8748b1e4b2a20fd` |

## Modules

- `async_fifo_core`
- `async_fifo_dw_simplex_top`

## Evidence boundary

This card summarizes open-source compile/lint/simulation evidence. It does not
claim formal equivalence, PPA signoff, CDC signoff, or production readiness.
Automatically inferred semantic annotations remain review candidates.
