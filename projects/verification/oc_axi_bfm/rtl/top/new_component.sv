`default_nettype none
// new_component.v

// This file was auto-generated as a prototype implementation of a module
// created in component editor.  It ties off all outputs to ground and
// ignores all inputs.  It needs to be edited to make it do something
// useful.
// 
// This file will not be automatically regenerated.  You should check it in
// to your version control system if you want to keep it.

`timescale 1 ps / 1 ps
module new_component (
		input  wire        clock_clk,        //   clock.clk
		output wire [31:0] axm_m0_awaddr,    //  axm_m0.awaddr
		output wire [2:0]  axm_m0_awprot,    //        .awprot
		output wire        axm_m0_awvalid,   //        .awvalid
		input  wire        axm_m0_awready,   //        .awready
		output wire [31:0] axm_m0_wdata,     //        .wdata
		output wire        axm_m0_wlast,     //        .wlast
		output wire        axm_m0_wvalid,    //        .wvalid
		input  wire        axm_m0_wready,    //        .wready
		input  wire        axm_m0_bvalid,    //        .bvalid
		output wire        axm_m0_bready,    //        .bready
		output wire [31:0] axm_m0_araddr,    //        .araddr
		output wire [2:0]  axm_m0_arprot,    //        .arprot
		output wire        axm_m0_arvalid,   //        .arvalid
		input  wire        axm_m0_arready,   //        .arready
		input  wire [31:0] axm_m0_rdata,     //        .rdata
		input  wire        axm_m0_rvalid,    //        .rvalid
		output wire        axm_m0_rready,    //        .rready
		input  wire [31:0] addr,             //  driver.new_signal
		output wire [31:0] r_data,           //        .new_signal_1
		input  wire        transaction_type, //        .new_signal_2
		input  wire [31:0] w_data,           //        .new_signal_3
		output wire        done,             //        .new_signal_4
		input  wire        start,            //        .new_signal_5
		input  wire        reset_reset       // reset_1.reset
	);

  localparam logic [1:0] IDLE=0, READ=1, WRITE=2;
  localparam logic [1:0] N_AW_W=0, AW_NW=1, NAW_W=2, B_WAIT=3;
  localparam logic [1:0] R_AR=0, R_R=1, R_RSP=2;

  logic [1:0] state;
  logic [1:0] write_state;
  logic [1:0] read_state;

  logic done_r;
  logic [31:0] r_data_r;

  logic [31:0] axm_m0_awaddr_r  ;
  logic        axm_m0_awvalid_r ;
  logic [31:0] axm_m0_wdata_r   ;
  logic        axm_m0_wvalid_r  ;
  logic        axm_m0_bready_r  ;
  logic [31:0] axm_m0_araddr_r  ;
  logic        axm_m0_arvalid_r ;
  logic        axm_m0_rready_r  ;
  logic        axm_m0_wlast_r   ;
  logic [2:0]  axm_m0_awprot_r  ; 

  assign done           = done_r          ;
  assign axm_m0_awaddr  = axm_m0_awaddr_r ;
  assign axm_m0_awvalid = axm_m0_awvalid_r;
  assign axm_m0_wdata   = axm_m0_wdata_r  ;
  assign axm_m0_wvalid  = axm_m0_wvalid_r ;
  assign axm_m0_bready  = axm_m0_bready_r ;
  assign axm_m0_arvalid = axm_m0_arvalid_r;
  assign axm_m0_araddr  = axm_m0_araddr_r ;
  assign axm_m0_rready  = axm_m0_rready_r ;
  assign axm_m0_wlast   = axm_m0_wlast_r  ;
  assign axm_m0_awprot  = axm_m0_awprot_r ;
  assign axm_m0_arprot  = 3'b000;
  assign r_data         = r_data_r        ;

  always_ff @(posedge clock_clk)
  begin
    if (reset_reset) begin
      state             <= IDLE;
      write_state       <= N_AW_W;
      read_state        <= R_AR;
      done_r            <= 1'b0;
      r_data_r          <= '0;
      axm_m0_awaddr_r   <= '0;
      axm_m0_awvalid_r  <= 1'b0;
      axm_m0_wdata_r    <= '0;
      axm_m0_wvalid_r   <= 1'b0;
      axm_m0_bready_r   <= 1'b0;
      axm_m0_araddr_r   <= '0;
      axm_m0_arvalid_r  <= 1'b0;
      axm_m0_rready_r   <= 1'b0;
      axm_m0_wlast_r    <= 1'b0;
      axm_m0_awprot_r   <= 3'b000;
    end
    else
    begin
      case(state)
        IDLE: 
        begin
          if(done_r)
          begin
            done_r <= 1'b0;
          end

          if(start)
          begin
            done_r <= 1'b0;
            if(transaction_type)
            begin
              axm_m0_arvalid_r <= 1'b1;
              axm_m0_araddr_r  <= addr;
              state            <= READ;
              read_state       <= R_AR;
            end
            else
            begin
              axm_m0_awaddr_r   <= addr;
              axm_m0_awvalid_r  <= 1'b1;
              axm_m0_wdata_r    <= w_data;
              axm_m0_wvalid_r   <= 1'b1;
              axm_m0_wlast_r    <= 1'b1;
              axm_m0_awprot_r   <= 3'b000;
              state             <= WRITE;
              write_state       <= N_AW_W;
            end
          end
        end
        READ:
        begin
          case(read_state)
            R_AR:
            begin
              if(axm_m0_arvalid & axm_m0_arready)
              begin
                read_state       <= R_R;
                axm_m0_arvalid_r <= 1'b0;
                axm_m0_rready_r  <= 1'b1;
              end
            end
            R_R:
            begin
              if(axm_m0_rready & axm_m0_rvalid)
              begin
                read_state      <= R_RSP;
                r_data_r        <= axm_m0_rdata;
                axm_m0_rready_r <= 1'b0;
              end
            end
            R_RSP:
            begin
              done_r <= 1'b1;
              state             <= IDLE;
            end
          endcase
        end
        WRITE:
        begin
          case(write_state)
            N_AW_W:
            begin
              if(axm_m0_awvalid & axm_m0_awready & axm_m0_wvalid & axm_m0_wready)
              begin
                axm_m0_awvalid_r <= 1'b0;
                axm_m0_wvalid_r <= 1'b0;
                axm_m0_bready_r <= 1'b1;
                write_state <= B_WAIT;
              end
              else if(axm_m0_awvalid & axm_m0_awready)
              begin
                axm_m0_awvalid_r <= 1'b0;
                write_state <= AW_NW;
              end
              else if(axm_m0_wvalid & axm_m0_wready) //Not sure if this can actually happen
              begin
                axm_m0_wvalid_r <= 1'b0;
                write_state <= NAW_W; 
              end
            end
            AW_NW:
            begin                        
                if(axm_m0_wvalid & axm_m0_wready)
                begin
                  axm_m0_wvalid_r <= 1'b0;
                  axm_m0_bready_r <= 1'b1;
                  write_state <= B_WAIT; 
                end
            end
            NAW_W:
            begin
              if(axm_m0_awvalid & axm_m0_awready)
              begin
                axm_m0_awvalid_r <= 1'b0;
                axm_m0_bready_r <= 1'b1;
                write_state <= B_WAIT;
              end
            end
            B_WAIT:
            begin
              if(axm_m0_bvalid & axm_m0_bready)
              begin
                state <= IDLE;
                done_r <= 1'b1;
                axm_m0_bready_r <= 1'b0;
              end
            end
          endcase
        end
      endcase
    end
  end



endmodule

`default_nettype wire
