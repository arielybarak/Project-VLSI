/*------------------------------------------------------------------------------
 * File          : box_m_testbench.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Oct 5, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module box_m_testbench
import pkg::*;
();

logic	clk ;
logic	rst_n ;
logic	tran_valid ;
logic	tran_ready ;
logic	ready_fall ;

burst_slot 	out_slot ;
axi_if		axi();
//axi_if    		   axi_slave_add() ;

logic [PCOMPLETE_DATA-1:0][7:0] ful_data ;


box_master dut (
	.rst_n     (rst_n          ),
	.clk       (clk            ),
	.tran_valid(tran_valid     ),
	.in_slot   (out_slot       ),
	.ready_fall(ready_fall     ),
	.tran_ready(tran_ready     ),
	.m_add     (axi.master_add ),
	.m_data    (axi.master_data)
);

// Clock generation
initial begin
	clk = 0 ;
	forever #5 clk = ~clk;  // 100MHz clock
end

// Reset generation
initial begin
	rst_n = 0 ;
	#10		  ;
	rst_n = 1 ;
end

// Initial block for test scenarios
initial begin
	tran_valid <= 0 ;
	ready_fall <= 0 ;
	
	axi.awready <= 0 ;
	axi.wready <= 0 ;
	for(int i = 0; i<PCOMPLETE_DATA; i++)
		ful_data[i][7:0] <= 8'b0 ;

	wait (rst_n == 1)  ;
	#2 ;
	
	











	// End simulation
	#1000;
$finish;
end
endmodule



