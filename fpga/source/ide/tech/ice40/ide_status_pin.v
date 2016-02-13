module ide_status_pin(
		      inout pin,
		      output in,
		      input clk
		      );

   SB_IO #(.PIN_TYPE(6'b000001), .PULLUP(1'b0), .NEG_TRIGGER(1'b1))
     ide_data_pin_impl(.PACKAGE_PIN(pin),
		       .CLOCK_ENABLE(1'b1),
		       .INPUT_CLK(clk),
		       .OUTPUT_CLK(),
		       .D_OUT_0(),
		       .D_OUT_1(),
		       .D_IN_0(in),
		       .D_IN_1()
		       );

endmodule // ide_status_pin
