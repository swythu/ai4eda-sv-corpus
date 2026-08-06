// Copyright (c) 2011, 2013, 2015 Robert Finch
// SPDX-License-Identifier: BSD-3-Clause
`default_nettype none

module rtfSimpleUartRx #(
  parameter int unsigned SamplerStyle = 0
) (
  input  logic       rst_i,
  input  logic       clk_i,
  input  logic       cyc_i,
  input  logic       stb_i,
  output logic       ack_o,
  input  logic       we_i,
  output logic [7:0] dat_o,
  input  logic       cs_i,
  input  logic       baud16x_ce,
  input  logic       baud8x,
  input  logic       clear,
  input  logic       rxd,
  output logic       data_present,
  output logic       frame_err,
  output logic       overrun
);
  typedef enum logic [1:0] {IDLE, START, DATA, STOP} rx_state_t;
  rx_state_t state;

  logic [1:0] rxd_sync;
  logic [7:0] shift_reg;
  logic [7:0] data_reg;
  logic [3:0] sample_period;
  logic [3:0] tick_count;
  logic [2:0] bit_count;
  logic       sampled_rxd;

  assign sampled_rxd = rxd_sync[1];
  assign ack_o = cyc_i & stb_i & cs_i;
  assign dat_o = (ack_o && !we_i) ? data_reg : 8'h00;

  initial assert (SamplerStyle <= 1)
    else $fatal(1, "SamplerStyle must be 0 or 1");

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      rxd_sync <= 2'b11;
    end else begin
      rxd_sync <= {rxd_sync[0], rxd};
    end
  end

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      state        <= IDLE;
      shift_reg    <= '0;
      data_reg     <= '0;
      sample_period <= 4'd15;
      tick_count   <= '0;
      bit_count    <= '0;
      data_present <= 1'b0;
      frame_err    <= 1'b0;
      overrun      <= 1'b0;
    end else begin
      if (clear) begin
        state        <= IDLE;
        data_present <= 1'b0;
        frame_err    <= 1'b0;
        overrun      <= 1'b0;
      end else begin
        if (ack_o && !we_i) begin
          data_present <= 1'b0;
        end

        if (baud16x_ce) begin
          unique case (state)
            IDLE: begin
              if (!sampled_rxd) begin
                sample_period <= baud8x ? 4'd7 : 4'd15;
                tick_count    <= baud8x ? 4'd3 : 4'd7;
                state         <= START;
              end
            end

            START: begin
              if (tick_count == 0) begin
                if (!sampled_rxd) begin
                  tick_count <= sample_period;
                  bit_count  <= '0;
                  state      <= DATA;
                end else begin
                  state <= IDLE;
                end
              end else begin
                tick_count <= tick_count - 1'b1;
              end
            end

            DATA: begin
              if (tick_count == 0) begin
                shift_reg[bit_count] <= sampled_rxd;
                tick_count <= sample_period;
                if (bit_count == 3'd7) begin
                  state <= STOP;
                end else begin
                  bit_count <= bit_count + 1'b1;
                end
              end else begin
                tick_count <= tick_count - 1'b1;
              end
            end

            STOP: begin
              if (tick_count == 0) begin
                frame_err <= ~sampled_rxd;
                if (data_present) begin
                  overrun <= 1'b1;
                end else begin
                  data_reg     <= shift_reg;
                  data_present <= 1'b1;
                end
                state <= IDLE;
              end else begin
                tick_count <= tick_count - 1'b1;
              end
            end

            default: state <= IDLE;
          endcase
        end
      end
    end
  end
endmodule

`default_nettype wire
