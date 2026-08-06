// Copyright (c) 2009 Authors and OpenCores.org
// SPDX-License-Identifier: LGPL-2.1-or-later
`default_nettype none

module aes_ip (
  output logic        int_ccf,
  output logic        int_err,
  output logic        dma_req_wr,
  output logic        dma_req_rd,
  output logic        PREADY,
  output logic        PSLVERR,
  output logic [31:0] PRDATA,
  input  logic [3:0]  PADDR,
  input  logic [31:0] PWDATA,
  input  logic        PWRITE,
  input  logic        PENABLE,
  input  logic        PSEL,
  input  logic        PCLK,
  input  logic        PRESETn
);
  logic [31:0] column_data;
  logic [31:0] key_data;
  logic [31:0] iv_data;
  logic        computation_done;
  logic [3:0]  iv_write_enable;
  logic [3:0]  iv_read_select;
  logic [3:0]  key_write_enable;
  logic [1:0]  key_read_select;
  logic [1:0]  data_type;
  logic [1:0]  column_address;
  logic [1:0]  operation_mode;
  logic [1:0]  chaining_mode;
  logic        start;
  logic        disable_core;
  logic        column_write;
  logic        column_read;
  logic        first_block;

  assign PREADY  = 1'b1;
  assign PSLVERR = 1'b0;

  host_interface u_host_interface (
    .key_en(key_write_enable), .col_addr(column_address),
    .col_wr_en(column_write), .col_rd_en(column_read),
    .key_sel(key_read_select), .iv_en(iv_write_enable),
    .iv_sel(iv_read_select), .int_ccf, .int_err,
    .chmod(chaining_mode), .mode(operation_mode), .data_type,
    .disable_core, .first_block, .dma_req_wr, .dma_req_rd,
    .start_core(start), .PRDATA, .PADDR, .PWDATA(PWDATA[12:0]),
    .PWRITE, .PENABLE, .PSEL, .PCLK, .PRESETn,
    .key_bus(key_data), .col_bus(column_data), .iv_bus(iv_data),
    .ccf_set(computation_done)
  );

  aes_core u_aes_core (
    .col_out(column_data), .key_out(key_data), .iv_out(iv_data),
    .end_aes(computation_done), .bus_in(PWDATA),
    .iv_en(iv_write_enable), .iv_sel_rd(iv_read_select),
    .key_en(key_write_enable), .key_sel_rd(key_read_select),
    .data_type, .addr(column_address), .op_mode(operation_mode),
    .aes_mode(chaining_mode), .start, .disable_core,
    .write_en(column_write), .read_en(column_read), .first_block,
    .rst_n(PRESETn), .clk(PCLK)
  );
endmodule

`default_nettype wire
