module sdcard_spi (
		   output sclk,
		   output mosi,
		   input  miso,

		   input rst,
		   input clk,
		   input [7:0] data_in,
		   output [7:0] data_out,
		   input [7:0] divider,
		   input [4:0] bits,
		   input start,
		   output finished,
		   output crc_bit,
		   output crc_strobe,
		  );

   reg 	     sclk_d, sclk_q;
   reg [7:0] shift_in_d, shift_in_q, shift_out_d, shift_out_q;
   reg [7:0] counter;
   reg 	     toggle, latch_d, latch_q, active_d, active_q;
   reg [4:0] bits_d, bits_q;

   assign    sclk = sclk_q;
   assign    mosi = shift_out_q[7];
   assign    finished = active_q & ~active_d;
   assign    data_out = {shift_in_q[6:0], latch_q};
   assign    crc_bit = latch_q;
   assign    crc_strobe = active_q & toggle & sclk_q;

   always @(posedge clk) begin
      if (divider == 0)
	toggle <= 1'b1;
      else
	toggle <= (counter+1 == divider);
      if (toggle | ~active_q)
	counter <= 0;
      else
	counter <= counter+1;
   end

   always @(*) begin
      sclk_d = sclk_q;
      shift_in_d = shift_in_q;
      shift_out_d = shift_out_q;
      latch_d = latch_q;
      bits_d = bits_q;
      active_d = active_q;
      if (active_q & toggle) begin
	 sclk_d = ~sclk_q;
	 if (sclk_q) begin
	    shift_in_d = {shift_in_q[6:0], latch_q};
	    shift_out_d = {shift_out_q[6:0], 1'b1};
	    if ((bits_q == 0) | ~shift_in_q[6]) begin
	       active_d = 1'b0;
	    end else begin
	       bits_d = bits_q-1;
	    end
	 end else begin
	    latch_d = miso;
	 end
      end

      if (start) begin
	 shift_in_d = 8'hff;
	 shift_out_d = data_in;
	 bits_d = bits;
	 active_d = 1'b1;
      end
   end

   always @(posedge clk) begin
      if (rst) begin
	 active_q <= 1'b0;
	 bits_q <= 5'h00;
	 sclk_q <= 1'b0;
	 latch_q <= 1'b0;
	 shift_in_q <= 8'h00;
	 shift_out_q <= 8'h00;
      end else begin
	 active_q <= active_d;
	 bits_q <= bits_d;
	 sclk_q <= sclk_d;
	 latch_q <= latch_d;
	 shift_in_q <= shift_in_d;
	 shift_out_q <= shift_out_d;
      end
   end

endmodule // sdcard_spi
