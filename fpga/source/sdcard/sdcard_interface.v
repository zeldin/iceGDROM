module sdcard_interface(
			output sclk,
			output mosi,
			input miso,

			input clk,
			input rst,
			input [9:0] sram_a,
			input [7:0] sram_d_in,
			output [7:0] sram_d_out,
			input sram_cs,
			input sram_oe,
			input sram_we,
			output sram_wait
			);

   wire [7:0] spi_data_in;
   wire [7:0] spi_data_out;
   wire       start, finished;

   reg [7:0]  divider_d, divider_q;
   reg [4:0]  bits_d, bits_q;
   reg [7:0]  latch_d, latch_q;
   reg 	      avail_d, avail_q;

   assign     spi_data_in = sram_d_in;
   assign     start = sram_cs & sram_we & (sram_a[1:0] == 2'b01);
   assign     sram_wait = 1'b0;

   reg [7:0] sram_d;
   assign sram_d_out = sram_d;

   sdcard_spi spi_inst(.sclk(sclk), .mosi(mosi), .miso(miso),
		       .rst(rst), .clk(clk), .data_in(spi_data_in),
		       .data_out(spi_data_out), .divider(divider_q),
		       .bits(bits_q), .start(start), .finished(finished));

   always @(*) begin
      case (sram_a[1:0])
	2'b00: sram_d = {avail_q, 2'b000, bits_q};
	2'b01: sram_d = latch_q;
	2'b10: sram_d = divider_q;
	default: sram_d = 8'h00;
      endcase
   end

   always @(*) begin
      divider_d = divider_q;
      bits_d = bits_q;
      avail_d = avail_q;
      latch_d = latch_q;

      if (sram_cs & sram_we) begin
	 case (sram_a[1:0])
	   2'b00: begin
	      bits_d = sram_d_in[4:0];
	   end
	   2'b01: avail_d = 1'b0;
	   2'b10: divider_d = sram_d_in;
	 endcase
      end

      if (finished) begin
	 avail_d = 1'b1;
	 latch_d = spi_data_out;
      end
   end // always @ (*)

   always @(posedge clk) begin
      if (rst) begin
	 divider_q <= 8'h00;
	 bits_q <= 5'h00;
	 avail_q <= 1'b0;
	 latch_q <= 8'h00;
      end else begin
	 divider_q <= divider_d;
	 bits_q <= bits_d;
	 avail_q <= avail_d;
	 latch_q <= latch_d;
      end
   end

endmodule // sdcard_interface
