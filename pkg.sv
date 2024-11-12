/*------------------------------------------------------------------------------
 * File          : pkg.sv
 * Project       : RTL
 * Author        : epabab
 * Creation date : Jul 20, 2024
 * Description   : Struct definitions and parameters
 *------------------------------------------------------------------------------*/

package pkg;
	
	
	localparam PID_WIDTH = 4 ;
	localparam PADDR_WIDTH = 32 ;
	localparam PLENGTH_WIDTH = 3 ;								//fixed 4 bytes in AXI3 and 8 bytes in AXI4
	localparam PAWUSER_WIDTH = 2 ;
	localparam PSIZE_WIDTH = 2 ;							//fixed 3(?). SIZE OF A TRANSTER IN BYTES
	
	localparam PDATA_WIDTH = 2**((2**PSIZE_WIDTH)-1) ;	// SIZE OF THE DATA BUS IN BYTES
	localparam PSTRB_WIDTH = PSIZE_WIDTH;						//is max(awsize)/8 = 128/8
	localparam SPEC_SLOT_AMOUNT = 5 ;//so we have 8 slots
	localparam INDEX_WIDTH = $clog2(SPEC_SLOT_AMOUNT) ;
	
	localparam PCOMPLETE_DATA = PDATA_WIDTH*((2**PLENGTH_WIDTH)+1) ; //IN BYTES      TODO calculate and 
	
	localparam REGULAR = 2'b00 ;
	localparam BLOCK   = 2'b01 ;
	localparam DIVERT  = 2'b10 ;
	localparam UNLUCKY = 2'b11 ;
	
	typedef struct packed {
		reg                 valid ;
		reg [PID_WIDTH-1:0] id ;
		reg [PAWUSER_WIDTH-1:0]           tran_type ;
	} slot ;
	
	
	typedef struct packed {				
		reg [PID_WIDTH-1:0]  	awid;
		reg [PLENGTH_WIDTH-1:0] awlen;
		reg [1:0]				awburst ;
		reg [PADDR_WIDTH-1:0] 	awaddr;
		reg [PSIZE_WIDTH-1:0]	awsize;				
		reg [PAWUSER_WIDTH-1:0] awuser;
		
		reg [PCOMPLETE_DATA-1:0][7:0] data ;
		reg [PCOMPLETE_DATA-1:0] strb ;
	} burst_slot ;
	
	
	typedef struct packed {
		reg [INDEX_WIDTH-1:0]         index ;
		reg                           unluck ;
		
		reg [PID_WIDTH-1:0]           awid;
		reg [PLENGTH_WIDTH-1:0]       awlen;
		reg [1:0]                     awburst ;
		reg [PADDR_WIDTH-1:0]         awaddr;
		reg [PSIZE_WIDTH-1:0]         awsize;
		reg [PAWUSER_WIDTH-1:0]       awuser;
		
		reg [PCOMPLETE_DATA-1:0][7:0] data ;
		reg [PCOMPLETE_DATA-1:0]      strb ;
	} spec_slot ;
	
//	typedef struct packed {
//		reg [INDEX_WIDTH-1:0] index ;
//		reg [PID_WIDTH-1:0]   id ;
//		reg                   unluck ;
//		reg [PCOMPLETE_DATA-1:0] many_many_data ;
//	} spec_slot ;
	
	
//	function logic rise(logic trig);
//		logic temp ;
//		if(~trig)
//			temp=1;
//		else if(temp & trig) 
//			temp=0;
//		return temp & trig ;
//	endfunction

	
//	function ris_e(trig);
//		logic temp ;
//		if(~trig)
//			temp=1;
//		else if(temp & trig) begin
//			temp=0;
//			return 1 ;
//		end
//		else return 0 ;
//	endfunction
	
endpackage

//	 function logic mini_fsm (logic trig_up, logic trig_down, logic rst_n);
//		logic temp ;
////		if (~rst_n)
////			temp = 0 ;
//		else if(trig_up)
//			temp = 1 ;
//		else if (trig_down)
//			temp = 0 ;
//		return temp ;
//	endfunction



