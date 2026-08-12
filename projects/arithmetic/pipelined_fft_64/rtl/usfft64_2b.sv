`default_nettype none
/////////////////////////////////////////////////////////////////////
//    USFFT64_2B
//    Top level of the high speed 64-complex point FFT core
//    Synthesizable Verilog model of Unicore Systems Ltd
//
// 1. Fully pipelined, 1 complex data in, 1 complex result out each
//    clock cycle
// 2. Input data, output data, coefficient widths are adjustable
//    in range 8..16
// 3. Normalization stages trigger the data overflow and shift
//    data right to prevent the overflow
// 4. Core can contain 2 or 3 data buffers. In the configuration of
//    2 buffers the results are in the shuffled order but provided with
//    the proper address.
// 5. The core operation can be slowed down by the control
//    of the ED input
// 6. The reset RST is synchronous
/////////////////////////////////////////////////////////////////////

module USFFT64_2B #(
	parameter nb = 12    // data bit width
)(
	input  wire            CLK,
	input  wire            RST,     // synchronous reset
	input  wire            ED,      // =1 enables the operation (enabling CLK)
	input  wire            START,   // its falling edge starts the transform
	input  wire [3:0]      SHIFT,   // bits 1,0 -shift code 1-st stage; bits 3,2 - 2-nd stage
	input  wire [nb-1:0]   DR,      // Real part of the input data
	input  wire [nb-1:0]   DI,      // Imaginary part of the input data
	output wire            RDY,     // next cycle after RDY=1 the 0-th result is present
	output wire            OVF1,    // overflow occurred in the 1-st stage
	output wire            OVF2,    // overflow occurred in the 2-nd stage
	output wire [5:0]      ADDR,    // result data address/number
	output wire [nb+2:0]   DOR,     // Real part of the output data
	output wire [nb+2:0]   DOI      // Imaginary part of the output data
);

	wire [nb-1:0] dr1, di1;
	wire [nb+1:0] dr3, di3, dr4, di4, dr5, di5;
	wire [nb+2:0] dr2, di2;
	wire [nb+4:0] dr6, di6;
	wire [nb+2:0] dr7, di7, dr8, di8;
	wire rdy1, rdy2, rdy3, rdy4, rdy5, rdy6, rdy7, rdy8;
	logic [5:0] addri;

	// input buffer = 8-bit inversion ordering
	BUFRAM64C1 #(nb) U_BUF1 (.CLK(CLK), .RST(RST), .ED(ED), .START(START),
		.DR(DR), .DI(DI), .RDY(rdy1), .DOR(dr1), .DOI(di1));

	// 1-st stage of FFT
	FFT8 #(nb) U_FFT1 (.CLK(CLK), .RST(RST), .ED(ED),
		.START(rdy1), .DIR(dr1), .DII(di1),
		.RDY(rdy2), .DOR(dr2), .DOI(di2));

	// 1-st normalization unit
	wire [1:0] shiftl = SHIFT[1:0];
	CNORM #(nb) U_NORM1 (.CLK(CLK), .ED(ED),
		.START(rdy2),
		.DR(dr2), .DI(di2),
		.SHIFT(shiftl),
		.OVF(OVF1),
		.RDY(rdy3),
		.DOR(dr3), .DOI(di3));

	// rotator to the angles proportional to PI/32
	ROTATOR64 U_MPU (.CLK(CLK), .RST(RST), .ED(ED),
		.START(rdy3), .DR(dr3), .DI(di3),
		.RDY(rdy4), .DOR(dr4), .DOI(di4));

	// intermediate buffer = 8-bit inversion ordering
	BUFRAM64C1 #(nb+2) U_BUF2 (.CLK(CLK), .RST(RST), .ED(ED),
		.START(rdy4), .DR(dr4), .DI(di4),
		.RDY(rdy5), .DOR(dr5), .DOI(di5));

	// 2-nd stage of FFT
	FFT8 #(nb+2) U_FFT2 (.CLK(CLK), .RST(RST), .ED(ED),
		.START(rdy5), .DIR(dr5), .DII(di5),
		.RDY(rdy6), .DOR(dr6), .DOI(di6));

	// 2-nd normalization unit
	wire [1:0] shifth = SHIFT[3:2];
	CNORM #(nb+2) U_NORM2 (.CLK(CLK), .ED(ED),
		.START(rdy6),
		.DR(dr6), .DI(di6),
		.SHIFT(shifth),
		.OVF(OVF2),
		.RDY(rdy7),
		.DOR(dr7), .DOI(di7));

	BUFRAM64C1 #(nb+3) Ubuf3 (.CLK(CLK), .RST(RST), .ED(ED),
		.START(rdy7), .DR(dr7), .DI(di7),
		.RDY(rdy8), .DOR(dr8), .DOI(di8));

`ifdef USFFT64parambuffers3
	// 3-data buffer configuration
	always_ff @(posedge CLK) begin	//POINTER to the result samples
			if (RST)
				addri <= 6'b000000;
			else if (rdy8 == 1'b1)
				addri <= 6'b000000;
			else if (ED)
				addri <= addri + 6'd1;
		end

	assign ADDR = addri;
	assign DOR  = dr8;
	assign DOI  = di8;
	assign RDY  = rdy8;
`else
	// 2-data buffer configuration
	always_ff @(posedge CLK) begin	//POINTER to the result samples
			if (RST)
				addri <= 6'b000000;
			else if (rdy7)
				addri <= 6'b000000;
			else if (ED)
				addri <= addri + 6'd1;
		end
	assign ADDR = {addri[2:0], addri[5:3]};
	assign DOR  = dr7;
	assign DOI  = di7;
	assign RDY  = rdy7;
`endif

endmodule
`default_nettype wire
