# xge_mac IP Card

Generated from the canonical IP-ETG. Review `ORIGIN.yml` and retained source
headers before reuse.

| Field | Value |
|---|---|
| Category | `communication` |
| Release status | `source_released` |
| Quality level | `Q2` |
| Modules | 24 |
| Instances | 29 |
| Task candidates | 16 |
| Protocol candidate | Wishbone |
| Clock candidates | clk, clk_156m25, clk_xgmii_rx, clk_xgmii_tx, wb_clk_i |
| Reset candidates | reset_156m25_n, reset_n, reset_xgmii_rx_n, reset_xgmii_tx_n |
| Graph SHA-256 | `282ebf0e6259cb029bda4fa185f349e22d8e5e626b98d491ed45b47b13ff8a72` |

## Modules

- `fault_sm`
- `generic_fifo`
- `generic_fifo_ctrl`
- `generic_mem_medium`
- `generic_mem_small`
- `meta_sync`
- `meta_sync_single`
- `rx_data_fifo`
- `rx_dequeue`
- `rx_enqueue`
- `rx_hold_fifo`
- `rx_stats_fifo`
- `stats`
- `stats_sm`
- `sync_clk_core`
- `sync_clk_wb`
- `sync_clk_xgmii_tx`
- `tx_data_fifo`
- `tx_dequeue`
- `tx_enqueue`
- `tx_hold_fifo`
- `tx_stats_fifo`
- `wishbone_if`
- `xge_mac`

## Evidence boundary

This card summarizes open-source compile/lint/simulation evidence. It does not
claim formal equivalence, PPA signoff, CDC signoff, or production readiness.
Automatically inferred semantic annotations remain review candidates.
