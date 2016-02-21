module ide_interface (
		      inout[15:0] dd,
		      input[2:0]  da,
		      input       cs1fx_,
		      input       cs3fx_,
		      inout       dasp_,
		      input       dior_,
		      input       diow_,
		      input       dmack_,
		      inout       dmarq,
		      inout       intrq,
		      inout       iocs16_,
		      inout       iordy,
		      inout       pdiag_,
		      input       reset_,
		      input       csel,
		      input       clk,
		      input[9:0]  sram_a,
		      input[7:0]  sram_d_in,
		      output[7:0] sram_d_out,
		      input       sram_cs,
		      input       sram_oe,
		      input       sram_we,
		      output      sram_wait
		      );

   parameter drv = 1'b0;
   
   assign dasp_ = 1'bz;
   assign pdiag_ = 1'bz;

   wire [2:0] da_in;
   wire       cs1fx_in, cs3fx_in, dior_in, diow_in;
   wire       dmack_in, reset_in;

   ide_status_pin da_pin[2:0](.pin(da), .in(da_in), .clk(clk));
   ide_status_pin cs1fx_pin(.pin(cs1fx_), .in(cs1fx_in), .clk(clk));
   ide_status_pin cs3fx_pin(.pin(cs3fx_), .in(cs3fx_in), .clk(clk));
   ide_status_pin dior_pin(.pin(dior_), .in(dior_in), .clk(clk));
   ide_status_pin diow_pin(.pin(diow_), .in(diow_in), .clk(clk));
   ide_status_pin dmack_pin(.pin(dmack_), .in(dmack_in), .clk(clk));
   ide_status_pin reset_pin(.pin(reset_), .in(reset_in), .clk(clk));
   
   wire dmarq_asserted;
   wire intrq_enabled;
   wire intrq_level;
   wire iocs16_asserted;
   wire iowait;
   
   ide_control_pin
     dmarq_pin(.pin(dmarq), .out(1'b1), .enable(dmarq_asserted), .clk(clk));
   ide_control_pin
     intrq_pin(.pin(intrq), .out(intrq_level), .enable(intrq_enabled), .clk(clk));
   ide_control_pin
     iocs16_pin(.pin(iocs16_), .out(1'b0), .enable(iocs16_asserted), .clk(clk));
   ide_control_pin
     iordy_pin(.pin(iordy), .out(1'b0), .enable(iowait), .clk(clk));

   assign dmarq_asserted = 1'b0;
   assign iocs16_asserted = 1'b0;
   assign iowait = 1'b0;

   wire [15:0] dd_in;
   reg  [15:0] dd_out;
   wire        dd_latch;
   wire        dd_enable;
   
   ide_data_pin ide_data_pin_inst[15:0](.pin(dd), .in(dd_in), .out(dd_out),
					.latch({16{dd_latch}}),
					.enable({16{dd_enable}}),
					.clk({16{clk}}));

   assign dd_latch = diow_in;
   assign dd_enable = (ctrl_blk|cmnd_blk)&(~cur_dior)&drv_selected;
   
   wire        rst;

   reg [7:0]   buffer_read_addr, buffer_write_addr;
   wire [15:0] buffer_read_data;
   reg [15:0]  buffer_write_data;
   reg         buffer_write_hi, buffer_write_lo;

   reg [6:0]   busctl_old, busctl_cur;

   always @(posedge clk) begin
      if (rst) begin
	 busctl_old <= 7'b1111000;
      end else begin
	 busctl_old <= busctl_cur;
      end
      busctl_cur <= {diow_in,dior_in,cs3fx_in,cs1fx_in,da_in};
   end

   wire[2:0] bus_addr;
   wire      bus_cs1;
   wire      bus_cs3;
   wire      old_dior;
   wire      old_diow;
   wire      cur_dior;
   wire      cur_diow;
   assign bus_addr = busctl_old[2:0];
   assign bus_cs1 = busctl_old[3];
   assign bus_cs3 = busctl_old[4];
   assign old_dior = busctl_old[5];
   assign old_diow = busctl_old[6];
   assign cur_dior = busctl_cur[5];
   assign cur_diow = busctl_cur[6];

   wire ctrl_blk;
   wire cmnd_blk;
   wire write_cycle;
   wire read_cycle;

   assign ctrl_blk = (~bus_cs3)&(bus_addr[2:1]==2'b11);
   assign cmnd_blk = ~bus_cs1;
   assign write_cycle = (~old_diow)&cur_diow&(ctrl_blk|cmnd_blk);
   assign read_cycle = (~old_dior)&cur_dior&(ctrl_blk|cmnd_blk);

   reg [7:0] status_d, status_q;
   reg [7:0] error_d, error_q;
   reg [7:0] features_d, features_q;
   reg [7:0] seccnt_d, seccnt_q;
   reg [7:0] secnr_d, secnr_q;
   reg [7:0] cyllo_d, cyllo_q;
   reg [7:0] cylhi_d, cylhi_q;
   reg [7:0] drvhead_d, drvhead_q;
   reg [7:0] command_d, command_q;
   reg [7:0] iocontrol_d, iocontrol_q;
   reg [7:0] iopos_d, iopos_q;
   reg [7:0] iotarget_d, iotarget_q;
   reg 	     cmd_d, cmd_q;
   reg 	     data_d, data_q;
   reg 	     hrst_d, hrst_q;
   reg 	     srst_d, srst_q;
   reg       nien_d, nien_q;
   reg       irq_d, irq_q;
   wire      bsy;
   wire      drv_selected;
   assign    bsy = status_q[7];
   assign drv_selected = (drvhead_q[4] == drv);


   assign intrq_enabled = (~nien_q) & drv_selected;
   assign intrq_level = irq_q;

   reg [7:0] sram_d;
   assign sram_wait = sram_cs & sram_oe & sram_a[9] & !sram_wait_q;
   assign sram_d_out = sram_d;
   reg sram_wait_q;

   always @(posedge clk) begin
      sram_wait_q <= sram_wait;
   end

   always @(posedge clk) begin
      if (rst) begin
	 dd_out <= 16'h0000;
      end else begin
	 case ({bus_cs1,bus_cs3,bus_addr})
	   5'b10110: dd_out <= {8'h00, status_q};   /* Alternate status */
	   5'b01000: dd_out <= buffer_read_data;    /* Data */
	   5'b01001: dd_out <= {8'h00, error_q};    /* Error register */
	   5'b01010: dd_out <= {8'h00, seccnt_q};   /* Sector count */
	   5'b01011: dd_out <= {8'h00, secnr_q};    /* Sector number */
	   5'b01100: dd_out <= {8'h00, cyllo_q};    /* Cylinder low */
	   5'b01101: dd_out <= {8'h00, cylhi_q};    /* Cylinder high */
	   5'b01110: dd_out <= {8'h00, drvhead_q};  /* Drive/head */
	   5'b01111: dd_out <= {8'h00, status_q};   /* Status */
	   default: dd_out <= 16'h0000;
	 endcase
      end
   end

   always @(*) begin
      if (sram_a[9]) begin
	 if (sram_a[0])
	   sram_d = buffer_read_data[15:8];
	 else
	   sram_d = buffer_read_data[7:0];
      end else
	case (sram_a[3:0])
	  4'b0000: sram_d = status_q;
	  4'b0001: sram_d = error_q;
	  4'b0010: sram_d = iocontrol_q;
	  4'b0011: sram_d = iopos_q;
	  4'b0100: sram_d = status_q;
	  4'b0101: sram_d = iotarget_q;
	  4'b0110: sram_d = { 2'b00, data_q, cmd_q, hrst_q, srst_q, nien_q, irq_q };
	  4'b1001: sram_d = features_q;
	  4'b1010: sram_d = seccnt_q;
	  4'b1011: sram_d = secnr_q;
	  4'b1100: sram_d = cyllo_q;
	  4'b1101: sram_d = cylhi_q;
	  4'b1110: sram_d = drvhead_q;
	  4'b1111: sram_d = command_q;
	  default: sram_d = 0;
	endcase // case (sram_a[3:0])
   end
   
   always @(*) begin
      status_d = status_q;
      error_d = error_q;
      features_d = features_q;
      seccnt_d = seccnt_q;
      secnr_d = secnr_q;
      cyllo_d = cyllo_q;
      cylhi_d = cylhi_q;
      drvhead_d = drvhead_q;
      command_d = command_q;
      iocontrol_d = iocontrol_q;
      iopos_d = iopos_q;
      iotarget_d = iotarget_q;
      cmd_d = cmd_q;
      data_d = data_q;
      hrst_d = hrst_q;
      srst_d = srst_q;
      nien_d = nien_q;
      irq_d = irq_q;
      if (read_cycle & ({bus_cs1,bus_cs3,bus_addr} == 5'b01111) & drv_selected) begin
	 /* Read status register; clear IRQ */
	 irq_d = 1'b0;
      end
      if (write_cycle & {bus_cs1,bus_cs3,bus_addr} == 5'b10110) begin
	 /* Write device control */
	 nien_d = dd_in[1];
	 srst_d = dd_in[2];
      end
      if ((read_cycle|write_cycle) & ({bus_cs1,bus_cs3,bus_addr} == 5'b01000) & drv_selected) begin
	 /* Read or write Data increments iopos */
	 iopos_d = iopos_q+1;
	 if (iopos_q == iotarget_q)
	   data_d = 1'b1;
      end
      if (sram_cs & sram_we & ~sram_a[9]) begin
	 case (sram_a[3:0])
	   4'b0000: begin
	      status_d = sram_d_in;
	      irq_d = 1'b1;
	   end
	   4'b0100: status_d = sram_d_in;
	   4'b0001: error_d = sram_d_in;
	   4'b0010: iocontrol_d = sram_d_in;
	   4'b0011: iopos_d = sram_d_in;
	   4'b0101: iotarget_d = sram_d_in;
	   4'b0110: begin
	      if (sram_d_in[2])
		srst_d = 1'b0;
	      if (sram_d_in[3])
		hrst_d = 1'b0;
	      if (sram_d_in[4])
		cmd_d = 1'b0;
	      if (sram_d_in[5])
		data_d = 1'b0;
	   end
	 endcase
      end
      if (bsy) begin
	 if (sram_cs & sram_we & ~sram_a[9]) begin
	    case (sram_a[3:0])
	      4'b1001: features_d = sram_d_in;
	      4'b1010: seccnt_d = sram_d_in;
	      4'b1011: secnr_d = sram_d_in;
	      4'b1100: cyllo_d = sram_d_in;
	      4'b1101: cylhi_d = sram_d_in;
	      4'b1110: drvhead_d = sram_d_in;
	      4'b1111: command_d = sram_d_in;
	    endcase
	 end
      end else if (write_cycle) begin
	 case ({bus_cs1,bus_cs3,bus_addr})
	   5'b01001: features_d = dd_in[7:0];
	   5'b01010: seccnt_d = dd_in[7:0];
	   5'b01011: secnr_d = dd_in[7:0];
	   5'b01100: cyllo_d = dd_in[7:0];
	   5'b01101: cylhi_d = dd_in[7:0];
	   5'b01110: drvhead_d = dd_in[7:0];
	   5'b01111: begin /* Command */
	      irq_d = 1'b0;
	      command_d = dd_in[7:0];
	      status_d[7] = 1'b1; /* BSY */
	      cmd_d = 1'b1;
	   end
	 endcase
      end
   end
   
   always @(posedge clk) begin
      if (rst) begin
	 status_q <= 8'b00000000;
	 error_q <= 8'h00;
	 features_q <= 8'h00;
	 seccnt_q <= 8'h00;
	 secnr_q <= 8'h00;
	 cyllo_q <= 8'h00;
	 cylhi_q <= 8'h00;
	 drvhead_q <= 8'h00;
	 command_q <= 8'h00;
	 iocontrol_q <= 8'h00;
	 iopos_q <= 8'h00;
	 iotarget_q <= 8'h00;
	 cmd_q <= 1'b0;
	 data_q <= 1'b0;
	 hrst_q <= 1'b1;
	 srst_q <= 1'b0;
	 nien_q <= 1'b0;
	 irq_q <= 1'b0;
      end else begin
	 status_q <= status_d;
	 error_q <= error_d;
	 features_q <= features_d;
	 seccnt_q <= seccnt_d;
	 secnr_q <= secnr_d;
	 cyllo_q <= cyllo_d;
	 cylhi_q <= cylhi_d;
	 drvhead_q <= drvhead_d;
	 command_q <= command_d;
	 iocontrol_q <= iocontrol_d;
	 iopos_q <= iopos_d;
	 iotarget_q <= iotarget_d;
	 cmd_q <= cmd_d;
	 data_q <= data_d;
	 hrst_q <= hrst_d;
	 srst_q <= srst_d;
	 nien_q <= nien_d;
	 irq_q <= irq_d;
      end
   end

   wire bus_data_write, avr_data_write;
   assign bus_data_write = write_cycle & ({bus_cs1,bus_cs3,bus_addr} == 5'b01000);
   assign avr_data_write = sram_cs & sram_we & sram_a[9];

   always @(*) begin
      if (iocontrol_q[0]) begin
	 /* Bus writes, AVR reads */
	 buffer_write_hi = bus_data_write;
	 buffer_write_lo = bus_data_write;
	 buffer_write_addr = iopos_q;
	 buffer_write_data = dd_in;

	 buffer_read_addr = sram_a[8:1];
       end else begin
	 /* Bus reads, AVR writes */
	 buffer_write_hi = avr_data_write & sram_a[0];
	 buffer_write_lo = avr_data_write & ~sram_a[0];
	 buffer_write_addr = sram_a[8:1];
	 buffer_write_data = {sram_d_in, sram_d_in};

	 buffer_read_addr = iopos_q;
       end
   end

   ide_data_buffer buffer_inst(.clk(clk), .rst(rst),
			       .read_addr(buffer_read_addr),
			       .read_data(buffer_read_data),
			       .write_addr(buffer_write_addr),
			       .write_data(buffer_write_data),
			       .write_hi(buffer_write_hi),
			       .write_lo(buffer_write_lo));

   ide_reset_generator reset_inst(.rst_in(reset_in), .clk(clk), .rst_out(rst));

endmodule // ide_interface
