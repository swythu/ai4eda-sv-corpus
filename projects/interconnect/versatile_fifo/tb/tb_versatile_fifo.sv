`timescale 1ns/1ps
`default_nettype none

module tb_versatile_fifo;
  localparam int unsigned DATA_WIDTH = 8;
  localparam int unsigned ADDR_WIDTH = 3;
  logic a_clk = 1'b0, b_clk = 1'b0;
  logic a_rst = 1'b1, b_rst = 1'b1;
  logic [7:0] a_d = '0, b_d = '0, a_q, b_q;
  logic a_wr = 1'b0, a_rd = 1'b0, b_wr = 1'b0, b_rd = 1'b0;
  logic a_full, a_empty, b_full, b_empty;
  int checks = 0;

  always #5 a_clk = ~a_clk;
  always #7 b_clk = ~b_clk;

  async_fifo_dw_simplex_top #(
    .data_width(DATA_WIDTH), .addr_width(ADDR_WIDTH)
  ) dut (
    .a_clk, .a_rst, .a_d, .a_wr, .a_fifo_full(a_full),
    .a_q, .a_rd, .a_fifo_empty(a_empty),
    .b_clk, .b_rst, .b_d, .b_wr, .b_fifo_full(b_full),
    .b_q, .b_rd, .b_fifo_empty(b_empty)
  );

  task automatic write_a(input logic [7:0] value);
    while (a_full) @(posedge a_clk);
    @(negedge a_clk); a_d = value; a_wr = 1'b1;
    @(negedge a_clk); a_wr = 1'b0;
  endtask

  task automatic write_b(input logic [7:0] value);
    while (b_full) @(posedge b_clk);
    @(negedge b_clk); b_d = value; b_wr = 1'b1;
    @(negedge b_clk); b_wr = 1'b0;
  endtask

  task automatic read_b_check(input logic [7:0] expected);
    while (b_empty) @(posedge b_clk);
    @(negedge b_clk); b_rd = 1'b1;
    @(posedge b_clk); #1;
    checks++;
    if (b_q !== expected) $fatal(1, "A->B mismatch actual=%h expected=%h", b_q, expected);
    @(negedge b_clk); b_rd = 1'b0;
  endtask

  task automatic read_a_check(input logic [7:0] expected);
    while (a_empty) @(posedge a_clk);
    @(negedge a_clk); a_rd = 1'b1;
    @(posedge a_clk); #1;
    checks++;
    if (a_q !== expected) $fatal(1, "B->A mismatch actual=%h expected=%h", a_q, expected);
    @(negedge a_clk); a_rd = 1'b0;
  endtask

  initial begin
    repeat (4) @(posedge a_clk);
    a_rst = 1'b0;
    b_rst = 1'b0;
    repeat (4) @(posedge b_clk);
    checks++;
    if (!a_empty || !b_empty || a_full || b_full) $fatal(1, "invalid reset flags");

    fork
      begin
        for (int i = 0; i < 6; i++) write_a(8'h20 + i);
      end
      begin
        for (int i = 0; i < 5; i++) write_b(8'hA0 + i);
      end
      begin
        for (int i = 0; i < 6; i++) read_b_check(8'h20 + i);
      end
      begin
        for (int i = 0; i < 5; i++) read_a_check(8'hA0 + i);
      end
    join

    repeat (5) @(posedge a_clk);
    checks++;
    if (!a_empty || !b_empty) $fatal(1, "FIFO did not return to empty");
    $display("VERSATILE_FIFO_SV_PASS checks=%0d a_to_b=6 b_to_a=5 cdc=gray2ff", checks);
    $finish;
  end
endmodule

`default_nettype wire
