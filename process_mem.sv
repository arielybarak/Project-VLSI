/*------------------------------------------------------------------------------
 * File          : process_mem.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Jul 20, 2024
 * Description   : linked list type memory, document every transaction (regular and special).
 * Main functions: Add new transaction to the database, Delete chosen transaction from the database, remain all the slots aligned (without spaces).  
 *------------------------------------------------------------------------------*/

import pkg::*;

module process_mem
	#(
		parameter SLOT_AMOUNT = 8  //so we have 32 slots
	) (
	input	logic		clk,
	input	logic		rst_n,
	
	input 	logic [PID_WIDTH - 1:0]	awid, 							
	input 	logic 		awvalid,
	input 	logic [PAWUSER_WIDTH - 1:0] awuser,

	input 	logic	 	bready, 							
	input 	logic	 	bvalid, 							
	input 	logic [3:0]	bid,
	
	input	logic 		block_ack,
	input	logic		release_ready,
	
	output 	logic 		full,
	output 	logic 		block_fin, 
	output 	logic 		spec_release		
	
	);

slot 	[SLOT_AMOUNT-1:0] memory ;
logic 	[SLOT_AMOUNT-1:0] proc_count ;
 
///output assign///
assign full = memory[SLOT_AMOUNT-1].valid ;

/// Inner logic ///
//logic new_head   ; 
logic new_tran   ;
logic new_delete ;
logic count_update ;

/////////// priority encoder var///////////////////////////
logic [SLOT_AMOUNT-1:0] priority_encoder_in ;
logic [SLOT_AMOUNT-1:0] priority_encoder_out ;
logic zeros;
logic [SLOT_AMOUNT-1:0] reverse_priority_encoder_out ;

/////instances//// 
DW_pricod #(SLOT_AMOUNT) priority_encoder (
	.a   (priority_encoder_in ),
	.cod (priority_encoder_out),
	.zero(zeros               )
);

//rise New_Head(.rst_n(rst_n), .clk (clk), .trig (reverse_priority_encoder_out[0]),  .out  (new_head)) ;
rise New_Tran(.rst_n(rst_n), .clk (clk), .trig (awvalid & ~full),  .out  (new_tran)) ;
rise New_Delete(.rst_n(rst_n), .clk (clk), .trig (bvalid & bready),  .out  (new_delete)) ;
rise count(.rst_n(rst_n), .clk (clk), .trig (~awvalid & ~full),  .out  (count_update)) ;
		
always_comb begin
			
		if (reverse_priority_encoder_out[0]) begin 
			spec_release = |(memory[0].tran_type^DIVERT) ;
		end 
		else if (release_ready) begin 
			spec_release = 1'b0 ;
		end
		if (block_ack & block_fin) begin
			block_fin = 1'b0 ;
		end
			
		for (int i = 0; i < SLOT_AMOUNT; i++) begin	
	/////////// Reset all memory slots and counter///////////////////////////
			if (!rst_n) begin
				memory[i].valid 	= 1'b0 ;
				memory[i].id 		= 4'b0000 ;
				memory[i].tran_type = 2'b00 ;
				priority_encoder_in = 0 ;
				spec_release 		= 1'b0 ;
				block_fin 			= 1'b0 ; 
			end else begin
				
	//////////////////new incoming transaction///////////////////////////////
				if(new_tran & (i === proc_count)) begin
					memory[i].valid =1'b1 ;
					memory[i].id = awid ;
					memory[i].tran_type = awuser ;
				end
				
	/////////////////transaction deletion/////////////////////////////////////////
				else if(new_delete) begin
					priority_encoder_in[SLOT_AMOUNT-1-i] = memory[i].valid & ~|(memory[i].id^bid) ;
					reverse_priority_encoder_out[i] = priority_encoder_out[SLOT_AMOUNT-1-i] ;					
					if (reverse_priority_encoder_out[i]) begin
						block_fin = ~|(memory[i].tran_type^BLOCK) ;  					
						memory[i].valid = 1'b0 ;						
					end 
				end
				
	////////////////Enable forward/////////////////////////////////////////
				else if ((i>0) & memory[i].valid & (~memory[i-1].valid) ) begin 
					memory[i-1].valid =1'b1 ;
					memory[i-1].id = memory[i].id ;
					memory[i-1].tran_type = memory[i].tran_type ;
					memory[i].valid = 1'b0 ;
				end
				
				else if (~new_delete) begin
					priority_encoder_in[SLOT_AMOUNT-1-i] = 1'b0 ;
				end
				
			end
	end	
end


////////////////Slot Counter Update/////////////////////////////////////////
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) 
		proc_count <= 0 ;																				
	else begin
		if(count_update) begin
			proc_count <= proc_count + 1 ;
		end
		if(new_delete) begin
			proc_count <= proc_count - 1 ;
		end
	end
end 

endmodule










//for (i = 0; i < SLOT_AMOUNT-1 ; i++) begin	: Pro_Mem_Main
//for(k = i; k < SLOT_AMOUNT-1 ; k++)	begin :Pro_Mem_En_Fr_In_Lo

	//always_ff @(posedge clk or negedge rst_n) begin

		////////////////Enable forward/////////////////////////////////////////		
/*for (j=0; j < SLOT_AMOUNT-1; j=j+1) begin : Pro_Mem_En_Fr	
		for(k=j; k<SLOT_AMOUNT-1; k=k+1)	begin :Pro_Mem_En_Fr_In_Lo
			always_ff @(posedge clk or negedge rst_n) begin	
				if (~memory[j].valid & memory[j+1].valid) begin
					memory[k].valid <=1 ;
					memory[k].id <= memory[k+1].id ;
					memory[k].tran_type <= memory[k+1].tran_type ;
					memory[k+1].valid <= 0 ;
				end	
		end
	end 
end
endgenerate 

*/


