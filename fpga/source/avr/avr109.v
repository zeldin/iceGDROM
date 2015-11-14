// To use:

// avrdude -c butterfly_mk -p ucr2 -b <baudrate> -P <serial port> -U flash:w:<fn>


module avr109 (
	       input rst,
	       input clk,
	       input rxd,
	       output txd,
	       output intercept_mode,
	       output prog_mode,
	       output[15:0] prog_addr,
	       output[15:0] prog_data,
	       input[15:0] prog_data_in,
	       output prog_low,
	       output prog_high,
	       output[7:0] debug
	       );
   parameter CLK_FREQUENCY = 1000000;
   parameter BAUD_RATE = 19200;

   parameter VERSION_HIGH = "1";
   parameter VERSION_LOW = "0";

   reg 	     tx_avail_d, tx_avail_q;
   reg [7:0] tx_data_d, tx_data_q;
   reg [4:0] state_d, state_q;
   reg [7:0] cnt_d, cnt_q;
   reg [15:0] addr_d, addr_q;
   reg 	      prog_strobe;
   reg        prog_mode_d, prog_mode_q;

   wire       tx_ready;
   wire       rx_avail;
   wire [7:0] rx_data;
   wire       rx_enabled;
   wire       send_ok;

   assign     intercept_mode = (state_q >= STATE_IDLE);
   assign     prog_addr = {1'b0,addr_q[15:1]};
   assign     prog_data = {rx_data,rx_data};
   assign     prog_mode = prog_mode_q;
   assign     prog_low = prog_strobe & ~addr_q[0];
   assign     prog_high = prog_strobe & addr_q[0];
   assign     send_ok = tx_ready & ~tx_avail_q;

   assign debug = {intercept_mode, rxd, txd, state_q};

   localparam STATE_INACTIVE    = 0;
   localparam STATE_ATTACHING   = 1;
   localparam STATE_IDLE        = 2;
   localparam STATE_BAD_COMMAND = 3;
   localparam STATE_GET_V_HIGH  = 4;
   localparam STATE_GET_V_LOW   = 5;
   localparam STATE_SEND_Y      = 6;
   localparam STATE_GET_BS_Y    = 7;
   localparam STATE_GET_BS_HI   = 8;
   localparam STATE_GET_BS_LO   = 9;
   localparam STATE_SEND_00     = 10;
   localparam STATE_IGNORE_DATA = 11;
   localparam STATE_ACK_CMD     = 12;
   localparam STATE_SET_ADDR_HI = 13;
   localparam STATE_SET_ADDR_LO = 14;
   localparam STATE_SET_CNT_HI  = 16;
   localparam STATE_SET_CNT_LO  = 17;
   localparam STATE_CHECK_FLASH = 18;
   localparam STATE_PROG_GET    = 19;
   localparam STATE_PROG_PUT    = 20;
   localparam STATE_EXIT1       = 21;
   localparam STATE_EXIT2       = 22;
   localparam STATE_SET_CNT_HI2  = 24;
   localparam STATE_SET_CNT_LO2  = 25;
   localparam STATE_CHECK_FLASH2 = 26;
   localparam STATE_READ_GET    = 27;
   localparam STATE_READ_PUT    = 28;

   avr109tx #(.CLK_FREQUENCY(CLK_FREQUENCY), .BAUD_RATE(BAUD_RATE))
            avr109tx_inst(.rst(rst), .clk(clk),
			  .tx_data(tx_data_q), .tx_avail(tx_avail_q),
			  .txd(txd), .tx_ready(tx_ready));

   avr109rx #(.CLK_FREQUENCY(CLK_FREQUENCY), .BAUD_RATE(BAUD_RATE))
            avr109rx_inst(.rst(rst), .clk(clk),
			  .rx_data(rx_data), .rx_avail(rx_avail),
			  .rxd(rxd), .rx_enabled(rx_enabled));

   assign rx_enabled = 1'b1;

   always @(*) begin
      tx_avail_d = 0;
      tx_data_d = 8'h00;
      state_d = state_q;
      cnt_d = cnt_q;
      addr_d = addr_q;
      prog_strobe = 1'b0;
      prog_mode_d = prog_mode_q;

      case (state_q)

	STATE_INACTIVE: begin
	   cnt_d = 0;
	   prog_mode_d = 0;
	   if (rx_avail & (rx_data == 8'h1b))
	     state_d = STATE_ATTACHING;
	end

	STATE_ATTACHING: begin
	   if (rx_avail) begin
	      if (rx_data != ((cnt_q&1)? 8'h1b : 8'haa))
		state_d = STATE_INACTIVE;
	      else begin
		 cnt_d[2:0] = cnt_q[2:0] + 1;
		 if (cnt_q[2:0] == 5)
		   state_d = STATE_IDLE;
	      end
	   end
	end

	STATE_IDLE: begin
	   if (rx_avail) begin
	      case (rx_data)
		8'h0a, 8'h1b: ;
		8'h41: state_d = STATE_SET_ADDR_HI;
		8'h42: state_d = STATE_SET_CNT_HI;
		8'h45: state_d = STATE_EXIT1;
		8'h4c: begin
		   prog_mode_d = 1'b0;
		   state_d = STATE_ACK_CMD;
		end
		8'h50: begin
		   prog_mode_d = 1'b1;
		   state_d = STATE_ACK_CMD;
		end
		8'h54: state_d = STATE_IGNORE_DATA;
		8'h56: state_d = STATE_GET_V_HIGH;
		8'h61: state_d = STATE_SEND_Y;
		8'h62: state_d = STATE_GET_BS_Y;
		8'h67: state_d = STATE_SET_CNT_HI2;
		8'h74: state_d = STATE_SEND_00;
		default: state_d = STATE_BAD_COMMAND;
	      endcase // case (rx_data)
	   end
	end

	STATE_BAD_COMMAND: begin
	   if (send_ok) begin
	      tx_data_d = 8'h3f;
	      tx_avail_d = 1'b1;
	      state_d = STATE_IDLE;
	   end
	end

	STATE_GET_V_HIGH: begin
	   if (send_ok) begin
	      tx_data_d = VERSION_HIGH;
	      tx_avail_d = 1'b1;
	      state_d = STATE_GET_V_LOW;
	   end
	end

	STATE_GET_V_LOW: begin
	   if (send_ok) begin
	      tx_data_d = VERSION_LOW;
	      tx_avail_d = 1'b1;
	      state_d = STATE_IDLE;
	   end
	end

	STATE_SEND_Y: begin
	   if (send_ok) begin
	      tx_data_d = 8'h59;
	      tx_avail_d = 1'b1;
	      state_d = STATE_IDLE;
	   end
	end

	STATE_GET_BS_Y: begin
	   if (send_ok) begin
	      tx_data_d = 8'h59;
	      tx_avail_d = 1'b1;
	      state_d = STATE_GET_BS_HI;
	   end
	end
	STATE_GET_BS_HI: begin
	   if (send_ok) begin
	      tx_data_d = 8'h00;
	      tx_avail_d = 1'b1;
	      state_d = STATE_GET_BS_LO;
	   end
	end
	STATE_GET_BS_LO: begin
	   if (send_ok) begin
	      tx_data_d = 8'hff;
	      tx_avail_d = 1'b1;
	      state_d = STATE_IDLE;
	   end
	end

	STATE_SEND_00: begin
	   if (send_ok) begin
	      tx_data_d = 8'h00;
	      tx_avail_d = 1'b1;
	      state_d = STATE_IDLE;
	   end
	end

	STATE_IGNORE_DATA: begin
	   if (rx_avail)
	     state_d = STATE_ACK_CMD;
	end

	STATE_ACK_CMD: begin
	   if (send_ok) begin
	      tx_data_d = 8'h0d;
	      tx_avail_d = 1'b1;
	      state_d = STATE_IDLE;
	   end
	end

	STATE_SET_ADDR_HI: begin
	   if (rx_avail) begin
	      addr_d[15:8] = rx_data;
	      state_d = STATE_SET_ADDR_LO;
	   end
	end
	STATE_SET_ADDR_LO: begin
	   if (rx_avail) begin
	      addr_d[7:0] = rx_data;
	      state_d = STATE_ACK_CMD;
	   end
	end

	STATE_SET_CNT_HI: begin
	   if (rx_avail) begin
	      if (rx_data == 0)
		state_d = STATE_SET_CNT_LO;
	      else
		state_d = STATE_BAD_COMMAND;
	   end
	end
	STATE_SET_CNT_LO: begin
	   if (rx_avail) begin
	      cnt_d = rx_data;
	      state_d = STATE_CHECK_FLASH;
	   end
	end
	STATE_CHECK_FLASH: begin
	   if (rx_avail) begin
	      if (rx_data == 8'h46)
		state_d = (cnt_q == 0? STATE_ACK_CMD : STATE_PROG_GET);
	      else
		state_d = STATE_BAD_COMMAND;
	   end
	end
	STATE_PROG_GET: begin
	   if (rx_avail) begin
	      cnt_d = cnt_q - 1;
	      state_d = STATE_PROG_PUT;
	      prog_strobe = 1'b1;
	   end
	end
	STATE_PROG_PUT: begin
	   addr_d = addr_q + 1;
	   state_d = (cnt_q == 0? STATE_ACK_CMD : STATE_PROG_GET);
	end

	STATE_SET_CNT_HI2: begin
	   if (rx_avail) begin
	      if (rx_data == 0)
		state_d = STATE_SET_CNT_LO2;
	      else
		state_d = STATE_BAD_COMMAND;
	   end
	end
	STATE_SET_CNT_LO2: begin
	   if (rx_avail) begin
	      cnt_d = rx_data;
	      state_d = STATE_CHECK_FLASH2;
	   end
	end
	STATE_CHECK_FLASH2: begin
	   if (rx_avail) begin
	      if (rx_data == 8'h46)
		state_d = (cnt_q == 0? STATE_IDLE : STATE_READ_GET);
	      else
		state_d = STATE_BAD_COMMAND;
	   end
	end
	STATE_READ_GET: begin
	   tx_data_d = (addr_q[0]? prog_data_in[15:8]:prog_data_in[7:0]);
	   if (send_ok) begin
	      tx_avail_d = 1'b1;
	      cnt_d = cnt_q - 1;
	      state_d = STATE_READ_PUT;
	   end
	end
	STATE_READ_PUT: begin
	   addr_d = addr_q + 1;
	   state_d = (cnt_q == 0? STATE_IDLE : STATE_READ_GET);
	end

	STATE_EXIT1: begin
	   if (send_ok) begin
	      tx_data_d = 8'h0d;
	      tx_avail_d = 1'b1;
	      state_d = STATE_EXIT2;
	   end
	end
	STATE_EXIT2: begin
	   if (send_ok)
	     state_d = STATE_INACTIVE;
	end

      endcase // case (state)
   end

   always @(posedge clk) begin
      if (rst) begin
	 tx_avail_q <= 1'b0;
	 tx_data_q <= 8'h00;
	 state_q <= STATE_INACTIVE;
	 cnt_q <= 0;
	 addr_q <= 0;
	 prog_mode_q <= 1'b0;
      end else begin
	 tx_avail_q <= tx_avail_d;
	 tx_data_q <= tx_data_d;
	 state_q <= state_d;
	 cnt_q <= cnt_d;
	 addr_q <= addr_d;
	 prog_mode_q <= prog_mode_d;
      end
   end

endmodule // avr109
