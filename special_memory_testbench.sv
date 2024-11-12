/*------------------------------------------------------------------------------
 * File          : special_memory_testbench.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Sep 15; 2024
 * Description   :
 *------------------------------------------------------------------------------*/

import pkg::*;
module special_memory_testbench #() ();

logic     rst_n		     ;
logic	  clk   		 ;

logic 	  proc_mem_full ;
logic     spec_release   ;  //connect to proc memory
logic     release_ready  ;  //connect to proc memory
spec_slot complete_tran  ;
logic     tran_valid     ;
logic     spec2router  ;  //connect to router
logic 	  unluck ;

axi_if				axi () ;
axi_if				axiOut () ;
logic [PCOMPLETE_DATA-1:0][7:0] ful_data ;


special_memory dut (
	.rst_n        (rst_n             ),
	.clk          (clk               ),
	.proc_full    (proc_mem_full     ),
	.spec_release (spec_release      ),
	.release_ready(release_ready     ),
	.tran_ready   (spec2router       ),
	.unluck       (unluck            ),
	.s_add        (axi.slave_add     ),
	.s_data       (axi.slave_data    ),
	.m_add        (axiOut.master_add ),
	.m_data       (axiOut.master_data)
);




task new_burst ([PID_WIDTH-1:0] id, [PADDR_WIDTH-1:0] address, [PLENGTH_WIDTH-1:0] length, [4:0] data, [PAWUSER_WIDTH-1:0] type_);
	#20 ;
	axi.awvalid <= 1 ;
	axi.awid <= id ;
	axi.awaddr <= address ;
	axi.awlen <= length ;
	axi.awsize <= 1 ;
	axi.awuser <= type_ ;
	
	for(int i = 0; i< (2**PLENGTH_WIDTH) + 1; i++) begin
		if(i<length + 1) begin
			ful_data[PDATA_WIDTH*i + i] = data+i+1 ;
			axi.wstrb[PDATA_WIDTH*i + i] = 1 ;
		end
	end
	#10 ;
	if(axi.awready)
		axi.awvalid = 0 ;
	
	for(int i = 0; i < (2**PLENGTH_WIDTH) + 1; i++) begin
		if(i < axi.awlen+1) begin
			
			if(i === axi.awlen)
				axi.wlast = 1 ;
			
			axi.wvalid <= 1 ;
			axi.wid <= 2 ;
			axi.wdata <= ful_data[PDATA_WIDTH*i +: PDATA_WIDTH-1] ;
			#20 ;
			if(axi.wready | axi.wlast) begin
				axi.wvalid <= 0 ;
				axi.wlast <= 0 ;
				#10 ;
			end
			if(axi.wready | axi.wlast) begin
				axi.wvalid <= 0 ;
				axi.wlast <= 0 ;
				#10 ;
			end
		end
	end
	axi.awvalid = 0 ;
endtask


task special_release ();
	#10 ;
	spec_release = 1'b1 ;
	#10 ;
	spec_release = release_ready ;
	#20 ;
	axiOut.awready <= 1 ;
	#10 ;
	axiOut.awready <= 0 ;
	
	for(int i = 0; i < (2**PLENGTH_WIDTH) + 1; i++) begin
		if(i < axiOut.awlen+1) begin
			
			if(axiOut.wvalid)
				axiOut.wready <= 1'b1 ;
			#10 ;
			axiOut.wready <= 1'b0 ;
			#10 ;
			
		end
	end
endtask


task if_luck_release ();
	#10 ;
	axiOut.awready <= 1'b1 ;
	#10 ;
	axiOut.awready <= 1'b0 ;
	for(int i = 0; i < (2**PLENGTH_WIDTH) + 1; i++) begin
		if(i < axiOut.awlen+1) begin
			
			if(axiOut.wvalid)
				axiOut.wready <= 1'b1 ;
			#10 ;
			axiOut.wready <= 1'b0 ;
			#20 ;
		end
	end
endtask



// Clock generation
initial begin
	clk = 1 ;
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
	// Initialize inputs
	axi.awvalid = 0 ;
	axi.wvalid = 0 ;
	axi.wlast = 0 ;
	proc_mem_full = 0 ;
	spec_release = 0 ;
	axi.wlast = 0 ;
	axiOut.awready = 0 ;
	axiOut.wready = 0 ;
	for(int i = 0; i<PCOMPLETE_DATA; i++) begin
		ful_data[i][7:0] <= 8'b0 ;
		axi.wstrb[i] <= 0 ;
	end
	
	wait (rst_n == 1'b1)  ;
	#2 ;
	
	//	new_burst( id, add, len, data, type )
	
	//										1: insert 5 bursts including unlucky
	new_burst(1,1,1,1,DIVERT) ;
	new_burst(2,2,2,2,DIVERT) ;
	new_burst(3,2,2,2,REGULAR) ;	//		1.1: normal (unlucky) burst check
	new_burst(1,3,3,3,DIVERT) ;
	new_burst(2,4,4,4,REGULAR) ;	//		1.2: unlucky burst
	new_burst(1,5,5,5,BLOCK) ;
	new_burst(3,1,1,1,DIVERT) ;		//		1.3: memory full check
	#100 ;
	//										2: all bursts release
	special_release() ;
	special_release() ;
	if_luck_release() ;				//		2.1 unlucky out
	special_release() ;
	if_luck_release() ;
	#100 ;
	//										3: unlucky train in and out
	new_burst(1,1,3,1,DIVERT) ;
	new_burst(1,1,4,2,REGULAR) ;
	new_burst(1,1,3,1,REGULAR) ;
	new_burst(1,1,4,2,REGULAR) ;
	#20 ;
	special_release() ;
	if_luck_release() ;
	if_luck_release() ;
	if_luck_release() ;
	#100 ;
	//										4: special release while insert
	new_burst(1,1,2,1,DIVERT) ;
	new_burst(2,2,2,3,DIVERT) ;
	new_burst(1,3,2,1,DIVERT) ;
	new_burst(2,4,2,5,REGULAR) ;
	#20 ;
	fork
		new_burst(2,5,3,5,REGULAR) ;
		#30 special_release() ;
	join
	#100 ;
	//										5: unlucky train release while inserting
	fork
		new_burst(2,7,7,0,REGULAR) ;
		#20 special_release() ;
		#60 if_luck_release() ;
		#120 if_luck_release() ;
		#170 if_luck_release() ;
		#220 if_luck_release() ;
	join
	
	
	//	new_burst( id, add, len, data, type )
	
	
	
	
	// End simulation
	#300;
	$finish;
end
endmodule



