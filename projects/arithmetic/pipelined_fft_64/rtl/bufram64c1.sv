`default_nettype none
/////////////////////////////////////////////////////////////////////
// 64-word complex buffer RAM with 8-th inverse read addressing
/////////////////////////////////////////////////////////////////////

module BUFRAM64C1 #(
	parameter nb = 12
)(
	input  wire           CLK,
	input  wire           RST,
	input  wire           ED,
	input  wire           START,
	input  wire [nb-1:0]  DR,
	input  wire [nb-1:0]  DI,
	output logic          RDY,
	output wire [nb-1:0]  DOR,
	output wire [nb-1:0]  DOI
);

	wire odd, we;
	wire [5:0] addrw, addrr;
	logic [6:0] addr;
	logic [7:0] ct2;		//counter for the RDY signal

	always_ff @(posedge CLK) begin   //   CTADDR
			if (RST) begin
					addr <= 7'b0000000;
					ct2 <= 8'b01000001;
					RDY <= 1'b0;
				end
			else if (START) begin
					addr <= 7'b0000000;
					ct2 <= 8'b00000000;
					RDY <= 1'b0;
				end
			else if (ED) begin
					RDY <= 1'b0;
					addr <= addr + 7'd1;
					if (ct2 != 65)
						ct2 <= ct2 + 8'd1;
					if (ct2 == 64)
						RDY <= 1'b1;
				end
		end

	assign addrw = addr[5:0];
	assign odd   = addr[6];             // signal which switches the 2 parts of the buffer
	assign addrr = {addr[2:0], addr[5:3]};   // 8-th inverse output address
	assign we    = ED;

	RAM2x64C_1 #(nb) URAM (.CLK(CLK), .ED(ED), .WE(we), .ODD(odd),
		.ADDRW(addrw), .ADDRR(addrr),
		.DR(DR), .DI(DI),
		.DOR(DOR), .DOI(DOI));

endmodule
`default_nettype wire
