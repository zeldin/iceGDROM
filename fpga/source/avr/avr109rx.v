module avr109rx (
		 input rst,
		 input clk,
		 output[7:0] rx_data,
		 output rx_avail,
		 input rxd,
		 input rx_enabled
		 );
   parameter CLK_FREQUENCY = 1000000;
   parameter BAUD_RATE = 19200;

   function integer log2;
      input integer value;
      begin
         value = value-1;
         for (log2=0; value>0; log2=log2+1)
           value = value>>1;
      end
   endfunction

   localparam BAUDDIV = (CLK_FREQUENCY / BAUD_RATE);
   localparam LOG2_BAUDDIV = log2(BAUDDIV);

   reg [7:0] rxshift_d, rxshift_q;
   reg 	     rx_active_d, rx_active_q;
   reg 	     rx_done_d, rx_done_q;
   reg [3:0] rxcnt_d,   rxcnt_q;
   reg [LOG2_BAUDDIV-1:0] rxbaud_d, rxbaud_q;

   assign rx_data = rxshift_q;
   assign rx_avail = rx_done_q;

   always @(*) begin
      rx_active_d = rx_active_q;
      rx_done_d = 1'b0;

      if (rx_active_q) begin
	 rxshift_d = rxshift_q;
	 rxcnt_d = rxcnt_q;
	 if (rxbaud_q == BAUDDIV-1) begin
	    if (rxcnt_q == 9) begin
	       if (rxd) begin
		  rx_active_d = 1'b0;
		  rx_done_d = 1'b1;
	       end
	    end else begin
	       rxshift_d = {rxd, rxshift_q[7:1]};
	       rxcnt_d = rxcnt_q + 1;
	    end
	    rxbaud_d = 0;
	 end else begin
	    rxbaud_d = rxbaud_q + 1;
	 end
      end else begin
	 rxshift_d = {8{1'b0}};
	 rxcnt_d = 0;
	 rxbaud_d = BAUDDIV/2;
	 if (~rxd) begin
	    rx_active_d = 1'b1;
	 end
      end

   end

   always @(posedge clk) begin
      if (rst | ~rx_enabled) begin
	 rxshift_q <= {8{1'b0}};
	 rx_active_q <= 1'b0;
	 rx_done_q <= 1'b0;
	 rxcnt_q <= 0;
	 rxbaud_q <= 0;
      end else begin
	 rxshift_q <= rxshift_d;
	 rx_active_q <= rx_active_d;
	 rx_done_q <= rx_done_d;
	 rxcnt_q <= rxcnt_d;
	 rxbaud_q <= rxbaud_d;
      end
   end

endmodule // avr109rx

