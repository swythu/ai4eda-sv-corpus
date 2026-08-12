// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module pipelined_mac #(
  parameter int W = 16,
  parameter int OW = 40
) (
  input  logic                          clk_i,
  input  logic                          rst_ni,
  input  logic                          ce_i,
  input  logic                          clear_i,
  input  logic                          valid_i,
  input  logic signed [W-1:0]  a_i,
  input  logic signed [W-1:0]  b_i,
  output logic                          valid_o,
  output logic signed [OW-1:0] result_o
);
  localparam int ProductWidth = 2 * W;
  logic signed [ProductWidth-1:0] product_q;
  logic product_valid_q;

  initial begin
    if (OW < ProductWidth) $fatal(1, "OW must hold a full product");
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      product_q       <= '0;
      product_valid_q <= 1'b0;
      result_o        <= '0;
      valid_o         <= 1'b0;
    end else if (ce_i) begin
      product_q       <= a_i * b_i;
      product_valid_q <= valid_i;
      valid_o         <= product_valid_q;
      if (clear_i) begin
        result_o <= '0;
      end else if (product_valid_q) begin
        result_o <= result_o + {{(OW-ProductWidth){product_q[ProductWidth-1]}}, product_q};
      end
    end
  end
endmodule
`default_nettype wire
