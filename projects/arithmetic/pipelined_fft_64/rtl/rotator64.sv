`default_nettype none
/////////////////////////////////////////////////////////////////////
// Module name: ROTATOR64
// FUNCTION:  rotator (complex multiplier) for the FFT results
// PROPERTIES: 1) Has 64-clock cycle period starting with the START impulse
//               and continuing forever
//             2) rounding is not used
/////////////////////////////////////////////////////////////////////

module ROTATOR64 #(
	parameter nb = 12,   // data bit width
	parameter nw = 16    // twiddle coefficient bit width
)(
	input  wire              CLK,
	input  wire              RST,
	input  wire              ED,     // operation enable
	input  wire              START,  // 1-st Data is entered after this impulse
	input  wire [nb+1:0]     DR,     // Real part of data
	input  wire [nb+1:0]     DI,     // Imaginary part of data
	output wire [nb+1:0]     DOR,    // Real part of data
	output wire [nb+1:0]     DOI,    // Imaginary part of data
	output logic             RDY     // repeats START impulse following the output data
);

	logic [5:0] addrw;
	logic sd1, sd2;
	always_ff @(posedge CLK) begin  //address counter for twiddle factors
			if (RST) begin
					addrw <= 6'd0;
					sd1 <= 1'b0;
					sd2 <= 1'b0;
					RDY <= 1'b0;
				end
			else if (START && ED) begin
					addrw <= 6'd0;
					sd1 <= START;
					sd2 <= 1'b0;
					RDY <= 1'b0;
				end
			else if (ED) begin
					addrw <= addrw + 6'd1;
					sd1 <= START;
					sd2 <= sd1;
					RDY <= sd2;
				end
		end

	wire signed [nw-1:0] wr, wi; //twiddle factor coefficients
	//twiddle factor ROM
	WROM64 #(nw) UROM (.ADDR(addrw), .WR(wr), .WI(wi));

	logic signed [nb+1:0] drd, did;
	logic signed [nw-1:0] wrd, wid;
	wire  signed [nw+nb+1:0] drri, drii, diri, diii;
	logic signed [nb+2:0] drr, dri, dir, dii, dwr, dwi;

	assign drri = drd * wrd;
	assign diri = did * wrd;
	assign drii = drd * wid;
	assign diii = did * wid;

	always_ff @(posedge CLK) begin  //complex multiplier
			if (ED) begin
					drd <= DR;
					did <= DI;
					wrd <= wr;
					wid <= wi;
					drr <= drri[nw+nb+1 : nw-1]; //msbs of multiplications are stored
					dri <= drii[nw+nb+1 : nw-1];
					dir <= diri[nw+nb+1 : nw-1];
					dii <= diii[nw+nb+1 : nw-1];
					dwr <= drr - dii;
					dwi <= dri + dir;
				end
		end
	assign DOR = dwr[nb+2:1];
	assign DOI = dwi[nb+2:1];

endmodule
`default_nettype wire
