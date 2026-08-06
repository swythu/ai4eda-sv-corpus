`timescale 1ns/1ps
`default_nettype none

module tb_scalable_arbiter;
  localparam int unsigned WIDTH = 8;
  localparam int unsigned SELECT_WIDTH = $clog2(WIDTH);

  logic                    clock = 1'b0;
  logic                    reset = 1'b1;
  logic                    enable = 1'b1;
  logic [WIDTH-1:0]        req = '0;
  logic [WIDTH-1:0]        grant;
  logic [SELECT_WIDTH-1:0] select;
  logic                    valid;
  logic [WIDTH-1:0]        seen;
  int                      granted_index;
  int                      checks = 0;

  always #5 clock = ~clock;

  arbiter #(
    .width(WIDTH),
    .select_width(SELECT_WIDTH)
  ) dut (
    .enable,
    .req,
    .grant,
    .select,
    .valid,
    .clock,
    .reset
  );

  task automatic wait_for_grant(output int index);
    int cycle;
    begin : wait_loop
      index = -1;
      for (cycle = 0; cycle < 6; cycle++) begin
        @(posedge clock);
        #1;
        if (grant != '0) begin
          if (!$onehot(grant))
            $fatal(1, "grant is not one-hot: %b", grant);
          if ((grant & ~req) != '0)
            $fatal(1, "grant without request: req=%b grant=%b", req, grant);
          index = int'(select);
          if (grant !== ({{(WIDTH-1){1'b0}}, 1'b1} << index))
            $fatal(1, "select/grant mismatch: select=%0d grant=%b", index, grant);
          checks++;
          disable wait_loop;
        end
      end
      $fatal(1, "grant timeout: req=%b", req);
    end
  endtask

  initial begin
    repeat (3) @(posedge clock);
    @(negedge clock);
    reset = 1'b0;

    // Every individual request must be granted and correctly encoded.
    for (int i = 0; i < WIDTH; i++) begin
      req = {{(WIDTH-1){1'b0}}, 1'b1} << i;
      wait_for_grant(granted_index);
      if (granted_index != i)
        $fatal(1, "single-request mismatch: expected=%0d got=%0d", i, granted_index);
      req = '0;
      repeat (3) @(posedge clock);
    end

    // With all requesters active, removing each winner must eventually service
    // every requester exactly once (round-robin progress/fairness check).
    seen = '0;
    req = '1;
    for (int i = 0; i < WIDTH; i++) begin
      wait_for_grant(granted_index);
      if (seen[granted_index])
        $fatal(1, "requester granted twice before all peers: %0d", granted_index);
      seen[granted_index] = 1'b1;
      req[granted_index] = 1'b0;
    end
    if (seen != '1)
      $fatal(1, "not all requesters were serviced: seen=%b", seen);

    // Disable masks grants even when requests are present.
    req = '1;
    enable = 1'b0;
    repeat (5) begin
      @(posedge clock);
      #1;
      if (grant != '0)
        $fatal(1, "grant asserted while disabled: %b", grant);
    end

    $display("SCALABLE_ARBITER_SV_PASS checks=%0d fairness=pass", checks);
    $finish;
  end
endmodule

`default_nettype wire
