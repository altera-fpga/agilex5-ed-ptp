//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module qsfp_com #(
   parameter ADDR_WIDTH         = 8,
   parameter DATA_WIDTH         = 64,
   parameter ADDR_WIDTH_SFP_REG = 8,
   parameter NUM_QSFP           = 2
  ) 
  (
    input                                  clk,
    input                                  reset,
    input   [DATA_WIDTH-1:0]               writedata,
    input                                  read,
    input                                  write,
    input   [DATA_WIDTH/8-1:0]             byteenable,
    output  [DATA_WIDTH-1:0]               readdata,
    output                                 readdatavalid,
    input   [ADDR_WIDTH-1:0]               address,
    input                                  init_done,
    input                                  status_modprsn_i,
    input                                  status_int_i2c_i,
    input                                  status_int_qsfp_i,  
    input  [NUM_QSFP-1:0]                  poll_en_sts_reg,  
    output  reg 					       config_softresetqsfpm,  
    output  reg 					       config_softresetqsfpc,  
    output  reg 					       config_modesel,  
    output  reg 					       config_lpmode,  
    output  reg 					       config_poll_en,
	input                                  status_a0_update_rdy_to_start,
	input                                  status_a0_update_in_progress, 
	input                                  status_a0_page_read_complete, 
	input                                  status_a0_page_read_error,    
	input                                  reset_a0_update_config_bit, 
    output                                 config_update_a0_page,
    output  [31:0]                         delay_csr_in,
    input   logic [ADDR_WIDTH_SFP_REG-1:0] curr_rd_addr,
    input   logic [7:0]                    curr_rd_page,
    input   logic [3:0]                    curr_fsm_state,
	input   logic                          src_ready_int, 
	input   logic                          sink_ready_int,
	input   logic                          lower_page_rd_compl
);
  
reg [DATA_WIDTH-1:0] config_reg;
reg [DATA_WIDTH-1:0] scratch_reg;
reg                  reset_a0_update_config_bit_d1;
reg [31:0]           delay_csr_in_reg;
reg [DATA_WIDTH-1:0] readdata_reg;
reg                  readdatavalid_reg;
reg                  status_a0_page_read_complete_d, status_a0_page_read_complete_latch;


always @(posedge  reset,  posedge clk)
begin
  if (reset) 
  begin
      config_reg <= 64'h0;
	  reset_a0_update_config_bit_d1 <= 0;
  end
  else
  begin
    reset_a0_update_config_bit_d1 <= reset_a0_update_config_bit;
    if  (reset_a0_update_config_bit && (!reset_a0_update_config_bit_d1))
        config_reg[5] <= 0;
    else if (write && (address == 6'h20)) 
        config_reg <=  writedata;  
  end
end

// 64 bit scratch register
always @(posedge  reset,  posedge clk)
  begin
    if (reset)
      scratch_reg <= 64'h0;
    else 
	 begin
	   if (write && (address == 6'h30))
        scratch_reg <=  writedata;  
	 end
  end

// first time read complete 
always @(posedge  reset,  posedge clk)
  begin
    if (reset)  
	 begin
       status_a0_page_read_complete_d <= 1'b0;
	   status_a0_page_read_complete_latch <= 1'b0;
	 end
    else 
	 begin
       status_a0_page_read_complete_d <= status_a0_page_read_complete;
	   
	   if (status_a0_page_read_complete && (!status_a0_page_read_complete_d))
	     status_a0_page_read_complete_latch <= 1'b1;

	 end
  end

// 32 bit delay csr register
always @(posedge  reset,  posedge clk)
  begin
    if (reset)  
	 begin
      //delay_csr_in <= 32'hFFFFFFFF;
      delay_csr_in_reg <= 32'h00000BFF;
	 end
    else 
	 begin
	   if (write && (address == 6'h38)) 
        delay_csr_in_reg <=  writedata[31:0]; 
	 end
  end



always @(posedge reset ,posedge clk)  
  if (reset) 
    begin
      readdata_reg          <= 64'h0; 
      readdatavalid_reg     <= 0;
    end
   else begin
     if (read)
       begin
         case (address)  
           8'h20 : begin // QSFP config reg
                     readdata_reg          <= config_reg;
                     readdatavalid_reg     <= 1;
                   end
           8'h28 : begin // QSFP status reg
                     readdata_reg [0]      <= status_modprsn_i;   // module present
                     readdata_reg [1]      <= status_int_qsfp_i;  // Int_sfp interrupt set by sfp                
                     readdata_reg [2]      <= status_int_i2c_i;   // Int_I2C - interrupt set by I2C master                
                     readdata_reg [3]      <= 0;   // NA  TX_err - indicates Error condition that write command is received when TX_ready is ‘0'                 
                     readdata_reg [4]      <= 0;   // NA  RX_err - indicates Error condition that read command is received when RX_ready is ‘0’                
                     readdata_reg [5]      <= sink_ready_int;  //  Snk_ready - indicates TRF_CMD is ready to accept new command                
                     readdata_reg [6]      <= src_ready_int;   //  Src_ready -  indicates RX_DATA is ready in RX FIFO                
                     readdata_reg [7]      <= 0;   // NA FSM_paused - indicates poller FSM is paused                                         
                     readdata_reg [15:8]   <= curr_rd_page;    //  curr_rd_page - read page which was last read by poller                                         
                     readdata_reg [23:16]  <= curr_rd_addr;    //  curr_rd_addr - address which was last read by poller                                         
                     readdata_reg [27:24]  <= curr_fsm_state;  //  curr_fsm_state - current state of Poller FSM                                         
                     readdata_reg [28]     <= 0;   // NA poller_fsm_to_reg - timeout status                                         
                     readdata_reg [31:29]  <= '0;  // NA FSM_paused - indicates poller FSM is paused                                         
                     //readdata_reg [32]     <= status_txfault;   // NA                                         
                     //readdata_reg [33]     <= status_rxlos  ;   // NA                                                       
                     readdata_reg [34]     <= status_a0_update_rdy_to_start ;  // QSFP controller is Ready to start A0 page update                                                          
                     readdata_reg [35]     <= status_a0_update_in_progress  ;  // QSFP controller A0 page update is in progress                                                       
                     readdata_reg [36]     <= status_a0_page_read_complete_latch  ;  // SFP controller A0 page read complete                                                          
                    // readdata_reg [37]     <= status_a2_update_in_progress  ;  // SFP controller A2 page update is in progress                                                           
                    // readdata_reg [38]     <= status_a2_page_read_complete  ;  // SFP controller A2 page read complete first time                                                           
                     readdata_reg [39]     <= status_a0_page_read_error     ;  // QSFP controller A0 page read error                                                          
                    // readdata_reg [40]     <= status_a2_page_read_error     ;  // SFP controller A2 page read error                                                          
                     readdata_reg [41]     <= lower_page_rd_compl;
                     readdata_reg [63:42]  <= '0;  // Reserved                   
                     readdatavalid_reg     <= 1;
                  end
           8'h30 : begin // Scratch Pad reg
                     readdata_reg [63:0]   <= scratch_reg; // RW for software access
                     readdatavalid_reg     <= 1;
                   end
           8'h38 : begin
                     readdata_reg [63:0]   <= {32'b0,delay_csr_in_reg};  
                     readdatavalid_reg     <= 1;
                   end
           8'h80 : begin 
                     readdata_reg [15:0]   <= '0;         // SFP Controller Version
                     readdata_reg [31:16]  <= 8'h03; 
                     readdata_reg [63:32]  <= '0;     
                     readdatavalid_reg     <= 1;
                   end         
		   8'h88 : begin 
                     readdata_reg [0]      <= 1'b1;  // 0 - Individual I2C master for each QSFP ; 1 - Single I2C master for all QSFPs (I2C Bus)

                     readdata_reg [31:1]   <= '0;    // Reserved
                     readdata_reg [35:32]  <= 4'h1;  // Number of QSFPs supported in solution. 0x0 indicates 1, 0x1 indicates 2 etc.      
                     readdata_reg [63:36]  <= '0;    // Reserved   
                     readdatavalid_reg     <= 1;
                   end
           8'h90 : begin                                          // I2C init done
                     readdata_reg [0]      <= init_done; 
                     readdata_reg [63:1]   <= '0;                 // Reserved
                     readdatavalid_reg     <= 1;
                   end

           8'h98 : begin                                          // poll en
                     readdata_reg [0]      <= config_reg[4]; 
                     readdata_reg [2:1]    <= poll_en_sts_reg;    // Reserved
                     readdata_reg [63:3]   <= '0;                 // Reserved
                     readdatavalid_reg     <= 1;
                   end
         
         
           default : begin
                     readdata_reg          <= 64'h0000000000000000;
                     readdatavalid_reg     <= 0;
                   end
         endcase
       end
		 else
		 begin
         readdata_reg          <= 64'h0000000000000000;
         readdatavalid_reg     <= 0;
		 end
     end

  
assign  config_softresetqsfpm   =  config_reg[0];  
assign  config_softresetqsfpc   =  config_reg[1];  
assign  config_modesel          =  config_reg[2];  
assign  config_lpmode           =  config_reg[3];  
assign  config_poll_en          =  config_reg[4];   // A2 poll enable
assign  config_update_a0_page   =  config_reg[5];   // start A0 update
//assign  config_sfp_sel         =  config_reg[7:6]; // NA : bit[6] SF supports SFF8273 page config, bit[7] protocol change over to A2
assign  delay_csr_in            =  delay_csr_in_reg;
assign  readdata                =  readdata_reg;    
assign  readdatavalid           =  readdatavalid_reg;

endmodule
