`timescale 1ns/1ps
`default_nettype none

module tb_fixed_point;
  localparam int unsigned N = 16;
  localparam int unsigned Q = 8;

  logic clk = 1'b0;
  logic rst_n = 1'b0;
  logic start = 1'b0;
  logic [N-1:0] a, b;
  logic [N-1:0] add_result, mult_result, quotient;
  logic busy, complete, divide_by_zero;
  int checks = 0;

  always #5 clk = ~clk;

  qadd  #(.Q(Q), .N(N)) u_add  (.a(a), .b(b), .c(add_result));
  qmult #(.Q(Q), .N(N)) u_mult (.a(a), .b(b), .c(mult_result));
  qdiv  #(.Q(Q), .N(N)) u_div (
    .clk, .rst_n, .start, .dividend(a), .divisor(b),
    .quotient_out(quotient), .busy, .complete, .divide_by_zero
  );

  function automatic logic [N-1:0] fx(input bit negative, input int magnitude_q);
    fx = {negative, magnitude_q[N-2:0]};
  endfunction

  task automatic check_value(input string label, input logic [N-1:0] actual,
                             input logic [N-1:0] expected);
    checks++;
    if (actual !== expected) begin
      $error("%s actual=%h expected=%h", label, actual, expected);
      $fatal(1);
    end
  endtask

  task automatic divide_and_expect(
    input logic [N-1:0] lhs,
    input logic [N-1:0] rhs,
    input logic [N-1:0] expected,
    input bit expected_zero
  );
    a = lhs;
    b = rhs;
    @(negedge clk); start = 1'b1;
    @(negedge clk); start = 1'b0;
    wait (complete);
    check_value("division quotient", quotient, expected);
    checks++;
    if (divide_by_zero !== expected_zero) $fatal(1, "divide-by-zero flag mismatch");
    @(negedge clk);
  endtask

  initial begin
    a = '0;
    b = '0;
    repeat (2) @(negedge clk);
    rst_n = 1'b1;

    a = fx(0, 384); b = fx(0, 576); #1; // 1.5 + 2.25
    check_value("positive add", add_result, fx(0, 960));
    a = fx(0, 1024); b = fx(1, 256); #1; // 4.0 + -1.0
    check_value("mixed add positive", add_result, fx(0, 768));
    a = fx(1, 1024); b = fx(0, 256); #1;
    check_value("mixed add negative", add_result, fx(1, 768));
    a = fx(1, 384); b = fx(0, 512); #1; // -1.5 * 2.0
    check_value("signed multiply", mult_result, fx(1, 768));

    divide_and_expect(fx(0, 1920), fx(0, 640), fx(0, 768), 0); // 7.5 / 2.5
    divide_and_expect(fx(1, 768), fx(0, 512), fx(1, 384), 0);  // -3.0 / 2.0
    divide_and_expect(fx(0, 256), fx(0, 0), fx(0, 0), 1);

    $display("FIXED_POINT_SV_PASS checks=%0d add_mult_div=pass", checks);
    $finish;
  end
endmodule

`default_nettype wire
