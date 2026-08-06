`timescale 1ns/1ps
`default_nettype none

`ifdef COMB_OUTPUT
  `define TB_SHADOWED "FALSE"
  `define TB_OBSERVED_Q preclock_q
`else
  `define TB_SHADOWED "TRUE"
  `define TB_OBSERVED_Q q
`endif

module tb_cdc_ufifo;
  logic in_clk = 1'b0;
  logic q_clk = 1'b0;
  logic reset = 1'b1;
  logic denable = 1'b0;
  logic qenable = 1'b0;
  logic [7:0] d = '0;
  logic [7:0] q;
  logic ready;
  logic [7:0] expected [0:2];
  int unsigned received = 0;

  always #5 in_clk = ~in_clk;
  always #7 q_clk = ~q_clk;

  cdc_ufifo #(
    .lpm_width(8), .lpm_depth(2),
    .shadowed(`TB_SHADOWED), .realization("REGS")
  ) dut (
    .in_clk(in_clk), .denable(denable), .reset(reset), .d(d),
    .q_clk(q_clk), .qenable(qenable), .q(q), .ready(ready)
  );

  task automatic push(input logic [7:0] value);
    @(negedge in_clk);
    d = value;
    denable = 1'b1;
    @(negedge in_clk);
    denable = 1'b0;
  endtask

  always @(posedge q_clk) begin
    logic dequeue;
    logic [7:0] preclock_q;
    dequeue = qenable && ready;
    preclock_q = q;
    #1;
    if (!reset && dequeue) begin
      if (received > 2)
        $fatal(1, "received more words than expected");
      if (`TB_OBSERVED_Q !== expected[received])
        $fatal(1, "mismatch index=%0d expected=%02x actual=%02x",
               received, expected[received], `TB_OBSERVED_Q);
      received++;
    end
  end

  initial begin
    expected[0] = 8'h11;
    expected[1] = 8'h35;
    expected[2] = 8'h7a;
    repeat (4) @(posedge in_clk);
    @(negedge in_clk);
    reset = 1'b0;
    push(expected[0]);
    push(expected[1]);
    push(expected[2]);
    wait (ready);
    repeat (5) begin
      @(posedge q_clk);
      #1;
      if (!ready)
        $fatal(1, "FIFO consumed data while qenable=0");
    end
    @(negedge q_clk);
    qenable = 1'b1;
    wait (received == 3);
    @(negedge q_clk);
    qenable = 1'b0;
    repeat (3) @(posedge q_clk);
    #1;
    if (ready)
      $fatal(1, "FIFO did not become empty after three reads");
    $display("CDC_UFIFO_PASS: mode=%s order, clock crossing and qenable backpressure", `TB_SHADOWED);
    $finish;
  end

  initial begin
    #5000;
    $fatal(1, "CDC_UFIFO_FAIL: timeout received=%0d ready=%0b", received, ready);
  end
endmodule

`undef TB_SHADOWED
`undef TB_OBSERVED_Q
`default_nettype wire
