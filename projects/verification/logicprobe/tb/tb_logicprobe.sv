`timescale 1ns/1ns
module tb_logicprobe;
  logic clock=0, reset=1;
  always #1 clock=~clock;
  logic trigger=0, sample=0;
  logic [127:0] channels=128'h00112233445566778899aabbccddeeff;
  wire full;
  logic [12:0] rdaddr='0;
  wire [7:0] data_out;
  logic xload=0;
  logic [7:0] parallel_in=8'ha5;
  wire empty, serial_out;
  int sampler_checks=0;
  int uart_checks=0;
  LogicProbe_sampler sampler(clock,reset,trigger,sample,channels,full,rdaddr,data_out);
  LogicProbe_xmt transmitter(clock,reset,xload,empty,parallel_in,serial_out);
  initial begin
    repeat(3) @(posedge clock);
    @(negedge clock); reset=0; trigger=1; sample=1;
    repeat(512) @(posedge clock); #1;
    if (full !== 1) $fatal(1,"sampler did not assert full");
    @(negedge clock); trigger=0; sample=0;
    for (int i=0;i<16;i++) begin
      rdaddr=i;
      repeat(3) @(posedge clock); #1;
      if (data_out !== channels[127-i*8 -: 8])
        $fatal(1,"read mux mismatch index=%0d expected=%02x got=%02x",i,channels[127-i*8 -: 8],data_out);
      sampler_checks++;
    end
    $display("LOGICPROBE_SAMPLER_PASS bytes=%0d capture_full=pass",sampler_checks);
  end
  initial begin
    repeat(3) @(posedge clock);
    @(negedge clock); reset=0;
    @(negedge clock); xload=1;
    @(posedge clock); #1;
    @(negedge clock); xload=0;
    for (int bitno=0;bitno<9;bitno++) begin
      if (serial_out !== (bitno==0 ? 1'b0 : parallel_in[bitno-1]))
        $fatal(1,"UART frame mismatch bit=%0d got=%b",bitno,serial_out);
      repeat(1303) @(posedge clock); #1;
      uart_checks++;
    end
    if (serial_out !== 1'b1) $fatal(1,"UART stop level not high");
    wait(empty===1'b1);
    $display("LOGICPROBE_UART_PASS byte=a5 data_bits=%0d timing=1303",uart_checks-1);
  end
  initial begin
    wait(sampler_checks==16 && uart_checks==9 && empty===1'b1);
    $display("LOGICPROBE_SV_PASS sampler=pass uart=pass hierarchy=pass");
    $finish;
  end
  initial begin #40000; $fatal(1,"timeout"); end
endmodule
