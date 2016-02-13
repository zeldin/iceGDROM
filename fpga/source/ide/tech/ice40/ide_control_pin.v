module ide_control_pin(
		       inout pin,
		       input out,
		       input enable,
		       input clk
		       );

   SB_IO #(.PIN_TYPE(6'b111001), .PULLUP(1'b0), .NEG_TRIGGER(1'b1))
     ide_data_pin_impl(.PACKAGE_PIN(pin),
		       .CLOCK_ENABLE(1'b1),
		       .INPUT_CLK(),
		       .OUTPUT_CLK(clk),
		       .OUTPUT_ENABLE(enable),
		       .D_OUT_0(out),
		       .D_OUT_1(),
		       .D_IN_0(),
		       .D_IN_1()
		       );
   
endmodule // ide_control_pin
