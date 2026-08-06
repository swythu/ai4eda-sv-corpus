`timescale 1ns/1ps
`default_nettype none

module tb_rtfsimpleuart;
  logic clk = 1'b0;
  logic rst = 1'b1;
  logic baud_ce = 1'b1;

  logic tx_cyc = 1'b0;
  logic tx_stb = 1'b0;
  logic tx_we = 1'b0;
  logic [7:0] tx_data = '0;
  logic tx_ack, txd, tx_empty, tx_complete;

  logic rx_cyc = 1'b0;
  logic rx_stb = 1'b0;
  logic rx_we = 1'b0;
  logic [7:0] rx_data;
  logic rx_ack, data_present, frame_error, overrun;
  int checks = 0;

  always #5 clk = ~clk;

  rtfSimpleUartTx u_tx (
    .rst_i(rst), .clk_i(clk), .cyc_i(tx_cyc), .stb_i(tx_stb),
    .ack_o(tx_ack), .we_i(tx_we), .dat_i(tx_data), .cs_i(1'b1),
    .baud16x_ce(baud_ce), .baud8x(1'b0), .cts(1'b1), .txd,
    .empty(tx_empty), .txc(tx_complete)
  );

  rtfSimpleUartRx u_rx (
    .rst_i(rst), .clk_i(clk), .cyc_i(rx_cyc), .stb_i(rx_stb),
    .ack_o(rx_ack), .we_i(rx_we), .dat_o(rx_data), .cs_i(1'b1),
    .baud16x_ce(baud_ce), .baud8x(1'b0), .clear(1'b0), .rxd(txd),
    .data_present, .frame_err(frame_error), .overrun
  );

  task automatic write_tx(input logic [7:0] value);
    @(negedge clk);
    tx_data = value;
    tx_cyc = 1'b1;
    tx_stb = 1'b1;
    tx_we  = 1'b1;
    #1;
    checks++;
    if (!tx_ack) $fatal(1, "TX Wishbone acknowledge missing");
    @(negedge clk);
    tx_cyc = 1'b0;
    tx_stb = 1'b0;
    tx_we  = 1'b0;
  endtask

  task automatic wait_and_read(input logic [7:0] expected);
    int timeout_cycles;
    timeout_cycles = 0;
    while (!data_present && timeout_cycles < 220) begin
      @(posedge clk);
      timeout_cycles++;
    end
    if (!data_present) $fatal(1, "RX timeout waiting for %h", expected);
    checks++;
    if (frame_error || overrun) $fatal(1, "unexpected RX status error");

    @(negedge clk);
    rx_cyc = 1'b1;
    rx_stb = 1'b1;
    #1;
    checks++;
    if (!rx_ack) $fatal(1, "RX Wishbone acknowledge missing");
    checks++;
    if (rx_data !== expected) begin
      $fatal(1, "RX mismatch actual=%h expected=%h", rx_data, expected);
    end
    @(negedge clk);
    rx_cyc = 1'b0;
    rx_stb = 1'b0;
  endtask

  initial begin
    repeat (4) @(posedge clk);
    rst = 1'b0;
    @(posedge clk);
    checks++;
    if (!tx_empty || !tx_complete || txd !== 1'b1) begin
      $fatal(1, "TX reset/idle state invalid");
    end

    write_tx(8'hA5);
    wait (tx_empty && !tx_complete);
    write_tx(8'h3C); // queue a second byte while the first is shifting

    wait_and_read(8'hA5);
    wait_and_read(8'h3C);
    wait (tx_complete);
    checks++;
    if (!tx_empty || txd !== 1'b1) $fatal(1, "TX did not return to idle");

    $display("RTFSIMPLEUART_SV_PASS checks=%0d loopback_bytes=2", checks);
    $finish;
  end
endmodule

`default_nettype wire
