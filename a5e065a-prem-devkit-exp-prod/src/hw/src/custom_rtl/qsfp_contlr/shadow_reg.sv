// ######################################################################## 
// Copyright (C) 2025 Altera Corporation.
// SPDX-License-Identifier: MIT
// ######################################################################## 
// -------------------------------------------------------------------------- #
//
// Engineer     : 
// Create Date  : April 2024
// Module Name  : shadow_reg.sv
// Project      : 
// -----------------------------------------------------------------------------
//
// Description:  This logic is the set of shadow regs for qsfps. 

module shadow_reg #(
   parameter ADDR_WIDTH = 8,	
   parameter DATA_WIDTH = 64,
	parameter BYTE_ENABLE_WIDTH= DATA_WIDTH/8
)(
 
input  logic                    		clk,
input  logic        			     	reset, 
input  logic [ADDR_WIDTH-1:0]		  	onchip_memory2_s1_address,
input  logic             				onchip_memory2_s1_read,
output logic [DATA_WIDTH-1:0]			onchip_memory2_s1_readdata,
input  logic [BYTE_ENABLE_WIDTH-1:0]	onchip_memory2_s1_byteenable,
input  logic             				onchip_memory2_s1_write,
input  logic [DATA_WIDTH-1:0]			onchip_memory2_s1_writedata,
input  logic [ADDR_WIDTH-1:0]		  	onchip_memory2_s2_address,
input  logic             				onchip_memory2_s2_read,
output logic [DATA_WIDTH-1:0]			onchip_memory2_s2_readdata,
input  logic [BYTE_ENABLE_WIDTH-1:0]	onchip_memory2_s2_byteenable,
input  logic     		  				onchip_memory2_s2_write,
input  logic [DATA_WIDTH-1:0]			onchip_memory2_s2_writedata);


logic rst_controller_reset_out_reset;
logic rst_controller_reset_out_reset_req;

		ocm2_0 ocm2_0_inst (
		.clk         (clk),         
		.address     (onchip_memory2_s1_address),     
		.read        (onchip_memory2_s1_read),           
		.readdata    (onchip_memory2_s1_readdata),    
		.byteenable  (onchip_memory2_s1_byteenable),     
		.write       (onchip_memory2_s1_write),          
		.writedata   (onchip_memory2_s1_writedata),     
		.reset       (rst_controller_reset_out_reset),          
		.reset_req   (rst_controller_reset_out_reset_req),      
		.address2    (onchip_memory2_s2_address),       
		.read2       (onchip_memory2_s2_read),          
		.readdata2   (onchip_memory2_s2_readdata),   
		.byteenable2 (onchip_memory2_s2_byteenable),    
		.write2      (onchip_memory2_s2_write),         
		.writedata2  (onchip_memory2_s2_writedata)    
	);

reset_req reset_req_inst (
		.clk_clk                             (clk),                             //   input,  width = 1,                       clk.clk
		.reset_reset                         (reset),                         //   input,  width = 1,                     reset.reset
		.reset_req_cntlr_reset_out_reset     (rst_controller_reset_out_reset),     //  output,  width = 1, reset_req_cntlr_reset_out.reset
		.reset_req_cntlr_reset_out_reset_req (rst_controller_reset_out_reset_req)  //  output,  width = 1,                          .reset_req
	);
	

endmodule
