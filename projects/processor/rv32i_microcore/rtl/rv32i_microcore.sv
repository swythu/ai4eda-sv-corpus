// SPDX-License-Identifier: Apache-2.0
`default_nettype none
module rv32i_microcore (
  input  logic        clk_i,
  input  logic        rst_ni,
  output logic [31:0] imem_addr_o,
  input  logic [31:0] imem_rdata_i,
  output logic        dmem_valid_o,
  output logic        dmem_write_o,
  output logic [31:0] dmem_addr_o,
  output logic [31:0] dmem_wdata_o,
  input  logic        dmem_ready_i,
  input  logic [31:0] dmem_rdata_i,
  output logic        trap_o
);
  logic [31:0] pc_q;
  logic [31:0] regs [0:31];
  logic [4:0] pending_rd_q;
  logic memory_wait_q, pending_load_q;
  integer register_index;

  logic [6:0] opcode;
  logic [4:0] rd, rs1, rs2;
  logic [31:0] immediate_i, immediate_s, immediate_b;

  assign imem_addr_o = pc_q;

  always_comb begin
    opcode = imem_rdata_i[6:0];
    rd  = imem_rdata_i[11:7];
    rs1 = imem_rdata_i[19:15];
    rs2 = imem_rdata_i[24:20];
    immediate_i = {{20{imem_rdata_i[31]}}, imem_rdata_i[31:20]};
    immediate_s = {{20{imem_rdata_i[31]}}, imem_rdata_i[31:25], imem_rdata_i[11:7]};
    immediate_b = {
      {19{imem_rdata_i[31]}}, imem_rdata_i[31], imem_rdata_i[7],
      imem_rdata_i[30:25], imem_rdata_i[11:8], 1'b0
    };
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pc_q           <= '0;
      trap_o         <= 1'b0;
      dmem_valid_o   <= 1'b0;
      dmem_write_o   <= 1'b0;
      dmem_addr_o    <= '0;
      dmem_wdata_o   <= '0;
      pending_rd_q   <= '0;
      memory_wait_q  <= 1'b0;
      pending_load_q <= 1'b0;
      for (register_index = 0; register_index < 32; register_index++) begin
        regs[register_index] <= '0;
      end
    end else if (!trap_o) begin
      regs[0] <= '0;
      if (memory_wait_q) begin
        if (dmem_ready_i) begin
          if (pending_load_q && (pending_rd_q != 0)) regs[pending_rd_q] <= dmem_rdata_i;
          dmem_valid_o  <= 1'b0;
          memory_wait_q <= 1'b0;
          pc_q          <= pc_q + 32'd4;
        end
      end else begin
        unique case (opcode)
          7'b0010011: begin // ADDI
            if (rd != 0) regs[rd] <= regs[rs1] + immediate_i;
            pc_q <= pc_q + 32'd4;
          end
          7'b0110011: begin // ADD
            if ((imem_rdata_i[14:12] == 3'b000) && (imem_rdata_i[31:25] == 7'b0)) begin
              if (rd != 0) regs[rd] <= regs[rs1] + regs[rs2];
              pc_q <= pc_q + 32'd4;
            end else begin
              trap_o <= 1'b1;
            end
          end
          7'b0000011: begin // LW subset
            dmem_valid_o   <= 1'b1;
            dmem_write_o   <= 1'b0;
            dmem_addr_o    <= regs[rs1] + immediate_i;
            pending_rd_q   <= rd;
            pending_load_q <= 1'b1;
            memory_wait_q  <= 1'b1;
          end
          7'b0100011: begin // SW subset
            dmem_valid_o   <= 1'b1;
            dmem_write_o   <= 1'b1;
            dmem_addr_o    <= regs[rs1] + immediate_s;
            dmem_wdata_o   <= regs[rs2];
            pending_load_q <= 1'b0;
            memory_wait_q  <= 1'b1;
          end
          7'b1100011: begin // BEQ
            if (imem_rdata_i[14:12] == 3'b000) begin
              pc_q <= (regs[rs1] == regs[rs2]) ? pc_q + immediate_b : pc_q + 32'd4;
            end else begin
              trap_o <= 1'b1;
            end
          end
          default: trap_o <= 1'b1;
        endcase
      end
    end
  end
endmodule
`default_nettype wire
