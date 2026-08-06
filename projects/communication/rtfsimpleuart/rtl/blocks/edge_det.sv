// Copyright (c) 2007, 2013 Robert Finch
// SPDX-License-Identifier: BSD-3-Clause
`default_nettype none

module edge_det (
  input  logic rst,
  input  logic clk,
  input  logic ce,
  input  logic i,
  output logic pe,
  output logic ne,
  output logic ee
);
  logic delayed;

  always_ff @(posedge clk) begin
    if (rst) begin
      delayed <= 1'b0;
    end else if (ce) begin
      delayed <= i;
    end
  end

  always_comb begin
    pe = ~delayed & i;
    ne = delayed & ~i;
    ee = delayed ^ i;
  end
endmodule

`default_nettype wire
