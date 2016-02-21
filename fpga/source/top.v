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
   localparam CPU_FREQ = 22579200;

   wire clkout, lock, lock_cdclk;
   wire [15:0] sram_a;
   wire [7:0]  d_to_ide, d_from_ide;
   wire sram_cs, sram_oe, sram_we, sram_wait;
   wire ide_irq;

   generate
      if(REFCLK_FREQ != CPU_FREQ) begin : use_clkgen

	 clkgen #(.INCLOCK_FREQ(REFCLK_FREQ),
		  .OUTCLOCK_FREQ(CPU_FREQ))
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

   ide_interface #(.drv(1'b0))
     ide_inst(.dd({D15,D14,D13,D12,D11,D10,D9,D8,D7,D6,D5,D4,D3,D2,D1,D0}),
	      .da({A2,A1,A0}), .cs1fx_(CS0n), .cs3fx_(CS1n), .dasp_(),
	      .dior_(RDn), .diow_(WRn), .dmack_(DMACKn), .dmarq(DMARQ),
	      .intrq(INTRQ), .iocs16_(), .iordy(IORDY), .pdiag_(),
	      .reset_(G_RST), .csel(1'b0), .clk(clkout),
	      .sram_a(sram_a), .sram_d_in(d_to_ide), .sram_d_out(d_from_ide),
	      .sram_cs(sram_cs), .sram_oe(sram_oe), .sram_we(sram_we),
	      .sram_wait(sram_wait), .cpu_irq(ide_irq));

   avr #(.pm_size(2),
	 .dm_size(2),
	 .impl_avr109(1),
	 .CLK_FREQUENCY(CPU_FREQ),
	 .AVR109_BAUD_RATE(115200),
`ifdef PM_INIT_LOW
	 .pm_init_low(`PM_INIT_LOW),
`endif
`ifdef PM_INIT_HIGH
	 .pm_init_high(`PM_INIT_HIGH),
`endif
	 )
     avr_inst(.nrst(1'b1), .clk(clkout),
	      .porta({LED7, LED6, LED5, LED4, LED3, LED2, LED1, LED0}),
	      .portb({PORTB7, PORTB6, PORTB5, PORTB4, PORTB3, PORTB2, PORTB1, PORTB0}),
	      .rxd(RXD), .txd(TXD),
	      .m_scl(), .m_sda(), .s_scl(), .s_sda(),
	      .sram_a(sram_a), .sram_d_in(d_from_ide), .sram_d_out(d_to_ide),
	      .sram_cs(sram_cs), .sram_oe(sram_oe), .sram_we(sram_we),
	      .sram_wait(sram_wait), .ext_irq1(ide_irq));

endmodule // top
