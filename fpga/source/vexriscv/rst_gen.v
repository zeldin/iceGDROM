module rst_gen(input clk, output reg nrst);

   reg [7:0] cnt = 0;

   always @(posedge clk)
     if (&cnt)
       nrst <= 1'b1;
     else begin
	nrst <= 1'b0;
	cnt <= cnt + 1;
     end

endmodule // rst_gen
