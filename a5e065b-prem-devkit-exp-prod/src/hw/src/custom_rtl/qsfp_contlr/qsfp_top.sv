
// ######################################################################## 
// Copyright (C) 2025 Altera Corporation.
// SPDX-License-Identifier: MIT
// ######################################################################## 
// -------------------------------------------------------------------------- #

//
// Engineer     : 
// Create Date  :
// Module Name  : qsfp_top.sv
// Project      : SM_PTP
// -----------------------------------------------------------------------------
//
// Description: 
// qsfp_controller top module instantiates all sub modules
// implementes AVMM address decoding logic


module qsfp_top  #(
   
   parameter NUM_QSFP   = 2,
   parameter ADDR_WIDTH = 14,                         // To accomodate max no.of qsfp(x1000,0x2000)
   parameter DATA_WIDTH = 64,
   parameter A0_PAGE_END_ADDR  = 128,
   parameter NUM_PG_SUPPORT    = 4
)(
   input  logic               clk,                   
   input  logic               reset,
   input  wire [NUM_QSFP-1:0] modprsn,                // Active Low Qsfp module present, asynchronous reset  
   input  wire                int_qsfp,               // Active Low Qsfp interrupt, Read by com csr as active high.
    
   input  wire                i2c_0_i2c_serial_sda_in,
   input  wire                i2c_0_i2c_serial_scl_in,
   output wire                i2c_0_i2c_serial_sda_oe,  
   output wire                i2c_0_i2c_serial_scl_oe,
   output wire [NUM_QSFP-1:0] modsel,               // Drive inverted value of modsel to actual qsfp module
   output wire [NUM_QSFP-1:0] lpmode,
   output wire [NUM_QSFP-1:0] softresetqsfpm,        // Drive inverted value of config_softresetqsfpm to actual qsfp module
   input   wire [7:0]         axi_bdg_s0_awid,             //    axi_bdg_s0.awid
   input   wire [ADDR_WIDTH-1:0] axi_bdg_s0_awaddr,        //              .awaddr
   input   wire [7:0]         axi_bdg_s0_awlen,            //              .awlen
   input   wire [2:0]         axi_bdg_s0_awsize,           //              .awsize
   input   wire [1:0]         axi_bdg_s0_awburst,          //              .awburst
   input   wire [0:0]         axi_bdg_s0_awlock,           //              .awlock
   input   wire [3:0]         axi_bdg_s0_awcache,          //              .awcache
   input   wire [2:0]         axi_bdg_s0_awprot,           //              .awprot
   input   wire               axi_bdg_s0_awvalid,          //              .awvalid
   output  wire               axi_bdg_s0_awready,          //              .awready
   input   wire [63:0]        axi_bdg_s0_wdata,            //              .wdata
   input   wire [7:0]         axi_bdg_s0_wstrb,            //              .wstrb
   input   wire               axi_bdg_s0_wlast,            //              .wlast
   input   wire               axi_bdg_s0_wvalid,           //              .wvalid
   output  wire               axi_bdg_s0_wready,           //              .wready
   output  wire [7:0]         axi_bdg_s0_bid,              //              .bid
   output  wire [1:0]         axi_bdg_s0_bresp,            //              .bresp
   output  wire               axi_bdg_s0_bvalid,           //              .bvalid
   input   wire               axi_bdg_s0_bready,           //              .bready
   input   wire [7:0]         axi_bdg_s0_arid,             //              .arid
   input   wire [13:0]        axi_bdg_s0_araddr,           //              .araddr
   input   wire [7:0]         axi_bdg_s0_arlen,            //              .arlen
   input   wire [2:0]         axi_bdg_s0_arsize,           //              .arsize
   input   wire [1:0]         axi_bdg_s0_arburst,          //              .arburst
   input   wire [0:0]         axi_bdg_s0_arlock,           //              .arlock
   input   wire [3:0]         axi_bdg_s0_arcache,          //              .arcache
   input   wire [2:0]         axi_bdg_s0_arprot,           //              .arprot
   input   wire               axi_bdg_s0_arvalid,          //              .arvalid
   output  wire               axi_bdg_s0_arready,          //              .arready
   output  wire [7:0]         axi_bdg_s0_rid,              //              .rid
   output  wire [63:0]        axi_bdg_s0_rdata,            //              .rdata
   output  wire [1:0]         axi_bdg_s0_rresp,            //              .rresp
   output  wire               axi_bdg_s0_rlast,            //              .rlast
   output  wire               axi_bdg_s0_rvalid,           //              .rvalid
   input   wire               axi_bdg_s0_rready,           //              .rready      
   input   logic              stp_clk
);

   localparam  ADDR_WIDTH_COM_CSR     = 8;               // to accomodate 0x00,0x10,0x20,0x30,0x80,0x88,0x90
   localparam  ADDR_WIDTH_QSFP_REG    = 8;               // Each page has 256Bytes of Data. So 8 no.of addr bits are required.
   localparam  ADDR_WIDTH_SHADOW_REG  = 8;
   localparam  DATA_WIDTH_I2C_MSTR    = 32;              // I2C Mstr is having 32bit data, So address will be word address.
   localparam  SINK_DATA_WIDTH        = 16;
   localparam  SRC_DATA_WIDTH         = 8;
//-------------------------------------------------------------------
// Signals

   logic [11:0]                        byte_offset_address;// The address value got from tfr_cmds, this value%8 gives byte_psn
   logic [2:0]                         count_sink_data;  // counter to count the no.of tfr_cmds values=0...6 [2a0,07f,100,2a0,000,2a1,000]                  

   logic [NUM_QSFP-1:0]                modprsn_sync;
   logic                               reset_hard_soft_sync;
   //Poller FSM signals --------------------------------------------
   logic [NUM_QSFP-1:0][31:0]          delay_csr_in;
   //logic [31:0]                        delay_csr_in_poll;
   logic [NUM_QSFP-1:0][31:0]          delay_csr_in_com;
   logic                               wren_logic;
   logic                               rd_done;
   logic [ADDR_WIDTH_QSFP_REG-1:0]     curr_rd_addr; 
   logic [7:0]                         curr_rd_page;
   logic [3:0]                         curr_fsm_state;
   logic                               read_timeout_fsm_flag;
   logic                               rd_done_ack;
   logic                               wr_cnt_rst;
   logic                               waitrequest;
   // Common csr signals --------------------------------------------
   logic [NUM_QSFP-1:0][DATA_WIDTH-1:0]                  qsfp_com_csr_writedata;
   logic [NUM_QSFP-1:0]                                  qsfp_com_csr_read;
   logic [NUM_QSFP-1:0]                                  qsfp_com_csr_write;
   logic [NUM_QSFP-1:0][DATA_WIDTH-1:0]                  qsfp_com_csr_readdata;
   logic [NUM_QSFP-1:0]                                  qsfp_com_csr_readdatavalid;
   logic [NUM_QSFP-1:0][ADDR_WIDTH_COM_CSR-1:0]          qsfp_com_csr_address;
   logic                               com_csr_read;
   logic                               com_csr_write;
   logic [DATA_WIDTH-1:0]              csr_readdata_comcsr;
   logic                               csr_readdata_valid_comcsr;
   logic [DATA_WIDTH-1:0]              csr_readdata_comcsr_dly1;
   logic                               csr_readdata_valid_comcsr_dly1;
   logic [DATA_WIDTH-1:0]              csr_readdata_comcsr_dly2;
   logic                               csr_readdata_valid_comcsr_dly2;
   logic [DATA_WIDTH-1:0]              csr_readdata_ocm2s1;
   logic                               csr_readdata_valid_ocm2s1;

    // config signals-------------------------------------------------
   logic [NUM_QSFP-1:0]                config_poll_en;  
   logic [NUM_QSFP-1:0]                config_poll_en_com;  // Reg for storing poll_en of each qsfps. One bit reg for each qsfp. This value is not known to another qsfp com csr.
   logic [NUM_QSFP-1:0]                poll_en_sts_reg;     // Reg for storing poll_en of every qsfps. 16 bit reg for each qsfp. This value is  known to another qsfp com csr.
    integer                             index;
    logic                                       poll_en_start;
   logic                                        poll_en_stop;
   logic                                        poll_en_stop_tmp='1; // Initial value of And operand is 1 
    logic [NUM_QSFP-1:0]                config_softresetqsfpc;
    logic [NUM_QSFP-1:0]                config_softresetqsfpc_com;
    logic                               reset_hard_soft;
   logic [NUM_QSFP-1:0]                config_softresetqsfpm_com;
   logic [NUM_QSFP-1:0]                config_softresetqsfpm;
   // poller_fsm signals---------------------------------------------   
   logic                               fsm_paused;
   logic                               init_done;
   logic [NUM_QSFP-1:0]                modsel_common_csr;
   logic [NUM_QSFP-1:0]                modsel_common_csr_com;
   logic [NUM_QSFP-1:0]                modsel_poller_fsm;
    // I2C Mstr signals-- Single instance is only using---------------- 
   logic [3:0]                         i2c_0_csr_address;
   logic                               i2c_0_csr_read;
   logic                               i2c_0_csr_write;
   logic [DATA_WIDTH/8-1:0]            csr_byteenable_bkp;
   logic [DATA_WIDTH/8-1:0]            csr_byteenable_bkp1;
   logic                               com_csr_unused;
   logic [DATA_WIDTH_I2C_MSTR-1:0]     i2c_0_csr_writedata;
   logic [DATA_WIDTH_I2C_MSTR-1:0]     i2c_0_csr_readdata;
   logic                               i2c_0_csr_readdata_valid;
   logic                               i2c_0_csr_readdata_valid_dly;
   logic                               i2c_0_csr_read_q;
   logic [DATA_WIDTH-1:0]              i2c_0_csr_writedata_64;
   logic [DATA_WIDTH-1:0]              i2c_0_csr_readdata_64;
   logic                               src_valid;
   logic [SRC_DATA_WIDTH-1:0]          src_data;
   logic                               src_ready;
   logic [NUM_QSFP-1:0]                src_ready_com;
   logic [SINK_DATA_WIDTH-1:0]         sink_data;
   logic                               sink_valid;
   logic                               sink_ready;
   logic [NUM_QSFP-1:0]                sink_ready_com;
   logic                               status_int_i2c_i;
   logic                               tx_err;
   logic                               rx_err;
   logic                               poll_sel;
  
   // Shadow reg signals---Read interface to S/m level csr space--------
    //Array signals for multiple qsfps, meant for 2nd level filter [13:12] check
    logic [NUM_QSFP-1:0]                                qsfp_cntrl_onchip_memory2_s1_read;  
    logic [NUM_QSFP-1:0][ADDR_WIDTH_SHADOW_REG-1:0]     qsfp_cntrl_onchip_memory2_s1_address;      
    logic [NUM_QSFP-1:0]                                qsfp_cntrl_onchip_memory2_s1_write;
    logic [NUM_QSFP-1:0][DATA_WIDTH-1:0]                qsfp_cntrl_onchip_memory2_s1_readdata;      
    logic [NUM_QSFP-1:0]                                qsfp_cntrl_onchip_memory2_s1_readdata_valid;
    // 1D signals from common path, meant for 1st level filter [11:6] check
    logic                                               onchip_memory2_s1_read; 
    logic                                               onchip_memory2_s1_write;
    
    // Csr write logic -> Shadow reg mem write --------------------------
    //Array signals for multiple qsfps, meant for 2nd level filter [13:12] check
   logic [NUM_QSFP-1:0]                             shadow_mem_wren;
   logic [NUM_QSFP-1:0][DATA_WIDTH-1:0]             shadow_mem_wdata;
   logic [NUM_QSFP-1:0][ADDR_WIDTH_SHADOW_REG-1:0]  shadow_mem_waddr;
   logic [NUM_QSFP-1:0]                             shadow_mem_chipsel;
    // Below signals are coming from csr write     
   logic                                            mem_wren;
   logic [DATA_WIDTH-1:0]                           mem_wdata;
   logic [ADDR_WIDTH_SHADOW_REG-1:0]                mem_waddr;
   logic                                            mem_chipsel;
   
    integer                                         i;
    integer                                         l;
    integer                                         m;
    integer                                         i_ocm;
   integer                                         i_com;
    logic                                                           readdatavalid_xor;
    logic [NUM_QSFP-1:0]                            lpmode_com;
    logic [NUM_QSFP-1:0]                            int_qsfp_reg;
//    logic                                                       tfr_cmd_done_modsel;
    logic                                           modsel_set;
    
  logic [DATA_WIDTH-1:0]       csr_readdata;     
  logic                        csr_readdata_valid; 
  logic [DATA_WIDTH-1:0]       csr_wdata;     
  logic [ADDR_WIDTH-1:0]       csr_addr;       
  logic                        csr_write;         
  logic                        csr_read;
  logic                        csr_waitreq;
  logic [DATA_WIDTH/8-1:0]     csr_byteenable;
  logic                        csr_burstcount;
  logic                        csr_debugaccess;
  
  logic [NUM_QSFP-1:0]        status_a0_update_rdy_to_start_com;
  logic [NUM_QSFP-1:0]        status_a0_update_in_progress_com ;
  logic [NUM_QSFP-1:0]        status_a0_page_read_complete_com ;
  logic [NUM_QSFP-1:0]        status_a0_page_read_error_com    ;   
  logic [NUM_QSFP-1:0]        reset_a0_update_config_bit_com   ;  
  logic [NUM_QSFP-1:0]        config_update_a0_page_com        ;
  logic [NUM_QSFP-1:0]        lower_page_rd_compl_com          ;
  logic                       status_a0_update_rdy_to_start    ;
  logic                       status_a0_update_in_progress     ;
  logic                       status_a0_page_read_complete     ;
  logic                       status_a0_page_read_error        ;   
  logic                       reset_a0_update_config_bit       ;  
  logic                       config_update_a0_page            ;
  logic                       lower_page_rd_compl              ;
 
axi_to_avmm_qsfp_cntlr u0 (
        .avmm_bdg_0_m0_waitrequest   (csr_waitreq),   //   input,   width = 1, avmm_bdg_0_m0.waitrequest
        .avmm_bdg_0_m0_readdata      (csr_readdata),      //   input,  width = 64,              .readdata
        .avmm_bdg_0_m0_readdatavalid (csr_readdata_valid), //   input,   width = 1,              .readdatavalid
        .avmm_bdg_0_m0_burstcount    (csr_burstcount),    //  output,   width = 1,              .burstcount
        .avmm_bdg_0_m0_writedata     (csr_wdata),     //  output,  width = 64,              .writedata
        .avmm_bdg_0_m0_address       (csr_addr),       //  output,  width = 14,              .address
        .avmm_bdg_0_m0_write         (csr_write),         //  output,   width = 1,              .write
        .avmm_bdg_0_m0_read          (csr_read),          //  output,   width = 1,              .read
        .avmm_bdg_0_m0_byteenable    (csr_byteenable),    //  output,   width = 8,              .byteenable
        .avmm_bdg_0_m0_debugaccess   (csr_debugaccess),   //  output,   width = 1,              .debugaccess
        .axi_bdg_s0_awid             (axi_bdg_s0_awid),             //   input,   width = 8,    axi_bdg_s0.awid
        .axi_bdg_s0_awaddr           (axi_bdg_s0_awaddr),           //   input,  width = 14,              .awaddr
        .axi_bdg_s0_awlen            (axi_bdg_s0_awlen),            //   input,   width = 8,              .awlen
        .axi_bdg_s0_awsize           (axi_bdg_s0_awsize),           //   input,   width = 3,              .awsize
        .axi_bdg_s0_awburst          (axi_bdg_s0_awburst),          //   input,   width = 2,              .awburst
        .axi_bdg_s0_awlock           (axi_bdg_s0_awlock),           //   input,   width = 1,              .awlock
        .axi_bdg_s0_awcache          (axi_bdg_s0_awcache),          //   input,   width = 4,              .awcache
        .axi_bdg_s0_awprot           (axi_bdg_s0_awprot),           //   input,   width = 3,              .awprot
        .axi_bdg_s0_awvalid          (axi_bdg_s0_awvalid),          //   input,   width = 1,              .awvalid
        .axi_bdg_s0_awready          (axi_bdg_s0_awready),          //  output,   width = 1,              .awready
        .axi_bdg_s0_wdata            (axi_bdg_s0_wdata),            //   input,  width = 64,              .wdata
        .axi_bdg_s0_wstrb            (axi_bdg_s0_wstrb),            //   input,   width = 8,              .wstrb
        .axi_bdg_s0_wlast            (axi_bdg_s0_wlast),            //   input,   width = 1,              .wlast
        .axi_bdg_s0_wvalid           (axi_bdg_s0_wvalid),           //   input,   width = 1,              .wvalid
        .axi_bdg_s0_wready           (axi_bdg_s0_wready),           //  output,   width = 1,              .wready
        .axi_bdg_s0_bid              (axi_bdg_s0_bid),              //  output,   width = 8,              .bid
        .axi_bdg_s0_bresp            (axi_bdg_s0_bresp),            //  output,   width = 2,              .bresp
        .axi_bdg_s0_bvalid           (axi_bdg_s0_bvalid),           //  output,   width = 1,              .bvalid
        .axi_bdg_s0_bready           (axi_bdg_s0_bready),           //   input,   width = 1,              .bready
        .axi_bdg_s0_arid             (axi_bdg_s0_arid),             //   input,   width = 8,              .arid
        .axi_bdg_s0_araddr           (axi_bdg_s0_araddr),           //   input,  width = 14,              .araddr
        .axi_bdg_s0_arlen            (axi_bdg_s0_arlen),            //   input,   width = 8,              .arlen
        .axi_bdg_s0_arsize           (axi_bdg_s0_arsize),           //   input,   width = 3,              .arsize
        .axi_bdg_s0_arburst          (axi_bdg_s0_arburst),          //   input,   width = 2,              .arburst
        .axi_bdg_s0_arlock           (axi_bdg_s0_arlock),           //   input,   width = 1,              .arlock
        .axi_bdg_s0_arcache          (axi_bdg_s0_arcache),          //   input,   width = 4,              .arcache
        .axi_bdg_s0_arprot           (axi_bdg_s0_arprot),           //   input,   width = 3,              .arprot
        .axi_bdg_s0_arvalid          (axi_bdg_s0_arvalid),          //   input,   width = 1,              .arvalid
        .axi_bdg_s0_arready          (axi_bdg_s0_arready),          //  output,   width = 1,              .arready
        .axi_bdg_s0_rid              (axi_bdg_s0_rid),              //  output,   width = 8,              .rid
        .axi_bdg_s0_rdata            (axi_bdg_s0_rdata),            //  output,  width = 64,              .rdata
        .axi_bdg_s0_rresp            (axi_bdg_s0_rresp),            //  output,   width = 2,              .rresp
        .axi_bdg_s0_rlast            (axi_bdg_s0_rlast),            //  output,   width = 1,              .rlast
        .axi_bdg_s0_rvalid           (axi_bdg_s0_rvalid),           //  output,   width = 1,              .rvalid
        .axi_bdg_s0_rready           (axi_bdg_s0_rready),           //   input,   width = 1,              .rready
        .clk_clk                     (clk),                     //   input,   width = 1,           clk.clk
        .reset_reset                 (reset)                  //   input,   width = 1,         reset.reset
    );
   
    always @(*) begin            
                if(reset_hard_soft_sync) 
                    waitrequest = 1'b1; 
                else if(csr_write | csr_read) 
                    waitrequest = 1'b0; 
                else 
                    waitrequest = 1'b1; 
         end
 
    assign csr_waitreq           = waitrequest;
    assign reset_hard_soft       = reset || (|config_softresetqsfpc[NUM_QSFP-1:0]);
    assign config_softresetqsfpm = reset? '0: config_softresetqsfpm_com;
    assign config_softresetqsfpc = reset? '0: config_softresetqsfpc_com;
    assign modsel_common_csr     = reset? '0: modsel_common_csr_com;
    assign lpmode                = lpmode_com;
    assign config_poll_en        = reset? '0: config_poll_en_com;
   
    

  
    
// Creation of poll_en_sts_reg----------------------------------------------------------------------------------------------------------//
// The sts_reg should always be the latest poll_en sts, so feed values on every clk-----------------------------------------------------// 
always @(posedge clk) begin
  if(reset_hard_soft_sync) begin 
  poll_en_sts_reg <= '0;
  index <= 0;end
  else  begin
     if(index == NUM_QSFP-1) 
     index <= 0; 
     else
     index <= index+1;
 poll_en_sts_reg[index] <=config_poll_en[index] ;end
 end
 
// Creation of poll_en_start------------------------------------------------------------------------------------------------------------//
// OR of each elt of poll_en_sts_reg register
   // ORing, so that if pll_en_0 is active and poll_en_1 is inactive, poll_en becomes 1. 
    // And Poller fsm will fetch data from QSFP0 using modesel0. Modesel is 0 for QSFP1. Using modesel as a select signal for demux, 
    // corresponding rx data fifo values will be going to Com_CSR_0 and won't go to com_csr_1. 
    // So unique poll_en for each qsfp is implemented here. So poller fsm will start if any of the poll_en becomes 1. 
    // So start cdn for poller fsm is OR of poll_en0 and poll_en1. --------------------------//
    assign poll_en_start = | poll_en_sts_reg;

// Creation of poll_en_stop-------------------------------------------------------------//   
// check every elt of poll_en_sts_reg. If every elts are zero, then poll_en_stop=1.
    assign poll_en_stop = ~ poll_en_start;  
    assign softresetqsfpm  = config_softresetqsfpm ;

    
   assign tx_err            = ~sink_ready && sink_valid;     
   assign rx_err            = ~src_ready & src_valid & sink_data[0] & sink_data[9] ; 
// Synchronizing modprsn reset---------------------------------------------
   always @(posedge clk) begin
     if(reset_hard_soft) begin
        modprsn_sync <= {NUM_QSFP{1'b1}};
        reset_hard_soft_sync <= 1; end    //by default, reset_hard_soft_sync should be 1.
     else begin
        modprsn_sync <=  modprsn;
        reset_hard_soft_sync <= reset_hard_soft; end
   end      
//---------------Assignment of Common csr, Shadow csr, Csr_write signals ---------------------------------------------- 
   
     
   generate for(genvar j=0;j<NUM_QSFP;j++) begin : gen_signal_inst
       // QSFP_0 is having address of 0x4404_1000,QSFP_1 is having address of 0x4404_2000
       // checking addr[13:12] for select between qsfps. QSFP0 for [13:12]= 01, QSFP1 for [13:12]=10
        // checking csr_addr[ADDR_WIDTH-1:12] with genvar i
        // when i =0, QSFP0 has to select, having addr of "01", inorder to match with i, use addr-1 as the checker to comapre with i
       assign qsfp_com_csr_address[j]  = (csr_addr[ADDR_WIDTH-1] == j)? csr_addr[ADDR_WIDTH_COM_CSR-1:0]:0;// byte address, changed from [5:0] to [7:0] to accomodate 0x00,0x10,0x20,0x30,0x80,0x88,0x90
       assign qsfp_com_csr_read[j]     = (csr_addr[ADDR_WIDTH-1] == j)? com_csr_read:0 ;                                                                                                                                       
       assign qsfp_com_csr_write[j]    = (csr_addr[ADDR_WIDTH-1] == j)? com_csr_write:0 ;
       assign qsfp_com_csr_writedata[j]= csr_wdata;
        
     // ------------System level user space CSR - Shadow reg csr path---------------------- 
       assign qsfp_cntrl_onchip_memory2_s1_address[j]     = (csr_addr[ADDR_WIDTH-1] == j)? csr_addr[10:3]-8'h20 :'0;         // Each address is for 64-bit data -- Adress translation from 0x100 to 0x00 (which is local offset)        
       assign qsfp_cntrl_onchip_memory2_s1_read[j]        = (csr_addr[ADDR_WIDTH-1] == j)? onchip_memory2_s1_read: 0 ; // Bits of lsb has been removed from addr, since 3 bits{2,1,0} stans for 2^3=8B=64bit 
       assign qsfp_cntrl_onchip_memory2_s1_write[j]       = (csr_addr[ADDR_WIDTH-1] == j)? onchip_memory2_s1_write: 0 ;

       assign int_qsfp_reg[j]       = int_qsfp;
	   assign src_ready_com[j]      = (csr_addr[ADDR_WIDTH-1] == j) ? src_ready : 0;
	   assign sink_ready_com[j]     = (csr_addr[ADDR_WIDTH-1] == j) ? sink_ready : 0;
	
   
    end endgenerate
    assign modsel = poll_sel ? 2'b01 : 2'b10;
	
  assign csr_readdata_comcsr = (csr_addr[ADDR_WIDTH-1] == 1)? qsfp_com_csr_readdata[1] : qsfp_com_csr_readdata[0];
  assign csr_readdata_valid_comcsr = (csr_addr[ADDR_WIDTH-1] == 1)? qsfp_com_csr_readdatavalid[1] : qsfp_com_csr_readdatavalid[0];
  assign csr_readdata_ocm2s1 = (csr_addr[ADDR_WIDTH-1] == 1)? qsfp_cntrl_onchip_memory2_s1_readdata[1] : qsfp_cntrl_onchip_memory2_s1_readdata[0];
  assign csr_readdata_valid_ocm2s1 = (csr_addr[ADDR_WIDTH-1] == 1)? qsfp_cntrl_onchip_memory2_s1_readdata_valid[1] : qsfp_cntrl_onchip_memory2_s1_readdata_valid[0];

wire switch_to_next_qsfp;

always_ff @(posedge clk) begin 
  if (reset) 
  begin
    poll_sel           <= 1'b0;
    shadow_mem_wren    <= '0 ;
    shadow_mem_waddr   <= '0 ;
    shadow_mem_chipsel <= '0 ; 
    shadow_mem_wdata   <= '0 ; 	
    lower_page_rd_compl_com <= '0;	 
  end
  else  
  begin
    case(modsel_common_csr)
	2'b00:
	  begin
	    poll_sel           <= 1'b0;
        shadow_mem_wren    <= '0 ;
        shadow_mem_waddr   <= '0 ;
        shadow_mem_chipsel <= '0 ; 
        shadow_mem_wdata   <= '0 ; 	  
        status_a0_update_rdy_to_start_com  <= '0;
        status_a0_update_in_progress_com   <= '0;
        status_a0_page_read_complete_com   <= '0;
        status_a0_page_read_error_com      <= '0;
        reset_a0_update_config_bit_com     <= '0;
        config_update_a0_page              <= '0;
		  lower_page_rd_compl_com            <= '0;            
	  end
	
	2'b01:
	  begin
	    poll_sel              <= 1'b0;
        shadow_mem_wren   [0] <= mem_wren    ;
        shadow_mem_waddr  [0] <= mem_waddr   ;
        shadow_mem_chipsel[0] <= mem_chipsel ; 
        shadow_mem_wdata  [0] <= mem_wdata   ; 	  
        shadow_mem_wren   [1] <= 1'b0 ;
        shadow_mem_waddr  [1] <= '0 ;
        shadow_mem_chipsel[1] <= 1'b0 ; 
        shadow_mem_wdata  [1] <= '0 ; 	  
        status_a0_update_rdy_to_start_com[0] <= status_a0_update_rdy_to_start ;
        status_a0_update_in_progress_com [0] <= status_a0_update_in_progress  ;
        status_a0_page_read_complete_com [0] <= status_a0_page_read_complete  ;
        status_a0_page_read_error_com    [0] <= status_a0_page_read_error     ;   
        reset_a0_update_config_bit_com   [0] <= reset_a0_update_config_bit  ;  
        config_update_a0_page                <= config_update_a0_page_com[0]        ;
		  lower_page_rd_compl_com          [0] <= lower_page_rd_compl;
	  end
	
	2'b10:
	  begin
	    poll_sel           <= 1'b1;
        shadow_mem_wren   [0] <= 1'b0 ;
        shadow_mem_waddr  [0] <= '0 ;
        shadow_mem_chipsel[0] <= 1'b0 ; 
        shadow_mem_wdata  [0] <= '0 ; 	  
        shadow_mem_wren   [1] <= mem_wren    ;
        shadow_mem_waddr  [1] <= mem_waddr   ;
        shadow_mem_chipsel[1] <= mem_chipsel ; 
        shadow_mem_wdata  [1] <= mem_wdata   ; 	  
        status_a0_update_rdy_to_start_com[1] <= status_a0_update_rdy_to_start ;
        status_a0_update_in_progress_com [1] <= status_a0_update_in_progress  ;
        status_a0_page_read_complete_com [1] <= status_a0_page_read_complete  ;
        status_a0_page_read_error_com    [1] <= status_a0_page_read_error     ;   
        reset_a0_update_config_bit_com   [1] <= reset_a0_update_config_bit    ;  
        config_update_a0_page                <= config_update_a0_page_com[1]  ;
		  lower_page_rd_compl_com          [1] <= lower_page_rd_compl;
	  end
	
	2'b11:
	  begin
	    if (poll_sel) begin
          shadow_mem_wren   [0] <= 1'b0 ;
          shadow_mem_waddr  [0] <= '0 ;
          shadow_mem_chipsel[0] <= 1'b0 ; 
          shadow_mem_wdata  [0] <= '0 ; 	  
          shadow_mem_wren   [1] <= mem_wren    ;
          shadow_mem_waddr  [1] <= mem_waddr   ;
          shadow_mem_chipsel[1] <= mem_chipsel ; 
          shadow_mem_wdata  [1] <= mem_wdata   ; 	  
		end 
		else
		begin
          shadow_mem_wren   [1] <= 1'b0 ;
          shadow_mem_waddr  [1] <= '0 ;
          shadow_mem_chipsel[1] <= 1'b0 ; 
          shadow_mem_wdata  [1] <= '0 ; 	  
          shadow_mem_wren   [0] <= mem_wren    ;
          shadow_mem_waddr  [0] <= mem_waddr   ;
          shadow_mem_chipsel[0] <= mem_chipsel ; 
          shadow_mem_wdata  [0] <= mem_wdata   ; 	  
		end
        status_a0_update_rdy_to_start_com[poll_sel] <= status_a0_update_rdy_to_start ;
        status_a0_update_in_progress_com [poll_sel] <= status_a0_update_in_progress  ;
        status_a0_page_read_complete_com [poll_sel] <= status_a0_page_read_complete  ;
        status_a0_page_read_error_com    [poll_sel] <= status_a0_page_read_error     ;   
        reset_a0_update_config_bit_com[poll_sel]    <= reset_a0_update_config_bit    ;  
        config_update_a0_page                       <= config_update_a0_page_com[poll_sel]        ;
		  lower_page_rd_compl_com [poll_sel]          <= lower_page_rd_compl;
		if (switch_to_next_qsfp)
		  poll_sel <= (~poll_sel);
	  end
	
    endcase
  end
end


    
    
// Address mapping-----------------------------------------------
//assign i2c_0_csr_address            =  csr_addr[5:2]; // word address (byte address to word address conversion)  
// I2C Mstr contains registers like TFR_CMD, RX_DATA, ISER. All are 32 bits wide regs.                                     
// Write data mapping--------------------------------------------
  assign i2c_0_csr_writedata_64       = csr_wdata;
// I2C controller 64<->32 mapping---------------------------------

always_comb
begin
   if(csr_byteenable== 8'hF0) begin // Upper/Odd 
      i2c_0_csr_writedata = i2c_0_csr_writedata_64[63:32];
        i2c_0_csr_address   = csr_addr[5:2];
        i2c_0_csr_address[0]= 1; end
   else if(csr_byteenable== 8'h0F) begin // Lower/Even
      i2c_0_csr_writedata = i2c_0_csr_writedata_64[31:0];
        i2c_0_csr_address   = csr_addr[5:2]; end
    else begin
       i2c_0_csr_writedata = '0;
        i2c_0_csr_address   = '0; end
end 

// byteenable for read will be valid only on that pulse. During rd_data_vld we need to configure accordinly.
always @(posedge clk) begin
   if(reset_hard_soft_sync)begin 
      csr_byteenable_bkp <='0;
        csr_byteenable_bkp1<='0;end
   else begin 
       csr_byteenable_bkp <= csr_byteenable;
        csr_byteenable_bkp1 <= csr_byteenable_bkp;end
end

  logic rd_data_en, rd_data_en_d1, rd_data_en_d2;
  
  always @(posedge clk) 
   begin
     if(reset_hard_soft_sync)
	 begin 
        rd_data_en    <= 0;
        rd_data_en_d1 <= 0;
        //rd_data_en_d2 <= 0;
	 end
     else 
	 begin 
        if (((csr_byteenable== 8'hF0) && (csr_addr[11:0] == 12'h040)) || ((csr_byteenable== 8'h0F) && (csr_addr[11:0] == 12'h044)))
		  rd_data_en <= csr_read;
		else
		  rd_data_en <= 0;
		  
		rd_data_en_d1 <= rd_data_en;
		//rd_data_en_d2 <= rd_data_en_d1;
	 end
   end
 logic [7:0] rxdata;  
   
   always @(posedge clk) 
   begin
      if(reset_hard_soft_sync)  
         i2c_0_csr_readdata_64 <= '0;
      else
      begin
	    if(csr_byteenable_bkp1== 8'hF0 && i2c_0_csr_readdata_valid)  // Upper/Odd 
            if (rd_data_en_d1)  // Upper/Odd 
               i2c_0_csr_readdata_64 <= {24'h0, rxdata, 32'h0};
	        else
               i2c_0_csr_readdata_64 <= {i2c_0_csr_readdata,32'h0};
        else if(csr_byteenable_bkp1== 8'h0F && i2c_0_csr_readdata_valid)  // Lower/Even
 	        if (rd_data_en_d1)
	           i2c_0_csr_readdata_64 <= {32'h0,24'h0, rxdata};
	        else
              i2c_0_csr_readdata_64 <= {32'h0,i2c_0_csr_readdata};
      end 
   end 
   
   

// Read-Write mapping---------------------------------------------
always_comb
begin
   com_csr_read                     = 1'b0;
   com_csr_write                    = 1'b0;
   onchip_memory2_s1_read           = 1'b0;
   onchip_memory2_s1_write          = 1'b0;
   i2c_0_csr_read                   = 1'b0;
   i2c_0_csr_write                  = 1'b0;
   com_csr_unused                   = 1'b0;
   casez (csr_addr[11:6])
      6'h00,
       6'h02    : begin                                      // Common CSR             -- 0x000 -> 0x030, 0x80,0x88,0x90 
         com_csr_read                     = csr_read;
         com_csr_write                    = csr_write;
         onchip_memory2_s1_read           = 1'b0;
         onchip_memory2_s1_write          = 1'b0;
         i2c_0_csr_read                   = 1'b0;
         i2c_0_csr_write                  = 1'b0;
         com_csr_unused                   = 1'b0;
      end   
      6'h01 : begin                                     // I2C controller CSR      -- 0x040 -> 0x068
         com_csr_read                     = 1'b0;
         com_csr_write                    = 1'b0;
         onchip_memory2_s1_read           = 1'b0;
         onchip_memory2_s1_write          = 1'b0;
         i2c_0_csr_read                   = csr_read;
         i2c_0_csr_write                  = csr_write;
         com_csr_unused                   = 1'b0;
      end
      6'b0001??,6'b001???,
      6'b01????: begin                                  // Shadow register memory    -- 0x100 -> 0x632
         com_csr_read                     = 1'b0;
         com_csr_write                    = 1'b0;
         onchip_memory2_s1_read           = csr_read;
         onchip_memory2_s1_write          = ~csr_read;  // No read signal for OCM, so invert read input to write port
         i2c_0_csr_read                   = 1'b0;
         i2c_0_csr_write                  = 1'b0;
         com_csr_unused                   = 1'b0;
      end
      default: begin
         com_csr_read                     = 1'b0;
         com_csr_write                    = 1'b0;
         onchip_memory2_s1_read           = 1'b0;
         onchip_memory2_s1_write          = 1'b0;
         i2c_0_csr_read                   = 1'b0;
         i2c_0_csr_write                  = 1'b0;
         com_csr_unused                   = 1'b1;
      end
   endcase
end

////Read data Valid generation-----------------------------------------
//always_ff @(posedge clk) begin
//   if(reset_hard_soft_sync) begin
//       i2c_0_csr_readdata_valid           <= 0;
//        i2c_0_csr_read_q                   <= 0;end
//    else  begin
//        i2c_0_csr_read_q                   <= i2c_0_csr_read;                  // 2 clk latency for I2C controller read
//        i2c_0_csr_readdata_valid           <= i2c_0_csr_read_q; end
//end 
//
   //Read data Valid generation-----------------------------------------
   always_ff @(posedge clk) begin
      if(reset_hard_soft_sync) 
	  begin
        i2c_0_csr_readdata_valid     <= 0;
        i2c_0_csr_read_q             <= 0;
		i2c_0_csr_readdata_valid_dly <= 0;
	  end
      else  
	  begin
        i2c_0_csr_read_q             <= i2c_0_csr_read;                  // 2 clk latency for I2C controller read
        i2c_0_csr_readdata_valid     <= i2c_0_csr_read_q; 
		i2c_0_csr_readdata_valid_dly <= i2c_0_csr_readdata_valid;
	  end
   end 
   
   
always_ff @(posedge clk) begin 
   for(int l=0;l<NUM_QSFP;l++) begin 
      if(reset_hard_soft_sync)
       qsfp_cntrl_onchip_memory2_s1_readdata_valid    <=2'd0;
      else
      qsfp_cntrl_onchip_memory2_s1_readdata_valid[l] <= qsfp_cntrl_onchip_memory2_s1_read[l]  
                                         & (~qsfp_cntrl_onchip_memory2_s1_write[l]);  // 1 clk latency for on-chip mem
   end 
end

always_ff @(posedge clk) begin          
  if (reset_hard_soft_sync) begin
     csr_readdata_comcsr_dly2 <=0;
     csr_readdata_comcsr_dly1 <=0;
     csr_readdata_valid_comcsr_dly2<=0;
     csr_readdata_valid_comcsr_dly1<=0;end
    else begin
     csr_readdata_comcsr_dly2 <=csr_readdata_comcsr_dly1;
     csr_readdata_comcsr_dly1 <=csr_readdata_comcsr;
     csr_readdata_valid_comcsr_dly2<= csr_readdata_valid_comcsr_dly1;
     csr_readdata_valid_comcsr_dly1<=csr_readdata_valid_comcsr; end
end  

// Read data mapping  
  always_ff @(posedge clk) 
  begin      
    if (reset_hard_soft_sync) 
    begin
      csr_readdata       <= '0;
      csr_readdata_valid <= 1'b0;
    end
    else if (csr_readdata_valid_comcsr_dly2) //csr_readdata_valid_comcsr_dly2) 
    begin
      csr_readdata       <= csr_readdata_comcsr_dly2; //csr_readdata_comcsr_dly2;
      csr_readdata_valid <= 1'b1; 
    end           
    else if (i2c_0_csr_readdata_valid_dly) 
    begin
      csr_readdata       <= i2c_0_csr_readdata_64;
      csr_readdata_valid <= 1'b1; 
    end
    else if (csr_readdata_valid_ocm2s1) 
    begin
      csr_readdata       <= csr_readdata_ocm2s1;
      csr_readdata_valid <= 1'b1; 
    end
    else 
    begin
      csr_readdata       <= '0;
      csr_readdata_valid <= 1'b0; 
    end  
  end 


//always_ff @(posedge clk) begin 
//       for(int m=0; m<NUM_QSFP; m++) begin 
//            if (reset) begin
//               delay_csr_in_poll <='0;end
//            else if (modsel[m]) begin
//               delay_csr_in_poll <=delay_csr_in_com[m];end
//        end
//end
//-----------------------------------------------------------------------

poller_fsm 
    #(
    .CSR_ADDR_WIDTH (12),
    .CSR_DATA_WIDTH (10),
    .MEM_ADDR_WIDTH (14),
    .MEM_DATA_WIDTH (64),
    .SRC_DATA_WIDTH (8),
    .SINK_DATA_WIDTH(16),
    .ADDR_WIDTH_SFP_REG (8),
    .A0_PAGE_END_ADDR (A0_PAGE_END_ADDR),
    .NUM_PG_SUPPORT (NUM_PG_SUPPORT)
   
    ) poller_fsm_inst
    (
    .clk                           (clk         ),
    .reset                         (reset_hard_soft_sync),
    .mod_det                       (modprsn_sync[poll_sel] ), //NOTE (TBD): this has to be selected between qsfp 0 and 1
    .poll_en                       (poll_en_sts_reg[poll_sel] ), //config_poll_en_com),  // Register of poll_en 
    .src_valid                     (src_valid   ),
    .src_data                      (src_data    ),
    .src_ready                     (src_ready   ),
    .sink_data                     (sink_data   ),
    .sink_valid                    (sink_valid  ),
    .sink_ready                    (sink_ready  ),
    .curr_rd_addr                  (curr_rd_addr),
    .curr_rd_page                  (curr_rd_page),
    .init_done                     (init_done   ),
    .status_a0_update_rdy_to_start (status_a0_update_rdy_to_start ),
    .status_a0_update_in_progress  (status_a0_update_in_progress  ),
    .status_a0_page_read_complete  (status_a0_page_read_complete  ),
	.switch_to_next_qsfp           (switch_to_next_qsfp           ),
    .status_a0_page_read_error     (status_a0_page_read_error     ),  
    .config_update_a0_page         (config_update_a0_page         ),
    .reset_a0_update_config_bit    (reset_a0_update_config_bit    ),
    .csr_wdata                     (i2c_0_csr_writedata[9:0]),
    .csr_write                     (csr_write),
    .csr_addr                      (csr_addr[11:0]),
    .delay_csr_in                  (delay_csr_in_com[poll_sel] ),
    .slave_address                 (slave_address),
    .mem_wren                      (mem_wren       ),
    .mem_chipsel                   (mem_chipsel    ),
    .mem_wdata                     (mem_wdata      ),
    .mem_byteenable                (mem_byteenable ),
    .mem_waddr                     (mem_waddr      ),
    .rxdata                        (rxdata ),
    .curr_fsm_state                (curr_fsm_state),
	  .lower_page_rd_compl           (lower_page_rd_compl)
    );
 

i2c_init_done_check #(
    .ADDR_WIDTH          (4),
    .DATA_WIDTH          (32)
    )i2c_init_done_check_inst
    (
    .clk                              (clk),
    .reset                            (reset_hard_soft_sync),
    .i2c_0_csr_address_snoop          (i2c_0_csr_address),
    .i2c_0_csr_write_snoop            (i2c_0_csr_write),
    .i2c_0_csr_writedata_snoop        (i2c_0_csr_writedata),
    .init_done                        (init_done)
    );
     
qsfp_ctrl qsfp_ctrl_inst (
   .clk_clk                           (clk),
   .i2c_0_interrupt_sender_irq        (status_int_i2c_i),    // Interrupt from I2C mstr 
   .i2c_0_csr_address                 (i2c_0_csr_address   ), //AVMM Csr to access RX_DATA,CTRL,ISER,ISR,STATUS,TFR_CMD_FIFO_LVL,RX_DATA_FIFO_LVL,SCL_LOW,SCL_HIGH,SDA_HOLD
   .i2c_0_csr_read                    (i2c_0_csr_read      ), // To access TFR_CMD_FIFO, software uses poller fsm. Since poller fsm is only connected to the sink path of I2C mastr.
   .i2c_0_csr_write                   (i2c_0_csr_write     ),
   .i2c_0_csr_writedata               (i2c_0_csr_writedata ),
   .i2c_0_csr_readdata                (i2c_0_csr_readdata  ), //Latency 2 clk
   .i2c_0_i2c_serial_sda_in           (i2c_0_i2c_serial_sda_in),
   .i2c_0_i2c_serial_scl_in           (i2c_0_i2c_serial_scl_in),
   .i2c_0_i2c_serial_sda_oe           (i2c_0_i2c_serial_sda_oe),
   .i2c_0_i2c_serial_scl_oe           (i2c_0_i2c_serial_scl_oe),
   .i2c_0_rx_data_source_data         (src_data),
   .i2c_0_rx_data_source_valid        (src_valid),
   .i2c_0_rx_data_source_ready        (src_ready),
   .i2c_0_transfer_command_sink_data  (sink_data),  //AVST
   .i2c_0_transfer_command_sink_valid (sink_valid),
   .i2c_0_transfer_command_sink_ready (sink_ready),  
   .reset_reset                       (reset_hard_soft_sync)
   );
   
   
// Common CSR space for NUM_QSFP instances-------------------------------------------------------
generate for(genvar k=0;k<NUM_QSFP;k++) begin : qsfp_com_inst
   
   qsfp_com  #(
    .ADDR_WIDTH            (8),
    .DATA_WIDTH            (DATA_WIDTH),
    .ADDR_WIDTH_SFP_REG    (8),
    .NUM_QSFP              (NUM_QSFP)
   ) qsfp_com_inst (

    .clk                           (clk                                 ),
    .reset                         (reset                               ),
    .writedata                     (qsfp_com_csr_writedata           [k]),
    .read                          (qsfp_com_csr_read                [k]),
    .delay_csr_in                  (delay_csr_in_com                 [k]),
    .write                         (qsfp_com_csr_write               [k]),
    .byteenable                    (csr_byteenable                      ),
    .readdata                      (qsfp_com_csr_readdata            [k]),
    .readdatavalid                 (qsfp_com_csr_readdatavalid       [k]),
    .address                       (qsfp_com_csr_address             [k]),
    .init_done                     (init_done                           ),
    .config_softresetqsfpm         (config_softresetqsfpm_com        [k]),
    .config_softresetqsfpc         (config_softresetqsfpc_com        [k]),
    .config_modesel                (modsel_common_csr_com            [k]),
    .config_lpmode                 (lpmode_com                       [k]),
    .status_modprsn_i              (modprsn_sync                     [k]),
    .status_int_qsfp_i             (int_qsfp_reg                     [k]),  //From QSFP module its active low, but inside com_csr, it is reading as actiuve high
    .poll_en_sts_reg               (poll_en_sts_reg                     ),
    .status_int_i2c_i              (status_int_i2c_i                    ),
 	.status_a0_update_rdy_to_start (status_a0_update_rdy_to_start_com[k]),
	.status_a0_update_in_progress  (status_a0_update_in_progress_com [k]),
	.status_a0_page_read_complete  (status_a0_page_read_complete_com [k]),
	.status_a0_page_read_error     (status_a0_page_read_error_com    [k]),   
    .config_poll_en                (config_poll_en_com               [k]),
    .config_update_a0_page         (config_update_a0_page_com        [k]),
	.reset_a0_update_config_bit    (reset_a0_update_config_bit_com   [k]),
    .curr_rd_addr                  (curr_rd_addr                     [k]),
    .curr_rd_page                  (curr_rd_page                     [k]),
	.curr_fsm_state                (curr_fsm_state                   [k]),
	.src_ready_int                 (src_ready_com                    [k]),
	.sink_ready_int                (sink_ready_com                   [k]),
	.lower_page_rd_compl           (lower_page_rd_compl_com          [k])
  );

//onchip_memory2_s1 is for csr access for SW    
shadow_reg #(
    .ADDR_WIDTH          (8), // Total memory size is 768B.Hence no.of addr bits required will be 768/8=96=x69 (7 bits)
    .DATA_WIDTH          (64),
    .BYTE_ENABLE_WIDTH   (DATA_WIDTH/8)
) shadow_reg_inst (
.clk                                (clk                                 ),
.reset                              (reset_hard_soft_sync                ), 
.onchip_memory2_s1_address          (qsfp_cntrl_onchip_memory2_s1_address [k]),
.onchip_memory2_s1_read             (qsfp_cntrl_onchip_memory2_s1_read    [k]),
.onchip_memory2_s1_readdata         (qsfp_cntrl_onchip_memory2_s1_readdata[k]),
.onchip_memory2_s1_byteenable       (16'hffff),//2*8   --parametrization  needed
.onchip_memory2_s1_write            (),
.onchip_memory2_s1_writedata        (),//64*4
.onchip_memory2_s2_address          (shadow_mem_waddr                     [k]),
.onchip_memory2_s2_read             (),
.onchip_memory2_s2_readdata         (),
.onchip_memory2_s2_byteenable       (16'hffff),//2*8   --parametrization  needed
.onchip_memory2_s2_write            (shadow_mem_wren                      [k]),
.onchip_memory2_s2_writedata        (shadow_mem_wdata                     [k])
);

end endgenerate




endmodule
