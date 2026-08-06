// Copyright (c) 2011, 2013 Robert Finch
// SPDX-License-Identifier: BSD-3-Clause
`default_nettype none

module rtfSimpleUart #(
  parameter int unsigned pClkFreq = 20_000_000,
  parameter int unsigned pBaud    = 19_200,
  parameter bit          pRts     = 1'b1,
  parameter bit          pDtr     = 1'b1,
  parameter logic [27:0] BASE_ADDR = 28'hFFDC0A0
) (
  input  logic        rst_i,
  input  logic        clk_i,
  input  logic        cyc_i,
  input  logic        stb_i,
  input  logic        we_i,
  input  logic [31:0] adr_i,
  input  logic [7:0]  dat_i,
  output logic [7:0]  dat_o,
  output logic        ack_o,
  output logic        vol_o,
  output logic        irq_o,
  input  logic        cts_ni,
  output logic        rts_no,
  input  logic        dsr_ni,
  input  logic        dcd_ni,
  output logic        dtr_no,
  input  logic        rxd_i,
  output logic        txd_o,
  output logic        data_present_o,
  output logic        baud16_clk
);
  localparam logic [3:0] UART_TRB  = 4'd0;
  localparam logic [3:0] UART_LS   = 4'd1;
  localparam logic [3:0] UART_MS   = 4'd2;
  localparam logic [3:0] UART_IS   = 4'd3;
  localparam logic [3:0] UART_IER  = 4'd4;
  localparam logic [3:0] UART_MC   = 4'd6;
  localparam logic [3:0] UART_CTRL = 4'd7;
  localparam logic [3:0] UART_CLKM1 = 4'd9;
  localparam logic [3:0] UART_CLKM2 = 4'd10;
  localparam logic [3:0] UART_CLKM3 = 4'd11;
  localparam logic [3:0] UART_FC   = 4'd13;
  localparam int unsigned DEFAULT_CLK_MUL =
    (64'd268435456 * pBaud) / pClkFreq;

  logic        cs;
  logic        txrx_select;
  logic [23:0] phase_accumulator;
  logic [23:0] clock_multiplier;
  logic        baud16;
  logic        tx_empty;
  logic        tx_complete;
  logic        rx_present_ie;
  logic        tx_empty_ie;
  logic        dcd_ie;
  logic        hwfc;
  logic [1:0]  cts_sync;
  logic [1:0]  dcd_sync;
  logic [1:0]  dsr_sync;
  logic        dcd_changed;
  logic        rx_irq;
  logic        tx_irq;
  logic        modem_irq;
  logic [2:0]  irq_encoding;
  logic [7:0]  rx_data;
  logic        frame_error;
  logic        overrun;
  logic        clear_rx;

  assign cs            = cyc_i && stb_i && (adr_i[31:4] == BASE_ADDR);
  assign txrx_select   = cs && (adr_i[3:0] == UART_TRB);
  assign ack_o         = cs;
  assign vol_o         = cs && (adr_i[3:2] == 2'b00);
  assign clear_rx      = cs && we_i && (adr_i[3:0] == UART_FC);
  assign dcd_changed   = dcd_sync[1] ^ dcd_sync[0];
  assign rx_irq        = data_present_o && rx_present_ie;
  assign tx_irq        = tx_empty && tx_empty_ie;
  assign modem_irq     = dcd_changed && dcd_ie;
  assign irq_o         = rx_irq | tx_irq | modem_irq;
  assign irq_encoding = rx_irq ? 3'd1 : tx_irq ? 3'd3 : modem_irq ? 3'd4 : 3'd0;
  assign baud16_clk    = baud16;

  always_comb begin
    dat_o = 8'h00;
    if (cs) begin
      unique case (adr_i[3:0])
        UART_MS: dat_o = {dcd_sync[1], 1'b0, dsr_sync[1], cts_sync[1],
                          dcd_changed, 3'b000};
        UART_IS: dat_o = {irq_o, 2'b00, irq_encoding, 2'b00};
        UART_LS: dat_o = {1'b0, tx_empty, tx_complete, 1'b0, frame_error,
                          1'b0, overrun, data_present_o};
        default: dat_o = rx_data;
      endcase
    end
  end

  edge_det u_baud_edge (
    .rst(rst_i), .clk(clk_i), .ce(1'b1), .i(phase_accumulator[23]),
    .pe(baud16), .ne(), .ee()
  );

  rtfSimpleUartRx u_rx (
    .rst_i, .clk_i, .cyc_i, .stb_i, .ack_o(), .we_i, .dat_o(rx_data),
    .cs_i(txrx_select), .baud16x_ce(baud16), .baud8x(1'b0),
    .clear(clear_rx), .rxd(rxd_i), .data_present(data_present_o),
    .frame_err(frame_error), .overrun
  );

  rtfSimpleUartTx u_tx (
    .rst_i, .clk_i, .cyc_i, .stb_i, .ack_o(), .we_i, .dat_i,
    .cs_i(txrx_select), .baud16x_ce(baud16), .baud8x(1'b0),
    .cts(cts_sync[1] | ~hwfc), .txd(txd_o), .empty(tx_empty),
    .txc(tx_complete)
  );

  always_ff @(posedge clk_i) begin
    if (rst_i) begin
      phase_accumulator <= '0;
      clock_multiplier <= 24'(DEFAULT_CLK_MUL);
      rts_no       <= ~pRts;
      dtr_no       <= ~pDtr;
      rx_present_ie <= 1'b0;
      tx_empty_ie  <= 1'b0;
      dcd_ie       <= 1'b0;
      hwfc         <= 1'b1;
      cts_sync     <= '0;
      dcd_sync     <= '0;
      dsr_sync     <= '0;
    end else begin
      phase_accumulator <= phase_accumulator + clock_multiplier;
      cts_sync <= {cts_sync[0], ~cts_ni};
      dcd_sync <= {dcd_sync[0], ~dcd_ni};
      dsr_sync <= {dsr_sync[0], ~dsr_ni};

      if (cs && we_i) begin
        unique case (adr_i[3:0])
          UART_IER: begin
            rx_present_ie <= dat_i[0];
            tx_empty_ie   <= dat_i[1];
            dcd_ie        <= dat_i[3];
          end
          UART_MC: begin
            dtr_no <= ~dat_i[0];
            rts_no <= ~dat_i[1];
          end
          UART_CTRL: hwfc <= dat_i[0];
          UART_CLKM1: clock_multiplier[7:0]   <= dat_i;
          UART_CLKM2: clock_multiplier[15:8]  <= dat_i;
          UART_CLKM3: clock_multiplier[23:16] <= dat_i;
          default: ;
        endcase
      end
    end
  end
endmodule

`default_nettype wire
