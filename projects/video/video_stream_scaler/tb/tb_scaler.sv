/////////////////////////////////////////////////////////////////////
// Self-checking testbench for streamScaler (video_stream_scaler)
//
// Stimulus: 8x8 single-channel synthetic gradient, pixel(x,y) = x*16+y.
// Two configurations run in parallel:
//   cfg0: 8x8 -> 8x8, xScale=yScale=1.0 (Q4.14 0x4000), bilinear
//   cfg1: 8x8 -> 4x4, xScale=yScale=2.0 (Q4.14 0x8000), bilinear
//
// Method: output pixel streams are compared word-by-word (4-state,
// including X) against golden references captured from the original
// Verilog-2001 sources (tb/g0.hex, tb/g1.hex).  In addition, cfg0
// (identity scaling) is checked to reproduce the input gradient
// wherever the original design produces a defined value.
/////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module tb_scaler;

	logic clk, rst, start;
	logic [7:0] dIn0, dIn1;
	logic dInValid0, dInValid1;
	wire nextDin0, nextDin1;
	wire [7:0] dOut0, dOut1;
	wire dOutValid0, dOutValid1;
	logic nextDout0, nextDout1;

	initial begin clk = 0; forever #5 clk = ~clk; end

	streamScaler #(.DATA_WIDTH(8), .CHANNELS(1), .DISCARD_CNT_WIDTH(8),
		.INPUT_X_RES_WIDTH(11), .INPUT_Y_RES_WIDTH(11),
		.OUTPUT_X_RES_WIDTH(11), .OUTPUT_Y_RES_WIDTH(11),
		.BUFFER_SIZE(4)) dut0 (
		.clk(clk), .rst(rst), .dIn(dIn0), .dInValid(dInValid0), .nextDin(nextDin0),
		.start(start), .dOut(dOut0), .dOutValid(dOutValid0), .nextDout(nextDout0),
		.inputDiscardCnt(0), .inputXRes(8-1), .inputYRes(8-1),
		.outputXRes(8-1), .outputYRes(8-1),
		.xScale(32'h4000), .yScale(32'h4000),
		.leftOffset(0), .topFracOffset(0), .nearestNeighbor(1'b0));

	streamScaler #(.DATA_WIDTH(8), .CHANNELS(1), .DISCARD_CNT_WIDTH(8),
		.INPUT_X_RES_WIDTH(11), .INPUT_Y_RES_WIDTH(11),
		.OUTPUT_X_RES_WIDTH(11), .OUTPUT_Y_RES_WIDTH(11),
		.BUFFER_SIZE(4)) dut1 (
		.clk(clk), .rst(rst), .dIn(dIn1), .dInValid(dInValid1), .nextDin(nextDin1),
		.start(start), .dOut(dOut1), .dOutValid(dOutValid1), .nextDout(nextDout1),
		.inputDiscardCnt(0), .inputXRes(8-1), .inputYRes(8-1),
		.outputXRes(4-1), .outputYRes(4-1),
		.xScale(32'h4000*2), .yScale(32'h4000*2),
		.leftOffset(0), .topFracOffset(0), .nearestNeighbor(1'b0));

	// golden references (4-state, captured from the original Verilog)
	logic [7:0] gold0 [0:63];
	logic [7:0] gold1 [0:15];
	initial begin
		$readmemb("g0.hex", gold0);
		$readmemb("g1.hex", gold1);
	end

	integer x0, y0, x1, y1, oc0, oc1;
	integer error_count;
	integer ident_checked;

	initial begin
		rst = 0; start = 0;
		dInValid0 = 0; dInValid1 = 0; nextDout0 = 0; nextDout1 = 0;
		dIn0 = 0; dIn1 = 0; x0 = 0; y0 = 0; x1 = 0; y1 = 0;
		oc0 = 0; oc1 = 0; error_count = 0; ident_checked = 0;
		repeat(4) @(posedge clk);
		rst = 1; @(posedge clk); rst = 0;
		@(posedge clk); start = 1; @(posedge clk); start = 0;
		nextDout0 = 1; nextDout1 = 1;
	end

	// feed cfg0: advance only when the DUT accepts the pixel
	always @(posedge clk) begin
		if (start) begin x0 <= 0; y0 <= 0; dInValid0 <= 1; dIn0 <= 8'd0; end
		else if (dInValid0 && nextDin0) begin
			dIn0 <= (x0 == 7 ? 0 : x0+1)*16 + (x0 == 7 ? y0+1 : y0);
			if (x0 == 7) begin
				x0 <= 0;
				if (y0 == 7) dInValid0 <= 0;
				else y0 <= y0 + 1;
			end
			else x0 <= x0 + 1;
		end
	end

	// feed cfg1
	always @(posedge clk) begin
		if (start) begin x1 <= 0; y1 <= 0; dInValid1 <= 1; dIn1 <= 8'd0; end
		else if (dInValid1 && nextDin1) begin
			dIn1 <= (x1 == 7 ? 0 : x1+1)*16 + (x1 == 7 ? y1+1 : y1);
			if (x1 == 7) begin
				x1 <= 0;
				if (y1 == 7) dInValid1 <= 0;
				else y1 <= y1 + 1;
			end
			else x1 <= x1 + 1;
		end
	end

	// drain and check cfg0 (identity 8x8 -> 8x8)
	always @(posedge clk) begin
		if (dOutValid0) begin
			if (oc0 < 64) begin
				if (dOut0 !== gold0[oc0]) begin
					error_count = error_count + 1;
					$display("ERROR: cfg0 out[%0d] = %b, golden %b", oc0, dOut0, gold0[oc0]);
				end
				// semantic check: identity scaling reproduces input pixel (x,y)=x*16+y
				// (skip entries where the original design drives x)
				if (^gold0[oc0] !== 1'bx) begin
					ident_checked = ident_checked + 1;
					if (dOut0 !== ((oc0%8)*16 + (oc0/8))) begin
						error_count = error_count + 1;
						$display("ERROR: cfg0 identity mismatch at pixel %0d: got %0d, input %0d",
							oc0, dOut0, (oc0%8)*16 + (oc0/8));
					end
				end
			end
			oc0 = oc0 + 1;
		end
		if (dOutValid1) begin
			if (oc1 < 16) begin
				if (dOut1 !== gold1[oc1]) begin
					error_count = error_count + 1;
					$display("ERROR: cfg1 out[%0d] = %b, golden %b", oc1, dOut1, gold1[oc1]);
				end
			end
			oc1 = oc1 + 1;
		end
		if (oc0 >= 64 && oc1 >= 16) begin
			$display("status: %t both configurations done (cfg0 %0d px, cfg1 %0d px, %0d identity-checked)",
				$time, oc0, oc1, ident_checked);
			// note: the original design keeps emitting (wrapped) output pixels
			// beyond the frame when nextDout stays high; only the first
			// 64 (cfg0) / 16 (cfg1) pixels belong to the frame and are checked
			if (oc0 < 64) begin
				error_count = error_count + 1;
				$display("ERROR: cfg0 produced only %0d pixels, expected at least 64", oc0);
			end
			if (oc1 < 16) begin
				error_count = error_count + 1;
				$display("ERROR: cfg1 produced only %0d pixels, expected at least 16", oc1);
			end
			if (ident_checked == 0) begin
				error_count = error_count + 1;
				$display("ERROR: no defined cfg0 pixels were identity-checked");
			end
			if (error_count == 0)
				$display("SCALER_SV_PASS identity=pass downsample2x=pass");
			else
				$display("Simulation Failed  --- Errors =%0d", error_count);
			$finish;
		end
	end

	// watchdog
	initial begin
		#2000000; // 2 ms
		$display("\nERROR: Simulation timeout at %t (oc0=%0d oc1=%0d)", $time, oc0, oc1);
		$display("Simulation Failed  --- timeout");
		$finish;
	end

endmodule
