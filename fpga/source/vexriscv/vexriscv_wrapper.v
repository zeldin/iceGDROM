module vexriscv_wrapper (
	    input  clk,
	    output rst_out,

	    // PORTA
	    inout[7:0]                    porta,

	    // PORTB
	    inout[7:0]                    portb,

	    // SDCARD
	    input                         sdcard_sck,
	    input                         sdcard_mosi,
	    output                        sdcard_miso,

	    // UART related
	    input                         rxd,
	    output reg                    txd,

	    // EXTRAM i/f
	    output wire[15:0]              extram_a,
	    input  wire[31:0]              extram_d_in,
	    output wire[31:0]              extram_d_out,
	    output wire                    extram_cs,
	    output wire                    extram_oe,
	    output wire[3:0]               extram_wstrb,

	    // IRQ
	    input  wire                    ext_irq3
            );

   parameter CLK_FREQUENCY = 50000000;
   parameter AVR109_BAUD_RATE = 19200;
   parameter mem_init = "";
   parameter mem_size = 1;

   // -------------------------------
   // Reset generator

   wire nrst;
   assign rst_out = ~nrst;

   rst_gen rst_gen_inst(.clk(clk), .nrst(nrst));


   // -------------------------------
   // AVR109

   wire prog_mode;
   wire intercept_mode;
   wire [15:0] prog_addr;
   wire [15:0] prog_data;
   wire        prog_low;
   wire        prog_high;
   wire        txd_core;
   wire        txd_avr109;

   avr109 #(.CLK_FREQUENCY(CLK_FREQUENCY), .BAUD_RATE(AVR109_BAUD_RATE))
     avr109_inst(.rst(~nrst), .clk(clk),
		 .rxd(rxd), .txd(txd_avr109), .intercept_mode(intercept_mode),
		 .prog_mode(prog_mode), .prog_addr(prog_addr),
		 .prog_data(prog_data),
		 .prog_data_in(prog_addr[0]? ram_read[31:16] : ram_read[15:0]),
		 .prog_low(prog_low), .prog_high(prog_high));

   always @(posedge clk)
     txd <= (nrst ? (intercept_mode ? txd_avr109 : txd_core ) : 1'b1);


   // -------------------------------
   // VexRiscv Core

   wire 	iBus_cmd_valid;
   wire 	iBus_cmd_ready;
   wire [31:0] 	iBus_cmd_payload_pc;
   wire 	iBus_rsp_valid;
   wire 	iBus_rsp_payload_error;
   wire [31:0] 	iBus_rsp_payload_inst;
   wire 	dBus_cmd_valid;
   wire 	dBus_cmd_ready;
   wire 	dBus_cmd_payload_wr;
   wire [31:0] 	dBus_cmd_payload_address;
   wire [31:0] 	dBus_cmd_payload_data;
   wire [1:0] 	dBus_cmd_payload_size;
   wire 	dBus_rsp_ready;
   wire 	dBus_rsp_error;
   wire [31:0] 	dBus_rsp_data;

   VexRiscv cpu(.iBus_cmd_valid(iBus_cmd_valid),
		.iBus_cmd_ready(iBus_cmd_ready),
		.iBus_cmd_payload_pc(iBus_cmd_payload_pc),
		.iBus_rsp_valid(iBus_rsp_valid),
		.iBus_rsp_payload_error(iBus_rsp_payload_error),
		.iBus_rsp_payload_inst(iBus_rsp_payload_inst),
		.timerInterrupt(timer0_comp_irq),
		.externalInterrupt(ext_irq3),
		.softwareInterrupt(1'b0),
		.dBus_cmd_valid(dBus_cmd_valid),
		.dBus_cmd_ready(dBus_cmd_ready),
		.dBus_cmd_payload_wr(dBus_cmd_payload_wr),
		.dBus_cmd_payload_address(dBus_cmd_payload_address),
		.dBus_cmd_payload_data(dBus_cmd_payload_data),
		.dBus_cmd_payload_size(dBus_cmd_payload_size),
		.dBus_rsp_ready(dBus_rsp_ready),
		.dBus_rsp_error(dBus_rsp_error),
		.dBus_rsp_data(dBus_rsp_data),
		.clk(clk), .reset(rst_out | prog_mode));

   // -------------------------------
   // Memory/IO Interface

   reg [31:0] ram[0:(mem_size*256)-1];
   reg [31:0] ram_read;
   reg [13:0] ram_read_addr;
   reg	      ram_read_enable;

   wire       dbus_ram_access;
   // assign dbus_ram_access = dBus_cmd_payload_address < mem_size * 1024;
   assign dbus_ram_access = dBus_cmd_payload_address[31] == 1'b0;

   generate
      if (mem_init == "") begin : no_initdata
	 ;
      end else begin : yes_initdata
	 initial $readmemh(mem_init, ram);
      end
   endgenerate

   always @(*) begin
      ram_read_enable = 1'b1;
      ram_read_addr = 14'hx;
      if (prog_mode) begin
	 ram_read_addr = prog_addr >> 1;
      end else if (!rst_out) begin
	 if (dBus_cmd_valid && !dBus_cmd_payload_wr && dbus_ram_access)
	   ram_read_addr = dBus_cmd_payload_address[15:2];
	 else if (ibus_stalled)
	   ram_read_addr = ibus_stall_pc;
	 else if (iBus_cmd_valid)
	   ram_read_addr = iBus_cmd_payload_pc[15:2];
	 else
	   ram_read_enable = 1'b0;
      end else
	ram_read_enable = 1'b0;
   end

   always @(posedge clk)
     if (ram_read_enable)
       ram_read <= ram[ram_read_addr];


   /* iBus */

   reg 		ibus_valid;
   reg          ibus_ready;
   reg          ibus_stalled;
   reg [15:2]   ibus_stall_pc;

   assign iBus_cmd_ready = ibus_ready;
   assign iBus_rsp_valid = ibus_valid;
   assign iBus_rsp_payload_error = 1'b0;
   assign iBus_rsp_payload_inst = ram_read;

   always @(posedge clk)
     if (prog_mode || rst_out) begin
	ibus_valid <= 1'b0;
	ibus_ready <= 1'b0;
	ibus_stalled <= 1'b0;
     end else if (dBus_cmd_valid && !dBus_cmd_payload_wr && dbus_ram_access) begin
	if (iBus_cmd_valid && ibus_ready) begin
	   // Stall until dBus read complete
	   ibus_valid <= 1'b0;
	   ibus_ready <= 1'b0;
	   ibus_stalled <= 1'b1;
	   ibus_stall_pc <= iBus_cmd_payload_pc[15:2];
	end
     end else if (ibus_stalled) begin
	// Clear stall
	ibus_valid <= 1'b1;
	ibus_ready <= 1'b1;
	ibus_stalled <= 1'b0;
     end else if(iBus_cmd_valid && ibus_ready) begin
	// Can read without stall
	ibus_valid <= 1'b1;
	ibus_ready <= 1'b1;
     end else begin
	ibus_valid <= 1'b0;
	ibus_ready <= 1'b1;
     end

   /* dBus */

   reg        dbus_ready;
   reg [31:0] reg_read;
   reg        dbus_regspace;

   wire   dbus_reg_access;
   wire   valid_internal_reg, valid_external_reg;
   wire [3:0] write_mask;
   assign dbus_reg_access = !dbus_ram_access;
   assign write_mask = (dBus_cmd_payload_size == 2'b00 ?
			4'b0001 << dBus_cmd_payload_address[1:0] :
			(dBus_cmd_payload_size == 2'b01 ?
			 (dBus_cmd_payload_address[1]? 4'b1100 : 4'b0011) :
			 4'b1111));
   assign valid_internal_reg = &dBus_cmd_payload_address[31:8];
   assign valid_external_reg = &dBus_cmd_payload_address[31:17] &&
			       dBus_cmd_payload_address[16:13] == 4'b0111;

   assign dBus_cmd_ready = 1'b1;
   assign dBus_rsp_ready = dbus_ready;
   assign dBus_rsp_error = 1'b0;
   assign dBus_rsp_data = (dbus_regspace? reg_read : ram_read);

   assign     extram_a = dBus_cmd_payload_address[15:0];
   assign     extram_d_out = dBus_cmd_payload_data;
   assign     extram_cs = dbus_reg_access && valid_external_reg;
   assign     extram_oe = dBus_cmd_valid && !dBus_cmd_payload_wr;
   assign     extram_wstrb = (dBus_cmd_valid && dBus_cmd_payload_wr? write_mask : 4'b0000);

   always @(posedge clk) begin

      if (prog_mode) begin
	 dbus_ready <= 1'b0;
	 if (prog_high) begin
	    if (prog_addr[0])
	      ram[prog_addr >> 1][31:24] <= prog_data;
	    else
	      ram[prog_addr >> 1][15:8] <= prog_data;
	 end else if (prog_low) begin
	    if (prog_addr[0])
	      ram[prog_addr >> 1][23:16] <= prog_data;
	    else
	      ram[prog_addr >> 1][7:0] <= prog_data;
	 end
      end else if (rst_out || !dBus_cmd_valid)
	dbus_ready <= 1'b0;
      else begin
	 dbus_ready <= 1'b1;
	 if (dbus_ram_access) begin
	    dbus_regspace <= 1'b0;
	    if (dBus_cmd_payload_wr) begin
	       if (write_mask[0]) ram[dBus_cmd_payload_address[15:2]][7:0] <= dBus_cmd_payload_data[7:0];
	       if (write_mask[1]) ram[dBus_cmd_payload_address[15:2]][15:8] <= dBus_cmd_payload_data[15:8];
	       if (write_mask[2]) ram[dBus_cmd_payload_address[15:2]][23:16] <= dBus_cmd_payload_data[23:16];
	       if (write_mask[3]) ram[dBus_cmd_payload_address[15:2]][31:24] <= dBus_cmd_payload_data[31:24];
	    end
	 end else if (dbus_reg_access) begin
	    dbus_regspace <= 1'b1;
	    if (!dBus_cmd_payload_wr) begin
	       if (valid_internal_reg)
		 reg_read <= periph_rdata;
	       else if (valid_external_reg)
		 reg_read <= extram_d_in;
	       else
		 reg_read <= 0;
	    end
	 end
      end // else: !if(rst_out || !dBus_cmd_valid)
   end // always @ (posedge clk)

   // -------------
   // Periherals

   wire [31:0] periph_rdata;
   wire        timer0_comp_irq;

   peripherals peripherals_inst(.clk(clk),
				.nrst(nrst),
				.data_out(periph_rdata),
				.data_in(dBus_cmd_payload_data),
				.addr(dBus_cmd_payload_address[7:2]),
				.cs(dbus_reg_access && valid_internal_reg),
				.oe(dBus_cmd_valid && !dBus_cmd_payload_wr),
				.wstrb(dBus_cmd_valid && dBus_cmd_payload_wr?
				       write_mask : 4'b0000),

				.porta(porta), .portb(portb),
				.sdcard_sck(sdcard_sck),
				.sdcard_mosi(sdcard_mosi),
				.sdcard_miso(sdcard_miso),
				.rxd(intercept_mode | rxd), .txd(txd_core),
				.timer0_comp_irq(timer0_comp_irq)
				);

endmodule // vexriscv_wrapper
