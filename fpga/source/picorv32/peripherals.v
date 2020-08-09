module peripherals (
	    input  clk,
	    input  nrst,

	    output reg[31:0] data_out,
	    input wire[31:0] data_in,
	    input wire[5:0] addr,
	    input cs,
	    input oe,
	    input[3:0] wstrb,

	    // PORTA
	    inout[7:0]                    porta,

	    // PORTB
	    inout[7:0]                    portb,

	    // SDCARD
	    input                         sdcard_sck,
	    input                         sdcard_mosi,
	    output                        sdcard_miso,

	    // UART related
	    input                         rxd,
	    output wire                   txd,
            );

   wire [7:0]  porta_pinx;
   reg [7:0]   porta_portx;
   reg [7:0]   porta_ddrx;

   wire [7:0]  portb_pinx;
   reg [7:0]   portb_portx;
   reg [7:0]   portb_ddrx;

   reg [10:0]  ser_out = ~0;
   reg [8:0]   ser_in = ~0;
   reg [15:0]  ser_tx_cnt = 0;
   reg [15:0]  ser_rx_cnt = 0;
   reg [7:0]   ser_rx_data;
   reg [15:0]  ser_brr;
   reg         ser_rxc;
   reg         ser_fe;
   reg         ser_dor;
   reg         rxd_s;
   assign txd = ser_out[0];

   tri_buf tri_buf_porta_inst[7:0](.out(porta_portx), .in(porta_pinx),
				   .en(porta_ddrx), .pin(porta));

   tri_buf tri_buf_portb_inst[7:0](
	       .out ({portb_portx[7:3],
		      {sdcard_mosi, sdcard_sck},
		      portb_portx[0]}),
	       .in  (portb_pinx),
	       .en  ({portb_ddrx[7:4], 1'b0, portb_ddrx[2:0]}),
	       .pin (portb));
   assign sdcard_miso = portb_pinx[3];

   always @(posedge clk)
     if (~nrst) begin
	porta_portx <= 8'h00;
	porta_ddrx <= 8'h00;
	portb_portx <= 8'h00;
	portb_ddrx <= 8'h00;
	ser_out <= ~0;
	ser_in <= ~0;
	ser_tx_cnt <= 0;
	ser_rx_cnt <= 0;
	ser_brr <= 0;
	ser_rx_data <= 8'h00;
	ser_rxc <= 1'b0;
	ser_fe  <= 1'b0;
	ser_dor <= 1'b0;
	rxd_s <= 1'b1;
     end else begin
	if (ser_tx_cnt == 0) begin
	   ser_out <= {1'b1,ser_out[10:1]};
	   ser_tx_cnt <= ser_brr;
	end else
	  ser_tx_cnt <= ser_tx_cnt - 1;

	if (ser_rx_cnt == 0) begin
	   ser_rx_cnt <= ser_brr;
	   if (!ser_in[0]) begin
	      ser_rx_data <= ser_in[8:1];
	      ser_fe <= ~rxd_s;
	      ser_dor <= ser_rxc;
	      ser_rxc <= 1'b1;
	      ser_in <= ~0;
	   end else
	     ser_in <= { rxd_s, ser_in[8:1] };
	end else if (&ser_in && rxd_s) // if (ser_rx_cnt == 0)
	  ser_rx_cnt <= ser_brr >> 1;
	else
	  ser_rx_cnt <= ser_rx_cnt - 1;
	rxd_s <= rxd;

	if(cs && oe && addr == 6'h08) begin
	   /* UDR0 is read, clear RXC0, FE0, and DOR0 */
	   ser_rxc <= 1'b0;
	   ser_fe <= 1'b0;
	   ser_dor <= 1'b0;
	end

	if(cs && wstrb[0])
	  case(addr)
	    6'h00: porta_portx <= data_in[7:0];
	    6'h02: porta_ddrx  <= data_in[7:0];
	    6'h04: portb_portx <= data_in[7:0];
	    6'h06: portb_ddrx  <= data_in[7:0];
	    6'h08: ser_out <= {1'b1, data_in[7:0], 1'b0, 1'b1};
	    6'h0a: ser_brr[7:0] <= data_in[7:0];
	  endcase; // case (addr)
	if(cs && wstrb[1])
	  case(addr)
	    6'h0a: ser_brr[15:8] <= data_in[15:8];
	  endcase; // case (addr)
     end // else: !if(~nrst)

   always @(*) begin
      data_out = 32'h00000000;
      if (nrst && cs && oe)
	case(addr)
	  6'h00: data_out[7:0] = porta_portx;
	  6'h01: data_out[7:0] = porta_pinx;
	  6'h02: data_out[7:0] = porta_ddrx;
	  6'h04: data_out[7:0] = portb_portx;
	  6'h05: data_out[7:0] = portb_pinx;
	  6'h06: data_out[7:0] = portb_ddrx;
	  6'h08: data_out[7:0] = ser_rx_data;
	  6'h09: data_out[7:0] = {ser_rxc, &ser_out, &ser_out, ser_fe, ser_dor, 3'b000};
	  6'h0a: data_out[15:0] = ser_brr;
	endcase // case (addr)
   end

endmodule // peripherals
