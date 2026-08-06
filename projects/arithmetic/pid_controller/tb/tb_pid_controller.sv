`timescale 1ns/1ps
`default_nettype none

module tb_pid_controller;
  logic clk = 1'b0, rst = 1'b1;
  logic wb_cyc = 1'b0, wb_stb = 1'b0, wb_we = 1'b0;
  logic [15:0] wb_adr = '0;
  logic [31:0] wb_data_i = '0, wb_data_o;
  logic wb_ack, valid;
  logic signed [31:0] control;
  int checks = 0;

  always #5 clk = ~clk;

  pid_controller dut (
    .clk, .rst, .wb_cyc, .wb_stb, .wb_we, .wb_adr,
    .wb_data_i, .wb_ack, .wb_data_o, .control_o(control),
    .control_valid_o(valid)
  );

  task automatic wb_write(input int word, input logic [31:0] value);
    @(negedge clk);
    wb_adr = word * 4; wb_data_i = value;
    wb_cyc = 1'b1; wb_stb = 1'b1; wb_we = 1'b1;
    do @(posedge clk); while (!wb_ack);
    @(negedge clk); wb_cyc = 1'b0; wb_stb = 1'b0; wb_we = 1'b0;
    @(posedge clk);
  endtask

  task automatic wb_read_check(input int word, input logic [31:0] expected);
    @(negedge clk);
    wb_adr = word * 4; wb_cyc = 1'b1; wb_stb = 1'b1; wb_we = 1'b0;
    #1; checks++;
    if (wb_data_o !== expected) $fatal(1, "read[%0d]=%h expected=%h", word, wb_data_o, expected);
    do @(posedge clk); while (!wb_ack);
    @(negedge clk); wb_cyc = 1'b0; wb_stb = 1'b0;
    @(posedge clk);
  endtask

  initial begin
    repeat (3) @(posedge clk);
    rst = 1'b0;
    wb_write(0, 32'd2);  // Kp
    wb_write(1, 32'd1);  // Ki
    wb_write(2, 32'd1);  // Kd
    wb_write(3, 32'd10); // setpoint
    wb_read_check(0, 32'd2);
    wb_read_check(3, 32'd10);

    wb_write(4, 32'd7); // e=3, P=6, I=3, D=3 => 12
    checks++;
    if (control !== 32'sd12) $fatal(1, "first PID output=%0d", control);
    wb_read_check(5, 32'd3);
    wb_read_check(8, 32'd3);

    wb_write(4, 32'd8); // e=2, P=4, I=5, D=-1 => 8
    checks++;
    if (control !== 32'sd8) $fatal(1, "second PID output=%0d", control);
    wb_read_check(6, 32'd3);
    wb_read_check(8, 32'd5);
    wb_read_check(10, 32'd0);

    wb_write(11, 32'd0);
    wb_read_check(7, 32'd0);
    wb_read_check(8, 32'd0);
    $display("PID_CONTROLLER_SV_PASS checks=%0d outputs=12,8 reset=pass", checks);
    $finish;
  end
endmodule

`default_nettype wire
