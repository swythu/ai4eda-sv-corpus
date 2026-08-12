// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module axi_lite_slice (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic [31:0] s_awaddr_i,
  input  logic        s_awvalid_i,
  output logic        s_awready_o,
  input  logic [31:0] s_wdata_i,
  input  logic [3:0]  s_wstrb_i,
  input  logic        s_wvalid_i,
  output logic        s_wready_o,
  output logic [1:0]  s_bresp_o,
  output logic        s_bvalid_o,
  input  logic        s_bready_i,
  input  logic [31:0] s_araddr_i,
  input  logic        s_arvalid_i,
  output logic        s_arready_o,
  output logic [31:0] s_rdata_o,
  output logic [1:0]  s_rresp_o,
  output logic        s_rvalid_o,
  input  logic        s_rready_i,
  output logic [31:0] m_awaddr_o,
  output logic        m_awvalid_o,
  input  logic        m_awready_i,
  output logic [31:0] m_wdata_o,
  output logic [3:0]  m_wstrb_o,
  output logic        m_wvalid_o,
  input  logic        m_wready_i,
  input  logic [1:0]  m_bresp_i,
  input  logic        m_bvalid_i,
  output logic        m_bready_o,
  output logic [31:0] m_araddr_o,
  output logic        m_arvalid_o,
  input  logic        m_arready_i,
  input  logic [31:0] m_rdata_i,
  input  logic [1:0]  m_rresp_i,
  input  logic        m_rvalid_i,
  output logic        m_rready_o
);
  logic aw_valid_q, w_valid_q, b_valid_q, ar_valid_q, r_valid_q;
  logic [31:0] aw_data_q, ar_data_q;
  logic [35:0] w_data_q;
  logic [1:0]  b_data_q;
  logic [33:0] r_data_q;

  assign s_awready_o = !aw_valid_q || m_awready_i;
  assign s_wready_o  = !w_valid_q  || m_wready_i;
  assign m_bready_o  = !b_valid_q  || s_bready_i;
  assign s_arready_o = !ar_valid_q || m_arready_i;
  assign m_rready_o  = !r_valid_q  || s_rready_i;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      aw_valid_q <= 1'b0;
      w_valid_q  <= 1'b0;
      b_valid_q  <= 1'b0;
      ar_valid_q <= 1'b0;
      r_valid_q  <= 1'b0;
    end else begin
      if (s_awready_o) begin
        aw_valid_q <= s_awvalid_i;
        if (s_awvalid_i) aw_data_q <= s_awaddr_i;
      end
      if (s_wready_o) begin
        w_valid_q <= s_wvalid_i;
        if (s_wvalid_i) w_data_q <= {s_wstrb_i, s_wdata_i};
      end
      if (m_bready_o) begin
        b_valid_q <= m_bvalid_i;
        if (m_bvalid_i) b_data_q <= m_bresp_i;
      end
      if (s_arready_o) begin
        ar_valid_q <= s_arvalid_i;
        if (s_arvalid_i) ar_data_q <= s_araddr_i;
      end
      if (m_rready_o) begin
        r_valid_q <= m_rvalid_i;
        if (m_rvalid_i) r_data_q <= {m_rresp_i, m_rdata_i};
      end
    end
  end

  assign m_awvalid_o = aw_valid_q;
  assign m_awaddr_o  = aw_data_q;
  assign m_wvalid_o  = w_valid_q;
  assign {m_wstrb_o, m_wdata_o} = w_data_q;
  assign s_bvalid_o  = b_valid_q;
  assign s_bresp_o   = b_data_q;
  assign m_arvalid_o = ar_valid_q;
  assign m_araddr_o  = ar_data_q;
  assign s_rvalid_o  = r_valid_q;
  assign {s_rresp_o, s_rdata_o} = r_data_q;
endmodule
`default_nettype wire
