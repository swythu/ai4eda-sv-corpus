`default_nettype none

module qadd #(
  parameter int unsigned Q = 15,
  parameter int unsigned N = 32
) (
  input  logic [N-1:0] a,
  input  logic [N-1:0] b,
  output logic [N-1:0] c
);
  localparam int unsigned MAG_W = N - 1;

  logic [MAG_W-1:0] a_mag;
  logic [MAG_W-1:0] b_mag;

  initial begin
    assert (N >= 2) else $fatal(1, "qadd requires N >= 2");
    assert (Q < N) else $fatal(1, "qadd requires Q < N");
  end

  always_comb begin
    a_mag = a[MAG_W-1:0];
    b_mag = b[MAG_W-1:0];
    c     = '0;

    if (a[N-1] == b[N-1]) begin
      c = {a[N-1], a_mag + b_mag};
    end else if (a_mag >= b_mag) begin
      c = {a[N-1], a_mag - b_mag};
    end else begin
      c = {b[N-1], b_mag - a_mag};
    end
  end
endmodule

`default_nettype wire
