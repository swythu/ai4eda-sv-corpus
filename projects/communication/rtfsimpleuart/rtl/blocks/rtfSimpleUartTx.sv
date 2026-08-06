// Copyright (c) 2011, 2013 Robert Finch
// SPDX-License-Identifier: BSD-3-Clause
`default_nettype none

module rtfSimpleUartTx (
  input  logic       rst_i,
  input  logic       clk_i,
  input  logic       cyc_i,
  input  logic       stb_i,
  output logic       ack_o,
  input  logic       we_i,
  input  logic [7:0] dat_i,
  input  logic       cs_i,
  input  logic       baud16x_ce,
  input  logic       baud8x,
  input  logic       cts,
  output logic       txd,
  output logic       empty,
  output logic       txc
);
  logic [7:0] holding_data;
  logic [9:0] shift_reg;
  logic [3:0] ticks_per_bit;
  logic [3:0] tick_count;
  logic [3:0] bit_count;
  logic       busy;

  assign ack_o = cyc_i & stb_i & cs_i;
  assign txd   = busy ? shift_reg[0] : 1'b1;
  assign txc   = ~busy & empty;

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      holding_data  <= '0;
      shift_reg     <= '1;
      ticks_per_bit <= 4'd15;
      tick_count    <= '0;
      bit_count     <= '0;
      busy          <= 1'b0;
      empty         <= 1'b1;
    end else begin
      if (ack_o && we_i && empty) begin
        holding_data <= dat_i;
        empty        <= 1'b0;
      end

      if (baud16x_ce) begin
        if (!busy) begin
          if (!empty && cts) begin
            shift_reg     <= {1'b1, holding_data, 1'b0};
            ticks_per_bit <= baud8x ? 4'd7 : 4'd15;
            tick_count    <= '0;
            bit_count     <= '0;
            busy          <= 1'b1;
            empty         <= 1'b1;
          end
        end else if (tick_count == ticks_per_bit) begin
          tick_count <= '0;
          if (bit_count == 4'd9) begin
            busy      <= 1'b0;
            shift_reg <= '1;
          end else begin
            shift_reg <= {1'b1, shift_reg[9:1]};
            bit_count <= bit_count + 1'b1;
          end
        end else begin
          tick_count <= tick_count + 1'b1;
        end
      end
    end
  end
endmodule

`default_nettype wire
