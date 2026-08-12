`default_nettype none
/////////////////////////////////////////////////////////////////////
// File name            : MPU707.v
// FUNCTION: Constant multiplier
// PROPERTIES:1)Is based on shifts right and add
//		  2)for short input bit width 0.7071 is approximated as
//              10110101 then rounding is not used
//		  3)for long input bit width 0.7071 is approximated as
//              10110101000000101
//		  4)hardware is 3 or 4 adders
/////////////////////////////////////////////////////////////////////

module MPU707 #(
	parameter nb = 12
)(
	input  wire              CLK,
	input  wire signed [nb+1:0] DI,
	input  wire              EI,
	output logic signed [nb+1:0] DO
);

	logic signed [nb+5:0] dx5;
	logic signed [nb+2:0] dt;
	wire  signed [nb+6:0] dx5p;
	wire  signed [nb+6:0] dot;

	always_ff @(posedge CLK)
		begin
			if (EI) begin
					dx5 <= DI + (DI << 2);	 //multiply by 5
					dt  <= DI;
					DO  <= dot >>> 4;
				end
		end

`ifdef USFFT64bitwidth_0707_high
	assign dot = (dx5p + (dt >>> 4) + (dx5 >>> 12)); // multiply by 10110101000000101
`else
	assign dot = (dx5p + (dt >>> 4));                // multiply by 10110101
`endif

	assign dx5p = (dx5 << 1) + (dx5 >>> 2);          // multiply by 101101

endmodule
`default_nettype wire
