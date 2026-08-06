//
// LogicProbe.v -- on-chip logic probe with trace memory and read-out facility
//

`timescale 1ns/1ns

`default_nettype none

module LogicProbe (
  input logic clock,
  input logic reset,
  input logic trigger,
  input logic sample,
  input logic [127:0] channels,
  output wire logic serial_out
);


  wire full;
  logic [12:0] rdaddr;
  wire [7:0] data;
  logic write;
  wire ready;
  logic done;
  logic state;

  LogicProbe_sampler
    sampler(clock, reset, trigger, sample, channels, full, rdaddr, data);

  LogicProbe_xmtbuf
    xmtbuf(clock, reset, write, ready, data, serial_out);

  always_ff @(posedge clock) begin
    if (reset == 1) begin
      rdaddr <= 13'd0;
      write <= 0;
      done <= 0;
      state <= 0;
    end else begin
      if (full == 1 && done == 0) begin
        if (state == 0) begin
          if (ready == 1) begin
            state <= 1;
            write <= 1;
          end
        end else begin
          if (rdaddr == 13'd8191) begin
            done <= 1;
          end
          state <= 0;
          write <= 0;
          rdaddr <= rdaddr + 1;
        end
      end
    end
  end

endmodule

`default_nettype none

module LogicProbe_sampler (
  input logic clock,
  input logic reset,
  input logic trigger,
  input logic sample,
  input logic [127:0] data_in,
  output logic full,
  input logic [12:0] rdaddr,
  output logic [7:0] data_out
);


  logic [31:0] mem3[0:511];
  logic [31:0] mem2[0:511];
  logic [31:0] mem1[0:511];
  logic [31:0] mem0[0:511];

  logic [8:0] wraddr;
  wire [8:0] addr;
  logic [31:0] data3;
  logic [31:0] data2;
  logic [31:0] data1;
  logic [31:0] data0;

  logic [3:0] muxctrl;
  logic triggered;

  // addr for trace memory
  // full == 0 means data capture
  // full == 1 means data readout
  assign addr = (full == 0) ? wraddr: rdaddr[12:4];

  // pipeline register for output mux control: necessary
  // because the trace memory has one clock delay too
  always_ff @(posedge clock) begin
    muxctrl <= rdaddr[3:0];
  end

  // output multiplexer
  always_comb begin
    case (muxctrl)
      4'h0: data_out = data3[31:24];
      4'h1: data_out = data3[23:16];
      4'h2: data_out = data3[15: 8];
      4'h3: data_out = data3[ 7: 0];
      4'h4: data_out = data2[31:24];
      4'h5: data_out = data2[23:16];
      4'h6: data_out = data2[15: 8];
      4'h7: data_out = data2[ 7: 0];
      4'h8: data_out = data1[31:24];
      4'h9: data_out = data1[23:16];
      4'hA: data_out = data1[15: 8];
      4'hB: data_out = data1[ 7: 0];
      4'hC: data_out = data0[31:24];
      4'hD: data_out = data0[23:16];
      4'hE: data_out = data0[15: 8];
      4'hF: data_out = data0[ 7: 0];
    endcase
  end

  // trace memory
  always_ff @(posedge clock) begin
    if (full == 0) begin
      mem3[addr] <= data_in[127:96];
      mem2[addr] <= data_in[ 95:64];
      mem1[addr] <= data_in[ 63:32];
      mem0[addr] <= data_in[ 31: 0];
    end
    data3 <= mem3[addr];
    data2 <= mem2[addr];
    data1 <= mem1[addr];
    data0 <= mem0[addr];
  end

  // state machine which fills trace memory after trigger occurred
  // it takes one sample per clock tick, but only when sample == 1
  always_ff @(posedge clock) begin
    if (reset == 1) begin
      wraddr <= 9'd0;
      triggered <= 0;
      full <= 0;
    end else begin
      if (triggered == 1) begin
        // capture data, but only when sample == 1
        if (sample == 1) begin
          if (wraddr == 9'd511) begin
            // last sample, memory is full
            full <= 1;
          end else begin
            wraddr <= wraddr + 1;
          end
        end
      end else begin
        // wait for trigger, possibly capture first sample
        if (trigger == 1) begin
          triggered <= 1;
          if (sample == 1) begin
            wraddr <= wraddr + 1;
          end
        end
      end
    end
  end

endmodule

`default_nettype none

module LogicProbe_xmtbuf (
  input logic clock,
  input logic reset,
  input logic write,
  output logic ready,
  input logic [7:0] data_in,
  output wire logic serial_out
);


  logic [1:0] state;
  logic [7:0] data_hold;
  logic load;
  wire empty;

  LogicProbe_xmt xmt(clock, reset, load, empty, data_hold, serial_out);

  always_ff @(posedge clock) begin
    if (reset == 1) begin
      state <= 2'b00;
      ready <= 1;
      load <= 0;
    end else begin
      case (state)
        2'b00:
          begin
            if (write == 1) begin
              state <= 2'b01;
              data_hold <= data_in;
              ready <= 0;
              load <= 1;
            end
          end
        2'b01:
          begin
            state <= 2'b10;
            ready <= 1;
            load <= 0;
          end
        2'b10:
          begin
            if (empty == 1 && write == 0) begin
              state <= 2'b00;
              ready <= 1;
              load <= 0;
            end else
            if (empty == 1 && write == 1) begin
              state <= 2'b01;
              data_hold <= data_in;
              ready <= 0;
              load <= 1;
            end else
            if (empty == 0 && write == 1) begin
              state <= 2'b11;
              data_hold <= data_in;
              ready <= 0;
              load <= 0;
            end
          end
        2'b11:
          begin
            if (empty == 1) begin
              state <= 2'b01;
              ready <= 0;
              load <= 1;
            end
          end
      endcase
    end
  end

endmodule

`default_nettype none

module LogicProbe_xmt (
  input logic clock,
  input logic reset,
  input logic load,
  output logic empty,
  input logic [7:0] parallel_in,
  output wire logic serial_out
);


  logic [3:0] state;
  logic [8:0] shift;
  logic [10:0] count;

  assign serial_out = shift[0];

  always_ff @(posedge clock) begin
    if (reset == 1) begin
      state <= 4'h0;
      shift <= 9'b111111111;
      empty <= 1;
    end else begin
      if (state == 4'h0) begin
        if (load == 1) begin
          state <= 4'h1;
          shift <= { parallel_in, 1'b0 };
          count <= 1302;
          empty <= 0;
        end
      end else
      if (state == 4'hb) begin
        state <= 4'h0;
        empty <= 1;
      end else begin
        if (count == 0) begin
          state <= state + 1;
          shift[8:0] <= { 1'b1, shift[8:1] };
          count <= 1302;
        end else begin
          count <= count - 1;
        end
      end
    end
  end

endmodule

`default_nettype wire

`default_nettype wire

`default_nettype wire

`default_nettype wire
