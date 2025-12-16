// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


//------------------------------------------------------------------------------
//
// Filename         : intel_eth_gts_ptp_stod_top.sv
//
//==============================================================================

//------------------------------------------------------------------------------
//
// Description :-
// This module is a PTP Subordinate Time-of-Day (TOD), which: 
// supports master TOD load,
// and provides 96-bit TOD data and 1-bit tod_valid outputs.
//------------------------------------------------------------------------------

`timescale 1ns / 1ns
module intel_eth_gts_ptp_stod_top
# (
    parameter EN_10G_ADV_MODE = 0,
	 parameter SYNC_MODE       = 0
)(
    // Clock and Reset
    input  logic                      i_clk_reconfig,
    input  logic                      i_clk_mtod,
    input  logic                      i_clk_stod,
    input  logic                      i_clk_todsync_sampling,
    input  logic                      i_reconfig_rst_n,
    input  logic                      i_mtod_rst_n,
    input  logic                      i_stod_rst_n,
    
    // Master TOD
    input  logic [95:0]               i_mtod_data,
    input  logic                      i_mtod_valid,
    // Output TOD
    output logic [95:0]               o_stod_data,
    output logic                      o_stod_valid
);
    // Internal logics
    logic        mtod_valid_sync;
    logic        tod_sync_valid;
    logic [95:0] tod_sync_data;
    
    // -----------------------------------------------
    // synchronizers
    intel_eth_gts_altera_std_synchronizer_nocut mtod_valid_sync_inst (
        .clk        (i_clk_stod),
        .reset_n    (1'b1),
        .din        (i_mtod_valid),
        .dout       (mtod_valid_sync)
    );

    generate if (EN_10G_ADV_MODE == 1) begin : TOD_GEN_10G_ADV_MODE
        // -----------------------------------------------
        // TOD Synchronizer
        intel_eth_gts_tod_sync_125_to_156p25 #(
		  .SYNC_MODE    (SYNC_MODE)
		  ) tod_sync_inst (
            .clk_master                 (i_clk_mtod),
            .reset_master               (~i_mtod_rst_n),
            .clk_slave                  (i_clk_stod),
            .reset_slave                (~i_stod_rst_n),
            .clk_sampling               (i_clk_todsync_sampling),
            .start_tod_sync             (1'b1),
            .tod_master_data            (i_mtod_data),
            .tod_slave_valid            (tod_sync_valid),
            .tod_slave_data             (tod_sync_data)
        );

        // -----------------------------------------------
        // Subordinate TOD
        intel_eth_gts_tod_156p25 tod_inst (
            .clk                         (i_clk_reconfig),
            .rst_n                       (i_reconfig_rst_n),
            .period_clk                  (i_clk_stod),
            .period_rst_n                (i_stod_rst_n),
            .csr_address                 (4'h0),
            .csr_write                   (1'b0),
            .csr_writedata               (32'h0),
            .csr_read                    (1'b0),
            .csr_readdata                (),
            .csr_waitrequest             (),
            .time_of_day_96b_load_valid  (tod_sync_valid),
            .time_of_day_96b_load_data   (tod_sync_data),
            .time_of_day_64b_load_valid  (1'b0),
            .time_of_day_64b_load_data   (64'h0),
            .time_of_day_96b             (o_stod_data),
            .time_of_day_64b             ()
        );
    end else begin : TOD_GEN_NON_10G_ADV_MODE
        // -----------------------------------------------
        // TOD Synchronizer
        intel_eth_gts_tod_sync_125_to_390p625 tod_sync_inst (
            .clk_master                 (i_clk_mtod),
            .reset_master               (~i_mtod_rst_n),
            .clk_slave                  (i_clk_stod),
            .reset_slave                (~i_stod_rst_n),
            .clk_sampling               (i_clk_todsync_sampling),
            .start_tod_sync             (1'b1),
            .tod_master_data            (i_mtod_data),
            .tod_slave_valid            (tod_sync_valid),
            .tod_slave_data             (tod_sync_data)
        );

        // -----------------------------------------------
        // Subordinate TOD
        intel_eth_gts_tod_390p625 tod_inst (
            .clk                         (i_clk_reconfig),
            .rst_n                       (i_reconfig_rst_n),
            .period_clk                  (i_clk_stod),
            .period_rst_n                (i_stod_rst_n),
            .csr_address                 (4'h0),
            .csr_write                   (1'b0),
            .csr_writedata               (32'h0),
            .csr_read                    (1'b0),
            .csr_readdata                (),
            .csr_waitrequest             (),
            .time_of_day_96b_load_valid  (tod_sync_valid),
            .time_of_day_96b_load_data   (tod_sync_data),
            .time_of_day_64b_load_valid  (1'b0),
            .time_of_day_64b_load_data   (64'h0),
            .time_of_day_96b             (o_stod_data),
            .time_of_day_64b             ()
        );
    end
    endgenerate
    // -----------------------------------------------
    // TOD valid generator
    localparam S_WAIT_MTOD_VALID = 0;
    localparam S_WAIT_LTOD_VALID = 1;
    localparam S_TOD_VALID       = 2;
    localparam WAIT_CNT_INT_LOAD = 12'd1040;
    // TODSync delay: reset release until 1st tod_slave_valid (4398ns or 1720cycles)
    // TODSync delay2: mtod_valid reassert until stod_slave_valid reassert ((2420ns/2.56)*1.1=1040cycles)
    // TOD load: 9 cycles, count as 10.
    logic [3:0] todv_state;
    logic [11:0] wait_cnt;
    
    always @ (posedge i_clk_stod) begin
        if (~i_stod_rst_n) begin
            o_stod_valid    <= 1'b0;
            todv_state      <= S_WAIT_MTOD_VALID;
            wait_cnt        <= 12'h0;   
        end
        else begin
            o_stod_valid    <= (todv_state == S_TOD_VALID) ? 1'b1 : 1'b0;
            
            case (todv_state)
            S_WAIT_MTOD_VALID: begin
                if (mtod_valid_sync) begin
                    todv_state      <= S_WAIT_LTOD_VALID;
                    wait_cnt        <= WAIT_CNT_INT_LOAD;
                end
            end
            S_WAIT_LTOD_VALID: begin
                if (wait_cnt != 12'h0) begin
                    wait_cnt    <= wait_cnt - 12'h1;
                end
                if      (~mtod_valid_sync)                      todv_state  <= S_WAIT_MTOD_VALID;
                else if ((wait_cnt == 12'h0) && tod_sync_valid) todv_state  <= S_TOD_VALID;
                else                                            todv_state  <= todv_state;
            end
            S_TOD_VALID: begin
                if (~mtod_valid_sync)   todv_state  <= S_WAIT_MTOD_VALID;
                else                    todv_state  <= S_TOD_VALID;
            end
            default: begin
                todv_state    <= S_WAIT_MTOD_VALID;
            end
            endcase
        end
    end


endmodule : intel_eth_gts_ptp_stod_top
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "mXypBqYlC5tPHKvGSz/OgELAzHpeDTMVm92T/G3Tu+Mtj/QKjdPq2C/7YjmBqURd42eqxLEPm5ROnJvj36ncaaR8Sspj9hTF+smYtFdsh6vMrIn7I2ujp7BRjzYw5I2AvAOQAp7snnaPLlJ7h0AspRt5h+aoUWOpH7IAlafE9plfycmjleDqZQRYeY5Pocjbv9fsy1/Wfhpiv3JjywCi+32tfuLfNErYoFt3ZHZNJfEItwmtVOGZj0nnYWLKqn563Die725nXoOQ2Ysg7fTLb6/4lsC9IyomvtumK3chTX4KhGx+U03r+1voEvp/g49Y65eRjgXkpeuYhbncdRzb3fAc+m8tthPxDKoXPq1zfGu+YjHD6gwlFveU2BuRzNXARoPfxzLoIIxOx6ca7zAVbmS4r5cDZkxCPxw1TRsRZaTUJmVxJ19vx8KPHj8dATqs95EdVp5Yt12Amfds6FEGdHKizaBcFf8g3P5KNxPwiW/ilxVFd2f5x92stercf8iGxGmZbfV2ECGj1rEY2PBZmXOR25Xg8+XyMhLXNco9padObdmu7VpSHkvBdbcOVhCAi1R3OuSrb+U3W93p9cmbqhQUDBFvfk6zmt0nXbn5S2BV09maBygL0Qj6stN+h3zBlHdX4EBXMmTDtA09AJEXl3kWrprXfhpAe/iWoumk77EqSJzS7E1IgiWg9jXiWIFHO8d0R8oW8fdvC4O6qTxeEwP4iQIe0BCv7oy1LGXB3gnx/q8mZ9tFWlXJ0QJ7ho0OYVMIhgSGZAYhJWN7MZSNxN7cIH3df0deslehAV5abMfbLgfUjtuB6R74xPs9DNJxxVbtZQakzVtdjY/rYOfroy4HBD5hOoQbAoxkKRFNsnOzhN8Ek42if4WF1G7cL/OnU2DVnjeeFfE5+hg8zcNoqP0G5ldIdXH0k3oNO+9yxXg/pgHy/p2NmOTF8f+TnjGbQWjEBNR6EWsDWFp1z9GD+wzGJYOqGplAe/J7miLY7WK5VdvkTuRJb4e8uBLsy1Y/"
`endif
