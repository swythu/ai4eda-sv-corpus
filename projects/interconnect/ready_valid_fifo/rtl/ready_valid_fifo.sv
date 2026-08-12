// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module ready_valid_fifo #(
  parameter int Width = 32,
  parameter int Depth = 4,
  localparam int AddrWidth  = (Depth <= 1) ? 1 : $clog2(Depth),
  localparam int CountWidth = $clog2(Depth + 1)
) (
  input  logic                  clk_i,
  input  logic                  rst_ni,
  input  logic [Width-1:0]      data_i,
  input  logic                  valid_i,
  output logic                  ready_o,
  output logic [Width-1:0]      data_o,
  output logic                  valid_o,
  input  logic                  ready_i,
  output logic [CountWidth-1:0] usage_o
);
  logic [Width-1:0] memory [0:Depth-1];
  logic [AddrWidth-1:0] read_pointer_q, write_pointer_q;
  logic push, pop;
  localparam logic [CountWidth-1:0] DepthCount = CountWidth'(Depth);
  localparam logic [AddrWidth-1:0] LastAddress = AddrWidth'(Depth - 1);

  assign ready_o = usage_o < DepthCount;
  assign valid_o = usage_o != 0;
  assign data_o  = memory[read_pointer_q];
  assign push = valid_i && ready_o;
  assign pop  = valid_o && ready_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      read_pointer_q  <= '0;
      write_pointer_q <= '0;
      usage_o         <= '0;
    end else begin
      if (push) begin
        memory[write_pointer_q] <= data_i;
        write_pointer_q <= (write_pointer_q == LastAddress) ? '0 : write_pointer_q + 1'b1;
      end
      if (pop) begin
        read_pointer_q <= (read_pointer_q == LastAddress) ? '0 : read_pointer_q + 1'b1;
      end
      unique case ({push, pop})
        2'b10: usage_o <= usage_o + 1'b1;
        2'b01: usage_o <= usage_o - 1'b1;
        default: usage_o <= usage_o;
      endcase
    end
  end
endmodule
`default_nettype wire
