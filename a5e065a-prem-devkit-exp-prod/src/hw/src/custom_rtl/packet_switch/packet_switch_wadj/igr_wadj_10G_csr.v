//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

// 
module igr_wadj_10G_csr (
// register offset : 0x0, field offset : 0, access : RW, scratch_reg.scratch
// register offset : 0x4, field offset : 0, access : RW, control_reg.cfg_rx_pause_en
output  reg control_reg_cfg_rx_pause_en,
// register offset : 0x4, field offset : 1, access : RO, control_reg.reserved
// register offset : 0x8, field offset : 0, access : RW, cfg_threshold_reg.rx_pause_threshold
output  reg[15:0] cfg_threshold_reg_rx_pause_threshold,
// register offset : 0x8, field offset : 16, access : RW, cfg_threshold_reg.drop_threshold
output  reg[15:0] cfg_threshold_reg_drop_threshold,
//Bus Interface
input clk,
input reset,
input [31:0] writedata,
input read,
input write,
input [3:0] byteenable,
output reg [31:0] readdata,
output reg readdatavalid,
input [3:0] address

);


wire reset_n = !reset;	
// Protocol management
// combinatorial read data signal declaration
reg [31:0] rdata_comb;

// synchronous process for the read
always @(posedge clk)  
   if (!reset_n) readdata[31:0] <= 32'h0; else readdata[31:0] <= rdata_comb[31:0];

// read data is always returned on the next cycle
always @( posedge clk)
   if (!reset_n) readdatavalid <= 1'b0; else readdatavalid <= read;
//
//  Protocol specific assignment to inside signals
//
wire  we = write;
wire  re = read;
wire [3:0] addr = address[3:0];
wire [31:0] din  = writedata [31:0];
// A write byte enable for each register
// register scratch_reg with  writeType: write
wire	[3:0]  we_scratch_reg		=	we  & (addr[3:0]  == 4'h0)	?	byteenable[3:0]	:	{4{1'b0}};
// register control_reg with  writeType: write
wire	  we_control_reg		=	we  & (addr[3:0]  == 4'h4)	?	byteenable[0]	:	1'b0;
// register cfg_threshold_reg with  writeType: write
wire	[3:0]  we_cfg_threshold_reg		=	we  & (addr[3:0]  == 4'h8)	?	byteenable[3:0]	:	{4{1'b0}};

// A read byte enable for each register

/* Definitions of REGISTER "scratch_reg" */

// scratch_reg_scratch
// bitfield description: Scratch Register.
// customType:  RW
// hwAccess: NA 
// reset value : 0x00000000 

reg [31:0] scratch_reg_scratch; // 

always @( posedge clk)
   if (!reset_n)  begin
      scratch_reg_scratch <= 32'h00000000;
   end
   else begin
   if (we_scratch_reg[0]) begin 
      scratch_reg_scratch[7:0]   <=  din[7:0];  //
   end
   if (we_scratch_reg[1]) begin 
      scratch_reg_scratch[15:8]   <=  din[15:8];  //
   end
   if (we_scratch_reg[2]) begin 
      scratch_reg_scratch[23:16]   <=  din[23:16];  //
   end
   if (we_scratch_reg[3]) begin 
      scratch_reg_scratch[31:24]   <=  din[31:24];  //
   end
end
/* Definitions of REGISTER "control_reg" */

// control_reg_cfg_rx_pause_en
// bitfield description: Enable RX pause.
// customType:  RW
// hwAccess: RO 
// reset value : 0x0 


always @( posedge clk)
   if (!reset_n)  begin
      control_reg_cfg_rx_pause_en <= 1'h0;
   end
   else begin
   if (we_control_reg) begin 
      control_reg_cfg_rx_pause_en   <=  din[0];  //
   end
end

// control_reg_reserved
// bitfield description: Reserved.
// customType:  RO
// hwAccess: NA 
// reset value : 0x00000000 
// NO register generated


/* Definitions of REGISTER "cfg_threshold_reg" */

// cfg_threshold_reg_rx_pause_threshold
// bitfield description: Configured threshold when RX pause is asserted.
// customType:  RW
// hwAccess: RO 
// reset value : 0x0400 


always @( posedge clk)
   if (!reset_n)  begin
      cfg_threshold_reg_rx_pause_threshold <= 16'h0400;
   end
   else begin
   if (we_cfg_threshold_reg[0]) begin 
      cfg_threshold_reg_rx_pause_threshold[7:0]   <=  din[7:0];  //
   end
   if (we_cfg_threshold_reg[1]) begin 
      cfg_threshold_reg_rx_pause_threshold[15:8]   <=  din[15:8];  //
   end
end

// cfg_threshold_reg_drop_threshold
// bitfield description: Configured threshold when packets are dropped.
// customType:  RW
// hwAccess: RO 
// reset value : 0x079c 


always @( posedge clk)
   if (!reset_n)  begin
      cfg_threshold_reg_drop_threshold <= 16'h079c;
   end
   else begin
   if (we_cfg_threshold_reg[2]) begin 
      cfg_threshold_reg_drop_threshold[7:0]   <=  din[23:16];  //
   end
   if (we_cfg_threshold_reg[3]) begin 
      cfg_threshold_reg_drop_threshold[15:8]   <=  din[31:24];  //
   end
end


// read process
always @ (*)
begin
rdata_comb = 32'h00000000;
   if(re) begin
      case (addr)  
	4'h0 : begin
		rdata_comb [31:0]	= scratch_reg_scratch [31:0] ;		// readType = read   writeType =write
	end
	4'h4 : begin
		rdata_comb [0]	= control_reg_cfg_rx_pause_en  ;		// readType = read   writeType =write
		rdata_comb [31:1]	= 31'h00000000 ;  // control_reg_reserved 	is reserved or a constant value, a read access gives the reset value
	end
	4'h8 : begin
		rdata_comb [15:0]	= cfg_threshold_reg_rx_pause_threshold [15:0] ;		// readType = read   writeType =write
		rdata_comb [31:16]	= cfg_threshold_reg_drop_threshold [15:0] ;		// readType = read   writeType =write
	end
	default : begin
		rdata_comb = 32'h00000000;
	end
      endcase
   end
end

endmodule
