// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module reset_synchronizer #(
  parameter int Stages = 2
) (
  input  logic clk_i,
  input  logic async_rst_ni,
  output logic sync_rst_ni
);
  (* async_reg = "true" *) logic [Stages-1:0] synchronizer_q;

  initial begin
    if (Stages < 2) $fatal(1, "Stages must be at least two");
  end

  always_ff @(posedge clk_i or negedge async_rst_ni) begin
    if (!async_rst_ni) synchronizer_q <= '0;
    else               synchronizer_q <= {synchronizer_q[Stages-2:0], 1'b1};
  end

  assign sync_rst_ni = synchronizer_q[Stages-1];
endmodule
`default_nettype wire
