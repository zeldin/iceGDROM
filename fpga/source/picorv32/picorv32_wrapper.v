module picorv32_wrapper (
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
	    input  wire[7:0]               extram_d_in,
	    output wire[7:0]               extram_d_out,
	    output wire                    extram_cs,
	    output wire                    extram_oe,
	    output wire                    extram_we,

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
		 .prog_data_in(prog_addr[0]? intmem_rdata[31:16] : intmem_rdata[15:0]),
		 .prog_low(prog_low), .prog_high(prog_high));

   always @(posedge clk)
     txd <= (nrst ? (intercept_mode ? txd_avr109 : txd_core ) : 1'b1);


   // -------------------------------
   // PicoRV32 Core

   wire mem_valid;
   wire [31:0] mem_addr;
   wire [31:0] mem_wdata;
   wire [3:0]  mem_wstrb;

   wire         mem_ready;
   wire         mem_instr;
   wire [31:0]  mem_rdata;

   picorv32 #(
	      .ENABLE_COUNTERS(0),
	      .CATCH_MISALIGN(0),
	      .CATCH_ILLINSN(0),
	      .ENABLE_IRQ(1),
	      .ENABLE_IRQ_QREGS(1),
	      .ENABLE_IRQ_TIMER(1),
	      .COMPRESSED_ISA(1),
	      .ENABLE_REGS_16_31(0),
	      .MASKED_IRQ(32'hfffffff6),
	      .LATCHED_IRQ(32'h00000007)
	) cpu (
		.clk      (clk      ),
		.resetn   (nrst & ~prog_mode),
		.mem_valid(mem_valid),
		.mem_ready(mem_ready),
		.mem_addr (mem_addr ),
		.mem_wdata(mem_wdata),
		.mem_wstrb(mem_wstrb),
		.mem_rdata(mem_rdata),
	        .mem_instr(mem_instr),
	        .irq({ext_irq3, 3'b000})
	);

   // -------------------------------
   // Memory/IO Interface

   reg [31:0] memory [0:(mem_size*256)-1];
   reg [31:0] intmem_rdata;

   assign     mem_ready = 1'b1;
   assign     mem_rdata = (mem_addr[31]?
			   {4{(mem_addr[16]? periph_rdata : extram_d_in)}}
			   : intmem_rdata);

   assign     extram_a = mem_addr[15:0];
   assign     extram_d_out = mem_wdata[7:0];
   assign     extram_cs = mem_addr[31] && !mem_addr[16];
   assign     extram_oe = mem_valid && !mem_wstrb;
   assign     extram_we = mem_valid && |mem_wstrb;

   generate
      if (mem_init == "")
	begin : no_initdata
	end else begin : yes_initdata
	   initial $readmemh(mem_init, memory);
	end
   endgenerate

   always @(negedge clk) begin
      if (prog_mode) begin
	   intmem_rdata <= memory[prog_addr >> 1];
	 if (prog_high) begin
	    if (prog_addr[0])
	      memory[prog_addr >> 1][31:24] <= prog_data;
	    else
	      memory[prog_addr >> 1][15:8] <= prog_data;
	 end else if (prog_low) begin
	    if (prog_addr[0])
	      memory[prog_addr >> 1][23:16] <= prog_data;
	    else
	      memory[prog_addr >> 1][7:0] <= prog_data;
	 end
      end else
      if (nrst && mem_valid) begin
	 if (!mem_wstrb && !mem_addr[31]) begin
	    intmem_rdata <= memory[mem_addr >> 2];
	 end else if (|mem_wstrb && !mem_addr[31]) begin
	    if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
	    if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
	    if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
	    if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
	 end
      end
   end

   // -------------
   // Periherals

   wire [7:0] periph_rdata;

   peripherals peripherals_inst(.clk(clk),
				.nrst(nrst),
				.data_out(periph_rdata),
				.data_in(mem_wdata[7:0]),
				.addr(mem_addr[7:2]),
				.cs(mem_addr[31] && mem_addr[16]),
				.oe(mem_valid && !mem_wstrb),
				.we(mem_valid && |mem_wstrb),

				.porta(porta), .portb(portb),
				.sdcard_sck(sdcard_sck),
				.sdcard_mosi(sdcard_mosi),
				.sdcard_miso(sdcard_miso),
				.rxd(intercept_mode | rxd), .txd(txd_core)
				);

endmodule // picorv32_wrapper
