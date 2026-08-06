//////////////////////////////////////////////////////////////////////
////                                                              ////
////  $Id: wb_flash.v,v 1.1 2008-06-04 06:10:35 hharte Exp $          ////
////  wb_flash.v - Wishbone FLASH interface for the StrataFLASH   ////
////               on the Xilinx Spartan3E Starter Kit            ////
////                                                              ////
////  This file is part of the wb_flash Project                   ////
////  http://www.opencores.org/projects/wb_flash/                 ////
////                                                              ////
////  Author:                                                     ////
////      - Howard M. Harte (hharte@opencores.org)                ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2008 Howard M. Harte                           ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`default_nettype none

module wb_flash #(
  parameter int unsigned aw = 19,
  parameter int unsigned dw = 32,
  parameter logic [3:0] ws = 4'hf
) (
  input logic clk_i,
  input logic nrst_i,
  input logic [aw-1:0] wb_adr_i,
  output wire logic [dw-1:0] wb_dat_o,
  input logic [dw-1:0] wb_dat_i,
  input logic [3:0] wb_sel_i,
  input logic wb_we_i,
  input logic wb_stb_i,
  input logic wb_cyc_i,
  output logic wb_ack_o,
  output wire logic [18:0] flash_adr_o,
  output wire logic [7:0] flash_dat_o,
  input logic [7:0] flash_dat_i,
  output wire logic flash_oe,
  output wire logic flash_ce,
  output wire logic flash_we
);

    //
    // Default address and data bus width
    //


    //
    // FLASH interface
    //


    logic [3:0] waitstate;

    wire logic [1:0] adr_low;

    // Wishbone read/write accesses
    wire logic wb_acc = wb_cyc_i & wb_stb_i;    // WISHBONE access
    wire logic wb_wr  = wb_acc & wb_we_i;       // WISHBONE write access
    wire logic wb_rd  = wb_acc & !wb_we_i;      // WISHBONE read access

    always_ff @(posedge clk_i or negedge nrst_i) begin
        if (!nrst_i) begin
            waitstate <= '0;
            wb_ack_o  <= 1'b0;
        end else if (!wb_acc) begin
            waitstate <= '0;
            wb_ack_o  <= 1'b0;
        end else if (waitstate == ws) begin
            waitstate <= '0;
            wb_ack_o  <= 1'b1;
        end else begin
            waitstate <= waitstate + 1'b1;
            wb_ack_o  <= 1'b0;
        end
    end

    assign flash_ce = !wb_acc;
    assign flash_we = !wb_wr;
    assign flash_oe = !wb_rd;

    assign adr_low = wb_sel_i == 4'b0001 ? 2'b00 : wb_sel_i == 4'b0010 ? 2'b01 : wb_sel_i == 4'b0100 ? 2'b10 : 2'b11;
    assign flash_adr_o = {wb_adr_i[18:2], adr_low};
    assign flash_dat_o = wb_sel_i == 4'b0001 ? wb_dat_i[7:0] : wb_sel_i == 4'b0010 ? wb_dat_i[15:8] : wb_sel_i == 4'b0100 ? wb_dat_i[23:16] : wb_dat_i[31:24];
    assign wb_dat_o = {flash_dat_i, flash_dat_i, flash_dat_i, flash_dat_i};

endmodule

`default_nettype wire
