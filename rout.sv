/*------------------------------------------------------------------------------
 * File          : rout.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Nov 1, 2012
 * Description   :
 *------------------------------------------------------------------------------*/

import pkg::*;
module rout

(
	input                            clk,
	input                            rst_n,
	input                            proc_full,
	input                            spec2router, //connect to spec
	input        [1:0]               unluck,      //connect to spec
	input                            wlast,       //connect to m_data.wlast
	input                            s_awvalid,   //connect to s_add.awvalid
	input                            block_fin,   //connect to proc memory
	input        [PAWUSER_WIDTH-1:0] m_awuser,    //connect to m_add.awuser (entering tran type)
	input        [PAWUSER_WIDTH-1:0] s_awuser,
	
	output                           block_ack,
	output logic [/*FSM_WIDTH-1*/2:0]routers_ps   
);
assign block_ack = block_fin ;
parameter FSM_WIDTH = 3 ;
//states//
parameter ROUT_REG_FLOW		 = 3'b000 ;
parameter ROUT_BLOCEKD		 = 3'b001 ;
parameter ROUT_MERGE 		 = 3'b010 ;
parameter ROUT_IDLE	 		 = 3'b111 ;

logic   [FSM_WIDTH-1:0]  routers_ns ;
//States signals//
wire  sig_routers_reg_flow   = ~|(routers_ps^ROUT_REG_FLOW) ;
wire  sig_routers_merge      = ~|(routers_ps^ROUT_MERGE) 	;
wire  sig_routers_blocked    = ~|(routers_ps^ROUT_BLOCEKD) 	;
wire  sig_routers_idle 		 = ~|(routers_ps^ROUT_IDLE) 	;

//States connections//
wire to_block = ~|(m_awuser^BLOCK) & wlast ;
wire to_regular	= ((unluck === 2'b10) ? 1'b1 : 1'b0) & (|(s_awuser^DIVERT)) & s_awvalid & ~proc_full ;
wire to_merge 	= spec2router & ~proc_full ;

always_ff @(posedge clk or negedge rst_n) begin
	if(~rst_n) begin
		routers_ps <= ROUT_IDLE ;
//		routers_ns <= ROUT_IDLE ;
		end 
	else begin //delete begin later
		routers_ps <= routers_ns ;
	
	
//	case (routers_ps)
//		
//		ROUT_IDLE:		routers_ns <= to_regular 				? ROUT_REG_FLOW :
//									 to_merge  				? ROUT_MERGE	:
//															  ROUT_IDLE	 	;
//		
//		ROUT_REG_FLOW:	routers_ns <= to_block 				? ROUT_BLOCEKD  :
//									 ~wlast  				? ROUT_REG_FLOW :
//									 (wlast & to_merge) 	? ROUT_MERGE  	:
//															  ROUT_IDLE     ;
//		
//		
//		ROUT_MERGE:		routers_ns <= to_merge  		 		? ROUT_MERGE 	:
//									 to_merge & to_block    ? ROUT_BLOCEKD  :			//TODO not sure that works
//									 to_regular 				? ROUT_REG_FLOW :
//															  ROUT_IDLE 	;
//		
//		ROUT_BLOCEKD :  routers_ns <= block_fin & to_merge   ? ROUT_MERGE    :
//									 block_fin & to_regular  ? ROUT_REG_FLOW :
//									 block_fin			    ? ROUT_IDLE 	:
//															  ROUT_BLOCEKD  ;
//				
//		default: 		routers_ns <= ROUT_IDLE ;
//		
//	endcase
	
	
end	
end


always_comb begin
	case (routers_ps)
		
		ROUT_IDLE:		routers_ns = to_regular 			? ROUT_REG_FLOW :
									 to_merge  				? ROUT_MERGE	:
															  ROUT_IDLE	 	;
		
		ROUT_REG_FLOW:	routers_ns = to_block 				? ROUT_BLOCEKD  :
									 ~wlast  				? ROUT_REG_FLOW :
									 (wlast & to_merge) 	? ROUT_MERGE  	:
															  ROUT_IDLE     ;
		
		
		ROUT_MERGE:		routers_ns = to_merge  		 		? ROUT_MERGE 	:
									 to_merge & to_block    ? ROUT_BLOCEKD  :			//TODO not sure that works
									 to_regular 			? ROUT_REG_FLOW :
													   		  ROUT_IDLE 	;
		
		ROUT_BLOCEKD :  routers_ns = block_fin & to_merge   ? ROUT_MERGE    :
									 block_fin & to_regular ? ROUT_REG_FLOW :
									 block_fin			    ? ROUT_IDLE 	:
													  		  ROUT_BLOCEKD  ;
				
		default: 		routers_ns = ROUT_IDLE ;
		
	endcase
end


endmodule






