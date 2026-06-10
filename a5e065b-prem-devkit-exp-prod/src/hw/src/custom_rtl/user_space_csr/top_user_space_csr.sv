//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//Module CSR Top level module

module top_user_space_csr 
#(parameter NUM_CHANNELS = 1,
  parameter FIFO_DEPTH = 5
)
(
	input 				                csr_clk        ,
    input 				                reset          , 
	input     [31:0]		            csr_wr_data    ,
	input     wire			            csr_read       ,
	input     wire 		                csr_write      ,
	input     [3:0]		                csr_byteenable ,
	input     [11:0]		            csr_address    ,
 	output    wire			            csr_waitrequest,	
	output    [31:0]  	                csr_rd_data    ,
	output    wire 		                csr_rd_vld     ,
	
	input        [NUM_CHANNELS-1:0]      ack_i_rst_n,
	input        [NUM_CHANNELS-1:0]      ack_i_tx_rst_n,
	input        [NUM_CHANNELS-1:0]      ack_i_rx_rst_n,
	
	output wire  [NUM_CHANNELS-1:0]      o_rst_n,
	output wire  [NUM_CHANNELS-1:0]      o_tx_rst_n,
	output wire  [NUM_CHANNELS-1:0]      o_rx_rst_n,
	
	
    input wire   [NUM_CHANNELS-1:0]      i_rx_pcs_ready   ,	
    input wire   [NUM_CHANNELS-1:0]      i_tx_lanes_stable,
    input wire   [NUM_CHANNELS-1:0]      i_tx_pll_locked  ,
    input wire   [NUM_CHANNELS-1:0]      i_cdr_lock       ,
    input wire                           i_sys_pll_locked ,
	
	input wire   [FIFO_DEPTH-1:0]        port0_tx_fifo_depth_i,
	input wire   [FIFO_DEPTH-1:0]        port1_tx_fifo_depth_i,
    input wire   [FIFO_DEPTH-1:0]        port0_rx_fifo_depth_i,
	input wire   [FIFO_DEPTH-1:0]        port1_rx_fifo_depth_i

	
);


 wire [NUM_CHANNELS-1:0]   sync_ack_i_rst_n, sync_ack_i_tx_rst_n, sync_ack_i_rx_rst_n;
 
 wire [NUM_CHANNELS-1:0]  sync_rx_pcs_ready,sync_tx_lanes_stable,sync_tx_pll_locked,sync_cdr_lock;
 wire sync_sys_pll_locked;
 reg  waitrequest;
 
 assign csr_waitrequest = waitrequest;
 
	//Generating waitrequest signal
   always @(posedge csr_clk)
    begin
		if(!reset)
          	waitrequest <= 1'b1;
		else if((waitrequest != 0) && (csr_write | csr_read))
            waitrequest <= 1'b0;
        else
			waitrequest <= 1'b1;
	end

  
generate for(genvar i=0;i<NUM_CHANNELS;i++) begin : gen_mulit_inst

    eth_f_altera_std_synchronizer_nocut sync_ack_i_rst_n_csr_clk (
     .clk                       ( csr_clk),
     .reset_n                   ( 1'b1 ),
     .din                       ( ack_i_rst_n[i] ),
     .dout                      ( sync_ack_i_rst_n[i])
    );

    eth_f_altera_std_synchronizer_nocut sync_ack_i_tx_rst_n_csr_clk (
     .clk                       ( csr_clk),
     .reset_n                   ( 1'b1 ),
     .din                       ( ack_i_tx_rst_n[i] ),
     .dout                      ( sync_ack_i_tx_rst_n[i])
    );
	
    eth_f_altera_std_synchronizer_nocut sync_ack_i_rx_rst_n_csr_clk (
     .clk                       ( csr_clk),
     .reset_n                   ( 1'b1 ),
     .din                       ( ack_i_rx_rst_n[i] ),
     .dout                      ( sync_ack_i_rx_rst_n[i])
    );	

    eth_f_altera_std_synchronizer_nocut sync_rx_pcs_ready_csr_clk (
     .clk                       ( csr_clk),
     .reset_n                   ( 1'b1 ),
     .din                       ( i_rx_pcs_ready[i] ),
     .dout                      ( sync_rx_pcs_ready[i])
    );
	
   eth_f_altera_std_synchronizer_nocut sync_tx_lanes_stable_csr_clk (
     .clk                       ( csr_clk),
     .reset_n                   ( 1'b1 ),
     .din                       ( i_tx_lanes_stable[i] ),
     .dout                      ( sync_tx_lanes_stable [i])
    );
	
   eth_f_altera_std_synchronizer_nocut sync_tx_pll_locked_csr_clk (
     .clk                       ( csr_clk),
     .reset_n                   ( 1'b1 ),
     .din                       ( i_tx_pll_locked[i] ),
     .dout                      ( sync_tx_pll_locked [i])
    );
	
   eth_f_altera_std_synchronizer_nocut sync_cdr_lock_csr_clk (
     .clk                       ( csr_clk),
     .reset_n                   ( 1'b1 ),
     .din                       ( i_cdr_lock[i] ),
     .dout                      ( sync_cdr_lock [i])
    );
	
end endgenerate

eth_f_altera_std_synchronizer_nocut sync_sys_pll_locked_csr_clk (
     .clk                       ( csr_clk),
     .reset_n                   ( 1'b1 ),
     .din                       ( i_sys_pll_locked ),
     .dout                      (sync_sys_pll_locked )
    );


user_csr_space user_csr_space(

   // CONTROL_REG.p0_i_rst_n
   .we_CONTROL_REG_p0_i_rst_n     (~sync_ack_i_rst_n[0]),          
   .CONTROL_REG_p0_i_rst_n_i      (1'b1),
   .CONTROL_REG_p0_i_rst_n        (o_rst_n[0]),         //out
	`ifdef NUM_CHANNELS_2
   // CONTROL_REG.p1_i_rst_n
   .we_CONTROL_REG_p1_i_rst_n     (~sync_ack_i_rst_n[1]), 
   .CONTROL_REG_p1_i_rst_n_i      (1'b1),
   .CONTROL_REG_p1_i_rst_n        (o_rst_n[1]),       //out
	
  // CONTROL_REG.p1_i_tx_rst_n
   .we_CONTROL_REG_p1_i_tx_rst_n   (~sync_ack_i_tx_rst_n[1]),
   .CONTROL_REG_p1_i_tx_rst_n_i    (1'b1),
   .CONTROL_REG_p1_i_tx_rst_n      (o_tx_rst_n[1]),    //out
	
	  // CONTROL_REG.p1_i_rx_rst_n
   .we_CONTROL_REG_p1_i_rx_rst_n   (~sync_ack_i_rx_rst_n[1]),
   .CONTROL_REG_p1_i_rx_rst_n_i    (1'b1),
   .CONTROL_REG_p1_i_rx_rst_n      (o_rx_rst_n[1]),  //out
	
   // STATUS_REG.p1_rx_pcs_ready
   .STATUS_REG_p1_rx_pcs_ready_i  (sync_rx_pcs_ready[1]),
	
   // STATUS_REG.p1_tx_lane_stable
   .STATUS_REG_p1_tx_lane_stable_i  (sync_tx_lanes_stable[1]),
	
   // STATUS_REG.p1_tx_pll_locked
   .STATUS_REG_p1_tx_pll_locked_i  (sync_tx_pll_locked[1]),
	
   // STATUS_REG.p1_rx_cdr_locked
   .STATUS_REG_p1_rx_cdr_locked_i  (sync_cdr_lock[1]),
	
	`endif

   // CONTROL_REG.p0_i_tx_rst_n
   .we_CONTROL_REG_p0_i_tx_rst_n   (~sync_ack_i_tx_rst_n[0]),
   .CONTROL_REG_p0_i_tx_rst_n_i    (1'b1),
   .CONTROL_REG_p0_i_tx_rst_n      (o_tx_rst_n[0]),     //out

   // CONTROL_REG.p0_i_rx_rst_n
   .we_CONTROL_REG_p0_i_rx_rst_n   (~sync_ack_i_rx_rst_n[0]), 
   .CONTROL_REG_p0_i_rx_rst_n_i    (1'b1),
   .CONTROL_REG_p0_i_rx_rst_n      (o_rx_rst_n[0]),      //out

   // ERROR_REG.fp_i_rst_n 
   .we_ERROR_REG_fp_i_rst_n        (),
   .ERROR_REG_fp_i_rst_n_i         (),
   .ERROR_REG_fp_i_rst_n           (),   //out
   // STATUS_REG.p0_rx_pcs_ready
   .STATUS_REG_p0_rx_pcs_ready_i  (sync_rx_pcs_ready[0]),
	
   // STATUS_REG.p0_tx_lane_stable
   .STATUS_REG_p0_tx_lane_stable_i  (sync_tx_lanes_stable[0]),

   // STATUS_REG.p0_tx_pll_locked
   .STATUS_REG_p0_tx_pll_locked_i  (sync_tx_pll_locked[0]),

   // STATUS_REG.p0_rx_cdr_locked
   .STATUS_REG_p0_rx_cdr_locked_i  (sync_cdr_lock[0]),

   // STATUS_REG.sys_pll_locked
   .STATUS_REG_sys_pll_locked_i       (sync_sys_pll_locked),
   // FIFO_STATUS_REG.port0_tx_fifo_depth
   .FIFO_STATUS_REG_port0_tx_fifo_depth_i  (),
   // FIFO_STATUS_REG.port1_tx_fifo_depth
   .FIFO_STATUS_REG_port1_tx_fifo_depth_i  (),
   // FIFO_STATUS_REG.port0_rx_fifo_depth
   .FIFO_STATUS_REG_port0_rx_fifo_depth_i  (),
   // FIFO_STATUS_REG.port1_rx_fifo_depth
   .FIFO_STATUS_REG_port1_rx_fifo_depth_i  (),

   // Bus interface
   .clk                  (  csr_clk        ),
   .reset                (  !reset         ),
   .writedata            (  csr_wr_data    ),
   .read                 (  csr_read & !csr_waitrequest),
   .write                (  csr_write & !csr_waitrequest),
   .byteenable           (  csr_byteenable ),
   .readdata             (  csr_rd_data    ),
   .readdatavalid        (  csr_rd_vld     ),
   .address              (  csr_address    )

	);                             


endmodule
