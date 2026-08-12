# apbtoaes128 IP Card

Generated from the canonical IP-ETG. Review `ORIGIN.yml` and retained source
headers before reuse.

| Field | Value |
|---|---|
| Category | `security` |
| Release status | `source_released` |
| Quality level | `Q2` |
| Modules | 11 |
| Instances | 11 |
| Task candidates | 16 |
| Protocol candidate | APB |
| Clock candidates | PCLK, clk |
| Reset candidates | PRESETn, rst_n |
| Graph SHA-256 | `3e803957091aa9f10409b629232899a0d75f8113f9af9f288273e0d6f8b9ee5b` |

## Modules

- `aes_core`
- `aes_ip`
- `control_unit`
- `data_swap`
- `datapath`
- `host_interface`
- `key_expander`
- `mix_columns`
- `sBox`
- `sBox_8`
- `shift_rows`

## Evidence boundary

This card summarizes open-source compile/lint/simulation evidence. It does not
claim formal equivalence, PPA signoff, CDC signoff, or production readiness.
Automatically inferred semantic annotations remain review candidates.
