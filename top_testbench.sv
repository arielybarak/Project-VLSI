/*------------------------------------------------------------------------------
 * File          : top_testbench.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Oct 18, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

import pkg::*;
module top_testbench #() ();

logic     rst_n		     ;
logic	  clk   		 ;



//burst_slot complete_tran  ;
axi_if				t_axi () ;
axi_if				t_axiOut () ;
logic [PCOMPLETE_DATA-1:0][7:0] ful_data ;
logic [PCOMPLETE_DATA-1:0][7:0] strb ;


WriteOrderTop dut (
	.rst_n   (rst_n             ),
	.clk     (clk               ),
	.t_s_add (t_axi.slave_add     ),
	.t_s_data(t_axi.slave_data    ),
	.t_s_resp(t_axi.slave_resp    ),
	.t_m_add (t_axiOut.master_add ),
	.t_m_data(t_axiOut.master_data),
	.t_m_resp(t_axiOut.master_resp)
);




task new_burst ([PID_WIDTH-1:0] id, [PADDR_WIDTH-1:0] address, [PLENGTH_WIDTH-1:0] length, [4:0] data, [PAWUSER_WIDTH-1:0] type_);
	#10 ;
	t_axi.awvalid <= 1 ;
	t_axi.awid <= id ;
	t_axi.awaddr <= address ;
	t_axi.awlen <= length ;
	t_axi.awsize <= 1 ;
	t_axi.awuser <= type_ ;
	
	for(int i = 0; i< (2**PLENGTH_WIDTH) + 1; i++) begin
		if(i<length + 1) begin
			ful_data[PDATA_WIDTH*i + i] = data+i+1 ;
			strb[PDATA_WIDTH*i + i] = 1 ;
		end
	end
	#10 ;
	
	
	for(int i = 0; i< 10 ; i++) begin
		if(t_axi.awready) begin
			t_axi.awvalid <= 0 ;
			break ;
		end
		else
			#10 ;
	end		
	
	for(int i = 0; i < (2**PLENGTH_WIDTH) + 1; i++) begin
		if(i < t_axi.awlen+1) begin
			t_axi.wvalid <= 1 ;
			t_axi.wid <= id ;
			t_axi.wdata <= ful_data[PDATA_WIDTH*i +: PDATA_WIDTH-1] ;
			t_axi.wstrb <= strb[PDATA_WIDTH*i +: PDATA_WIDTH-1] ;
			if(i === t_axi.awlen)
				t_axi.wlast <= 1 ;
			#10 ;
			
			for(int i = 0; i< 10 ; i++) begin
				if(t_axi.wready) begin
					t_axi.wvalid <= 0 ;
					break ;
				end
				else
					#10 ;
			end	
			t_axi.wlast = 0 ;
			#10 ;
		end
	end

endtask


task slave_recieve();
	#10 ;
	for(int i = 0; i< 10 ; i++) begin
		if(t_axiOut.awvalid) begin
			t_axiOut.awready <= 1 ;
			break ;
		end 
		#10 ;
	end
	#10 ;
	t_axiOut.awready <= 0 ;
	
	for(int i = 0; i < (2**PLENGTH_WIDTH) + 1; i++) begin
		if(i < t_axiOut.awlen+1) begin
			
			for(int i = 0; i< 10 ; i++) begin
				if(t_axiOut.wvalid) begin
					t_axiOut.wready <= 1 ;
					break ;
				end 
				#10 ;
			end
			
			#10 ;
			t_axiOut.wready <= 0 ;
			#10 ;
		end
	end
endtask

task end_burst([PID_WIDTH-1:0] id);
	#10 ;
	t_axiOut.bvalid = 1 ;
	t_axiOut.bid = id ;
	#10 ;
	if(t_axi.bvalid)
		t_axi.bready = 1 ;
	#20 ;
	
	if(t_axiOut.bready) begin
		t_axiOut.bvalid = 0 ;
		t_axiOut.bid = 0 ;
		t_axi.bready = 0 ;
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
	t_axi.awvalid = 0 ;
	t_axiOut.awready = 0 ;
	t_axi.wvalid = 0 ;
	t_axiOut.wready = 0 ;
	t_axi.wlast = 0 ;
	t_axiOut.bvalid = 0 ;
	t_axiOut.bid = 0 ;
	t_axiOut.bresp = 0 ;
	t_axi.bready = 0 ;

	for(int i = 0; i<PCOMPLETE_DATA; i++) begin
		ful_data[i][7:0] = 8'b0 ;
		strb[i] = 0 ;
	end
	
	wait (rst_n == 1'b1)  ;
	#9 ;
//		 new_burst( id, add, len, data, type )
	
	
	//1: one regular burst
	fork
		new_burst(4'b1,1,3,1,REGULAR) ;
		slave_recieve() ;
	join
	#20 ;
	end_burst(1) ;
	#50 ;
	
	//2: one special burst (should pass immediately)
	fork
		new_burst(1,1,3,1,DIVERT) ;
		slave_recieve() ;				
	join
	#10 ;
	end_burst(1) ;
	#50 ;

	//3: simple special flow
	fork
	new_burst(1,1,3,1,REGULAR) ;
	slave_recieve() ;
	join
	new_burst(1,1,3,1,DIVERT) ;
	#50 ;
	end_burst(1) ;
	#2 ;
	slave_recieve() ;
	#18 ;
	end_burst(1) ;
	#50 ;
	
	//4: simple block
	fork
	new_burst(3,1,3,1,BLOCK) ;
	slave_recieve() ;
	join
	fork
		new_burst(2,1,3,1,REGULAR) ;
		#40 end_burst(3) ;
		slave_recieve() ;
	join
	#20 ;
	end_burst(2) ;
	#70 ;
	
	
//	//	1: simple regular flow
//	new_burst(1,1,3,1,REGULAR) ;
//	new_burst(2,1,3,1,REGULAR) ;
//	new_burst(2,1,3,1,REGULAR) ;
//	new_burst(3,1,3,1,REGULAR) ;
//	
//	end_burst(1) ;
//	end_burst(3) ;
//	end_burst(2) ;
//	end_burst(2) ;
//	#70 ;
//	


//	
//	end_burst(1) ;
//	#20 ;
//	end_burst(1) ;
//	#100 ;
	

//	
//	//	4 & 5: simple unluck  &  blocked unluck
//	new_burst(1,1,1,1,REGULAR) ;
//	new_burst(1,1,2,2,DIVERT) ;
//	new_burst(1,1,3,3,REGULAR) ;
//	new_burst(1,1,4,4,REGULAR) ;
//	new_burst(2,1,3,1,REGULAR) ;
//	new_burst(1,1,5,5,BLOCK) ;
//	#50 ;
//	new_burst(1,1,3,1,REGULAR) ; // remain outside
//	end_burst(1) ;
//	end_burst(1) ;
//	new_burst(1,1,3,1,REGULAR) ; // remain outside
//	#50 ;
//	new_burst(1,1,3,1,REGULAR) ;
//	end_burst(1) ;
//	end_burst(1) ;
//	end_burst(1) ;
//	end_burst(1) ;
//	end_burst(2) ;
//	#70 ;
//	
//	//	6: process memory is full
//	
//	
//	
//	//	7: spec memory is full
//	new_burst(1,1,1,1,REGULAR) ;
//	new_burst(1,1,2,2,DIVERT) ;
//	new_burst(1,1,3,3,REGULAR) ;
//	new_burst(1,1,4,4,DIVERT) ;
//	new_burst(1,1,5,5,REGULAR) ;
//	new_burst(1,1,6,6,REGULAR) ;
//	#30 ; 								//memory is full now
//	fork
//		new_burst(1,1,2,2,REGULAR) ;
//		#20 end_burst(1) ;
//	join
//	#50 ;
//	end_burst(1) ;
//	end_burst(1) ;
//	end_burst(1) ;
//	end_burst(1) ;
//	end_burst(1) ;
	
	
	
	
	// End simulation
	#400;
	$finish;
end
endmodule




