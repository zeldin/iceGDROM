module clkgen(
	   input clkin,
	   output clkout,
	   output lock
);

   parameter INCLOCK_FREQ = 12000000;
   parameter OUTCLOCK_FREQ = 24000000;

   localparam r_bits = 4;
   localparam f_bits = 7;
   localparam q_bits = 3;

   localparam rfq = compute_divisors(INCLOCK_FREQ, OUTCLOCK_FREQ);
   localparam r = rfq[(q_bits+f_bits) +: r_bits];
   localparam f = rfq[q_bits +: f_bits];
   localparam q = rfq[0 +: q_bits];

   function integer gcd;
      input integer a;
      input integer b;
      integer       t;
      begin
         while (b != 0) begin
            t = b;
            b = a % b;
            a = t;
         end;
         gcd = a;
      end
   endfunction // gcd

   function integer pack_rfq;
      input integer r;
      input integer f;
      input integer q;
      begin
         pack_rfq = {r[0 +: r_bits], f[0 +: f_bits], q[0 +: q_bits]};
      end
   endfunction // pack_rfq

   function integer compute_divisors;
      input integer f_ref;
      input integer f_out;
      integer       g;
      integer       r;
      integer       f;
      integer       q;
      begin
         g = gcd(f_ref, f_out);
         r = f_ref / g;
         f = f_out / g;
	 q = 3;
	 while (q > 0 && f_out > f_ref) begin
	    q = q - 1;
	    f_ref = f_ref * 2;
	 end
	 if (r < 1 || r > 16 || f < 1 || f > 64)
	   compute_divisors = -1;
	 else
           compute_divisors = pack_rfq(r-1, f-1, q);
      end
   endfunction // compute_divisors

   generate
      if (rfq < 0) begin
	 initial $finish;
      end else begin
	 initial $display("r = %d, f = %d, q = %d", r, f, q);

	 SB_PLL40_CORE #(.DIVR(r), .DIVF(f), .DIVQ(q),
			 .FILTER_RANGE(1), .FEEDBACK_PATH("PHASE_AND_DELAY"),
			 .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
			 .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
			 .FDA_FEEDBACK(0), .FDA_RELATIVE(0),
			 .SHIFTREG_DIV_MODE(0), .ENABLE_ICEGATE(0),
			 .PLLOUT_SELECT("SHIFTREG_0deg"))
	 pll_inst(.REFERENCECLK(clkin),
		  .PLLOUTGLOBAL(clkout),
		  .RESETB(1'b1),
		  .BYPASS(1'b0),
		  .LOCK(lock));
      end
   endgenerate

endmodule // clkgen
