/*------------------------------------------------------------------------------
 * File          : WriteOrderTop.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Jul 17, 2024
 * Description   :
 *------------------------------------------------------------------------------*/

module WriteOrderTop
import pkg::*;
(
	input              clk,
	input              rst_n,
	
	/*Master side of the module (connected as a Slave)*/
	axi_if.slave_add   t_s_add,
	axi_if.slave_data  t_s_data,
	axi_if.slave_resp  t_s_resp,
	
	/*Slave side of the module (connected as a Master)*/
	axi_if.master_add  t_m_add,
	axi_if.master_data t_m_data,
	axi_if.master_resp t_m_resp
	
);
axi_if axi () ;
axi_if axiOut () ;
logic [2:0] cur_state ;
wire [1:0] unluck ;
wire spec2router;

wire proc_full ;
wire proc_empty ;
wire spec_release ;
wire release_ready ;
wire block_fin ;

parameter ROUTERS_REG_FLOW = 3'b000 ;
parameter ROUTERS_MERGE = 3'b010 ;

/*Connecting master and slave's respond channel*/
assign t_s_resp.bvalid = t_m_resp.bvalid ;
assign t_m_resp.bready = t_s_resp.bready ;
assign t_s_resp.bid = t_m_resp.bid ;
assign t_s_resp.bresp = t_m_resp.bresp ;

/*Connecting handshake's signals for address channel and data channel*/
assign t_s_add.awready = axi.awready | t_m_add.awready ;
assign t_s_data.wready = axi.wready | t_m_data.wready ;
assign axiOut.awready = t_m_add.awready ;
assign axiOut.wready = t_m_data.wready ;

/*Connecting internal AXI bus to the Master side (Slave's modports)*/
assign axi.awvalid = t_s_add.awvalid ;
assign axi.awid = t_s_add.awid ;
assign axi.awaddr = t_s_add.awaddr ;
assign axi.awburst = t_s_add.awburst ;
assign axi.awlen = t_s_add.awlen ;
assign axi.awsize = t_s_add.awsize ;
assign axi.awuser = t_s_add.awuser ;
assign axi.wvalid = t_s_data.wvalid ;
assign axi.wid = t_s_data.wid ;
assign axi.wdata = t_s_data.wdata ;
assign axi.wstrb = t_s_data.wstrb ;
assign axi.wlast = t_s_data.wlast ;


process_mem monitor (
	.clk          (clk            ),
	.rst_n        (rst_n          ),
	.full         (proc_full      ),
	.empty        (proc_empty     ),
	.awvalid      (t_s_add.awvalid),
	.awid         (t_s_add.awid   ),
	.awuser       (t_s_add.awuser ),
	.bvalid       (t_s_resp.bvalid),
	.bready       (t_m_resp.bready),
	.bid          (t_s_resp.bid   ),
	.block_fin    (block_fin      ),
	.spec_release (spec_release   ),
	.release_ready(release_ready  )
);

special_memory spec_mem (
	.clk          (clk               ),
	.rst_n        (rst_n             ),
	.proc_full    (proc_full         ),
	.proc_empty   (proc_empty        ),
	.spec_release (spec_release      ),
	.release_ready(release_ready     ),
	.tran_ready   (spec2router       ),
	.unluck       (unluck            ),
	.s_add        (axi.slave_add     ),
	.s_data       (axi.slave_data    ),
	.m_add        (axiOut.master_add ),
	.m_data       (axiOut.master_data)
);

rout router (
	.clk        (clk            ),
	.rst_n      (rst_n          ),
	.proc_full  (proc_full      ),
	.proc_empty (proc_empty     ),
	.spec2router(~spec2router   ),
	.unluck     (unluck         ),
	.wlast      (t_m_data.wlast ),
	.s_awvalid  (t_s_add.awvalid),
	.m_awuser   (t_m_add.awuser ),
	.block_fin  (block_fin      ),
	.s_awuser   (t_s_add.awuser ),
	.routers_ps (cur_state      ),
	.wready     (t_m_data.wready)
);


/*which bus is permitted to send bursts to the Slaves - Masters or Special Memory*/
always_comb begin
	case (cur_state)
		
		ROUTERS_REG_FLOW: begin
			t_m_add.awburst = t_s_add.awburst ;
			t_m_add.awid 	  = t_s_add.awid ;
			t_m_add.awaddr  = t_s_add.awaddr ;
			t_m_add.awlen   = t_s_add.awlen ;
		    	t_m_add.awsize  = t_s_add.awsize ;
			t_m_add.awvalid = t_s_add.awvalid ;
			t_m_add.awuser  = t_s_add.awuser ;
			
			t_m_data.wid    = t_s_data.wid ;
			t_m_data.wdata  = t_s_data.wdata ;
			t_m_data.wstrb  = t_s_data.wstrb ;
			t_m_data.wlast  = t_s_data.wlast ;
			t_m_data.wvalid = t_s_data.wvalid ;
		end
		
		ROUTERS_MERGE:	begin
			t_m_add.awburst = axiOut.awburst ;
			t_m_add.awid 	  = axiOut.awid ;
			t_m_add.awaddr  = axiOut.awaddr ;
			t_m_add.awlen   = axiOut.awlen ;
			t_m_add.awsize  = axiOut.awsize ;
			t_m_add.awvalid = axiOut.awvalid ;
			t_m_add.awuser  = axiOut.awuser ;
			
			t_m_data.wid	  = axiOut.wid ;
			t_m_data.wdata  = axiOut.wdata ;
			t_m_data.wstrb  = axiOut.wstrb ;
			t_m_data.wlast  = axiOut.wlast ;
			t_m_data.wvalid = axiOut.wvalid ;
		end
		
		default: begin
			t_m_add.awvalid = 0 ;
			t_m_data.wvalid = 0 ;	 
		end

	endcase
end


endmodule







