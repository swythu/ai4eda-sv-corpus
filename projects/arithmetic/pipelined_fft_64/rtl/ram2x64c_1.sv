`default_nettype none
/////////////////////////////////////////////////////////////////////
// Two-buffer 2x64-word complex data RAM for the FFT buffer
/////////////////////////////////////////////////////////////////////

module RAM2x64C_1 #(
	parameter nb = 12
)(
	input  wire           CLK,
	input  wire           ED,
	input  wire           WE,     //write enable
	input  wire           ODD,    // RAM part switching
	input  wire [5:0]     ADDRW,
	input  wire [5:0]     ADDRR,
	input  wire [nb-1:0]  DR,
	input  wire [nb-1:0]  DI,
	output wire [nb-1:0]  DOR,
	output wire [nb-1:0]  DOI
);

	logic oddd, odd2;
	always_ff @(posedge CLK) begin //switch which reswitches the RAM parts
			if (ED)	begin
					oddd <= ODD;
					odd2 <= oddd;
				end
		end

`ifdef USFFT64bufferports1
	//One-port RAMs are used
	wire we0, we1;
	wire [nb-1:0] dor0, dor1, doi0, doi1;
	wire [5:0]    addr0, addr1;

	assign addr0 =  ODD ? ADDRW : ADDRR;    //MUXA0
	assign addr1 = ~ODD ? ADDRW : ADDRR;    // MUXA1
	assign we0   =  ODD ? WE : 1'b0;        // MUXW0
	assign we1   = ~ODD ? WE : 1'b0;        // MUXW1

	//1-st half - write when odd=1	 read when odd=0
	RAM64 #(nb) URAM0(.CLK(CLK),.ED(ED),.WE(we0), .ADDR(addr0),.DI(DR),.DO(dor0));
	RAM64 #(nb) URAM1(.CLK(CLK),.ED(ED),.WE(we0), .ADDR(addr0),.DI(DI),.DO(doi0));

	//2-d half
	RAM64 #(nb) URAM2(.CLK(CLK),.ED(ED),.WE(we1), .ADDR(addr1),.DI(DR),.DO(dor1));
	RAM64 #(nb) URAM3(.CLK(CLK),.ED(ED),.WE(we1), .ADDR(addr1),.DI(DI),.DO(doi1));

	assign DOR = ~odd2 ? dor0 : dor1;       // MUXDR
	assign DOI = ~odd2 ? doi0 : doi1;       // MUXDI

`else
	//Two-port RAM is used
	wire [6:0]      addrr2 = {ODD, ADDRR};
	wire [6:0]      addrw2 = {~ODD, ADDRW};
	wire [2*nb-1:0] di  = {DR, DI};
	wire [2*nb-1:0] doi;

	logic [2*nb-1:0] ram [127:0];
	logic [6:0]      read_addra;
	always_ff @(posedge CLK) begin
			if (ED)
				begin
					if (WE)
						ram[addrw2] <= di;
					read_addra <= addrr2;
				end
		end
	assign doi = ram[read_addra];

	assign DOR = doi[2*nb-1:nb];     // Real read data
	assign DOI = doi[nb-1:0];        // Imaginary read data

`endif
endmodule
`default_nettype wire
