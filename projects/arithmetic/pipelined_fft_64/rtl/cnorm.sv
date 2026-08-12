`default_nettype none
/////////////////////////////////////////////////////////////////////
// Output normalizer: dynamic shifter with overflow detection
/////////////////////////////////////////////////////////////////////

module CNORM #(
	parameter nb = 12
)(
	input  wire            CLK,
	input  wire            ED,
	input  wire            START,
	input  wire [nb+2:0]   DR,
	input  wire [nb+2:0]   DI,
	input  wire [1:0]      SHIFT,
	output logic           OVF,
	output logic           RDY,
	output wire [nb+1:0]   DOR,
	output wire [nb+1:0]   DOI
);

	wire [nb+2:0] diri, diii;
	assign diri = DR << SHIFT;
	assign diii = DI << SHIFT;

	logic [nb+2:0] dir, dii;
	always_ff @(posedge CLK) begin
			if (ED) begin
					dir <= diri[nb+2:1];
					dii <= diii[nb+2:1];
				end
		end

	always_ff @(posedge CLK) begin
			if (ED) begin
				RDY <= START;
				if (START)
					OVF <= 1'b0;
				else
					case (SHIFT)
						2'b01 : OVF <= (DR[nb+2] != DR[nb+1]) || (DI[nb+2] != DI[nb+1]);
						2'b10 : OVF <= (DR[nb+2] != DR[nb+1]) || (DI[nb+2] != DI[nb+1]) ||
							(DR[nb+2] != DR[nb]) || (DI[nb+2] != DI[nb]);
						2'b11 : OVF <= (DR[nb+2] != DR[nb+1]) || (DI[nb+2] != DI[nb+1]) ||
							(DR[nb+2] != DR[nb]) || (DI[nb+2] != DI[nb]) ||
							(DR[nb+2] != DR[nb+1]) || (DI[nb-1] != DI[nb-1]);
						default: OVF <= 1'b0;
					endcase
				end
		end

	assign DOR = dir;
	assign DOI = dii;

endmodule
`default_nettype wire
