`timescale 1ns/1ps
`default_nettype none

module tb_ima_adpcm_equiv;
  localparam int SAMPLE_COUNT = 64;

  logic clk = 1'b0;
  logic reset = 1'b1;
  logic [15:0] in_sample = '0;
  logic in_valid = 1'b0;

  logic sv_in_ready, legacy_in_ready;
  logic [3:0] sv_pcm, legacy_pcm;
  logic sv_pcm_valid, legacy_pcm_valid;
  logic [15:0] sv_predict, legacy_predict;
  logic [6:0] sv_step, legacy_step;
  logic sv_dec_ready, legacy_dec_ready;
  logic [15:0] sv_dec_sample, legacy_dec_sample;
  logic sv_dec_valid, legacy_dec_valid;
  int encoded_checks = 0;
  int decoded_checks = 0;

  always #5 clk = ~clk;

  ima_adpcm_enc sv_enc (
    .clock(clk), .reset, .inSamp(in_sample), .inValid(in_valid),
    .inReady(sv_in_ready), .outPCM(sv_pcm), .outValid(sv_pcm_valid),
    .outPredictSamp(sv_predict), .outStepIndex(sv_step)
  );
  ima_adpcm_enc_legacy legacy_enc (
    .clock(clk), .reset, .inSamp(in_sample), .inValid(in_valid),
    .inReady(legacy_in_ready), .outPCM(legacy_pcm),
    .outValid(legacy_pcm_valid), .outPredictSamp(legacy_predict),
    .outStepIndex(legacy_step)
  );

  ima_adpcm_dec sv_dec (
    .clock(clk), .reset, .inPCM(sv_pcm), .inValid(sv_pcm_valid),
    .inReady(sv_dec_ready), .inPredictSamp('0), .inStepIndex('0),
    .inStateLoad(1'b0), .outSamp(sv_dec_sample), .outValid(sv_dec_valid)
  );
  ima_adpcm_dec_legacy legacy_dec (
    .clock(clk), .reset, .inPCM(legacy_pcm), .inValid(legacy_pcm_valid),
    .inReady(legacy_dec_ready), .inPredictSamp(16'b0),
    .inStepIndex(7'b0), .inStateLoad(1'b0),
    .outSamp(legacy_dec_sample), .outValid(legacy_dec_valid)
  );

  initial begin : stimulus
    repeat (4) @(posedge clk);
    @(negedge clk);
    reset = 1'b0;
    for (int i = 0; i < SAMPLE_COUNT; i++) begin
      while (!(sv_in_ready && legacy_in_ready)) @(negedge clk);
      in_sample = 16'((i * 997) ^ (i << 11) ^ 16'h5a3c);
      in_valid = 1'b1;
      @(negedge clk);
      in_valid = 1'b0;
    end
  end

  always @(negedge clk) begin : equivalence_monitor
    if (!reset) begin
      if (sv_in_ready !== legacy_in_ready)
        $fatal(1, "encoder ready mismatch");
      if (sv_pcm_valid !== legacy_pcm_valid)
        $fatal(1, "encoder valid mismatch");
      if (sv_pcm_valid) begin
        if ({sv_pcm, sv_predict, sv_step} !==
            {legacy_pcm, legacy_predict, legacy_step})
          $fatal(1, "encoder state mismatch at output %0d", encoded_checks);
        encoded_checks++;
      end
      if (sv_dec_ready !== legacy_dec_ready)
        $fatal(1, "decoder ready mismatch");
      if (sv_dec_valid !== legacy_dec_valid)
        $fatal(1, "decoder valid mismatch");
      if (sv_dec_valid) begin
        if (sv_dec_sample !== legacy_dec_sample)
          $fatal(1, "decoder sample mismatch at output %0d", decoded_checks);
        decoded_checks++;
        if (decoded_checks == SAMPLE_COUNT) begin
          if (encoded_checks != SAMPLE_COUNT)
            $fatal(1, "encoded count mismatch: %0d", encoded_checks);
          $display("IMA_ADPCM_SV_PASS samples=%0d cycle_equivalence=pass", decoded_checks);
          $finish;
        end
      end
    end
  end

  initial begin
    #100000;
    $fatal(1, "test timeout: encoded=%0d decoded=%0d", encoded_checks, decoded_checks);
  end
endmodule

`default_nettype wire
