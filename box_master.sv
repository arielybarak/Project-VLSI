/*------------------------------------------------------------------------------
 * File          : box_master.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Oct 5, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module box_master
import pkg::*;
(
	input              clk,
	input              rst_n,
	
	input              tran_valid, //connect to special memory
	input spec_slot   in_slot,
	input              ready_fall,
	
	output logic       tran_ready, //connect to special memory
	axi_if.master_add  m_add,
	axi_if.master_data m_data
);
spec_slot slot ;
logic [PLENGTH_WIDTH-1:0] sent_transfer ;

assign slot = in_slot ;

always_comb begin
	
//	if(tran_valid & tran_ready)
//		tran_ready = 0 ;
end

always_ff @(posedge clk or negedge rst_n) begin
	
	if(~rst_n) begin
		tran_ready <= 1 ;
		m_data.wvalid <= 0 ;
		m_add.awvalid <= 0 ;
		m_data.wlast <= 0 ;
		sent_transfer <= 0 ;
	end
	else begin
		
		if(tran_valid & tran_ready)
			tran_ready <= 0 ;
		
		if(~tran_ready) begin
			if(ready_fall)
				m_add.awvalid <= 1 ;
			if(m_add.awready)
				m_add.awvalid <= 0 ;
			m_add.awburst <= slot.awburst ;
			m_add.awid <= slot.awid ;
			m_add.awaddr <= slot.awaddr ;
			m_add.awlen <= slot.awlen ;
			m_add.awsize <= slot.awsize ;
			m_add.awuser <= slot.awuser ;
			
			m_data.wdata[0 +: PDATA_WIDTH-1]  <=  slot.data[ (sent_transfer*PDATA_WIDTH) +: PDATA_WIDTH-1 ] ;
			m_data.wstrb[0 +: PDATA_WIDTH-1]  <=  slot.strb[ (sent_transfer*PDATA_WIDTH) +: PDATA_WIDTH-1 ] ;
			
			if(~m_data.wvalid & (sent_transfer < slot.awlen+1)) begin
				m_data.wvalid <= 1 ;
				m_data.wid <= slot.awid ;
				if(sent_transfer == slot.awlen)
					m_data.wlast <= 1 ;
			end
			if(m_data.wready) begin
				m_data.wvalid = 0 ;
				sent_transfer <= sent_transfer + 1 ;
			end
			if(m_data.wlast) begin
				sent_transfer <= 0 ;
				tran_ready <= 1 ;
				m_data.wlast = 0 ;
			end
		end
	end
end


endmodule

