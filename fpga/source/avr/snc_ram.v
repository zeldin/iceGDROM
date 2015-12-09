`timescale 1 ns / 1 ns

module snc_ram(
   clk,
   en,
   we,
   adr,
   din,
   dout
);

   parameter                 adr_width  = 10;
   parameter                 data_width = 8;
   parameter                 initdata   = "";

   input                     clk;
   input                     en;
   input                     we;
   input [(adr_width-1):0]   adr;
   input [(data_width-1):0]  din;
   output [(data_width-1):0] dout;

   reg [(data_width-1):0]    ram_data[(2**adr_width-1):0];
   reg [(data_width-1):0]    data_latch;
   assign dout = data_latch;

   always @(posedge clk) begin
      if (en) begin
	 if (we) begin
	    ram_data[adr] <= din;
	 end else begin
	    data_latch <= ram_data[adr];
	 end
      end
   end

   generate
      if (initdata == "")
	begin : no_initdata
	end else begin : yes_initdata
	   initial $readmemh(initdata, ram_data);
	end
   endgenerate

endmodule // snc_ram
