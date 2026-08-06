`timescale 1ns/1ps
module tb_tiny_spi;
  logic clk_i = 1'b0;
  logic rst_i = 1'b1;
  logic stb_i = 1'b0;
  logic we_i = 1'b0;
  logic [31:0] dat_i = '0;
  logic [2:0] adr_i = '0;
  logic cyc_i = 1'b0;
  wire [31:0] dat_o;
  wire int_o;
  wire ack_o;
  wire MOSI;
  wire SCLK;
  wire MISO = MOSI;
  int checks = 0;

  always #5 clk_i = ~clk_i;

  tiny_spi #(.BAUD_DIV(4), .SPI_MODE(0)) dut (.*);

  task automatic wb_write(input logic [2:0] address, input logic [31:0] value);
    @(negedge clk_i);
    adr_i = address;
    dat_i = value;
    we_i = 1'b1;
    stb_i = 1'b1;
    cyc_i = 1'b1;
    #1;
    if (!ack_o) $fatal(1, "Wishbone write was not acknowledged");
    @(negedge clk_i);
    stb_i = 1'b0;
    cyc_i = 1'b0;
    we_i = 1'b0;
  endtask

  task automatic transfer_and_check(input logic [7:0] value);
    wb_write(3'd1, value);
    wait (dut.spi_seq != 0);
    wait (dut.spi_seq == 0);
    @(negedge clk_i);
    adr_i = 3'd0;
    #1;
    if (dat_o[7:0] !== value)
      $fatal(1, "SPI loopback mismatch: sent=%02x got=%02x", value, dat_o[7:0]);
    checks++;
  endtask

  initial begin
    repeat (3) @(posedge clk_i);
    rst_i = 1'b0;
    repeat (2) @(posedge clk_i);
    if (SCLK !== 1'b0 || int_o !== 1'b0)
      $fatal(1, "Unexpected reset state SCLK=%b int_o=%b", SCLK, int_o);

    transfer_and_check(8'h3c);
    transfer_and_check(8'ha5);
    transfer_and_check(8'hff);
    transfer_and_check(8'h00);

    $display("TINY_SPI_SV_PASS vectors=%0d serial_loopback=pass wishbone=pass", checks);
    $finish;
  end

  initial begin
    #10000;
    $fatal(1, "timeout");
  end
endmodule
