module ide_data_pin (
		     inout pin,
		     output in,
		     input out,
		     input latch,
		     input enable,
		     input clk
		     );

   SB_IO #(.PIN_TYPE(6'b111011), .PULLUP(1'b0), .NEG_TRIGGER(1'b1))
     ide_data_pin_impl(.PACKAGE_PIN(pin),
		       .LATCH_INPUT_VALUE(latch),
		       .CLOCK_ENABLE(1'b1),
		       .INPUT_CLK(),
		       .OUTPUT_CLK(clk),
		       .OUTPUT_ENABLE(enable),
		       .D_OUT_0(out),
		       .D_OUT_1(),
		       .D_IN_0(in),
		       .D_IN_1()
		       );

endmodule // ide_data_pin
