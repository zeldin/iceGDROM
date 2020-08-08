module tri_buf(
	       input out,
	       output in,
	       input en,
	       inout pin
	       );

   SB_IO #(.PIN_TYPE(6'b101001), .PULLUP(1'b1))
      tri_buf_impl(.PACKAGE_PIN(pin),
		   .LATCH_INPUT_VALUE(),
		   .CLOCK_ENABLE(),
		   .INPUT_CLK(),
		   .OUTPUT_CLK(),
		   .OUTPUT_ENABLE(en),
		   .D_OUT_0(out),
		   .D_OUT_1(),
		   .D_IN_0(in),
		   .D_IN_1()
		   );

endmodule // tri_buf

