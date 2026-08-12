`default_nettype none
//---------------------------------------------------------------------------------------
// uart top level module
//
//---------------------------------------------------------------------------------------

module uart_top
(
	// global signals
	input  wire        clock,        // global clock input
	input  wire        reset,        // global reset input
	// uart serial signals
	input  wire        ser_in,       // serial data input
	output wire        ser_out,      // serial data output
	// transmit and receive internal interface signals
	output wire [7:0]  rx_data,      // data byte received
	output wire        new_rx_data,  // signs that a new byte was received
	input  wire [7:0]  tx_data,      // data byte to transmit
	input  wire        new_tx_data,  // asserted to indicate that there is a new data byte for transmission
	output wire        tx_busy,      // signs that transmitter is busy
	// baud rate configuration register - see baud_gen.sv for details
	input  wire [11:0] baud_freq,    // baud rate setting registers - see header description
	input  wire [15:0] baud_limit,
	output wire        baud_clk
);

// internal wires
wire ce_16;		// clock enable at bit rate

assign baud_clk = ce_16;

//---------------------------------------------------------------------------------------
// module implementation
// baud rate generator module
baud_gen baud_gen_1
(
	.clock(clock), .reset(reset),
	.ce_16(ce_16), .baud_freq(baud_freq), .baud_limit(baud_limit)
);

// uart receiver
uart_rx uart_rx_1
(
	.clock(clock), .reset(reset),
	.ce_16(ce_16), .ser_in(ser_in),
	.rx_data(rx_data), .new_rx_data(new_rx_data)
);

// uart transmitter
uart_tx uart_tx_1
(
	.clock(clock), .reset(reset),
	.ce_16(ce_16), .tx_data(tx_data), .new_tx_data(new_tx_data),
	.ser_out(ser_out), .tx_busy(tx_busy)
);

endmodule
//---------------------------------------------------------------------------------------
//						Th.. Th.. Th.. Thats all folks !!!
//---------------------------------------------------------------------------------------
`default_nettype wire
