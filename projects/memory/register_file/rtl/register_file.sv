// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
// Modified by the AI4EDA SV Corpus project into a 2R1W register file.
`default_nettype none
module register_file #(
  parameter int Width=32, Depth=32, parameter bit ZeroRegister=1'b1,
  localparam int AddrWidth=$clog2(Depth)
) (
  input logic clk_i,we_i,input logic[AddrWidth-1:0] waddr_i,input logic[Width-1:0] wdata_i,
  input logic[AddrWidth-1:0] raddr_a_i,raddr_b_i,output logic[Width-1:0] rdata_a_o,rdata_b_o
);
  logic[Width-1:0] mem[0:Depth-1];
  initial if(Width<=0||Depth<=1)$fatal(1,"invalid register-file parameters");
  always_ff @(posedge clk_i) if(we_i && !(ZeroRegister && waddr_i=='0)) mem[waddr_i]<=wdata_i;
  always_comb begin
    rdata_a_o=(ZeroRegister&&raddr_a_i=='0)?'0:((we_i&&waddr_i==raddr_a_i)?wdata_i:mem[raddr_a_i]);
    rdata_b_o=(ZeroRegister&&raddr_b_i=='0)?'0:((we_i&&waddr_i==raddr_b_i)?wdata_i:mem[raddr_b_i]);
  end
endmodule
`default_nettype wire
