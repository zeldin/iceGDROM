module avr109tx (
		 input rst,
		 input clk,
		 input[7:0] tx_data,
		 input tx_avail,
		 output txd,
		 output tx_ready
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

   reg [8:0] 		txshift_d, txshift_q;
   reg [3:0] 	   txcnt_d, txcnt_q;
   reg		   tx_active_d, tx_active_q;
   reg [LOG2_BAUDDIV-1:0] txbaud_d, txbaud_q;

   assign txd = txshift_q[0];
   assign tx_ready = ~tx_active_q;

   always @(*) begin
      txshift_d = txshift_q;
      txcnt_d = txcnt_q;
      tx_active_d = tx_active_q;
      txbaud_d = txbaud_q;

      if (tx_active_q) begin
	 if (txbaud_q == BAUDDIV-1) begin
	    txshift_d = {1'b1, txshift_q[8:1]};
	    if (txcnt_q == 9)
	       tx_active_d = 0;
	    txcnt_d = txcnt_q + 1;
	    txbaud_d = 0;
	 end else begin
	    txbaud_d = txbaud_q + 1;
	 end
      end else if (tx_avail) begin
	 txshift_d = {tx_data, 1'b0};
	 txcnt_d = 0;
	 txbaud_d = 0;
	 tx_active_d = 1;
      end
   end

   always @(posedge clk) begin
      if (rst) begin
	 txshift_q <= 9'b111111111;
	 txcnt_q <= 4'b0;
	 tx_active_q <= 1'b0;
	 txbaud_q <= {LOG2_BAUDDIV{1'b0}};
      end else begin
	 txshift_q <= txshift_d;
	 txcnt_q <= txcnt_d;
	 tx_active_q <= tx_active_d;
	 txbaud_q <= txbaud_d;
      end
   end

endmodule // avr109tx
