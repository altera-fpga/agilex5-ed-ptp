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
// Filename         : intel_eth_gts_ptp_mtod_top.sv
//
//==============================================================================

//------------------------------------------------------------------------------
//
// Description :-
// This module is a PTP Master Time-of-Day (TOD), which: 
// supports 1 Pulse Per Second,
// and provides 96-bit TOD data and 1-bit tod_valid outputs,
// as well as 1-pulse-per-second output.
//------------------------------------------------------------------------------

`timescale 1ns / 1ns
module intel_eth_gts_ptp_mtod_top
#(
    parameter EN_PPS_ADV                    = 1,
    parameter MASTER_PPS_CYCLE              = 100000000,
	 parameter PPS_PULSE_ASSERT_CYCLE_MASTER = 156, //pps out pulse width 1us
	 parameter DEFAULT_NSEC_PERIOD           = 6,
	 parameter DEFAULT_FNSEC_PERIOD          = 26214,
	 parameter DEFAULT_NSEC_ADJPERIOD        = 6,
	 parameter DEFAULT_FNSEC_ADJPERIOD       = 26214
)(
    // Clock and Reset
    input  logic                    i_clk_reconfig,
    input  logic                    i_clk_tod,
    input  logic                    i_reconfig_rst_n,
    input  logic                    i_tod_rst_n,
	 
	 input  logic                    pps_samp_clk,
    
    // CSR
    input  logic [3:0]              i_csr_addr,
    input  logic                    i_csr_write,
    input  logic [31:0]             i_csr_writedata,
    input  logic                    i_csr_read,
    output logic [31:0]             o_csr_readdata,
    output logic                    o_csr_waitrequest,
    // TOD load            
    input  logic                    i_tod_96b_load_valid,
    input  logic [95:0]             i_tod_96b_load_data,
    // Output TOD
    output logic                    o_tod_96b_valid,
    output logic [95:0]             o_tod_96b_data,
    // 1-Pulse-Per-Second
    output logic                    o_pps
);
    // Internal logics
    logic       csr_tod_load, csr_tod_load_d, csr_tod_load_2d;
    logic       csr_tod_load_sync;

    generate if (EN_PPS_ADV == 1) begin : MTOD_GEN_PPS_ADV_MODE
	 logic       pps_phased_clk;
    logic       ppll_lock;
	 wire [31:0] pll_calbus_rd; 
	 wire [57:0] pll_calbus;
	 logic       phased_pll_reset;
	 wire [26:0] s0_axi4lite_awaddr; 
    wire        s0_axi4lite_awvalid;
    wire        s0_axi4lite_awready;
    wire [26:0] s0_axi4lite_araddr; 
    wire        s0_axi4lite_arvalid;
    wire        s0_axi4lite_arready;
    wire [31:0] s0_axi4lite_wdata;  
    wire        s0_axi4lite_wvalid; 
    wire        s0_axi4lite_wready; 
    wire [1:0]  s0_axi4lite_rresp;  
    wire [31:0] s0_axi4lite_rdata;  
    wire        s0_axi4lite_rvalid; 
    wire        s0_axi4lite_rready; 
    wire [1:0]  s0_axi4lite_bresp;  
    wire        s0_axi4lite_bvalid; 
    wire        s0_axi4lite_bready; 
    wire [2:0]  s0_axi4lite_awprot; 
    wire [2:0]  s0_axi4lite_arprot; 
    wire [3:0]  s0_axi4lite_wstrb;  
    

	 
	phase_iopll phase_clk (
		.refclk              (i_clk_tod),              
		.locked              (ppll_lock),              
		.rst                 (~i_reconfig_rst_n | phased_pll_reset),                 
		.pll_calbus          (pll_calbus),          
		.pll_calbus_readdata (pll_calbus_rd), 
		.outclk_0            (pps_phased_clk)             
	);


	
	
	
	master_tod_adv_mode #(
		.DEFAULT_NSEC_PERIOD           (DEFAULT_NSEC_PERIOD),
		.DEFAULT_FNSEC_PERIOD          (DEFAULT_FNSEC_PERIOD),
		.DEFAULT_NSEC_ADJPERIOD        (DEFAULT_NSEC_ADJPERIOD),
		.DEFAULT_FNSEC_ADJPERIOD       (DEFAULT_FNSEC_ADJPERIOD),
		.PPS_PULSE_ASSERT_CYCLE_MASTER (PPS_PULSE_ASSERT_CYCLE_MASTER)
		
	) master_tod (
		.clk                        (i_clk_reconfig),                        //   input,   width = 1,                 csr_clock.clk
		.rst_n                      (i_reconfig_rst_n),                      //   input,   width = 1,                 csr_reset.reset_n
		.period_clk                 (i_clk_tod),                        //   input,   width = 1,              period_clock.clk
		.period_rst_n               (i_tod_rst_n),                      //   input,   width = 1,        period_clock_reset.reset_n
		.csr_readdata               (o_csr_readdata),                      //  output,  width = 32,                       csr.readdata
		.csr_write                  (i_csr_write),                         //   input,   width = 1,                          .write
		.csr_read                   (i_csr_read),                          //   input,   width = 1,                          .read
		.csr_writedata              (i_csr_writedata),                     //   input,  width = 32,                          .writedata
		.csr_waitrequest            (o_csr_waitrequest),                   //  output,   width = 1,                          .waitrequest
		.csr_address                (i_csr_addr),                             //   input,   width = 4,                          .address
		.time_of_day_96b            (o_tod_96b_data),                        //  output,  width = 96,           time_of_day_96b.data
		.time_of_day_64b            (),                  //  output,  width = 64,           time_of_day_64b.data
		.time_of_day_96b_load_data  (i_tod_96b_load_data),                    ///   input,  width = 96,      time_of_day_96b_load.data
		.time_of_day_96b_load_valid (i_tod_96b_load_valid),                   ///   input,   width = 1,                          .valid
		.time_of_day_64b_load_data  (64'd0),                                  //   input,  width = 64,      time_of_day_64b_load.data
		.time_of_day_64b_load_valid (1'b0),                                   //   input,   width = 1,                          .valid
		.pps_sampling_clk           (pps_samp_clk),           //   input,   width = 1,            sampling_clock.clk
		.iopll_phased_clk           (pps_phased_clk),           //   input,   width = 1,              phased_clock.clk
		.iopll_locked               (ppll_lock),               //   input,   width = 1, phased_clk_lock_interface.lock
		.pps_pulse_per_second       (o_pps),       //  output,   width = 1,             pps_interface.phased_pulse
		.o_awaddr                   (s0_axi4lite_awaddr ),                   //  output,  width = 27,         axilite_interface.write_address
		.o_awvalid                  (s0_axi4lite_awvalid),                  //  output,   width = 1,                          .write_address_valid
		.o_awprot                   (s0_axi4lite_awprot ),                   //  output,   width = 3,                          .write_address_prot
		.i_awready                  (s0_axi4lite_awready),                  //   input,   width = 1,                          .write_address_ready
		.o_wdata                    (s0_axi4lite_wdata ),                    //  output,  width = 32,                          .write_data
		.o_wstrb                    (s0_axi4lite_wstrb  ),                    //  output,   width = 4,                          .write_strobe
		.o_wvalid                   (s0_axi4lite_wvalid ),                   //  output,   width = 1,                          .write_valid
		.i_wready                   (s0_axi4lite_wready ),                   //   input,   width = 1,                          .write_ready
		.i_bresp                    (s0_axi4lite_bresp  ),                    //   input,   width = 2,                          .response
		.i_bvalid                   (s0_axi4lite_bvalid),                   //   input,   width = 1,                          .response_valid
		.o_bready                   (s0_axi4lite_bready ),                   //  output,   width = 1,                          .response_ready
		.o_araddr                   (s0_axi4lite_araddr),                   //  output,  width = 27,                          .read_address
		.o_arvalid                  (s0_axi4lite_arvalid),                  //  output,   width = 1,                          .read_address_valid
		.o_arprot                   (s0_axi4lite_arprot ),                   //  output,   width = 3,                          .read_address_prot
		.i_arready                  (s0_axi4lite_arready),                  //   input,   width = 1,                          .read_address_ready
		.i_rdata                    (s0_axi4lite_rdata  ),                    //   input,  width = 32,                          .read_data
		.i_rresp                    (s0_axi4lite_rresp ),                    //   input,   width = 2,                          .read_response
		.i_rvalid                   (s0_axi4lite_rvalid ),                   //   input,   width = 1,                          .read_valid
		.o_rready                   (s0_axi4lite_rready ),                   //  output,   width = 1,                          .read_ready
		.phased_pll_reset           (phased_pll_reset)            //  output,   width = 1,      phased_pll_reset_gts.reset
	);
	
	emif_calib emif_calib_inst (
		.pll_calbus_0          (pll_calbus),         //  output,  width = 58,      calbus_pll_0.calbus
		.pll_calbus_readdata_0 (pll_calbus_rd),      //   input,  width = 32,                  .calbus_readdata
		.s0_axi4lite_clk       (i_clk_tod),          //   input,   width = 1,   s0_axi4lite_clk.clk
		.s0_axi4lite_rst_n     (i_tod_rst_n),           //   input,   width = 1, s0_axi4lite_rst_n.reset_n
		.s0_axi4lite_awaddr    (s0_axi4lite_awaddr  ), //   input,  width = 27,       s0_axi4lite.awaddr
		.s0_axi4lite_awvalid   (s0_axi4lite_awvalid ), //   input,   width = 1,                  .awvalid
		.s0_axi4lite_awready   (s0_axi4lite_awready ), //  output,   width = 1,                  .awready
		.s0_axi4lite_araddr    (s0_axi4lite_araddr  ), //   input,  width = 27,                  .araddr
		.s0_axi4lite_arvalid   (s0_axi4lite_arvalid ), //   input,   width = 1,                  .arvalid
		.s0_axi4lite_arready   (s0_axi4lite_arready ), //  output,   width = 1,                  .arready
		.s0_axi4lite_wdata     (s0_axi4lite_wdata   ), //   input,  width = 32,                  .wdata
		.s0_axi4lite_wvalid    (s0_axi4lite_wvalid  ), //   input,   width = 1,                  .wvalid
		.s0_axi4lite_wready    (s0_axi4lite_wready  ), //  output,   width = 1,                  .wready
		.s0_axi4lite_rresp     (s0_axi4lite_rresp   ), //  output,   width = 2,                  .rresp
		.s0_axi4lite_rdata     (s0_axi4lite_rdata   ), //  output,  width = 32,                  .rdata
		.s0_axi4lite_rvalid    (s0_axi4lite_rvalid  ), //  output,   width = 1,                  .rvalid
		.s0_axi4lite_rready    (s0_axi4lite_rready  ), //   input,   width = 1,                  .rready
		.s0_axi4lite_bresp     (s0_axi4lite_bresp   ), //  output,   width = 2,                  .bresp
		.s0_axi4lite_bvalid    (s0_axi4lite_bvalid  ), //  output,   width = 1,                  .bvalid
		.s0_axi4lite_bready    (s0_axi4lite_bready  ), //   input,   width = 1,                  .bready
		.s0_axi4lite_awprot    (s0_axi4lite_awprot  ), //   input,   width = 3,                  .awprot
		.s0_axi4lite_arprot    (s0_axi4lite_arprot  ), //   input,   width = 3,                  .arprot
		.s0_axi4lite_wstrb     (s0_axi4lite_wstrb   ) //   input,   width = 4,                  .wstrb
	);



end
	else begin : MTOD_GEN_PPS_BASIC_MODE
        // -----------------------------------------------
        // Master TOD
        intel_eth_gts_master_tod  #(
		  .PPS_PULSE_ASSERT_CYCLE_MASTER (PPS_PULSE_ASSERT_CYCLE_MASTER),
		  .DEFAULT_NSEC_PERIOD           (DEFAULT_NSEC_PERIOD),
		  .DEFAULT_FNSEC_PERIOD          (DEFAULT_FNSEC_PERIOD),
		  .DEFAULT_NSEC_ADJPERIOD        (DEFAULT_NSEC_ADJPERIOD),
		  .DEFAULT_FNSEC_ADJPERIOD       (DEFAULT_FNSEC_ADJPERIOD)
		  )mtod (
            .clk                         (i_clk_reconfig),
            .rst_n                       (i_reconfig_rst_n),
            .period_clk                  (i_clk_tod),
            .period_rst_n                (i_tod_rst_n),
            .csr_address                 (i_csr_addr),
            .csr_write                   (i_csr_write),
            .csr_writedata               (i_csr_writedata),
            .csr_read                    (i_csr_read),
            .csr_readdata                (o_csr_readdata),
            .csr_waitrequest             (o_csr_waitrequest),
            .time_of_day_96b_load_valid  (i_tod_96b_load_valid),
            .time_of_day_96b_load_data   (i_tod_96b_load_data),
            .time_of_day_64b_load_valid  (1'b0),
            .time_of_day_64b_load_data   (64'h0),
            .time_of_day_96b             (o_tod_96b_data),
            .time_of_day_64b             (),
            // PPS interface
            .pps_pulse_per_second        (o_pps)
        );
    end
    endgenerate

    always @(posedge i_clk_tod) begin
        csr_tod_load_d  <= csr_tod_load;
        csr_tod_load_2d <= csr_tod_load_d;
     end
    // -----------------------------------------------
    // synchronizers
    intel_eth_gts_altera_std_synchronizer_nocut csr_tod_load_sync_inst (
        .clk        (i_clk_tod),
        .reset_n    (1'b1),
        .din        (csr_tod_load_2d),
        .dout       (csr_tod_load_sync)
    );
    // -----------------------------------------------
    // TOD valid generator
    localparam MTOD_CSR_ADDR_SECONDH = 4'h0;
    localparam S_IDLE                = 4'h0;
    localparam S_WAIT_LOAD           = 4'h1;
    localparam S_TOD_VALID           = 4'h2;
    localparam WAIT_CNT_CSR_LOAD     = 8'd100;  
    localparam WAIT_CNT_INT_LOAD     = 8'd10;  

    logic [3:0]   todv_state;
    logic [7:0]   wait_cnt;
    
     always @(posedge i_clk_reconfig) begin
         if (~i_reconfig_rst_n)
             csr_tod_load <= 1'b0;
         else
             csr_tod_load <= (i_csr_write && i_csr_addr == MTOD_CSR_ADDR_SECONDH);
     end
	  
    always @ (posedge i_clk_tod) begin
        if (~i_tod_rst_n) begin
            o_tod_96b_valid <= 1'b0;
            todv_state      <= S_IDLE;
            wait_cnt        <= 8'h0;   
        end
        else begin
            o_tod_96b_valid    <= (todv_state == S_TOD_VALID) ? 1'b1 : 1'b0;
            
            case (todv_state)
            S_IDLE: begin
                todv_state  <= S_TOD_VALID;
            end
            S_WAIT_LOAD: begin
                if (i_tod_96b_load_valid)   wait_cnt    <= WAIT_CNT_INT_LOAD;
                else if (csr_tod_load_sync) wait_cnt    <= WAIT_CNT_CSR_LOAD;
                else                        wait_cnt    <= wait_cnt - 8'h1;
                
                if (wait_cnt == 0) todv_state <= S_TOD_VALID;
                else               todv_state <= todv_state;
            end
            S_TOD_VALID: begin
                if (i_tod_96b_load_valid) begin
                    todv_state  <= S_WAIT_LOAD;
                    wait_cnt    <= WAIT_CNT_INT_LOAD;
                end
                else if (csr_tod_load_sync) begin
                    todv_state  <= S_WAIT_LOAD;
                    wait_cnt    <= WAIT_CNT_CSR_LOAD;
                end
                else begin
                    todv_state  <= S_TOD_VALID;
                end
            end
            default: begin
                todv_state      <= S_IDLE;
            end    
            endcase
        end // else
    end

endmodule : intel_eth_gts_ptp_mtod_top

`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "mXypBqYlC5tPHKvGSz/OgELAzHpeDTMVm92T/G3Tu+Mtj/QKjdPq2C/7YjmBqURd42eqxLEPm5ROnJvj36ncaaR8Sspj9hTF+smYtFdsh6vMrIn7I2ujp7BRjzYw5I2AvAOQAp7snnaPLlJ7h0AspRt5h+aoUWOpH7IAlafE9plfycmjleDqZQRYeY5Pocjbv9fsy1/Wfhpiv3JjywCi+32tfuLfNErYoFt3ZHZNJfE3rymVOo6sG6SLlEBSaMLSFP2DP79qt6QCxBJOlkRNq/VfEr1s0IX2zEgK7oZ4+xbnYzIu+R7kEW7t0yGXjzmkeztBMhoPNbpXlwIn4e6rTmGGUI9kLWBbDZ2j5NDL3cEykJB8B/LUIfA9GMB0c/a36S7ssdvwKvd8T8SghK3CcEmO29E7uDnlkirfTgwe+NTB6cdMYAgomKgyQ8UZvqJ4Ro5BSHVivUgSBukWocYS0fwQEBM1svGRZlAfNCrcq3ag3Hv73qekmzDLweYHTun+CHcsTEltmKYEEtOHheIvaqGprMpQw8NKK4dZ9eMcIiASrTOXIdtdoGVVvsvgQffS7+gYHsE4VzFo1xK7qBrz5SNHoy/Xj+GY6CpIi68sqM9neGviBF6T0Fe5hOFgjLwyPBanWAX5ulsmAEMwCpnV8el0kNOqUL4UNPDWfIXq5P0i3ZBts0p0V/HHMOQacKYW9HPUTLfB7ogEQabB5v87DM9M6LHTgnrpvj5azpbpaQPPvOJW5wocujg6Twt2+v+Cq4TPt27X14tFcWlWHlzi/b6iDTRY7pbjsxCA0KMrKWjyjSUMgFu7tAOt55oeBU5UBLhCB5cU06FuYRyttLgWJ4f/O2AB6IBd/heqd4Be7iwO9fFQ+Rwb+iw+0/uoJ7j1sjlsxjKarw7Hx2Uwfj8o0ji1oNKiHPIxrfa5t8QBnm3Ivk4t2TJ0iH7Xy5+9+izCxLRUnpg5/X8MqcAhfwK3RoLA4LU4iaEgzXXGz3FTtEti3XWHu8Zfo+tV8MDnLOpf"
`endif
