`default_nettype none
/////////////////////////////////////////////////////////////////////
// File name            : FFT8.v
// FUNCTION: 8-point FFT
// FILES: FFT8.v - 1-st stage, contains
//        MPU707.v - multiplier to the factor 0.707.
// PROPERTIES:1) Fully pipelined
//		  2) Each clock cycle complex datum is entered
//               and complex result is outputted
//		  3) Has 8-clock cycle period starting with the START
//               impulse and continuing forever
//		  4) rounding	is not used
//		  5)Algorithm is from the book "H.J.Nussbaumer FFT and
//              convolution algorithms".
//		  6)IFFT is performed by substituting the output result
//              order to the reversed one
//		    (by exchanging - to + and + to -)
/////////////////////////////////////////////////////////////////////

module FFT8 #(
	parameter nb = 12
)(
	input  wire            CLK,
	input  wire            RST,
	input  wire            ED,
	input  wire            START,
	input  wire [nb-1:0]   DIR,   // Real part of input data
	input  wire [nb-1:0]   DII,   // Imaginary part of input data
	output wire [nb+2:0]   DOR,   // Real part of output data
	output wire [nb+2:0]   DOI,   // Imaginary part of output data
	output logic           RDY
);

	logic [2:0] ct;   //main phase counter
	logic [3:0] ctd;  //delay counter

	always_ff @(posedge CLK) begin	//Control counter
			if (RST) begin
					ct  <= 3'd0;
					ctd <= 4'd15;
					RDY <= 1'b0;
				end
			else if (START) begin
					ct  <= 3'd0;
					ctd <= 4'd0;
					RDY <= 1'b0;
				end
			else if (ED) begin
					RDY <= 1'b0;
					ct  <= ct + 3'd1;
					if (ctd != 4'b1111)
						ctd <= ctd + 4'd1;
					if (ctd == 12)
						RDY <= 1'b1;
				end
		end

	logic signed [nb-1:0] dr, d1r, d2r, d3r, d4r, di, d1i, d2i, d3i, d4i;
	always_ff @(posedge CLK) begin	  // input register file
			if (ED) begin
					dr  <= DIR;
					d1r <= dr;
					d2r <= d1r;
					d3r <= d2r;
					d4r <= d3r;
					di  <= DII;
					d1i <= di;
					d2i <= d1i;
					d3i <= d2i;
					d4i <= d3i;
				end
		end

	logic signed [nb:0] s1r, s2r, s1d1r, s1d2r, s1d3r, s2d1r, s2d2r, s2d3r;
	logic signed [nb:0] s1i, s2i, s1d1i, s1d2i, s1d3i, s2d1i, s2d2i, s2d3i;
	always_ff @(posedge CLK) begin		   // S1,S2 =t1-t6,m3 and delayed
			if (ED && ((ct == 5) || (ct == 6) || (ct == 7) || (ct == 0))) begin
					s1r <= d4r + dr;
					s1i <= d4i + di;
					s2r <= d4r - dr;
					s2i <= d4i - di;
				end
			if (ED) begin
					s1d1r <= s1r;
					s1d2r <= s1d1r;
					s1d1i <= s1i;
					s1d2i <= s1d1i;
					if (ct == 0 || ct == 1) begin
							s1d3r <= s1d2r;
							s1d3i <= s1d2i;
						end
					if (ct == 6 || ct == 7 || ct == 0) begin
							s2d1r <= s2r;
							s2d2r <= s2d1r;
							s2d1i <= s2i;
							s2d2i <= s2d1i;
						end
					if (ct == 0) begin
							s2d3r <= s2d2r;
							s2d3i <= s2d2i;
						end
				end
		end

	logic signed [nb+1:0] s3r, s4r, s3d1r, s3d2r, s3d3r;
	logic signed [nb+1:0] s3i, s4i, s3d1i, s3d2i, s3d3i;
	always_ff @(posedge CLK) begin		  //ALU	S3:
			if (ED)
				case (ct)
					0: begin s3r <= s1d2r + s1r;         //t7
						s3i <= s1d2i + s1i; end
					1: begin s3r <= s1d3r - s1d1r;       //m2
						s3i <= s1d3i - s1d1i; end
					2: begin s3r <= s1d3r + s1r;         //t8
						s3i <= s1d3i + s1i; end
					3: begin s3r <= s1d3r - s1r;         //
						s3i <= s1d3i - s1i; end
					default: ;
				endcase

			if (ED) begin
					if (ct == 1 || ct == 2 || ct == 3) begin
							s3d1r <= s3r;               //t8
							s3d1i <= s3i;
						end
					if (ct == 2 || ct == 3) begin
							s3d2r <= s3d1r;             //m2
							s3d3r <= s3d2r;             //t7
							s3d2i <= s3d1i;
							s3d3i <= s3d2i;
						end
				end
		end

	always_ff @(posedge CLK) begin		  // S4
			if (ED) begin
					if (ct == 1) begin
							s4r <= s2d2r + s2r;
							s4i <= s2d2i + s2i;
						end
					else if (ct == 2) begin
							s4r <= s2d2r - s2r;
							s4i <= s2d2i - s2i;
						end
				end
		end

	wire em = ((ct == 2 || ct == 3 || ct == 4) && ED);

	wire signed [nb+1:0] m4m7r, m4m7i;
	MPU707 #(nb) UMR (.CLK(CLK), .EI(em), .DI(s4r), .DO(m4m7r));
	MPU707 #(nb) UMI (.CLK(CLK), .EI(em), .DI(s4i), .DO(m4m7i));

	logic signed [nb+1:0] sjr, sji, m6r, m6i;
	always_ff @(posedge CLK) begin		   //multiply by J
			if (ED) begin
					case (ct)
						3: begin sjr <= s2d1i;              //m6
							sji <= 0 - s2d1r; end
						4: begin sjr <= m4m7i;              //m7
							sji <= 0 - m4m7r; end
						6: begin sjr <= s3i;                //m5
							sji <= 0 - s3r; end
						default: ;
					endcase
					if (ct == 4) begin
							m6r <= sjr;                 //m6
							m6i <= sji;
						end
				end
		end

	logic signed [nb+2:0] s5r, s5d1r, s5d2r, q1r;
	logic signed [nb+2:0] s5i, s5d1i, s5d2i, q1i;
	always_ff @(posedge CLK) begin	     // 	S5:
			if (ED)
				case (ct)
					5: begin q1r <= s2d3r + m4m7r;      //	 S1
							q1i <= s2d3i + m4m7i;
							s5r <= m6r + sjr;
							s5i <= m6i + sji; end
					6: begin s5r <= m6r - sjr;
							s5i <= m6i - sji;
							s5d1r <= s5r;
							s5d1i <= s5i; end
					7: begin s5r <= s2d3r - m4m7r;
							s5i <= s2d3i - m4m7i;
							s5d1r <= s5r;
							s5d1i <= s5i;
							s5d2r <= s5d1r;
							s5d2i <= s5d1i;
						end
					default: ;
				endcase
		end

	logic signed [nb+3:0] s6r, s6i;
`ifdef USFFT64paramifft
	always_ff @(posedge CLK) begin		 //  S6-- result adder (IFFT)
			if (ED)
				case (ct)
					5: begin s6r <= s3d3r + s3d1r;      //	 D0
						s6i <= s3d3i + s3d1i; end
					6: begin
							s6r <= q1r - s5r;
							s6i <= q1i - s5i; end
					7: begin
							s6r <= s3d2r - sjr;
							s6i <= s3d2i - sji; end
					0: begin
							s6r <= s5r + s5d1r;
							s6i <= s5i + s5d1i; end
					1: begin s6r <= s3d3r - s3d1r;      //	 D4
						s6i <= s3d3i - s3d1i; end
					2: begin
							s6r <= s5r - s5d1r;         //	 D5
							s6i <= s5i - s5d1i; end
					3: begin                            //	 D6
							s6r <= s3d3r + sjr;
							s6i <= s3d3i + sji;
						end
					4: begin                            //	 D7
							s6r <= q1r + s5d2r;
							s6i <= q1i + s5d2i;
						end
					default: ;
				endcase
		end
`else
	always_ff @(posedge CLK) begin		 //  S6-- result adder (FFT)
			if (ED)
				case (ct)
					5: begin s6r <= s3d3r + s3d1r;      //	 D0
						s6i <= s3d3i + s3d1i; end
					6: begin
							s6r <= q1r + s5r;           //	 D1
							s6i <= q1i + s5i; end
					7: begin
							s6r <= s3d2r + sjr;         //	 D2
							s6i <= s3d2i + sji; end
					0: begin
							s6r <= s5r - s5d1r;         //	 D3
							s6i <= s5i - s5d1i; end
					1: begin s6r <= s3d3r - s3d1r;      //	 D4
						s6i <= s3d3i - s3d1i; end
					2: begin
							s6r <= s5r + s5d1r;         //	 D5
							s6i <= s5i + s5d1i; end
					3: begin
							s6r <= s3d3r - sjr;         //	 D6
							s6i <= s3d3i - sji; end
					4: begin
							s6r <= q1r - s5d2r;         //	 D7
							s6i <= q1i - s5d2i; end
					default: ;
				endcase
		end
`endif

	assign DOR = s6r[nb+2:0];
	assign DOI = s6i[nb+2:0];

endmodule
`default_nettype wire
