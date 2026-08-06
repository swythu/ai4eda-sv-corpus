/*
    Clock Domain Crossing micro FIFO
    Copyright (C) 2010 Alexandr Litjagin (aka AlexRayne)

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

`default_nettype none

module cdc_ufifo #(
  parameter int unsigned lpm_width = 8,
  parameter int unsigned lpm_depth = 2,
  parameter string shadowed = "FALSE",
  parameter string realization = "REGS"
) (
  input  logic                 in_clk,
  input  logic                 denable,
  input  logic                 reset,
  input  logic [lpm_width-1:0] d,
  input  logic                 q_clk,
  input  logic                 qenable,
  output logic [lpm_width-1:0] q,
  output logic                 ready
);
  localparam int unsigned DEPTH = lpm_depth * 2;
  localparam int unsigned ADDR_WIDTH = $clog2(DEPTH);
  localparam int unsigned PTR_WIDTH = ADDR_WIDTH + 1;

  logic [lpm_width-1:0] memory [0:DEPTH-1];
  logic [PTR_WIDTH-1:0] write_binary, write_binary_next;
  logic [PTR_WIDTH-1:0] write_gray, write_gray_next;
  logic [PTR_WIDTH-1:0] read_binary, read_binary_next;
  logic [PTR_WIDTH-1:0] read_gray, read_gray_next;
  (* async_reg = "true" *) logic [PTR_WIDTH-1:0] read_gray_sync1;
  (* async_reg = "true" *) logic [PTR_WIDTH-1:0] read_gray_sync2;
  (* async_reg = "true" *) logic [PTR_WIDTH-1:0] write_gray_sync1;
  (* async_reg = "true" *) logic [PTR_WIDTH-1:0] write_gray_sync2;
  logic write_full, write_full_next;
  logic read_empty, read_empty_next;
  logic write_fire, read_fire;

  function automatic logic [PTR_WIDTH-1:0] binary_to_gray(
    input logic [PTR_WIDTH-1:0] value
  );
    return (value >> 1) ^ value;
  endfunction

  initial begin
    if (DEPTH < 4 || (DEPTH & (DEPTH - 1)) != 0)
      $error("cdc_ufifo DEPTH must be a power of two and at least four");
    if (realization != "REGS")
      $error("refactored cdc_ufifo supports realization=REGS only");
  end

  always_comb begin
    write_fire = denable && !write_full;
    write_binary_next = write_binary + write_fire;
    write_gray_next = binary_to_gray(write_binary_next);
    write_full_next = (
      write_gray_next
      == {
        ~read_gray_sync2[PTR_WIDTH-1:PTR_WIDTH-2],
        read_gray_sync2[PTR_WIDTH-3:0]
      }
    );
  end

  always_ff @(posedge in_clk or posedge reset) begin
    if (reset) begin
      write_binary <= '0;
      write_gray <= '0;
      write_full <= 1'b0;
    end else begin
      write_binary <= write_binary_next;
      write_gray <= write_gray_next;
      write_full <= write_full_next;
      if (write_fire)
        memory[write_binary[ADDR_WIDTH-1:0]] <= d;
    end
  end

  always_ff @(posedge in_clk or posedge reset) begin
    if (reset) begin
      read_gray_sync1 <= '0;
      read_gray_sync2 <= '0;
    end else begin
      read_gray_sync1 <= read_gray;
      read_gray_sync2 <= read_gray_sync1;
    end
  end

  always_comb begin
    read_fire = qenable && !read_empty;
    read_binary_next = read_binary + read_fire;
    read_gray_next = binary_to_gray(read_binary_next);
    read_empty_next = (read_gray_next == write_gray_sync2);
  end

  always_ff @(posedge q_clk or posedge reset) begin
    if (reset) begin
      read_binary <= '0;
      read_gray <= '0;
      read_empty <= 1'b1;
    end else begin
      read_binary <= read_binary_next;
      read_gray <= read_gray_next;
      read_empty <= read_empty_next;
    end
  end

  always_ff @(posedge q_clk or posedge reset) begin
    if (reset) begin
      write_gray_sync1 <= '0;
      write_gray_sync2 <= '0;
    end else begin
      write_gray_sync1 <= write_gray;
      write_gray_sync2 <= write_gray_sync1;
    end
  end

  generate
    if (shadowed == "TRUE") begin : generate_registered_output
      always_ff @(posedge q_clk or posedge reset) begin
        if (reset)
          q <= '0;
        else if (read_fire)
          q <= memory[read_binary[ADDR_WIDTH-1:0]];
      end
    end else begin : generate_combinational_output
      always_comb begin
        q = memory[read_binary[ADDR_WIDTH-1:0]];
      end
    end
  endgenerate

  always_comb begin
    ready = !read_empty;
  end
endmodule

`default_nettype wire
