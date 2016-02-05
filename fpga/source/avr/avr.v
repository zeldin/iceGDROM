`include "tech_def_pack.vh"

module avr (
	    input                         nrst,
	    input                         clk,
			 
	    // PORTA
	    inout[7:0]                    porta,
			 
	    // PORTB
	    inout[7:0]                    portb,

	    // UART related
	    input                         rxd,
	    output wire                   txd,  
			  
	    //I2C related
	    inout                          m_scl,
	    inout                          m_sda,
	    inout                          s_scl,
	    inout                          s_sda,
			 
  	    // SRAM i/f
	    output wire[15:0]              sram_a,
	    input  wire[7:0]               sram_d_in,
	    output wire[7:0]               sram_d_out,
	    output wire                    sram_cs,
	    output wire                    sram_oe,
	    output wire                    sram_we,
	    input  wire                    sram_wait
            );

parameter pm_size = 1;
parameter dm_size = 1;
parameter impl_avr109 = 0;
parameter CLK_FREQUENCY = 1000000;
parameter AVR109_BAUD_RATE = 19200;
parameter sram_address = 16'hE000;
parameter sram_size    = 1024;
parameter pm_init_low = "";
parameter pm_init_high = "";

localparam LP_DM_START_ADR = 16'h0060; /*16'h0100  M103/M128*/
localparam irqs_width = 23;
localparam pc22b_core = 0;
localparam dm_int_sram_read_ws = 1;  // DM access(read) wait stait is inserted
localparam use_rst = 1;
localparam rst_act_high = 0;

   function integer log2;
      input integer value;
      begin
         value = value-1;
         for (log2=0; value>0; log2=log2+1)
           value = value>>1;
      end
   endfunction

   // PortA interface
 wire[7:0]               porta_portx;
 wire[7:0]               porta_ddrx;
 wire[7:0]               porta_pinx;

   // PortB interface
 wire[7:0]               portb_portx;
 wire[7:0]               portb_ddrx;
 wire[7:0]               portb_pinx;

wire		 	 spe;
wire                     spimaster;
wire                     sdaen;
wire                  sclen;
   wire               msdaen;
   wire               msclen;
   wire               msclout;
   wire               msdaout;
   wire               sclout;
   wire               sdaout;
   wire               misoo;
   wire               mosio;
   wire               scko;
   wire               misoi;
   wire               mosii;
   wire               scki;
   wire 	      spi_slave_cs_n;
   
    // PM interface
 wire[15:0]              pm_adr;
 wire[15:0]              pm_dout;
 wire[15:0]              pm_din;		
 wire                    pm_we_h;
 wire                    pm_we_l;
 
 // DM interface
 wire[15:0]              dm_adr;
 wire[7:0]               dm_dout;
 wire[7:0]               dm_din;
 wire                    dm_we;


   // Bootloader interface
   wire        intercept_mode;
   wire        prog_mode;
   wire [15:0] prog_addr;
   wire [15:0] prog_data;
   wire        prog_low;
   wire        prog_high;

   wire        txd_core;
   wire        txd_avr109;
   reg 	       txd_q;

 wire                    clkn;

 wire 			 pwr_on_nrst;
 wire 		 core_ireset;
 wire wdt_wdovf;


   assign txd = txd_q;

rst_gen #(.rst_high(rst_act_high))
   rst_gen_inst(
	        // Clock inputs
		.cp2	    (clk),
		// Reset inputs
	        .nrst       (nrst & ~prog_mode),
		.npwrrst    (pwr_on_nrst),  // !!!! From the POWER-ON reset generator
		.wdovf      (wdt_wdovf),
		.jtagrst    (1'b0),
		// Reset outputs
		.nrst_cp2   (core_ireset),
		.nrst_clksw ()
		);



   
wire core_valid_instr;
wire core_change_flow;

wire[15:0] core_pc;
wire[15:0] core_inst;
wire[5:0] core_adr;
wire core_iore;
wire core_iowe;
wire[15:0] core_ramadr;
wire core_ramre;
wire core_ramwe;
wire core_cpuwait;
wire[7:0] core_dbusout;

wire[irqs_width-1:0] core_irqlines;
wire      core_irqack;
wire[4+pc22b_core:0] core_irqackad;

wire core_sleepi;
wire core_irqok;
wire core_globint;
wire core_wdri;

wire[15:0] core_spm_out;
wire core_spm_inst;
wire core_spm_wait;
// Wires connected to AVR core (end)


// To master(s)
wire[7:0]			   msts_dbusout; // Data from the selected slave(Common for all masters)
wire[0:0]		 	   msts_rdy;   // analog of !cpuwait
wire[0:0]			   msts_busy;  // analog of cpuwait
// To DM slave(s)
//wire[15:0]			   ramadr;
//wire[7:0]			   ramdout;
//wire				   ramre;
//wire				   ramwe;
// DM address decoder
wire[3:0]			   avr_interconnect_dm_ext_slv_sel;
// IRQ related
wire[irqs_width-1:0]		   avr_interconnect_ind_irq_ack;
// Clock and reset
wire				   cp2;

wire[7:0]                         core_dbusout_rg;

// To DM slaves
wire[15:0]                        avr_interconnect_ramadr;
wire[7:0]                         avr_interconnect_ramdout;
wire                              avr_interconnect_ramre;
wire                              avr_interconnect_ramwe;


// Peripherals
wire io_slv_out_en;
wire[7:0] io_slv_dbusout;



//******************************************************************************************

assign cp2 = clk;
assign clkn = ~clk;

avr_interconnect #(
                          .num_of_msts         (1),
                          .io_slv_num          (1),
			  .mem_slv_num         (1),
			  .irqs_width          (irqs_width),
			  .pc22b               (0         ),
			  // Added
			  .dm_int_sram_read_ws (dm_int_sram_read_ws),
			  .dm_start_adr        (LP_DM_START_ADR /*16'h0100*/),
			  .dm_size             (dm_size * 1024),	 // Size of DM SRAM in Bytes
			  //
			  .dm_ext_slv_adr0     (sram_address),
                          .dm_ext_slv_len0     (sram_size   ),
			  )
avr_interconnect_inst(
	 // To master(s)
	 .msts_dbusout   (msts_dbusout), // Data from the selected slave(Common for all masters)
         .msts_rdy       (msts_rdy    ),   // analog of !cpuwait
         .msts_busy      (msts_busy   ),   // analog of cpuwait
	 // To DM slave(s)
	 .ramadr         (avr_interconnect_ramadr ),
	 .ramdout        (avr_interconnect_ramdout),
         .ramre          (avr_interconnect_ramre  ),
         .ramwe          (avr_interconnect_ramwe  ),
         // DM address decoder
	 .sel_60_ff      ( ),
	 .sel_100_1ff    ( ),
	 .dm_ext_slv_sel (avr_interconnect_dm_ext_slv_sel),
	 // IRQ related
	 .ind_irq_ack    (avr_interconnect_ind_irq_ack),
         // Clock and reset
         .ireset         (core_ireset),
         .cp2            (cp2),
         // From master(s)
	 .msts_outs      ({core_ramwe, core_ramre, core_ramadr[15:0], core_dbusout_rg[7:0]}),   // avr_core     (Master 0)
         // From DM slave(s)
	 .dm_slv_outs    ({sram_cs & sram_oe, sram_wait, sram_d_in[7:0]}),
	 .dm_dout        (dm_din[7:0]), // From DM
	 // From IO slave(s)
	 .io_slv_outs    ({io_slv_out_en, io_slv_dbusout[7:0]}),
	 // IRQ related
         .irqack         (core_irqack),
         .irqackad       (core_irqackad)
	);


assign sram_a   = avr_interconnect_ramadr;
assign sram_d_out = avr_interconnect_ramdout;
assign sram_cs    = avr_interconnect_dm_ext_slv_sel[0];
assign sram_oe    = avr_interconnect_ramre;
assign sram_we    = avr_interconnect_ramwe;

assign core_cpuwait = msts_busy[0]; // cpuwait for Master 0


// AVR core

localparam eind_width  = 1;
localparam rampz_width = 8;
localparam impl_mul    = 1;

avr_core  #(
            .impl_mul    (impl_mul   ),
            .use_rst     (use_rst	),
            .pc22b       (pc22b_core	),
            .eind_width  (eind_width ),
            .rampz_width (rampz_width),
            .irqs_width  (irqs_width )
            )
avr_core_inst(
                .cp2         (cp2),
                .cp2en       (1'b1),
		.ireset      (core_ireset),

		.valid_instr (core_valid_instr),
		.insert_nop  (1'b0),
		.block_irq   (1'b0),
		.change_flow (core_change_flow),

		.pc          (core_pc      ),
		.inst        (core_inst    ),
		.adr         (core_adr     ),
		.iore        (core_iore    ),
		.iowe        (core_iowe    ),
		.ramadr      (core_ramadr  ),
		.ramre       (core_ramre   ),
		.ramwe       (core_ramwe   ),
		.cpuwait     (core_cpuwait ),
		.dbusin      (msts_dbusout ),
		.dbusout     (core_dbusout ),
		.irqlines    (core_irqlines),
		.irqack      (core_irqack  ),
		.irqackad    (core_irqackad),
		.sleepi      (core_sleepi  ),
		.irqok       (core_irqok   ),
		.globint     (core_globint ),
		.wdri        (core_wdri    ),

		.spm_out     (core_spm_out ),
		.spm_inst    (core_spm_inst),
		.spm_wait    (core_spm_wait)
		);

ram_data_rg ram_data_rg_inst(
	                   // Clock and Reset
                           .ireset   (core_ireset),
                           .cp2      (cp2   ),
		           // Data and Control
                           .cpuwait   (core_cpuwait),
			   .data_in   (core_dbusout),
			   .data_out  (core_dbusout_rg)
	                   );


// PM interface
assign pm_adr = (prog_mode? prog_addr : core_pc);
assign core_inst         = pm_din[15:0];

// PM data output
assign pm_dout = (prog_mode? prog_data : 16'h0000);
assign pm_we_h = prog_mode & prog_high;
assign pm_we_l = prog_mode & prog_low;


// DM interface
assign dm_adr[15:0] = avr_interconnect_ramadr[15:0];
assign dm_dout[7:0] = avr_interconnect_ramdout[7:0];
assign dm_we        = avr_interconnect_ramwe;


peripherals #(.irqs_width(irqs_width))
   peripherals_inst( .ireset         (core_ireset),
                     .cp2	     (cp2),

		     .adr(core_adr),
		     .iore(core_iore),
		     .iowe(core_iowe),
		     .out_en(io_slv_out_en),
		     .dbus_in(core_dbusout),
		     .dbus_out(io_slv_dbusout),

		     .irqlines(core_irqlines),
		     .irq_ack(avr_interconnect_ind_irq_ack),

		     // PORTA related
		     .porta_portx(porta_portx),
		     .porta_ddrx(porta_ddrx),
		     .porta_pinx(porta_pinx),

		     // PORTB related
		     .portb_portx(portb_portx),
		     .portb_ddrx(portb_ddrx),
		     .portb_pinx(portb_pinx),

		     // Timer related
		     .tmr_ext_1(1'b0),
		     .tmr_ext_2(1'b0),
		     .wdt_wdovf(wdt_wdovf),
		     .wdri(core_wdri),

		     // UART related
		     .rxd(intercept_mode | rxd),
		     .txd(txd_core),

		     // SPI related
		     .misoi(misoi),
		     .mosii(mosii),
		     .scki(scki),
		     .ss_b(spi_slave_cs_n),

		     .misoo(misoo),
		     .mosio(mosio),
		     .scko(scko),
		     .spe(spe),
		     .spimaster(spimaster),

                     //I2C related
		     // TRI control and data for the slave channel
		     .sdain(s_sda),
		     .sdaout(sdaout),
		     .sdaen(sdaen),
		     .sclin(s_scl),
		     .sclout(sclout),
		     .sclen(sclen),
		     // TRI control and data for the master channel
		     .msdain(m_sda),
		     .msdaout(msdaout),
		     .msdaen(msdaen),
		     .msclin(m_scl),
		     .msclout(msclout),
		     .msclen(msclen),

		     //SPM
		     .spm_out(core_spm_out),
		     .spm_inst(core_spm_inst),
		     .spm_wait(core_spm_wait)
		     );


snc_ram #(
	  .adr_width(log2(pm_size)+10),
	  .data_width(8),
	  .initdata(pm_init_low)
	  )
p_mem_low_inst(
   .clk     (clkn),
   .en      (1'b1),
   .we      (pm_we_l),
   .adr     (pm_adr),
   .din     (pm_dout[7:0]),
   .dout    (pm_din[7:0])
);

snc_ram #(
	  .adr_width(log2(pm_size)+10),
	  .data_width(8),
	  .initdata(pm_init_high)
	  )
p_mem_high_inst(
   .clk     (clkn),
   .en      (1'b1),
   .we      (pm_we_h),
   .adr     (pm_adr),
   .din     (pm_dout[15:8]),
   .dout    (pm_din[15:8])
);

snc_ram #(
	.adr_width(log2(dm_size)+10),
	.data_width(8)
)
d_mem_inst(
   .clk     (dm_int_sram_read_ws? clk : clkn),
   .en      (1'b1),
   .we      (dm_we),
   .adr     (dm_adr),
   .din     (dm_dout),
   .dout    (dm_din)
);

tri_buf tri_buf_porta_inst[7:0](
	       .out (porta_portx),
	       .in  (porta_pinx),
	       .en  (porta_ddrx) ,
	       .pin (porta)
	       );

tri_buf tri_buf_portb_inst[7:0](
	       .out ({portb_portx[7:4],
		      ((spe & (~spimaster))? misoo : portb_portx[3]),
		      ((spe & spimaster)? {mosio, scko} : portb_portx[2:1]),
		      portb_portx[0]}),
	       .in  (portb_pinx),
	       .en  ({portb_ddrx[7:4],
		      ((spe & spimaster)? 1'b0 : portb_ddrx[3]),
		      ((spe & (~spimaster))? 3'b000 : portb_ddrx[2:0])}),
	       .pin (portb)
	       );

assign spi_slave_cs_n = portb_pinx[0];
assign scki = portb_pinx[1];
assign mosii = portb_pinx[2];
assign misoi = portb_pinx[3];

por_rst_gen #(.tech(c_tech_generic)) por_rst_gen_inst(
   .clk       (clk),
   .por_n_i   (1'b1),
   .por_n_o   (pwr_on_nrst),
   .por_n_o_g ()
   );

generate
if(impl_avr109) begin : avr109_is_implemented

   avr109 #(.CLK_FREQUENCY(CLK_FREQUENCY), .BAUD_RATE(AVR109_BAUD_RATE))
     avr109_inst(.rst(~pwr_on_nrst), .clk(clk),
		 .rxd(rxd), .txd(txd_avr109), .intercept_mode(intercept_mode),
		 .prog_mode(prog_mode), .prog_addr(prog_addr),
		 .prog_data(prog_data), .prog_data_in(pm_din),
		 .prog_low(prog_low), .prog_high(prog_high));

end
else begin : avr109_is_not_implemented

   assign intercept_mode = 1'b0;
   assign prog_mode = 1'b0;
   assign prog_addr = 16'h0000;
   assign prog_data = 16'h0000;
   assign prog_low = 1'b0;
   assign prog_high = 1'b0;
   assign txd_avr109 = 1'b1;

end
endgenerate

always @(posedge clk) begin
   if (~pwr_on_nrst)
     txd_q <= 1'b1;
   else if (intercept_mode)
     txd_q <= txd_avr109;
   else
     txd_q <= txd_core;
end

endmodule // avr
