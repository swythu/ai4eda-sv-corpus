`default_nettype none
//---------------------------------------------------------------------------------------
// register file model as a simple memory
//
//---------------------------------------------------------------------------------------

module reg_file_model
(
	input  wire       clock,        // global clock input
	input  wire       reset,        // global reset input
	// internal bus to register file
	input  wire [7:0] int_address,  // address bus to register file
	input  wire [7:0] int_wr_data,  // write data to register file
	input  wire       int_write,    // write control to register file
	input  wire       int_read,     // read control to register file
	output logic [7:0] int_rd_data  // data read from register file
);

// internal signal
logic [7:0] reg_file [0:255];   // 256 of 8 bit registers

//---------------------------------------------------------------------------------------
// internal tasks
// clear memory
task clear_reg_file;
integer regfile_adr;
begin
   for (regfile_adr = 0; regfile_adr < 256; regfile_adr = regfile_adr + 1)
   begin
	  reg_file[regfile_adr] = 8'h0;
   end
end
endtask

//---------------------------------------------------------------------------------------
// module implementation
// register file write
always_ff @ (posedge clock or posedge reset)
begin
	if (reset)
		clear_reg_file;
	else if (int_write)
		reg_file[int_address] <= int_wr_data;
end

// register file read
always_ff @ (posedge clock or posedge reset)
begin
	if (reset)
		int_rd_data <= 8'h0;
	else if (int_read)
		int_rd_data <= reg_file[int_address];
end

endmodule
//---------------------------------------------------------------------------------------
//						Th.. Th.. Th.. Thats all folks !!!
//---------------------------------------------------------------------------------------
`default_nettype wire
