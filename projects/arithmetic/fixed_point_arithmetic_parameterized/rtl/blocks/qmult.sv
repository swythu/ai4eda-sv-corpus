`default_nettype none

module qmult #(
  parameter int unsigned Q = 15,
  parameter int unsigned N = 32
) (
  input  logic [N-1:0] a,
  input  logic [N-1:0] b,
  output logic [N-1:0] c
);
  localparam int unsigned MAG_W = N - 1;

  logic [(2*MAG_W)-1:0] magnitude_product;

  initial begin
    assert (N >= 2) else $fatal(1, "qmult requires N >= 2");
    assert (Q < N) else $fatal(1, "qmult requires Q < N");
  end

  always_comb begin
    magnitude_product = a[MAG_W-1:0] * b[MAG_W-1:0];
    c[N-1]             = a[N-1] ^ b[N-1];
    c[MAG_W-1:0]       = magnitude_product[Q +: MAG_W];
  end
endmodule

`default_nettype wire
