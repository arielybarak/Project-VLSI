/*------------------------------------------------------------------------------
 * File          : special_memory.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Aug 23, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module special_memory
import pkg::*;
(
	input               rst_n,
	input               clk,
	input               proc_full,     //connect to process memory
	input				proc_empty,
	input               spec_release,  //connect to process memory
	
	output 	logic       release_ready, //connect to process memory    
	output              tran_ready,   //connect to router
	output logic  [1:0] unluck,
	
	axi_if.slave_add    s_add,
	axi_if.slave_data   s_data,
	axi_if.master_add   m_add,
	axi_if.master_data  m_data
);
spec_slot [SPEC_SLOT_AMOUNT-1:0]  spec_mem 		  ;
reg  	  [SPEC_SLOT_AMOUNT-1:0]  spec_mem_unluck ;
reg	  	  [INDEX_WIDTH-1:0] 	  spec_count 	  ;
reg  	  [INDEX_WIDTH-1:0]		  cur_index    	  ;
reg 	  [PID_WIDTH-1:0] 		  cur_id 		  ;
logic 	  [PLENGTH_WIDTH:0]		  transfer 		  ;

spec_slot complete_tran ;
reg 	   mem_full 	;
reg  	   found_unluck ;
logic	   new_burst 	;
logic 	   double 		;
logic      tran_valid 	;
wire	   ready_fall 	;
logic	   rise_wlast 	;
logic 	   wready_rise 	;
logic 	   double_rise 	;	

reg [SPEC_SLOT_AMOUNT-1:0] priority_encoder_in 			;
wire [SPEC_SLOT_AMOUNT-1:0] priority_encoder_out 		;
reg [SPEC_SLOT_AMOUNT-1:0] reverse_priority_encoder_out ;
wire zeros ;


DW_pricod #(SPEC_SLOT_AMOUNT) priority_encoder (
	.a   (priority_encoder_in ),
	.cod (priority_encoder_out),
	.zero(zeros               )
);
box_master send_burst (
	.clk       (clk          ),
	.rst_n     (rst_n        ),
	.tran_valid(tran_valid   ),
	.in_slot   (complete_tran),
	.ready_fall(ready_fall   ),
	.tran_ready(tran_ready   ),
	.m_add     (m_add        ),
	.m_data    (m_data       )
);
rise wlast(.rst_n(rst_n), .clk (clk), .trig (s_data.wlast),  .out  (rise_wlast)) ;
rise t_ready(.rst_n(rst_n), .clk (clk), .trig (~tran_ready),   .out  (ready_fall)) ;
rise wready (.rst_n(rst_n), .clk (clk), .trig (s_data.wready), .out (wready_rise)) ;
rise doul   (.rst_n(rst_n), .clk (clk), .trig (double), .out (double_rise)) 	   ;


assign mem_full = (SPEC_SLOT_AMOUNT == spec_count) ;
assign release_ready = tran_ready & spec_release & (spec_count > 0)   ;
assign s_data.wready = new_burst & s_data.wvalid /*& (~ready_fall)*/  			  ;
assign found_unluck = |(spec_mem_unluck & reverse_priority_encoder_out) 		  ;
assign tran_valid = tran_ready & (spec_release | found_unluck) & (spec_count > 0) ;


always_comb begin
	for(int i=0; i<SPEC_SLOT_AMOUNT; i++) begin
		
		if(tran_ready) begin
			if(reverse_priority_encoder_out[i] & spec_mem_unluck[i])															/////transaction train operator/////
				cur_index = i ;
			else if(spec_release)
				cur_index = 0 ;
			
			if(spec_release & (spec_mem[i].index === 0)) begin										/* & (spec_count>0)*/
				complete_tran = spec_mem[i] ;
				cur_id = spec_mem[i].awid ;
			end
			if(found_unluck & spec_mem[i].index == cur_index)
				complete_tran = spec_mem[i] ;
		end
		
		spec_mem_unluck[spec_mem[i].index] = spec_mem[i].unluck ;
		reverse_priority_encoder_out[i] = priority_encoder_out[SPEC_SLOT_AMOUNT-1-i] ;
		priority_encoder_in[SPEC_SLOT_AMOUNT-1-spec_mem[i].index] = ~|(spec_mem[i].awid^cur_id) & (spec_mem[i].index < spec_count) & tran_ready ;
		
		if(s_add.awvalid & (|(s_add.awuser^DIVERT))) begin 																		/////luck check/////
			unluck[1] = 1'b1 ;
			unluck[0] = (spec_mem[i].awid === s_add.awid) ;
		end
		else if(s_data.wlast)
			unluck[1] = 1'b0 ;
	end
	
	if(new_burst & ready_fall)
		double = 1 ;
	else if(~new_burst)													
		double = 0 ;
	
end


genvar i;
generate
	
	for (i = 0; i < SPEC_SLOT_AMOUNT; i++) begin	: For_Spec_Mem
		always_ff @(posedge clk or negedge rst_n) begin
			
			if(!rst_n) begin
				spec_mem[i].index <= i  ;
				spec_mem[i].awburst <= 0;
				spec_mem[i].awid <= 0   ;
				spec_mem[i].awaddr <= 0 ;
				spec_mem[i].awlen <= 0  ;
				spec_mem[i].awsize <= 0 ;
				spec_mem[i].awuser <= 0 ;
				spec_mem[i].unluck <= 0 ;
				
				for(int j = 0; j<PCOMPLETE_DATA; j++) begin
					spec_mem[i].data[j] <= 8'h0 ;
					spec_mem[i].strb[j] <= 0 	;
				end
			end
			else begin
				
				if(new_burst) begin																									/////new incoming transaction////
					if((~double & (spec_mem[i].index === spec_count)) || (double & (spec_mem[i].index === spec_count-1))) begin
						if(s_add.awready) begin
							spec_mem[i].awburst <= s_add.awburst ;
							spec_mem[i].awid <= s_add.awid 		 ;
							spec_mem[i].awaddr <= s_add.awaddr 	 ;
							spec_mem[i].awlen <= s_add.awlen 	 ;
							spec_mem[i].awsize <= s_add.awsize 	 ;
							spec_mem[i].awuser <= s_add.awuser 	 ;
							spec_mem[i].unluck <= unluck 		 ;
						end
						if(wready_rise) begin
							spec_mem[i].data[transfer*PDATA_WIDTH +: PDATA_WIDTH-1] <= s_data.wdata ;
							spec_mem[i].strb[transfer*PDATA_WIDTH +: PDATA_WIDTH-1] <= s_data.wstrb ;
						end
					end
				end
				
				if(ready_fall) begin																								/////delete operator/////
					if((spec_mem[i].index === cur_index) & (spec_count > 0))
						spec_mem[i].index <= new_burst ? spec_count : spec_count-1 ;
					
					if((spec_mem[i].index > cur_index) & (spec_mem[i].index < spec_count) || (double & (spec_mem[i].index === spec_count)))	 		
						spec_mem[i].index <= spec_mem[i].index-1 ;
				end
			end
		end
	end
endgenerate



always_ff @(posedge clk or negedge rst_n) begin
	
	if (!rst_n) begin
		spec_count <= 0	   ;
		s_add.awready <= 0 ;
		new_burst <= 0     ;
		transfer <= 0 	   ;
	end
	else begin
		
		s_add.awready <=  ~mem_full & ~proc_full & ~proc_empty & s_add.awvalid & (s_add.awuser === DIVERT || unluck[0]) ;
		if(s_add.awvalid & ~mem_full & ~proc_full & ~proc_empty & (s_add.awuser === DIVERT || unluck[0]))
			new_burst <= 1 ;
		else if((transfer === 0) & ~wready_rise /*s_data.wlast & s_data.wready*/)
			new_burst <= 0 ;
		
		if(s_data.wlast)
			transfer <= 0 ;
		else if(wready_rise)
			transfer <= transfer + 1 ;
		
		if((~double) & rise_wlast & s_data.wready)
			spec_count <= spec_count + 1 ;
		
		if((~double_rise) & ready_fall)
			spec_count <= spec_count - 1 ;
	end
end

endmodule


	
		





