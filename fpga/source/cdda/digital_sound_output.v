module digital_sound_output (
			     input clk,
			     input rst,
			     input enabled,
			     input[15:0] left,
			     input[15:0] right,
			     output bck,
			     output sd,
			     output lrck,
			     output consume
		       );

   parameter CLK_FREQUENCY = 33868800;

   localparam BCK_HALF_PERIOD = (CLK_FREQUENCY / 44100 / 64 / 2);

   function integer log2;
      input integer value;
      begin
         value = value-1;
         for (log2=0; value>0; log2=log2+1)
           value = value>>1;
      end
   endfunction

   reg [log2(BCK_HALF_PERIOD)-1:0]  bck_counter_d, bck_counter_q;
   reg 	      bck_d, bck_q;
   reg 	      sd_d, sd_q;
   reg 	      lrck_d, lrck_q;
   reg	      bit_active_d, bit_active_q;
   reg [5:0]  bit_counter_d, bit_counter_q;
   reg [31:0] shiftreg_d, shiftreg_q;
   reg 	      consume_d, consume_q;

   assign bck = bck_q;
   assign sd = sd_q;
   assign lrck = lrck_q;
   assign consume = consume_q;

   always @(*) begin

      if (enabled) begin
	 if (bck_counter_q == BCK_HALF_PERIOD-1) begin
	    bck_counter_d = 0;
	    bck_d = ~bck_q;
	 end else begin
	    bck_counter_d = bck_counter_q + 1;
	    bck_d = bck_q;
	 end
      end else begin
	 bck_counter_d = 0;
	 bck_d = bck_q;
      end

      if ((bck_counter_q == BCK_HALF_PERIOD-2) & bck_q & enabled)
	bit_active_d = 1'b1;
      else
	bit_active_d = 1'b0;

      shiftreg_d = (enabled? shiftreg_q : 32'h00000000);
      consume_d = 1'b0;
      if (bit_active_q) begin
	 if (bit_counter_q[4]) begin
	    sd_d = shiftreg_q[31];
	    shiftreg_d = {shiftreg_q[30:0],1'b0};
	 end else begin
	    sd_d = 1'b0;
	    if (bit_counter_q == 0) begin
	       shiftreg_d = {left, right};
	       consume_d = 1'b1;
	    end
	 end
	 lrck_d = ~bit_counter_q[5];
	 bit_counter_d = bit_counter_q+1;
      end else begin
	 sd_d = sd_q;
	 lrck_d = lrck_q;
	 bit_counter_d = bit_counter_q;
      end

   end

   always @(posedge clk) begin
      if (rst) begin
	 bck_counter_q <= 0;
	 bck_q <= 1'b0;
	 sd_q <= 1'b0;
	 lrck_q <= 1'b0;
	 bit_active_q <= 1'b0;
	 bit_counter_q <= 5'b00000;
	 shiftreg_q <= 32'h00000000;
	 consume_q <= 1'b0;
      end else begin
	 bck_counter_q <= bck_counter_d;
	 bck_q <= bck_d;
	 sd_q <= sd_d;
	 lrck_q <= lrck_d;
	 bit_active_q <= bit_active_d;
	 bit_counter_q <= bit_counter_d;
	 shiftreg_q <= shiftreg_d;
	 consume_q <= consume_d;
      end
   end

endmodule // digital_sound_output

