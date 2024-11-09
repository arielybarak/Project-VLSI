/*------------------------------------------------------------------------------
 * File          : process_mem_test_bench.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Aug 7, 2024
 * Description   : first test bench for process memory - 2 incoming transactions, 1 deletion.
 *------------------------------------------------------------------------------*/

import pkg::*;

module process_mem_test_bench

	#(
		parameter SLOT_AMOUNT = 32 //so we have 32 slots
	) 
();

// Signals for the DUT 

logic		clk;                   
logic		rst_n;                 
								   
logic [3:0]	awid; 					
logic 		awvalid;               
logic [PAWUSER_WIDTH - 1:0] awuser;
								   
logic	 	bready; 				
logic	 	bvalid; 				
logic [3:0]	bid;                   
								   
logic 		block_ack;
logic		release_ready;								   
								   
logic 		full;                  
logic 		block_fin;             
logic 		spec_release;                   

// Instantiate the DUT
process_mem #(
	.SLOT_AMOUNT(SLOT_AMOUNT)
) dut (
	.awid(awid),
	.awvalid(awvalid),
	.awuser(awuser),
	.bready(bready),
	.bvalid(bvalid),
	.bid(bid),
	.block_ack(block_ack),
	.block_fin(block_fin),
	.spec_release(spec_release),
	.release_ready(release_ready),
	.clk(clk),
	.rst_n(rst_n),
	.full(full)
);


task new_tran ([PID_WIDTH-1:0] id, [PAWUSER_WIDTH-1:0] type_);
	#10
	awvalid = 1'b1 ;
	awid = id ;
	awuser = type_ ;
	#20
	awvalid = 1'b0 ;
			
endtask

task delete_tran ([PID_WIDTH-1:0] id);
	#10
	bvalid = 1'b1;
	bready = 1'b1;
	bid = id;
	#20;
	bvalid = 1'b0;
	bready = 1'b0;
	#10;
	if(spec_release) begin  release_ready = 1'b1; end
	else if (block_fin) begin block_ack = 1'b1; end
	#10;
	release_ready = 1'b0;
	block_ack = 1'b0;
			
endtask


// Clock generation
initial begin
	clk = 1'b0;
	forever #5 clk = ~clk; // 100MHz clock
end

// Reset generation
initial begin
	rst_n = 1'b0;
	#20;
	rst_n = 1'b1;
end

//	localparam REGULAR = 2'b00 ;
//	localparam BLOCK   = 2'b01 ;
//	localparam DIVERT  = 2'b10 ;
//	localparam UNLUCKY = 2'b11 ;


// Input stimulus and output check
initial begin
	// Initialize inputs
	awvalid = 1'b0;
	awuser = 2'b00;
	awid = 4'b0001;
	bready = 1'b0;
	bvalid = 1'b0;
	bid = 4'b0000;
	block_ack = 1'b0;
	release_ready = 1'b0;
	
	// Wait for reset
	wait (rst_n == 1'b1);
	#5;
	// Test case 1: Add a new transaction - Regular ID = 1
	new_tran(1,REGULAR);

	// Test case 2: Add another new transaction - Divert ID = 2
	new_tran(2,DIVERT);

	// Test case 3: Delete the first transaction - ID = 1
	delete_tran(1);
	
	// Test case 4: Add several new transactions - Regular ID = 3
	new_tran(3,REGULAR);
	// BLOCK ID = 4
	new_tran(4,BLOCK);
	// Regular ID = 5
	new_tran(5,REGULAR);

	// Test case 5: Delete in the middle transaction - ID = 3
	delete_tran(3);
	
	// Test case 6: Delete block transaction - ID = 4
	delete_tran(4);
	
	// End simulation
	#100;
	$finish;
end
endmodule
