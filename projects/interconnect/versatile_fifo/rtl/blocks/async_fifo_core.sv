// Copyright (c) 2009 Authors and OpenCores.org
// SPDX-License-Identifier: LGPL-2.1-or-later
`default_nettype none

module async_fifo_core #(
  parameter int unsigned DATA_WIDTH = 18,
  parameter int unsigned ADDR_WIDTH = 4
) (
  input  logic                  write_clk,
  input  logic                  write_reset,
  input  logic [DATA_WIDTH-1:0] write_data,
  input  logic                  write_enable,
  output logic                  full,
  input  logic                  read_clk,
  input  logic                  read_reset,
  output logic [DATA_WIDTH-1:0] read_data,
  input  logic                  read_enable,
  output logic                  empty
);
  localparam int unsigned PTR_WIDTH = ADDR_WIDTH + 1;
  localparam int unsigned DEPTH = 1 << ADDR_WIDTH;

  logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];
  logic [PTR_WIDTH-1:0] write_binary, write_binary_next;
  logic [PTR_WIDTH-1:0] write_gray, write_gray_next;
  logic [PTR_WIDTH-1:0] read_binary, read_binary_next;
  logic [PTR_WIDTH-1:0] read_gray, read_gray_next;
  (* async_reg = "true" *) logic [PTR_WIDTH-1:0] read_gray_sync1, read_gray_sync2;
  (* async_reg = "true" *) logic [PTR_WIDTH-1:0] write_gray_sync1, write_gray_sync2;
  logic full_next, empty_next;

  initial begin
    assert (ADDR_WIDTH >= 2) else $fatal(1, "async_fifo_core requires ADDR_WIDTH >= 2");
    assert (DATA_WIDTH >= 1) else $fatal(1, "async_fifo_core requires DATA_WIDTH >= 1");
  end

  always_comb begin
    write_binary_next = write_binary +
      {{(PTR_WIDTH-1){1'b0}}, (write_enable && !full)};
    write_gray_next = (write_binary_next >> 1) ^ write_binary_next;
    full_next = write_gray_next == {
      ~read_gray_sync2[PTR_WIDTH-1:PTR_WIDTH-2],
       read_gray_sync2[PTR_WIDTH-3:0]
    };

    read_binary_next = read_binary +
      {{(PTR_WIDTH-1){1'b0}}, (read_enable && !empty)};
    read_gray_next = (read_binary_next >> 1) ^ read_binary_next;
    empty_next = read_gray_next == write_gray_sync2;
  end

  always_ff @(posedge write_clk or posedge write_reset) begin
    if (write_reset) begin
      write_binary <= '0;
      write_gray   <= '0;
      full         <= 1'b0;
    end else begin
      write_binary <= write_binary_next;
      write_gray   <= write_gray_next;
      full         <= full_next;
      if (write_enable && !full) begin
        memory[write_binary[ADDR_WIDTH-1:0]] <= write_data;
      end
    end
  end

  always_ff @(posedge read_clk or posedge read_reset) begin
    if (read_reset) begin
      read_binary <= '0;
      read_gray   <= '0;
      read_data   <= '0;
      empty       <= 1'b1;
    end else begin
      read_binary <= read_binary_next;
      read_gray   <= read_gray_next;
      empty       <= empty_next;
      if (read_enable && !empty) begin
        read_data <= memory[read_binary[ADDR_WIDTH-1:0]];
      end
    end
  end

  always_ff @(posedge write_clk or posedge write_reset) begin
    if (write_reset) begin
      read_gray_sync1 <= '0;
      read_gray_sync2 <= '0;
    end else begin
      read_gray_sync1 <= read_gray;
      read_gray_sync2 <= read_gray_sync1;
    end
  end

  always_ff @(posedge read_clk or posedge read_reset) begin
    if (read_reset) begin
      write_gray_sync1 <= '0;
      write_gray_sync2 <= '0;
    end else begin
      write_gray_sync1 <= write_gray;
      write_gray_sync2 <= write_gray_sync1;
    end
  end
endmodule

`default_nettype wire
