`default_nettype none
/////////////////////////////////////////////////////////////////////
// 64-word single-port synchronous RAM with registered output
/////////////////////////////////////////////////////////////////////

module RAM64 #(
	parameter nb = 12
)(
	input  wire           CLK,
	input  wire           ED,
	input  wire           WE,
	input  wire [5:0]     ADDR,
	input  wire [nb-1:0]  DI,
	output logic [nb-1:0] DO
);

	logic [nb-1:0] mem [63:0];
	logic [5:0]    addrrd;

	always_ff @(posedge CLK) begin
			if (ED) begin
					if (WE)		mem[ADDR] <= DI;
					addrrd <= ADDR;	         //storing the address
					DO <= mem[addrrd];	       // registering the read datum
				end
		end

endmodule
`default_nettype wire
