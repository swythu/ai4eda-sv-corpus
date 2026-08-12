// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module wishbone_apb_bridge (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        wb_cyc_i,
  input  logic        wb_stb_i,
  input  logic        wb_we_i,
  input  logic [31:0] wb_adr_i,
  input  logic [31:0] wb_dat_i,
  input  logic [3:0]  wb_sel_i,
  output logic [31:0] wb_dat_o,
  output logic        wb_ack_o,
  output logic        wb_err_o,
  output logic        psel_o,
  output logic        penable_o,
  output logic        pwrite_o,
  output logic [31:0] paddr_o,
  output logic [31:0] pwdata_o,
  output logic [3:0]  pstrb_o,
  input  logic [31:0] prdata_i,
  input  logic        pready_i,
  input  logic        pslverr_i
);
  typedef enum logic [1:0] {Idle, Setup, Access} state_t;
  state_t state_q;

  assign psel_o    = state_q != Idle;
  assign penable_o = state_q == Access;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q   <= Idle;
      wb_ack_o  <= 1'b0;
      wb_err_o  <= 1'b0;
      wb_dat_o  <= '0;
      paddr_o   <= '0;
      pwdata_o  <= '0;
      pstrb_o   <= '0;
      pwrite_o  <= 1'b0;
    end else begin
      wb_ack_o <= 1'b0;
      wb_err_o <= 1'b0;
      unique case (state_q)
        Idle: begin
          if (wb_cyc_i && wb_stb_i) begin
            paddr_o  <= wb_adr_i;
            pwdata_o <= wb_dat_i;
            pstrb_o  <= wb_sel_i;
            pwrite_o <= wb_we_i;
            state_q  <= Setup;
          end
        end
        Setup: state_q <= Access;
        Access: begin
          if (pready_i) begin
            wb_dat_o <= prdata_i;
            wb_ack_o <= !pslverr_i;
            wb_err_o <= pslverr_i;
            state_q  <= Idle;
          end
        end
        default: state_q <= Idle;
      endcase
    end
  end
endmodule
`default_nettype wire
