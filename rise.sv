/*------------------------------------------------------------------------------
 * File          : rise.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Sep 30, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module rise (
	input        rst_n,
	input        clk,
	input        trig,
	output logic out
);

logic temp ;

assign out = temp & trig ;
always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n)
		temp <= 0;
	
	if(~trig)
		temp <= 1;
	
	else if(temp)
		temp <= 0 ;
end

endmodule

