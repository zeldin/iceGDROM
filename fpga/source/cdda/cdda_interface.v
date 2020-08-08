module cdda_interface (
		       output bck,
		       output sd,
		       output lrck,

		       input clk,
		       input rst,
		       input[10:0] sram_a,
		       input[7:0]  sram_d_in,
		       output[7:0] sram_d_out,
		       input       sram_cs,
		       input       sram_oe,
		       input       sram_we,
		       output      sram_wait,
		       input[7:0]  sdcard_dma_data,
		       input[8:0]  sdcard_dma_addr,
		       input       sdcard_dma_strobe,
		       );

   parameter CLK_FREQUENCY = 33868800;

   assign sram_wait = 1'b0;

   reg [7:0] sram_d;
   assign sram_d_out = sram_d;

   wire consume_data;

   wire [15:0] left_read_data, right_read_data;

   wire [7:0]  cpu_access_pos;
   wire        cpu_writes_to_buffer;
   wire        cpu_writes_left, cpu_writes_right;
   wire        cpu_writes_high, cpu_writes_low;

   reg enabled_d, enabled_q;
   reg dso_enabled_d, dso_enabled_q;
   reg underflow_d, underflow_q;
   reg dma_mode_d, dma_mode_q;
   reg dma_buffer_select_d, dma_buffer_select_q;
   reg [7:0] bufpos_d, bufpos_q;
   reg [7:0] last_valid_data_d, last_valid_data_q;
   reg [7:0] scratchpad_d, scratchpad_q;

   wire [9:0] write_addr;
   wire [7:0] write_data;
   assign write_addr = (dma_mode_q? {dma_buffer_select_q, sdcard_dma_addr} : sram_a[9:0]);
   assign write_data = (dma_mode_q? sdcard_dma_data : sram_d_in);

   assign cpu_access_pos = write_addr[9:2];
   assign cpu_writes_to_buffer = (dma_mode_q? sdcard_dma_strobe : (sram_cs & sram_we & sram_a[10]));
   assign cpu_writes_left = cpu_writes_to_buffer & ~write_addr[1];
   assign cpu_writes_right = cpu_writes_to_buffer & write_addr[1];
   assign cpu_writes_high = write_addr[0];
   assign cpu_writes_low  = ~cpu_writes_high;

   digital_sound_output #(.CLK_FREQUENCY(CLK_FREQUENCY))
   dso_inst(.clk(clk), .rst(rst), .enabled(dso_enabled_q),
	    .left(left_read_data), .right(right_read_data),
	    .bck(bck), .sd(sd), .lrck(lrck), .consume(consume_data));

   ide_data_buffer left_data(.clk(clk), .rst(rst),
			     .read_addr(bufpos_q),
			     .read_data(left_read_data),
			     .write_addr(cpu_access_pos),
			     .write_data({write_data, write_data}),
			     .write_hi(cpu_writes_left & cpu_writes_high),
			     .write_lo(cpu_writes_left & cpu_writes_low));

   ide_data_buffer right_data(.clk(clk), .rst(rst),
			      .read_addr(bufpos_q),
			      .read_data(right_read_data),
			      .write_addr(cpu_access_pos),
			      .write_data({write_data, write_data}),
			      .write_hi(cpu_writes_right & cpu_writes_high),
			      .write_lo(cpu_writes_right & cpu_writes_low));

   always @(*) begin
      case (sram_a[3:2])
	2'b00: sram_d = { 4'b0000, dma_buffer_select_q, dma_mode_q, underflow_q, enabled_q };
	2'b01: sram_d = bufpos_q;
	2'b10: sram_d = last_valid_data_q;
	2'b11: sram_d = scratchpad_q;
	default: sram_d = 0;
      endcase // case (sram_a[3:2])
   end

   always @(*) begin
      bufpos_d = bufpos_q;
      underflow_d = underflow_q;
      enabled_d = enabled_q;
      last_valid_data_d = last_valid_data_q;
      scratchpad_d = scratchpad_q;
      dma_mode_d = dma_mode_q;
      dma_buffer_select_d = dma_buffer_select_q;

      if (enabled_q) begin
	 dso_enabled_d = 1'b1;
	 if (consume_data) begin
	    if (bufpos_q == last_valid_data_q)
	      underflow_d = 1'b1;
	    else
	      bufpos_d = bufpos_q+1;
	 end
      end else begin
	 if (consume_data)
	   dso_enabled_d = 1'b0;
	 else
	   dso_enabled_d = dso_enabled_q;
      end

      if (sram_cs & sram_we & ~sram_a[10]) begin
	 case (sram_a[3:2])
	   2'b00: begin
	      enabled_d = sram_d_in[0];
	      if (sram_d_in[1]) underflow_d = 1'b0;
	      dma_mode_d = sram_d_in[2];
	      dma_buffer_select_d = sram_d_in[3];
	   end
	   2'b01: bufpos_d = sram_d_in;
	   2'b10: last_valid_data_d = sram_d_in;
	   2'b11: scratchpad_d = sram_d_in;
	 endcase // case (sram_a[3:2])
      end
   end

   always @(posedge clk) begin
      if (rst) begin
	 enabled_q <= 1'b0;
	 dso_enabled_q <= 1'b0;
	 underflow_q <= 1'b0;
	 bufpos_q <= 8'h00;
	 last_valid_data_q <= 8'h00;
	 scratchpad_q <= 8'h55;
	 dma_mode_q <= 1'b0;
	 dma_buffer_select_q <= 1'b0;
      end else begin
	 enabled_q <= enabled_d;
	 dso_enabled_q <= dso_enabled_d;
	 underflow_q <= underflow_d;
	 bufpos_q <= bufpos_d;
	 last_valid_data_q <= last_valid_data_d;
	 scratchpad_q <= scratchpad_d;
	 dma_mode_q <= dma_mode_d;
	 dma_buffer_select_q <= dma_buffer_select_d;
      end
   end

endmodule // cdda_interface

