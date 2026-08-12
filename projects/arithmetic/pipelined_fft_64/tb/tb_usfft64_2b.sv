/////////////////////////////////////////////////////////////////////
// Self-checking testbench for the USFFT64_2B 64-point pipelined FFT
//
// Stimulus: complex exponential at frequency bin 2,
//   DR = cos(2*pi*2*n/64), DI = sin(2*pi*2*n/64), 12-bit truncated
//   (derived from the original Unicore sine ROM table)
//
// Method: the second 64-point output frame (first frame after the
// pipeline is completely filled) is compared word-by-word against a
// golden reference captured from the original Verilog-2001 sources
// (tb/golden.txt).  Exact bit match is required on every bin, plus
// the spectral peak must land on bin 2 (the stimulus frequency) and
// no overflow may be flagged.
/////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module tb_usfft64_2b;

	localparam nb = 12;

	logic CLK;
	logic RST;
	logic ED;
	logic START;
	logic [3:0] SHIFT;
	wire [nb-1:0] DR;
	wire [nb-1:0] DI;
	wire RDY;
	wire OVF1;
	wire OVF2;
	wire [5:0] ADDR;
	wire signed [nb+2:0] DOR;
	wire signed [nb+2:0] DOI;

	// clock: 100 MHz
	initial begin
		CLK = 1'b0;
		forever #5 CLK = ~CLK;
	end

	// reset and start sequencing (as in the original testbench)
	initial begin
		SHIFT = 4'b0000;
		ED    = 1'b1;
		RST   = 1'b0;
		START = 1'b0;
		#13 RST = 1'b1;
		#43 RST = 1'b0;
		#53 START = 1'b1;
		#12 START = 1'b0;
	end

	// sample index, wraps every 64 clocks, restarted by START
	logic [5:0] ct64;
	always @(posedge CLK or posedge START) begin
		if (START) ct64 <= 6'b000000;
		else       ct64 <= ct64 + 6'd1;
	end

	// stimulus: bin-2 complex exponential taken from the sine ROM:
	//   sin(2*pi*2*n/64) = sine[(2n) mod 64]
	//   cos(2*pi*2*n/64) = sine[(2n+8) mod 64]
	logic [15:0] sine [0:63];
	initial $readmemh("sine.hex", sine);

	wire [5:0]  idx_sin = ct64[4:0] << 1;          // (2n) mod 64
	wire [5:0]  idx_cos = (ct64[4:0] << 1) + 6'd8; // (2n+8) mod 64
	wire [15:0] sin16 = sine[idx_sin];
	wire [15:0] cos16 = sine[idx_cos];

	assign DR = cos16[15 : 15-nb+1];
	assign DI = sin16[15 : 15-nb+1];

	// Unit Under Test
	USFFT64_2B #(.nb(nb)) UUT (
		.CLK(CLK), .RST(RST), .ED(ED), .START(START), .SHIFT(SHIFT),
		.DR(DR), .DI(DI),
		.RDY(RDY), .OVF1(OVF1), .OVF2(OVF2), .ADDR(ADDR),
		.DOR(DOR), .DOI(DOI)
	);

	// golden reference: "bin dore doim ovf1 ovf2" per line, in output order
	integer gold_re  [0:63];
	integer gold_im  [0:63];
	integer gold_ovf [0:63];
	initial begin
		integer fd, code, a, r, im, o1, o2;
		fd = $fopen("golden.txt", "r");
		if (fd == 0) begin
			$display("ERROR: cannot open golden.txt");
			$finish;
		end
		for (integer k = 0; k < 64; k = k + 1) begin
			code = $fscanf(fd, "%d %d %d %d %d\n", a, r, im, o1, o2);
			if (code != 5) begin
				$display("ERROR: golden.txt parse failure at line %0d", k);
				$finish;
			end
			gold_re[k]  = r;
			gold_im[k]  = im;
			gold_ovf[k] = o1 | o2;
		end
		$fclose(fd);
	end

	// capture the second output frame (the 64 results starting 64 clocks
	// after the first RDY) and compare against the golden reference
	integer nclk;
	integer rdy_clk;
	integer cap_cnt;
	integer error_count;
	integer peak_bin;
	integer peak_mag2;
	integer m;

	initial begin
		nclk = 0;
		rdy_clk = -1;
		cap_cnt = 0;
		error_count = 0;
		peak_bin = 0;
		peak_mag2 = 0;
	end

	always @(posedge CLK) begin
		nclk = nclk + 1;
		if (RDY && rdy_clk < 0)
			rdy_clk = nclk;
		if (rdy_clk > 0 && nclk >= rdy_clk + 64 && cap_cnt < 64) begin
			// bit-exact comparison with the original-Verilog golden frame
			if (($signed(DOR) !== gold_re[cap_cnt]) || ($signed(DOI) !== gold_im[cap_cnt])) begin
				error_count = error_count + 1;
				$display("ERROR: out[%0d] (bin %0d): got (%0d,%0d), golden (%0d,%0d)",
					cap_cnt, ADDR, $signed(DOR), $signed(DOI),
					gold_re[cap_cnt], gold_im[cap_cnt]);
			end
			if ((OVF1 | OVF2) !== gold_ovf[cap_cnt][0]) begin
				error_count = error_count + 1;
				$display("ERROR: out[%0d] (bin %0d): ovf=%b%b, golden %b",
					cap_cnt, ADDR, OVF1, OVF2, gold_ovf[cap_cnt][0]);
			end
			// track spectral peak for the sanity check
			m = $signed(DOR) * $signed(DOR) + $signed(DOI) * $signed(DOI);
			if (m > peak_mag2) begin
				peak_mag2 = m;
				peak_bin  = ADDR;
			end
			cap_cnt = cap_cnt + 1;
			if (cap_cnt == 64) begin
				$display("status: %t output frame captured and compared", $time);
				if (peak_bin != 2) begin
					error_count = error_count + 1;
					$display("ERROR: spectral peak at bin %0d, expected 2", peak_bin);
				end
				else
					$display("status: %t spectral peak at bin 2 (stimulus frequency)", $time);

				if (error_count == 0)
					$display("FFT64_SV_PASS golden_match=pass peak_bin2=pass");
				else
					$display("Simulation Failed  --- Errors =%0d", error_count);
				$finish;
			end
		end
	end

	// watchdog
	initial begin
		#200000; // 200 us
		$display("\nERROR: Simulation timeout at %t", $time);
		$display("Simulation Failed  --- timeout");
		$finish;
	end

endmodule
