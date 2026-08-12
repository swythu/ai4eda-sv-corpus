// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module ready_valid_checker #(
  parameter int Width = 32
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic             clear_i,
  input  logic             valid_i,
  input  logic             ready_i,
  input  logic [Width-1:0] data_i,
  output logic             error_o,
  output logic [31:0]      transfer_count_o
);
  logic stalled_q;
  logic [Width-1:0] held_data_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      error_o          <= 1'b0;
      stalled_q        <= 1'b0;
      held_data_q      <= '0;
      transfer_count_o <= '0;
    end else begin
      if (clear_i) error_o <= 1'b0;
      if (stalled_q && (!valid_i || (data_i != held_data_q))) error_o <= 1'b1;
      if (valid_i && !ready_i) begin
        stalled_q   <= 1'b1;
        held_data_q <= data_i;
      end else begin
        stalled_q <= 1'b0;
      end
      if (valid_i && ready_i) transfer_count_o <= transfer_count_o + 1'b1;
    end
  end
endmodule
`default_nettype wire
