module top (
	    input clk,
	    input RXD,
	    output TXD,
	    inout LED0,
	    inout LED1,
	    inout LED2,
	    inout LED3,
	    inout LED4,
	    inout LED5,
	    inout LED6,
	    inout LED7,
	    inout PORTB0,
	    inout PORTB1,
	    inout PORTB2,
	    inout PORTB3,
	    inout PORTB4,
	    inout PORTB5,
	    inout PORTB6,
	    inout PORTB7,

	    output CDCLK,
	    output SCK,
	    output SDAT,
	    output LRCK,

	    input G_RST,
	    inout D0,
	    inout D1,
	    inout D2,
	    inout D3,
	    inout D4,
	    inout D5,
	    inout D6,
	    inout D7,
	    inout D8,
	    inout D9,
	    inout D10,
	    inout D11,
	    inout D12,
	    inout D13,
	    inout D14,
	    inout D15,
	    inout DMARQ,
	    input WRn,
	    input RDn,
	    inout IORDY,
	    input DMACKn,
	    inout INTRQ,
	    input CS0n,
	    input CS1n,
	    input A0,
	    input A1,
	    input A2
	    );

   localparam REFCLK_FREQ = 11289600;
   localparam CDCLK_FREQ = 33868800;
   localparam CPU_FREQ = 16934400;

   wire clkout, lock, lock_cdclk;
   wire [15:0] sram_a;
   wire [7:0]  d_to_ide_or_cdda_or_sdcard, d_from_ide, d_from_cdda, d_from_sdcard;
   wire sram_cs, sram_oe, sram_we, sram_wait_ide, sram_wait_cdda, sram_wait_sdcard;
   wire ide_irq;
   reg ide_irq_sync;
   wire cs_gate, sram_cs_ide, sram_cs_cdda, sram_cs_sdcard;
   wire sdcard_sck, sdcard_miso, sdcard_mosi;
   wire [7:0] sdcard_dma_data;
   wire [8:0] sdcard_dma_addr;
   wire       sdcard_dma_strobe;
   wire       avr_reset;

   assign cs_gate = ~clkout_cpu&~clkout_cpu2;
   assign sram_cs_ide = sram_cs & sram_a[12] & cs_gate;
   assign sram_cs_sdcard = sram_cs & ~sram_a[12] & ~sram_a[11] & cs_gate;
   assign sram_cs_cdda = sram_cs & ~sram_a[12] & sram_a[11] & cs_gate;

   generate
      if(REFCLK_FREQ != CPU_FREQ*4) begin : use_clkgen

	 clkgen #(.INCLOCK_FREQ(REFCLK_FREQ),
		  .OUTCLOCK_FREQ(CPU_FREQ*4))
	 clkgen_inst(.clkin(clk), .clkout(clkout), .lock(lock));

      end
      else begin : use_refclk

	 assign clkout = clk;
	 assign lock = 1'b1;

      end
   endgenerate

   clkgen #(.INCLOCK_FREQ(REFCLK_FREQ),
	    .OUTCLOCK_FREQ(CDCLK_FREQ))
   clkgen_cdclk_inst(.clkin(clk), .clkout(CDCLK), .lock(lock_cdclk));

   reg clkout_cpu, clkout_cpu2;
   always @(posedge clkout) begin
      clkout_cpu2 <= ~clkout_cpu2;
      if (~clkout_cpu2)
	clkout_cpu <= ~clkout_cpu;
      if (~clkout_cpu&~clkout_cpu2)
	ide_irq_sync <= ide_irq;
   end

   ide_interface #(.drv(1'b0), .add_read_ws(0))
     ide_inst(.dd({D15,D14,D13,D12,D11,D10,D9,D8,D7,D6,D5,D4,D3,D2,D1,D0}),
	      .da({A2,A1,A0}), .cs1fx_(CS0n), .cs3fx_(CS1n), .dasp_(),
	      .dior_(RDn), .diow_(WRn), .dmack_(DMACKn), .dmarq(DMARQ),
	      .intrq(INTRQ), .iocs16_(), .iordy(IORDY), .pdiag_(),
	      .reset_(G_RST), .csel(1'b0), .clk(clkout), .sram_a(sram_a),
	      .sram_d_in(d_to_ide_or_cdda_or_sdcard), .sram_d_out(d_from_ide),
	      .sram_cs(sram_cs_ide), .sram_oe(sram_oe), .sram_we(sram_we),
	      .sram_wait(sram_wait_ide), .cpu_irq(ide_irq),
	      .sdcard_dma_data(sdcard_dma_data), .sdcard_dma_addr(sdcard_dma_addr),
	      .sdcard_dma_strobe(sdcard_dma_strobe));

   cdda_interface #(.CLK_FREQUENCY(CPU_FREQ*4))
     cdda_inst(.bck(SCK), .sd(SDAT), .lrck(LRCK),
	       .clk(clkout), .rst(avr_reset),
	       .sram_a(sram_a),
	       .sram_d_in(d_to_ide_or_cdda_or_sdcard), .sram_d_out(d_from_cdda),
	       .sram_cs(sram_cs_cdda), .sram_oe(sram_oe), .sram_we(sram_we),
	       .sram_wait(sram_wait_cdda), .sdcard_dma_data(sdcard_dma_data),
	       .sdcard_dma_addr(sdcard_dma_addr), .sdcard_dma_strobe(sdcard_dma_strobe));

   sdcard_interface
     sdcard_inst(.sclk(sdcard_sck), .mosi(sdcard_mosi), .miso(sdcard_miso),
		 .clk(clkout), .rst(avr_reset),
		 .sram_a(sram_a), .sram_d_in(d_to_ide_or_cdda_or_sdcard),
		 .sram_d_out(d_from_sdcard), .sram_cs(sram_cs_sdcard),
		 .sram_oe(sram_oe), .sram_we(sram_we), .sram_wait(sram_wait_sdcard),
		 .dma_data(sdcard_dma_data), .dma_addr(sdcard_dma_addr), .dma_strobe(sdcard_dma_strobe));

   avr #(.pm_size(4),
	 .dm_size(4),
	 .sram_address(16'hE000),
	 .sram_size(8192),
	 .impl_avr109(1),
	 .sdcard_spi(1),
	 .CLK_FREQUENCY(CPU_FREQ),
	 .AVR109_BAUD_RATE(115200),
`ifdef PM_INIT_LOW
	 .pm_init_low(`PM_INIT_LOW),
`endif
`ifdef PM_INIT_HIGH
	 .pm_init_high(`PM_INIT_HIGH),
`endif
	 )
     avr_inst(.nrst(1'b1), .clk(clkout_cpu), .rst_out(avr_reset),
	      .porta({LED7, LED6, LED5, LED4, LED3, LED2, LED1, LED0}),
	      .portb({PORTB7, PORTB6, PORTB5, PORTB4, PORTB3, PORTB2, PORTB1, PORTB0}),
	      .sdcard_sck(sdcard_sck), .sdcard_mosi(sdcard_mosi),
	      .sdcard_miso(sdcard_miso), .rxd(RXD), .txd(TXD),
	      .m_scl(), .m_sda(), .s_scl(), .s_sda(),
	      .sram_a(sram_a),
	      .sram_d_in(sram_a[12]? d_from_ide : (sram_a[11]? d_from_cdda : d_from_sdcard)),
	      .sram_d_out(d_to_ide_or_cdda_or_sdcard),
	      .sram_cs(sram_cs), .sram_oe(sram_oe), .sram_we(sram_we),
	      .sram_wait(sram_a[12]? sram_wait_ide : (sram_a[11]? sram_wait_cdda : sram_wait_sdcard)),
	      .ext_irq1(ide_irq_sync));

endmodule // top
