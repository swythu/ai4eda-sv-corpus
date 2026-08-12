// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module fir_filter #(
  parameter int W = 12,
  parameter int CW = 12,
  parameter int OW = 28,
  parameter logic signed [CW-1:0] C0 = 1,
  parameter logic signed [CW-1:0] C1 = 2,
  parameter logic signed [CW-1:0] C2 = 3,
  parameter logic signed [CW-1:0] C3 = 4
) (
  input  logic                          clk_i,
  input  logic                          rst_ni,
  input  logic                          valid_i,
  input  logic signed [W-1:0]  sample_i,
  output logic                          valid_o,
  output logic signed [OW-1:0] sample_o
);
  logic signed [W-1:0] delay_1_q, delay_2_q, delay_3_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      delay_1_q <= '0;
      delay_2_q <= '0;
      delay_3_q <= '0;
      sample_o  <= '0;
      valid_o   <= 1'b0;
    end else begin
      valid_o <= valid_i;
      if (valid_i) begin
        sample_o <= sample_i * C0 + delay_1_q * C1 + delay_2_q * C2 + delay_3_q * C3;
        delay_3_q <= delay_2_q;
        delay_2_q <= delay_1_q;
        delay_1_q <= sample_i;
      end
    end
  end
endmodule
`default_nettype wire
