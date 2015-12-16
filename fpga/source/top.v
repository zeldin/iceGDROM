module top (
	    input clk,
	    input RXD,
	    output TXD,
	    output LED0,
	    output LED1,
	    output LED2,
	    output LED3,
	    output LED4,
	    output LED5,
	    output LED6,
	    output LED7
	    );

   localparam REFCLK_FREQ = 12000000;
   localparam CPU_FREQ = 24000000;

   wire clkout, lock;

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

   avr #(.pm_size(1),
	 .dm_size(1),
	 .impl_avr109(1),
	 .CLK_FREQUENCY(CPU_FREQ),
	 .AVR109_BAUD_RATE(115200),
	 .pm_init_low("pmem_low.hex"),
	 .pm_init_high("pmem_high.hex"),
	 )
     avr_inst(.nrst(1'b1), .clk(clkout),
	      .porta({LED7, LED6, LED5, LED4, LED3, LED2, LED1, LED0}),
	      .rxd(RXD), .txd(TXD),
	      .mosi(), .miso(), .sck(), .spi_cs_n(),
	      .m_scl(), .m_sda(), .s_scl(), .s_sda(),
	      .sram_a(), .sram_d_in({8{1'b0}}), .sram_d_out(),
	      .sram_cs(), .sram_oe(), .sram_we(), .sram_wait(1'b0));

endmodule // top
