// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
// Modified by the AI4EDA SV Corpus project: dependency-closed SECDED RAM.
`default_nettype none
module ecc_ram #(
  parameter int Depth=16, localparam int AddrWidth=$clog2(Depth)
) (
  input logic clk_i,req_i,write_i,input logic[AddrWidth-1:0]addr_i,input logic[31:0]wdata_i,
  input logic inject_i,input logic[5:0]inject_bit_i,
  output logic[31:0]rdata_o,output logic corrected_o,uncorrectable_o
);
  logic[38:0]mem[0:Depth-1]; logic[38:0]encoded,codeword; logic[5:0]syndrome;
  function automatic bit is_parity_pos(input int pos);is_parity_pos=(pos==1||pos==2||pos==4||pos==8||pos==16||pos==32);endfunction
  function automatic logic[38:0] encode(input logic[31:0]d);
    logic[38:0]c;integer pos,di,p,j;logic parity;begin c='0;di=0;
      for(pos=1;pos<=38;pos=pos+1)if(!is_parity_pos(pos))begin c[pos-1]=d[di];di=di+1;end
      for(j=0;j<6;j=j+1)begin p=1<<j;parity=0;for(pos=1;pos<=38;pos=pos+1)if((pos&p)!=0)parity=parity^c[pos-1];c[p-1]=parity;end
      c[38]=^c[37:0];encode=c;end
  endfunction
  always_comb begin
    encoded=encode(wdata_i);codeword=mem[addr_i];if(inject_i&&inject_bit_i<39)codeword[inject_bit_i]=~codeword[inject_bit_i];
  end
  integer pos,j,di;logic overall;logic[38:0]corrected_word;
  always_comb begin syndrome='0;for(j=0;j<6;j=j+1)begin for(pos=1;pos<=38;pos=pos+1)if((pos&(1<<j))!=0)syndrome[j]=syndrome[j]^codeword[pos-1];end
    overall=^codeword;corrected_word=codeword;corrected_o=0;uncorrectable_o=0;
    if(overall&&syndrome!=0)begin corrected_word[syndrome-1]=~corrected_word[syndrome-1];corrected_o=1;end
    else if(overall&&syndrome==0)corrected_o=1;else if(!overall&&syndrome!=0)uncorrectable_o=1;
    rdata_o='0;di=0;for(pos=1;pos<=38;pos=pos+1)if(!is_parity_pos(pos))begin rdata_o[di]=corrected_word[pos-1];di=di+1;end
  end
  always_ff @(posedge clk_i) if(req_i&&write_i)mem[addr_i]<=encoded;
endmodule
`default_nettype wire
