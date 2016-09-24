module ide_data_buffer(input clk,
		       input rst,
		       input[7:0] read_addr,
		       output[15:0] read_data,
		       input[7:0] write_addr,
		       input[15:0] write_data,
		       input write_hi,
		       input write_lo
		       );

   reg [15:0] ram_data[255:0];
   reg [15:0] data_latch;

   assign read_data = data_latch;

   always @(posedge clk) begin
      if (write_hi)
	ram_data[write_addr][15:8] <= write_data[15:8];
      if (write_lo)
	ram_data[write_addr][7:0] <= write_data[7:0];

      data_latch <= ram_data[read_addr];
   end

endmodule // ide_data_buffer
