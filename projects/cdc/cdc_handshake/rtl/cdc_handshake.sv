// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module cdc_handshake #(
  parameter int Width = 32
) (
  input  logic             src_clk_i,
  input  logic             src_rst_ni,
  input  logic [Width-1:0] src_data_i,
  input  logic             src_valid_i,
  output logic             src_ready_o,
  input  logic             dst_clk_i,
  input  logic             dst_rst_ni,
  output logic [Width-1:0] dst_data_o,
  output logic             dst_valid_o,
  input  logic             dst_ready_i
);
  logic request_q, acknowledge_q, consumed_q;
  logic [Width-1:0] held_data_q;
  (* async_reg = "true" *) logic [1:0] acknowledge_sync_q;
  (* async_reg = "true" *) logic [1:0] request_sync_q;

  // held_data_q remains stable from request launch until acknowledgement.
  assign src_ready_o = request_q == acknowledge_sync_q[1];
  assign dst_valid_o = request_sync_q[1] != consumed_q;
  assign dst_data_o  = held_data_q;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      request_q          <= 1'b0;
      held_data_q        <= '0;
      acknowledge_sync_q <= '0;
    end else begin
      acknowledge_sync_q <= {acknowledge_sync_q[0], acknowledge_q};
      if (src_valid_i && src_ready_o) begin
        held_data_q <= src_data_i;
        request_q   <= !request_q;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      request_sync_q <= '0;
      consumed_q     <= 1'b0;
      acknowledge_q  <= 1'b0;
    end else begin
      request_sync_q <= {request_sync_q[0], request_q};
      if (dst_valid_o && dst_ready_i) begin
        consumed_q    <= request_sync_q[1];
        acknowledge_q <= request_sync_q[1];
      end
    end
  end
endmodule
`default_nettype wire
