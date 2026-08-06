`default_nettype none

module pid_controller #(
  parameter int unsigned ADDR_WIDTH = 16
) (
  input  logic                  clk,
  input  logic                  rst,
  input  logic                  wb_cyc,
  input  logic                  wb_stb,
  input  logic                  wb_we,
  input  logic [ADDR_WIDTH-1:0] wb_adr,
  input  logic [31:0]           wb_data_i,
  output logic                  wb_ack,
  output logic [31:0]           wb_data_o,
  output logic signed [31:0]    control_o,
  output logic                  control_valid_o
);
  localparam logic [3:0] REG_KP       = 4'd0;
  localparam logic [3:0] REG_KI       = 4'd1;
  localparam logic [3:0] REG_KD       = 4'd2;
  localparam logic [3:0] REG_SETPOINT = 4'd3;
  localparam logic [3:0] REG_PROCESS  = 4'd4;
  localparam logic [3:0] REG_ERROR    = 4'd5;
  localparam logic [3:0] REG_PREV_ERR = 4'd6;
  localparam logic [3:0] REG_CONTROL  = 4'd7;
  localparam logic [3:0] REG_INTEGRAL = 4'd8;
  localparam logic [3:0] REG_STATUS   = 4'd10;
  localparam logic [3:0] REG_RESET    = 4'd11;

  logic signed [15:0] kp, ki, kd;
  logic signed [15:0] setpoint, process_value;
  logic signed [16:0] error, previous_error;
  logic signed [31:0] integral;
  logic overflow_sticky;
  logic request;
  logic [3:0] word_address;

  logic signed [16:0] sample_error;
  logic signed [17:0] derivative_error;
  logic signed [33:0] proportional_wide, integral_delta_wide;
  logic signed [34:0] derivative_wide;
  logic signed [34:0] integral_next_wide, control_wide;

  assign request = wb_cyc && wb_stb;
  assign word_address = wb_adr[5:2];
  assign sample_error = $signed(setpoint) - $signed(wb_data_i[15:0]);
  assign derivative_error = sample_error - error;
  assign proportional_wide = $signed(kp) * sample_error;
  assign integral_delta_wide = $signed(ki) * sample_error;
  assign derivative_wide = $signed(kd) * derivative_error;
  assign integral_next_wide = $signed({{3{integral[31]}}, integral}) + integral_delta_wide;
  assign control_wide = proportional_wide + integral_next_wide + derivative_wide;

  always_comb begin
    unique case (word_address)
      REG_KP:       wb_data_o = {{16{kp[15]}}, kp};
      REG_KI:       wb_data_o = {{16{ki[15]}}, ki};
      REG_KD:       wb_data_o = {{16{kd[15]}}, kd};
      REG_SETPOINT: wb_data_o = {{16{setpoint[15]}}, setpoint};
      REG_PROCESS:  wb_data_o = {{16{process_value[15]}}, process_value};
      REG_ERROR:    wb_data_o = {{15{error[16]}}, error};
      REG_PREV_ERR: wb_data_o = {{15{previous_error[16]}}, previous_error};
      REG_CONTROL:  wb_data_o = control_o;
      REG_INTEGRAL: wb_data_o = integral;
      REG_STATUS:   wb_data_o = {31'b0, overflow_sticky};
      default:      wb_data_o = 32'h0;
    endcase
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      wb_ack          <= 1'b0;
      kp              <= '0;
      ki              <= '0;
      kd              <= '0;
      setpoint        <= '0;
      process_value   <= '0;
      error           <= '0;
      previous_error  <= '0;
      integral        <= '0;
      control_o       <= '0;
      control_valid_o <= 1'b0;
      overflow_sticky <= 1'b0;
    end else begin
      wb_ack          <= request && !wb_ack;
      control_valid_o <= 1'b0;

      if (request && !wb_ack && wb_we) begin
        unique case (word_address)
          REG_KP:       kp <= wb_data_i[15:0];
          REG_KI:       ki <= wb_data_i[15:0];
          REG_KD:       kd <= wb_data_i[15:0];
          REG_SETPOINT: setpoint <= wb_data_i[15:0];
          REG_PROCESS: begin
            process_value   <= wb_data_i[15:0];
            previous_error  <= error;
            error           <= sample_error;
            integral        <= integral_next_wide[31:0];
            control_o       <= control_wide[31:0];
            control_valid_o <= 1'b1;
            overflow_sticky <= overflow_sticky |
              (integral_next_wide[34:32] != {3{integral_next_wide[31]}}) |
              (control_wide[34:32] != {3{control_wide[31]}});
          end
          REG_RESET: if (wb_data_i == 0) begin
            error           <= '0;
            previous_error  <= '0;
            integral        <= '0;
            control_o       <= '0;
            overflow_sticky <= 1'b0;
          end
          default: ;
        endcase
      end
    end
  end
endmodule

`default_nettype wire
