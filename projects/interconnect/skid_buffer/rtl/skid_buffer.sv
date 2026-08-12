// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module skid_buffer #(
  parameter int Width = 32
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  input  logic             clear_i,
  input  logic [Width-1:0] data_i,
  input  logic             valid_i,
  output logic             ready_o,
  output logic [Width-1:0] data_o,
  output logic             valid_o,
  input  logic             ready_i
);
  logic [Width-1:0] data_q, skid_q;
  logic [1:0] count_q;
  logic push, pop;

  assign ready_o = count_q < 2;
  assign valid_o = count_q != 0;
  assign data_o  = data_q;
  assign push = valid_i && ready_o;
  assign pop  = valid_o && ready_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      count_q <= '0;
      data_q  <= '0;
      skid_q  <= '0;
    end else if (clear_i) begin
      count_q <= '0;
    end else begin
      unique case ({push, pop})
        2'b10: begin
          if (count_q == 0) data_q <= data_i;
          else              skid_q <= data_i;
          count_q <= count_q + 1'b1;
        end
        2'b01: begin
          data_q  <= skid_q;
          count_q <= count_q - 1'b1;
        end
        2'b11: begin
          if (count_q == 1) begin
            data_q <= data_i;
          end else begin
            data_q <= skid_q;
            skid_q <= data_i;
          end
        end
        default: count_q <= count_q;
      endcase
    end
  end
endmodule
`default_nettype wire
