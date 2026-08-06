`default_nettype none

module qdiv #(
  parameter int unsigned Q = 15,
  parameter int unsigned N = 32
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start,
  input  logic [N-1:0] dividend,
  input  logic [N-1:0] divisor,
  output logic [N-1:0] quotient_out,
  output logic         busy,
  output logic         complete,
  output logic         divide_by_zero
);
  localparam int unsigned MAG_W   = N - 1;
  localparam int unsigned NUM_W   = MAG_W + Q;
  localparam int unsigned COUNT_W = $clog2(NUM_W + 1);

  logic [NUM_W-1:0] numerator_shift;
  logic [NUM_W-1:0] quotient_work;
  logic [MAG_W:0]    remainder;
  logic [MAG_W-1:0]  divisor_mag;
  logic               quotient_sign;
  logic [COUNT_W-1:0] iterations_left;

  logic [MAG_W:0]    shifted_remainder;
  logic [NUM_W-1:0] next_quotient;

  initial begin
    assert (N >= 2) else $fatal(1, "qdiv requires N >= 2");
    assert ((Q > 0) && (Q < N)) else $fatal(1, "qdiv requires 0 < Q < N");
  end

  always_comb begin
    shifted_remainder = {remainder[MAG_W-1:0], numerator_shift[NUM_W-1]};
    next_quotient     = quotient_work << 1;
    if (shifted_remainder >= {1'b0, divisor_mag}) begin
      shifted_remainder = shifted_remainder - {1'b0, divisor_mag};
      next_quotient[0]  = 1'b1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      numerator_shift <= '0;
      quotient_work   <= '0;
      remainder       <= '0;
      divisor_mag     <= '0;
      quotient_sign   <= 1'b0;
      iterations_left <= '0;
      quotient_out    <= '0;
      busy            <= 1'b0;
      complete        <= 1'b0;
      divide_by_zero  <= 1'b0;
    end else begin
      complete <= 1'b0;

      if (start && !busy) begin
        divide_by_zero <= (divisor[MAG_W-1:0] == '0);
        if (divisor[MAG_W-1:0] == '0) begin
          quotient_out <= '0;
          complete     <= 1'b1;
        end else begin
          numerator_shift <= {{Q{1'b0}}, dividend[MAG_W-1:0]} << Q;
          quotient_work   <= '0;
          remainder       <= '0;
          divisor_mag     <= divisor[MAG_W-1:0];
          quotient_sign   <= dividend[N-1] ^ divisor[N-1];
          iterations_left <= COUNT_W'(NUM_W);
          busy            <= 1'b1;
        end
      end else if (busy) begin
        numerator_shift <= numerator_shift << 1;
        quotient_work   <= next_quotient;
        remainder       <= shifted_remainder;
        iterations_left <= iterations_left - 1'b1;

        if (iterations_left == 1) begin
          quotient_out <= {quotient_sign, next_quotient[MAG_W-1:0]};
          busy         <= 1'b0;
          complete     <= 1'b1;
        end
      end
    end
  end
endmodule

`default_nettype wire
