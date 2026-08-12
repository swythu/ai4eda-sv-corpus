# dma_axi32 IP Card

Generated from the canonical IP-ETG. Review `ORIGIN.yml` and retained source
headers before reuse.

| Field | Value |
|---|---|
| Category | `interconnect` |
| Release status | `metadata_only` |
| Quality level | `Q2` |
| Modules | 49 |
| Instances | 154 |
| Task candidates | 16 |
| Protocol candidate | AXI |
| Clock candidates | CLK, clk, pclk |
| Reset candidates | reset |
| Graph SHA-256 | `bde01c8b57ac018e083c61e13fdbeeee21e1312c1ed4039454367d20b320b3ae` |

## Modules

- `dma_axi32`
- `dma_axi32_apb_mux`
- `dma_axi32_core0`
- `dma_axi32_core0_arbiter`
- `dma_axi32_core0_axim_cmd`
- `dma_axi32_core0_axim_rd`
- `dma_axi32_core0_axim_rdata`
- `dma_axi32_core0_axim_resp`
- `dma_axi32_core0_axim_timeout`
- `dma_axi32_core0_axim_wdata`
- `dma_axi32_core0_axim_wr`
- `dma_axi32_core0_ch`
- `dma_axi32_core0_ch_calc`
- `dma_axi32_core0_ch_calc_addr`
- `dma_axi32_core0_ch_calc_joint`
- `dma_axi32_core0_ch_calc_size`
- `dma_axi32_core0_ch_empty`
- `dma_axi32_core0_ch_fifo`
- `dma_axi32_core0_ch_fifo_ctrl`
- `dma_axi32_core0_ch_fifo_ptr`
- `dma_axi32_core0_ch_offsets`
- `dma_axi32_core0_ch_outs`
- `dma_axi32_core0_ch_periph_mux`
- `dma_axi32_core0_ch_rd_slicer`
- `dma_axi32_core0_ch_reg`
- `dma_axi32_core0_ch_reg_size`
- `dma_axi32_core0_ch_remain`
- `dma_axi32_core0_ch_wr_slicer`
- `dma_axi32_core0_channels`
- `dma_axi32_core0_channels_apb_mux`
- `dma_axi32_core0_channels_mux`
- `dma_axi32_core0_ctrl`
- `dma_axi32_core0_top`
- `dma_axi32_core0_wdt`
- `dma_axi32_dual_core`
- `dma_axi32_reg`
- `dma_axi32_reg_core0`
- `prgen_delay`
- `prgen_demux8`
- `prgen_fifo`
- `prgen_joint_stall`
- `prgen_min2`
- `prgen_min3`
- `prgen_mux8`
- `prgen_or8`
- `prgen_rawstat`
- `prgen_scatter8_1`
- `prgen_stall`
- `prgen_swap32`

## Evidence boundary

This card summarizes open-source compile/lint/simulation evidence. It does not
claim formal equivalence, PPA signoff, CDC signoff, or production readiness.
Automatically inferred semantic annotations remain review candidates.
