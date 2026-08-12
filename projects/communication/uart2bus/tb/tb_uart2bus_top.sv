//---------------------------------------------------------------------------------------
// uart2bus self-checking test bench
//
// Original bench: OpenCores uart2bus project (bench/verilog/tb_uart2bus_top.v)
// Refactored to SystemVerilog with self-checking scoreboard:
//   1. ASCII write command  "w d9 1a" + CR  -> reg_file[0x1a] must become 0xd9
//   2. ASCII read command   "r 1a"    + CR  -> DUT must transmit "D9" + CR + LF
//   3. ASCII write command  "w a5 0a" + CR  -> reg_file[0x0a] must become 0xa5
//   4. ASCII read command   "r 0a"    + CR  -> DUT must transmit "A5" + CR + LF
//
//---------------------------------------------------------------------------------------

`include "timescale.svh"

module tb_uart2bus_top();
//---------------------------------------------------------------------------------------
// include uart tasks
`include "uart_tasks.svh"

// internal signal
logic       clock;      // global clock
logic       reset;      // global reset

// self-checking error count
integer     error_count;
logic [7:0] rx_byte;

// continuous serial sniffer with receive buffer.
// the DUT may start its response before the command stop bit has fully
// elapsed, so the receiver must stay armed at all times; bytes are queued
// into a circular buffer and checked in order by expect_byte.
logic [7:0] rxbuf [0:255];
integer     rxwr;
integer     rxrd;

// serial sniffer loop
always
begin
	// call serial sniffer
	get_serial(BAUD_115200, PARITY_EVEN, PARITY_OFF, NSTOPS_1, NBITS_8);

	// check serial receiver status
	if (get_serial_status == RECEIVE_RESULT_OK)
	begin
		rxbuf[rxwr] = get_serial_data;
		rxwr = rxwr + 1;
		if (get_serial_data >= 8'h20)
			$display("status: %t received byte 0x%h (\"%c\")", $time, get_serial_data, get_serial_data);
		else
			$display("status: %t received byte 0x%h", $time, get_serial_data);
	end
	else
	begin
		error_count = error_count + 1;
		$display("ERROR: serial receive status 0x%h at %t", get_serial_status, $time);
	end
end

//---------------------------------------------------------------------------------------
// test bench implementation
// global signals generation
initial
begin
	clock = 0;
	reset = 1;
	#40 reset = 0;
end

// clock generator - 40MHz clock
always
begin
	#12 clock = 0;
	#13 clock = 1;
end

//------------------------------------------------------------------
// send one ASCII character at 115200 baud, 8N1
task send_char;
input [7:0] ch;
begin
	send_serial (ch, BAUD_115200, PARITY_EVEN, PARITY_OFF, NSTOPS_1, NBITS_8, 0);
	#100;
end
endtask

// receive one byte from the DUT transmitter and check it against exp
task expect_byte;
input [7:0] exp;
integer   wait_cnt;
begin
	// wait until the sniffer has queued a byte (bit time is ~8.7us; allow ~4 bytes worth)
	wait_cnt = 0;
	while ((rxrd == rxwr) && (wait_cnt < 400))
	begin
		#1000;
		wait_cnt = wait_cnt + 1;
	end
	if (rxrd == rxwr)
	begin
		error_count = error_count + 1;
		$display("ERROR: expected 0x%h, but no byte received before timeout at %t", exp, $time);
	end
	else
	begin
		rx_byte = rxbuf[rxrd];
		rxrd = rxrd + 1;
		if (rx_byte !== exp)
		begin
			error_count = error_count + 1;
			$display("ERROR: expected 0x%h, received 0x%h at %t", exp, rx_byte, $time);
		end
		else
			$display("status: %t byte 0x%h matches expected", $time, rx_byte);
	end
end
endtask

// hierarchical check of the register file model contents
task check_reg;
input [7:0]  addr;
input [7:0]  exp;
begin
	if (reg_file1.reg_file[addr] !== exp)
	begin
		error_count = error_count + 1;
		$display("ERROR: reg_file[0x%h] = 0x%h, expected 0x%h at %t", addr, reg_file1.reg_file[addr], exp, $time);
	end
	else
		$display("status: %t reg_file[0x%h] == 0x%h (write check)", $time, addr, exp);
end
endtask

//------------------------------------------------------------------
// main stimulus
initial
begin
	error_count = 0;
	serial_out = 1;
	// NOTE: get_serial_data/get_serial_status are initialized inside the
	// get_serial task itself; the sniffer loop is armed from time 0 and must
	// not have its status raced by this initial block.
	rxwr = 0;
	rxrd = 0;

	// wait for reset deassertion
	@(negedge reset);
	repeat(4) @(posedge clock);

	// transmit a write command to internal register file
	// command string: "w d9 1a" + CR  (write data 0xd9 to address 0x1a)
	$display("status: %t sending write command: w d9 1a", $time);
	send_char (8'h77); // 'w'
	send_char (8'h20); // ' '
	send_char (8'h64); // 'd'
	send_char (8'h39); // '9'
	send_char (8'h20); // ' '
	send_char (8'h31); // '1'
	send_char (8'h61); // 'a'
	send_char (8'h0d); // CR

	// allow the parser to issue the bus write
	repeat(20) @(posedge clock);
	check_reg (8'h1a, 8'hd9);

	// transmit a read command from register file
	// command string: "r 1a" + CR
	$display("status: %t sending read command: r 1a", $time);
	send_char (8'h72); // 'r'
	send_char (8'h20); // ' '
	send_char (8'h31); // '1'
	send_char (8'h61); // 'a'
	send_char (8'h0d); // CR

	// the DUT answers with the two hex digits of the read data + CR + LF
	expect_byte (8'h44); // 'D'
	expect_byte (8'h39); // '9'
	expect_byte (8'h0d); // CR
	expect_byte (8'h0a); // LF

	// second location: write 0xa5 to 0x0a and read it back
	$display("status: %t sending write command: w a5 0a", $time);
	send_char (8'h77); // 'w'
	send_char (8'h20); // ' '
	send_char (8'h61); // 'a'
	send_char (8'h35); // '5'
	send_char (8'h20); // ' '
	send_char (8'h30); // '0'
	send_char (8'h61); // 'a'
	send_char (8'h0d); // CR

	repeat(20) @(posedge clock);
	check_reg (8'h0a, 8'ha5);

	$display("status: %t sending read command: r 0a", $time);
	send_char (8'h72); // 'r'
	send_char (8'h20); // ' '
	send_char (8'h30); // '0'
	send_char (8'h61); // 'a'
	send_char (8'h0d); // CR

	expect_byte (8'h41); // 'A'
	expect_byte (8'h35); // '5'
	expect_byte (8'h0d); // CR
	expect_byte (8'h0a); // LF

	// wrap up
	#100000;
	$display("\nstatus: %t Testbench done", $time);
	if (error_count == 0)
		$display("UART2BUS_SV_PASS ascii_write=pass ascii_readback=pass");
	else
		$display("Simulation Failed  --- Errors =%0d", error_count);
	$finish;
end

// watchdog: abort if the DUT stops responding
initial
begin
	#30000000; // 30 ms
	$display("\nERROR: Simulation timeout at %t", $time);
	$display("Simulation Failed  --- timeout");
	$finish;
end

//------------------------------------------------------------------
// device under test
// DUT interface
wire [15:0] int_address;    // address bus to register file
wire [7:0]  int_wr_data;    // write data to register file
wire        int_write;      // write control to register file
wire        int_read;       // read control to register file
wire [7:0]  int_rd_data;    // data read from register file
wire        int_req;        // bus access request signal
wire        int_gnt;        // bus access grant signal
wire        ser_in;         // DUT serial input
wire        ser_out;        // DUT serial output

// DUT instance
uart2bus_top uart2bus1
(
	.clock(clock), .reset(reset),
	.ser_in(ser_in), .ser_out(ser_out),
	.int_address(int_address), .int_wr_data(int_wr_data), .int_write(int_write),
	.int_rd_data(int_rd_data), .int_read(int_read),
	.int_req(int_req), .int_gnt(int_gnt)
);
// bus grant is always active
assign int_gnt = 1'b1;

// serial interface to test bench
assign ser_in = serial_out;
always @ (posedge clock) serial_in = ser_out;

// register file model (8-bit address space)
reg_file_model reg_file1
(
	.clock(clock), .reset(reset),
	.int_address(int_address[7:0]), .int_wr_data(int_wr_data), .int_write(int_write),
	.int_rd_data(int_rd_data), .int_read(int_read)
);

endmodule
//---------------------------------------------------------------------------------------
//						Th.. Th.. Th.. Thats all folks !!!
//---------------------------------------------------------------------------------------
