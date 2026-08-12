// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module apb_register_bank (
  input  logic        pclk_i,
  input  logic        preset_ni,
  input  logic        psel_i,
  input  logic        penable_i,
  input  logic        pwrite_i,
  input  logic [7:0]  paddr_i,
  input  logic [31:0] pwdata_i,
  input  logic [3:0]  pstrb_i,
  input  logic [31:0] status_i,
  output logic [31:0] prdata_o,
  output logic        pready_o,
  output logic        pslverr_o,
  output logic [31:0] control_o
);
  integer byte_index;

  assign pready_o = psel_i && penable_i;

  always_comb begin
    unique case (paddr_i)
      8'h00: prdata_o = control_o;
      8'h04: prdata_o = status_i;
      default: prdata_o = '0;
    endcase
    pslverr_o = pready_o && (paddr_i != 8'h00) && (paddr_i != 8'h04);
  end

  always_ff @(posedge pclk_i or negedge preset_ni) begin
    if (!preset_ni) begin
      control_o <= '0;
    end else if (psel_i && penable_i && pwrite_i && (paddr_i == 8'h00)) begin
      for (byte_index = 0; byte_index < 4; byte_index++) begin
        if (pstrb_i[byte_index]) begin
          control_o[byte_index*8 +: 8] <= pwdata_i[byte_index*8 +: 8];
        end
      end
    end
  end
endmodule
`default_nettype wire
