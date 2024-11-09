/*------------------------------------------------------------------------------
 * File          : router_testbench.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Aug 23, 2024
 * Description   :
 *------------------------------------------------------------------------------*/
`timescale 1ns/1ps

import pkg::*;

module router_testbench ();
logic       clk ;
logic       rst_n ;

logic       proc_full ;
logic       spec2router ;    //connect to spec
logic [1:0] unluck ;         //connect to spec
logic       wlast;          //connect to m_data.wlast
logic       s_awvalid ;      //connect to s_add.awvalid
logic		m_wvalid ;
logic       block_fin ; //connect to proc memory
logic      [PAWUSER_WIDTH-1:0] m_awuser ;      //connect to m_add.awuser (entering tran type)
logic      [PAWUSER_WIDTH-1:0] s_awuser ;

logic [2:0] routers_ps ;


// Instantiate the brain module
router uut (
	.clk        (clk        ),
	.rst_n      (rst_n      ),
	.proc_full  (proc_full  ),
	.spec2router(spec2router),
	.unluck     (unluck     ),
	.wlast      (wlast      ),
	.m_wvalid   (m_wvalid   ),
	.s_awvalid  (s_awvalid  ),
	.block_fin  (block_fin  ),
	.m_awuser   (m_awuser   ),
	.s_awuser   (s_awuser   ),
	.routers_ps (routers_ps )
);

parameter ROUTERS_REG_FLOW		 = 3'b000 ;
parameter ROUTERS_BLOCEKD		 = 3'b001 ;				
parameter ROUTERS_MERGE 		 = 3'b010 ;													
parameter ROUTERS_IDLE	 		 = 3'b111 ;



// Clock generation
initial begin
	clk = 0;
	forever #5 clk = ~clk; // 100MHz clock
end

// Reset generation
initial begin
	rst_n = 0;
	#20;
	rst_n = 1;
end

// Initial block for test scenarios
initial begin
	// Initialize inputs
	proc_full = 0 ;
	spec2router = 0 ;
	unluck = 0 ;
	wlast = 0 ;
	s_awvalid = 0 ;
	block_fin = 0 ;
	m_awuser = 0 ;
	s_awuser = 0 ;
	m_wvalid = 0 ;
	
	// Wait for reset
	wait (rst_n == 1'b1);
	#2 ;
	
	
	
	
	//1: regular burst + memory full
	#10 ;
	proc_full = 1 ;
	#10 ;
	s_awvalid = 1 ;
	unluck = 2'b10 ;
	s_awuser = REGULAR ;
	#20 ;
	proc_full = 0 ;
	#10 ;
	s_awvalid = 0 ;
	#30 ;
	wlast = 1 ;
	spec2router = 1 ;
	#10 ;
	wlast = 0 ;
	
	//2: special release and blocked wait to enter
//	#10 ;
//	spec2router = 1 ;
	#30 ;
	s_awvalid = 1 ;
	s_awuser = BLOCK ;
	#20 ;
	spec2router = 0 ;
	#10 ;
	m_awuser = BLOCK ;
	#10 ;
	s_awvalid = 0 ;
	#20 ;
	
	//3: we are at BLOCKED state. regular burst wait to enter
	m_wvalid = 1 ;
	wlast = 1 ;
	#10 ;
	m_wvalid = 0 ;
	wlast = 0 ;
	
	#10 ;
	s_awvalid = 1 ;
	unluck = 2'b10 ;
	m_awuser = REGULAR ;
	#70 ;
	block_fin = 1 ;
	#10 ;
	block_fin = 0 ;
	#10 ;
	s_awvalid = 0 ;
	#20 ;
	wlast = 1 ;
	#10 ;
	wlast = 0 ;
	
	//4: Block burst and special right after
	#100 ;
	s_awvalid = 1 ;
	s_awuser = BLOCK ;
	unluck = 2'b10 ;
	#10 ;
	spec2router = 1 ;
	s_awvalid = 0 ;
	m_awuser = BLOCK ;
	#30 ;
	wlast = 1 ;
	#10 ;
	wlast = 0 ;
	#40 ;
	block_fin = 1 ;
	#10 ;
	block_fin = 0 ;
	#30 ;
	spec2router = 0 ;
	#10 ;
	
	
	
	
	




	// End simulation
	#1000;
	$finish;
end
endmodule

