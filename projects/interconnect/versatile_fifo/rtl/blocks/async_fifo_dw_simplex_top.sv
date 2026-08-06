// Copyright (c) 2009 Authors and OpenCores.org
// SPDX-License-Identifier: LGPL-2.1-or-later
`default_nettype none

module async_fifo_dw_simplex_top #(
  parameter int unsigned data_width = 18,
  parameter int unsigned addr_width = 4
) (
  input  logic                  a_clk,
  input  logic                  a_rst,
  input  logic [data_width-1:0] a_d,
  input  logic                  a_wr,
  output logic                  a_fifo_full,
  output logic [data_width-1:0] a_q,
  input  logic                  a_rd,
  output logic                  a_fifo_empty,
  input  logic                  b_clk,
  input  logic                  b_rst,
  input  logic [data_width-1:0] b_d,
  input  logic                  b_wr,
  output logic                  b_fifo_full,
  output logic [data_width-1:0] b_q,
  input  logic                  b_rd,
  output logic                  b_fifo_empty
);
  async_fifo_core #(
    .DATA_WIDTH(data_width), .ADDR_WIDTH(addr_width)
  ) u_a_to_b (
    .write_clk(a_clk), .write_reset(a_rst), .write_data(a_d),
    .write_enable(a_wr), .full(a_fifo_full),
    .read_clk(b_clk), .read_reset(b_rst), .read_data(b_q),
    .read_enable(b_rd), .empty(b_fifo_empty)
  );

  async_fifo_core #(
    .DATA_WIDTH(data_width), .ADDR_WIDTH(addr_width)
  ) u_b_to_a (
    .write_clk(b_clk), .write_reset(b_rst), .write_data(b_d),
    .write_enable(b_wr), .full(b_fifo_full),
    .read_clk(a_clk), .read_reset(a_rst), .read_data(a_q),
    .read_enable(a_rd), .empty(a_fifo_empty)
  );
endmodule

`default_nettype wire
