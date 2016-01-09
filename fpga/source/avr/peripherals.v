`include "synth_ctrl_pack.vh"
`include "avr_adr_pack.vh"

module peripherals
  #(
    parameter impl_usart       = `c_impl_usart,
    parameter impl_smb	       = `c_impl_smb,
    parameter impl_spi	       = `c_impl_spi,
    parameter impl_wdt	       = `c_impl_wdt,
    parameter irqs_width       = `c_irqs_width,
    )
   (
    // Clock and Reset
    input wire       ireset,
    input wire       cp2,

    // I/O Slave interface
    input[5:0] adr,
    input iore,
    input iowe,
    output out_en,
    input[7:0] dbus_in,
    output[7:0] dbus_out,

    // IRQ interface
    output[irqs_width-1:0] irqlines,
    input[irqs_width-1:0]  irq_ack,

			 // PORTA related
			 output[7:0]                    porta_portx,
	                 output[7:0]                    porta_ddrx,
	                 input[7:0]                     porta_pinx,

			 // PORTB related
			 output[7:0]                    portb_portx,
	                 output[7:0]                    portb_ddrx,
	                 input[7:0]                     portb_pinx,

			 // Timer related
			 input                          tmr_ext_1,
			 input                          tmr_ext_2,
                         output                         wdt_wdovf,
			 input wdri,

			 // UART related
			 input                          rxd,
			 output                         txd,

			 // SPI related
			input	                        misoi,
			input	                        mosii,
			input	                        scki,
			input	                        ss_b,

			output wire                     misoo,
			output wire                     mosio,
			output wire                     scko,
			output wire                     spe,
			output wire                     spimaster,
                        output wire                     spi_cs_n,

                         //I2C related
			 // TRI control and data for the slave channel
			 input                          sdain,
			 output wire                    sdaout,
			 output wire                    sdaen,
			 input                          sclin,
			 output wire                    sclout,
			 output wire                    sclen,
			 // TRI control and data for the master channel
			 input                          msdain,
			 output wire                    msdaout,
			 output wire                    msdaen,
			 input                          msclin,
			 output wire                    msclout,
			 output wire                    msclen,

			//SPM related
			input[15:0] spm_out,
			input       spm_inst,
			output      spm_wait
    );


//==========================================================================================
// USART configuration

 `define C_DBG_USART_USED TRUE

localparam LP_USART_SYNC_RST	     = 0;
localparam LP_USART_RXB_TXB_ADR	     = 6'h0C; // UDR0_Address
localparam LP_USART_STATUS_ADR	     = 6'h0B; // UCSR0A_Address
localparam LP_USART_CTRLA_ADR	     = ADCSRA_Address; // TBD ???
localparam LP_USART_CTRLB_ADR	     = 6'h0A; // UCSR0B_Address
localparam LP_USART_CTRLC_ADR	     = ADMUX_Address;  // TBD ???
localparam LP_USART_BAUDCTRLA_ADR    = 6'h09; // UBRR0L_Address
localparam LP_USART_BAUDCTRLB_ADR    = ACSR_Address;   // TBD ???
localparam LP_USART_RXB_TXB_DM_LOC   = 0;
localparam LP_USART_STATUS_DM_LOC    = 0;
localparam LP_USART_CTRLA_DM_LOC     = 0;
localparam LP_USART_CTRLB_DM_LOC     = 0;
localparam LP_USART_CTRLC_DM_LOC     = 0;
localparam LP_USART_BAUDCTRLA_DM_LOC = 0;
localparam LP_USART_BAUDCTRLB_DM_LOC = 0;
localparam LP_USART_RX_FIFO_DEPTH    = 2;
localparam LP_USART_TX_FIFO_DEPTH    = 2;
localparam LP_USART_MEGA_COMPAT_MODE = 1;
localparam LP_USART_COMPAT_MODE      = 0;
localparam LP_USART_IMPL_DFT         = 0;

//==========================================================================================

// WDT

// WDT IO slave output
wire[7:0]wdt_io_slv_dbusout;
wire wdt_io_slv_out_en;


// Timer/Counter IO slave output
wire[7:0]tmr_io_slv_dbusout;
wire     tmr_io_slv_out_en;

// PORTA slave output
wire[7:0] pport_a_io_slv_dbusout;
wire      pport_a_io_slv_out_en;

// PORTB slave output
wire[7:0] pport_b_io_slv_dbusout;
wire      pport_b_io_slv_out_en;

// SPI slave output
wire[7:0] spi_io_slv_dbusout;
wire      spi_io_slv_out_en;

localparam c_spi_slvs_num = 8;
wire[7:0] spi_slv_sel_n;

// UART
wire[7:0] uart_io_slv_dbusout;
wire      uart_io_slv_out_en;

// SMBus
wire[7:0]smb_io_slv_dbusout;
wire     smb_io_slv_out_en;

// SPM module
wire[7:0]spm_mod_io_slv_dbusout;
wire spm_mod_io_slv_out_en;

// SPM
wire spm_mod_rwwsre_op;
wire spm_mod_blbset_op;
wire spm_mod_pgwrt_op ;
wire spm_mod_pgers_op ;
wire spm_mod_spmen_op ;

wire spm_mod_rwwsre_rdy;
wire spm_mod_blbset_rdy;
wire spm_mod_pgwrt_rdy ;
wire spm_mod_pgers_rdy ;
wire spm_mod_spmen_rdy ;


wire vcc = 1'b1;
wire gnd = 1'b0;


generate
if(impl_wdt) begin : wdt_is_implemented
wdt_mod wdt_mod_inst(
	                 // Clock and Reset
                     .ireset         (ireset),
                     .cp2	     (cp2),
		      // AVR Control
                     .adr            (adr),
                     .dbus_in        (dbus_in),
                     .dbus_out       (wdt_io_slv_dbusout),
                     .iore           (iore),
                     .iowe           (iowe),
                     .out_en         (wdt_io_slv_out_en),
		      // Watchdog timer
		     .runmod         (1'b1),
                     .wdt_irqack     (gnd),
                     .wdri	     (wdri),
                     .wdt_irq	     ( ),
                     .wdtmout	     (wdt_wdovf),
                     .wdtcnt 	     ( )
                     );
end // wdt_is_implemented
else begin : wdt_is_not_implemented
 assign wdt_wdovf          = gnd;
 assign wdt_io_slv_dbusout = {8{1'b0}};
 assign wdt_io_slv_out_en  = gnd;
end // wdt_is_not_implemented

endgenerate

// Timer counter
Timer_Counter Timer_Counter_inst(
   // AVR Control
   .ireset         (ireset),
   .cp2            (cp2   ),
   .cp2en          (1'b1  ),
   .tmr_cp2en      (1'b1  ),
   .stopped_mode   (1'b0 ),	      // ??
   .tmr_running    (1'b0  ),	      // ??
   .adr            (adr    ),
   .dbus_in        (dbus_in),
   .dbus_out       (tmr_io_slv_dbusout),
   .iore           (iore),
   .iowe           (iowe),
   .out_en         (tmr_io_slv_out_en),
   // External inputs/outputs
   .EXT1           (tmr_ext_1),
   .EXT2           (tmr_ext_2),
   .OC0_PWM0       (/*Not used*/),
   .OC1A_PWM1A     (/*Not used*/),
   .OC1B_PWM1B     (/*Not used*/),
   .OC2_PWM2       (/*Not used*/),
   // Interrupt related signals
   .TC0OvfIRQ      (irqlines[15]),
   .TC0OvfIRQ_Ack  (irq_ack[15]),
   .TC0CmpIRQ      (irqlines[14]),
   .TC0CmpIRQ_Ack  (irq_ack[14]),
   .TC2OvfIRQ      (irqlines[9] ),
   .TC2OvfIRQ_Ack  (irq_ack[9] ),
   .TC2CmpIRQ      (irqlines[8] ),
   .TC2CmpIRQ_Ack  (irq_ack[8] ),
   .TC1OvfIRQ      (irqlines[13]),
   .TC1OvfIRQ_Ack  (irq_ack[13]),
   .TC1CmpAIRQ     (irqlines[11]),
   .TC1CmpAIRQ_Ack (irq_ack[11]),
   .TC1CmpBIRQ     (irqlines[12]),
   .TC1CmpBIRQ_Ack (irq_ack[12]),
   .TC1ICIRQ       (irqlines[10]),
   .TC1ICIRQ_Ack   (irq_ack[10])
);


//################################################ PORTA #################################################

         pport#(
	       .portx_adr    (PORTA_Address),
	       .ddrx_adr     (DDRA_Address),
	       .pinx_adr     (PINA_Address),
	       .portx_dm_loc (0),
	       .ddrx_dm_loc  (0),
	       .pinx_dm_loc  (0),
	       .port_width   (8),
	       .port_rs_type (0 /*c_pport_rs_md_fre*/),
	       .port_mode    (0 /*c_pport_mode_bidir*/)
	       )
   pport_a_inst(
	           // Clock and Reset
               .ireset      (ireset),
               .cp2	    (cp2),
	        // I/O
               .adr	    (adr),
               .dbus_in     (dbus_in),
               .dbus_out    (pport_a_io_slv_dbusout),
               .iore	    (iore),
               .iowe	    (iowe),
               .io_out_en   (pport_a_io_slv_out_en),
	        // DM
	       .ramadr      ({8{1'b0}} ),
	       .dm_dbus_in  ({8{1'b0}}),
               .dm_dbus_out (/*Not used*/),
               .ramre	    (gnd),
               .ramwe	    (gnd),
	       .dm_sel      (gnd),
	       .cpuwait     (/*Not used*/),
	       .dm_out_en   (/*Not used*/),
		// External connection
	       .portx	    (porta_portx),
	       .ddrx	    (porta_ddrx),
	       .pinx	    (porta_pinx),
		//
	       .resync_out  (/*Not used*/)
	        );

//################################################ PORTB #################################################

         pport#(
	       .portx_adr    (PORTB_Address),
	       .ddrx_adr     (DDRB_Address),
	       .pinx_adr     (PINB_Address),
	       .portx_dm_loc (0),
	       .ddrx_dm_loc  (0),
	       .pinx_dm_loc  (0),
	       .port_width   (8),
	       .port_rs_type (0 /*c_pport_rs_md_fre*/),
	       .port_mode    (0 /*c_pport_mode_bidir*/)
	       )
   pport_b_inst(
	           // Clock and Reset
               .ireset      (ireset),
               .cp2	    (cp2),
	        // I/O
               .adr	    (adr),
               .dbus_in     (dbus_in),
               .dbus_out    (pport_b_io_slv_dbusout),
               .iore	    (iore),
               .iowe	    (iowe),
               .io_out_en   (pport_b_io_slv_out_en),
	        // DM
	       .ramadr      ({8{1'b0}} ),
	       .dm_dbus_in  ({8{1'b0}}),
               .dm_dbus_out (/*Not used*/),
               .ramre	    (gnd),
               .ramwe	    (gnd),
	       .dm_sel      (gnd),
	       .cpuwait     (/*Not used*/),
	       .dm_out_en   (/*Not used*/),
		// External connection
	       .portx	    (portb_portx),
	       .ddrx	    (portb_ddrx),
	       .pinx	    (portb_pinx),
		//
	       .resync_out  (/*Not used*/)
	        );


// I/O slaves outputs
   wire [8*(8+1)-1:0] io_slv_outs;
   assign io_slv_outs = {
                      wdt_io_slv_out_en,wdt_io_slv_dbusout[7:0],
                      tmr_io_slv_out_en,tmr_io_slv_dbusout[7:0],
		      pport_a_io_slv_out_en,pport_a_io_slv_dbusout[7:0],
		      pport_b_io_slv_out_en,pport_b_io_slv_dbusout[7:0],
		      spi_io_slv_out_en,spi_io_slv_dbusout[7:0],
		      uart_io_slv_out_en,uart_io_slv_dbusout[7:0],
		      smb_io_slv_out_en,smb_io_slv_dbusout[7:0],
		      spm_mod_io_slv_out_en,spm_mod_io_slv_dbusout[7:0]
		      };

genvar i;
generate
   for(i=0; i<8; i=i+1) begin : peripheral_out
      wire out_en, prev_en;
      wire [7:0] dbusout, prevout;
      if (i==0) begin
	 assign prev_en = 1'b0;
	 assign prevout = {8{1'b0}};
      end else begin
	 assign prev_en = peripheral_out[i-1].out_en;
	 assign prevout = peripheral_out[i-1].dbusout;
      end
      assign out_en = io_slv_outs[i*9+8] | prev_en;
      assign dbusout = (io_slv_outs[i*9+8]? io_slv_outs[i*9+7:i*9] : prevout);
   end
endgenerate

   assign out_en = peripheral_out[7].out_en;
   assign dbus_out = peripheral_out[7].dbusout;


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 assign irqlines[1]    = 1'b0;

// SPI module
generate
if(impl_spi) begin : spi_is_implemented

spi_mod spi_mod_inst(
	                // AVR Control
                    .ireset     (ireset),
                    .cp2	(cp2),
                    .adr        (adr),
                    .dbus_in    (dbus_in),
                    .dbus_out   (spi_io_slv_dbusout),
                    .iore       (iore),
                    .iowe       (iowe),
                    .out_en     (spi_io_slv_out_en),
                    // SPI i/f
		    .misoi       (misoi),
		    .mosii       (mosii),
		    .scki        (scki),
		    .ss_b        (ss_b),
		    .misoo       (misoo),
		    .mosio       (mosio),
		    .scko        (scko),
		    .spe         (spe),
		    .spimaster   (spimaster),
		    // IRQ
		    .spiirq      (irqlines[16]),
		    .spiack      (irq_ack[16]),
		    // Slave Programming Mode
		    .por	 (gnd),
		    .spiextload  (gnd),
		    .spidwrite   (/*Not used*/),
		    .spiload     (/*Not used*/)
                    );


// SPI slave select module
spi_slv_sel #(.num_of_slvs (c_spi_slvs_num))
	spi_slv_sel_inst(
	                // AVR Control
                    .ireset     (ireset),
                    .cp2	(cp2),
                    .adr        (adr),
                    .dbus_in    (dbus_in),
                    .dbus_out   (/*Not used*/),
                    .iore       (iore),
                    .iowe       (iowe),
                    .out_en     (/*Not used*/),
		     // Output
                    .slv_sel_n  (spi_slv_sel_n)
                    );

end // spi_is_implemented
else begin : spi_is_not_implemented

assign spi_io_slv_dbusout = {8{1'b0}};
assign spi_io_slv_out_en  = gnd;
assign spi_slv_sel_n      = {c_spi_slvs_num{1'b1}};

assign misoo = 1'b0;
assign mosio = 1'b0;
assign scko = 1'b0;
assign spe = 1'b0;
assign spimaster = 1'b0;

end // spi_is_not_implemented

endgenerate

assign spi_cs_n = spi_slv_sel_n[0];


// UART/USART

// TBD hardware flow control support
wire rtsn;
wire ctsn;
// assign ctsn = rtsn; // Support for loopback tests

generate

if(!impl_usart) begin : uart_is_implemented

`ifdef C_DBG_USART_USED
// USART
      usart #(
             .SYNC_RST	       (LP_USART_SYNC_RST	 ),
             .RXB_TXB_ADR      (LP_USART_RXB_TXB_ADR	 ),
             .STATUS_ADR       (LP_USART_STATUS_ADR	 ),
             .CTRLA_ADR        (LP_USART_CTRLA_ADR	 ),
             .CTRLB_ADR        (LP_USART_CTRLB_ADR	 ),
             .CTRLC_ADR        (LP_USART_CTRLC_ADR	 ),
             .BAUDCTRLA_ADR    (LP_USART_BAUDCTRLA_ADR   ),
             .BAUDCTRLB_ADR    (LP_USART_BAUDCTRLB_ADR   ),
             .RXB_TXB_DM_LOC   (LP_USART_RXB_TXB_DM_LOC  ),
             .STATUS_DM_LOC    (LP_USART_STATUS_DM_LOC   ),
             .CTRLA_DM_LOC     (LP_USART_CTRLA_DM_LOC	 ),
             .CTRLB_DM_LOC     (LP_USART_CTRLB_DM_LOC	 ),
             .CTRLC_DM_LOC     (LP_USART_CTRLC_DM_LOC	 ),
             .BAUDCTRLA_DM_LOC (LP_USART_BAUDCTRLA_DM_LOC),
             .BAUDCTRLB_DM_LOC (LP_USART_BAUDCTRLB_DM_LOC),
	     .RX_FIFO_DEPTH    (LP_USART_RX_FIFO_DEPTH   ),
             .TX_FIFO_DEPTH    (LP_USART_TX_FIFO_DEPTH   ),
	     .MEGA_COMPAT_MODE (LP_USART_MEGA_COMPAT_MODE),
	     .COMPAT_MODE      (LP_USART_COMPAT_MODE	 ),
             .IMPL_DFT         (LP_USART_IMPL_DFT        )
	     )
   usart_inst(
             // Clock and Reset
             .ireset      (ireset                     ),
             .cp2         (cp2	                           ),
             .adr         (adr                  ),
             .dbus_in     (dbus_in              ),
             .dbus_out    (uart_io_slv_dbusout             ),
             .iore        (iore	           ),
             .iowe        (iowe	           ),
             .io_out_en   (uart_io_slv_out_en              ),
             .ramadr 	  ({3{1'b0}}                       ),
             .dm_dbus_in  ({8{1'b0}}                       ),
             .dm_dbus_out (                                ),
             .ramre	  (1'b0			           ),
             .ramwe	  (1'b0			           ),
             .dm_sel	  (1'b0                            ),
             .cpuwait	  (                                ),
             .dm_out_en   (                                ),
             .rxcintlvl   (                                ),
             .txcintlvl   (                                ),
             .dreintlvl   (                                ),
             .rxd	  (rxd  			   ),
             .rx_en	  (/*Not used*/ 		   ),
             .txd	  (txd  			   ),
             .tx_en	  (/*Not used*/ 		   ),
             .txcirq	  (irqlines[19]               ),
             .txc_irqack  (irq_ack[19]),
             .udreirq	  (irqlines[18]               ),
             .rxcirq	  (irqlines[17]               ),
	     .rtsn        (rtsn                            ),
	     .ctsn        (ctsn                            ),
	      // Test related
	     .test_se     (1'b0                            ),
	     .test_si1    (1'b0                            ),
	     .test_si2    (1'b0                            ),

	     .test_so1    (                                ),
	     .test_so2	  (                                )
	         );

`else

uart uart_inst(
	             // AVR Control
                    .ireset     (ireset),
                    .cp2	(cp2),
                    .adr        (adr),
                    .dbus_in    (dbus_in),
                    .dbus_out   (uart_io_slv_dbusout),
                    .iore       (iore),
                    .iowe       (iowe),
                    .out_en     (uart_io_slv_out_en),
                    // External connection
                    .rxd        (rxd),
                    .rx_en      (/*Not used*/),
                    .txd        (txd),
                    .tx_en      (/*Not used*/),
                    // IRQ
                    .txcirq     (irqlines[19]),
                    .txc_irqack (irq_ack[19]),
                    .udreirq    (irqlines[18]),
	            .rxcirq     (irqlines[17])
		);
`endif

end // uart_is_implemented
else begin : uart_is_not_implemented

assign uart_io_slv_dbusout = {8{1'b0}};
assign uart_io_slv_out_en  = 1'b0;

assign irqlines[17] = 1'b0;
assign irqlines[18] = 1'b0;
assign irqlines[19] = 1'b0;


end // uart_is_not_implemented

endgenerate




generate
if(impl_smb) begin : smb_is_implemented
            smb_mod #(.impl_pec (1))
	    smb_mod_inst(
	                 // AVR Control
                        .ireset       (ireset),
                        .cp2	      (cp2),
                        .adr          (adr),
                        .dbus_in      (dbus_in),
                        .dbus_out     (smb_io_slv_dbusout),
                        .iore         (iore),
                        .iowe         (iowe),
                        .out_en       (smb_io_slv_out_en),
                        // Slave IRQ
                        .twiirq       (irqlines[21]),
                        // Master IRQ
			.msmbirq      (irqlines[20]),
			 // "Off state" timer IRQ
                        .offstirq     (irqlines[22]),
                        .offstirq_ack (irq_ack[22]),
			 // TRI control and data for the slave channel
			.sdain        (sdain  ), // in  std_logic;
			.sdaout       (sdaout ),// out std_logic;
			.sdaen        (sdaen  ), // out std_logic;
			.sclin        (sclin  ), // in  std_logic;
			.sclout       (sclout ),// out std_logic;
			.sclen        (sclen  ), // out std_logic;
		        // TRI control and data for the master channel
			.msdain       (msdain ), // in  std_logic;
			.msdaout      (msdaout),// out std_logic;
			.msdaen       (msdaen ), // out std_logic;
			.msclin       (msclin ), // in  std_logic;
			.msclout      (msclout),// out std_logic;
			.msclen       (msclen )  // out std_logic
			);

end // smb_is_implemented
else begin : smb_is_not_implemented

assign smb_io_slv_dbusout = {8{1'b0}};
assign smb_io_slv_out_en  = 1'b0;

// Slave related
assign sdaout = 1'b0;
assign sdaen  = 1'b0;
assign sclout = 1'b0;
assign sclen  = 1'b0;

// Master related
assign msdaout = 1'b0;
assign msdaen  = 1'b0;
assign msclout = 1'b0;
assign msclen  = 1'b0;

assign irqlines[22:20] = {3{1'b0}}; // !!! Width

end // smb_is_not_implemented

endgenerate

// TBD
localparam SPMCSR_IO_Address = PORTD_Address;

   spm_mod #(
	     .use_dm_loc (0),
	     .csr_adr	 (SPMCSR_IO_Address)
	    )
       spm_mod_inst(
	                // AVR Control
                    .ireset      (ireset),
                    .cp2	 (cp2),
	             // I/O
                    .adr         (adr),
                    .dbus_in     (dbus_in),
                    .dbus_out    (spm_mod_io_slv_dbusout),
                    .iore        (iore),
                    .iowe        (iowe),
                    .io_out_en   (spm_mod_io_slv_out_en),
		     // DM
		    .ramadr      ({8{1'b0}}),
		    .dm_dbus_in  ({8{1'b0}}),
                    .dm_dbus_out (/*Not used*/),
                    .ramre       (gnd),
                    .ramwe       (gnd),
		    .dm_sel      (gnd),
		    .cpuwait     (/*Not used*/),
		    .dm_out_en   (/*Not used*/),
		    //
		   .spm_out      (spm_out),
		   .spm_inst     (spm_inst),
		   .spm_wait     (spm_wait),
		    // IRQ
		   .spm_irq      (irqlines[7]),
		   .spm_irq_ack  (irq_ack[7]),
		    //
		   .rwwsre_op    (spm_mod_rwwsre_op),
		   .blbset_op    (spm_mod_blbset_op),
		   .pgwrt_op     (spm_mod_pgwrt_op),
		   .pgers_op     (spm_mod_pgers_op),
		   .spmen_op     (spm_mod_spmen_op),
		    //
		   .rwwsre_rdy   (spm_mod_rwwsre_rdy),
                   .blbset_rdy   (spm_mod_blbset_rdy),
                   .pgwrt_rdy    (spm_mod_pgwrt_rdy),
                   .pgers_rdy    (spm_mod_pgers_rdy),
                   .spmen_rdy    (spm_mod_spmen_rdy)
		   );


  // Unused irqlines (TBD)
  assign irqlines[0]   = 1'b0;
  assign irqlines[6:2] = {5{1'b0}};

endmodule // peripherals


