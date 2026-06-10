//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module poller_fsm #(
  parameter CSR_ADDR_WIDTH         = 12, 
  parameter CSR_DATA_WIDTH         = 10, 
  parameter MEM_ADDR_WIDTH         = 14, 
  parameter MEM_DATA_WIDTH         = 64, 
  parameter SRC_DATA_WIDTH         = 8 ,
  parameter SINK_DATA_WIDTH        = 16,
  parameter ADDR_WIDTH_SFP_REG     = 8 ,
  parameter A0_PAGE_END_ADDR       = 128,
  parameter NUM_PG_SUPPORT         = 4
  //parameter NUM_QSFP               = 2
 
)(
  input   logic                          clk,
  input   logic                          reset,
  input   logic                          mod_det,
  input   logic                          poll_en,
  input   logic                          src_valid,
  input   logic [SRC_DATA_WIDTH-1:0]     src_data,
  output  logic                          src_ready,
  output  logic [SINK_DATA_WIDTH-1:0]    sink_data,
  output  logic                          sink_valid,
  input   logic                          sink_ready,

  output  logic [ADDR_WIDTH_SFP_REG-1:0] curr_rd_addr,
  output  logic [7:0]                    curr_rd_page,
  input   logic                          init_done,               
  output  reg                            status_a0_update_rdy_to_start,
  output  reg                            status_a0_update_in_progress, 
  output  reg                            status_a0_page_read_complete, 
  output  reg                            switch_to_next_qsfp, 
  output  reg                            status_a0_page_read_error, 
  input                                  config_update_a0_page,  
  output  reg                            reset_a0_update_config_bit, 
  input   logic [CSR_DATA_WIDTH-1:0]     csr_wdata, // csr interface is for useravmm to fetch qsfp regs while poll_en =0
  input   logic                          csr_write,
  input   logic [CSR_ADDR_WIDTH-1:0]     csr_addr,
  input   logic [31:0]                   delay_csr_in,
  output  logic [7:0]                    slave_address,
  output  logic                          mem_wren ,
  output  logic [MEM_DATA_WIDTH-1:0]     mem_wdata,
  output  logic [MEM_DATA_WIDTH/8-1:0]   mem_byteenable,
  output  logic                          mem_chipsel,
  output  logic [MEM_ADDR_WIDTH-1:0]     mem_waddr,
  output  logic [7:0]                    rxdata,
  output  logic [4:0]                    curr_fsm_state,
  output  logic                          lower_page_rd_compl
 );

  localparam  A0_IDLE            = 5'b00000;
  localparam  A0_UPDT_STRT       = 5'b00001;
  localparam  A0_INIT            = 5'b00010;
  localparam  A0_WAIT_INIT       = 5'b00011;
  localparam  A0_WR_AVMM         = 5'b00100;
  localparam  A0_PG_DISCV        = 5'b00101;
  localparam  A0_UP_TFRWR        = 5'b00110;
  localparam  A0_UP_TFRWO        = 5'b00111;
  localparam  A0_UP_TFRACK       = 5'b01000;
  localparam  A0_UP_DLY          = 5'b01001;
  localparam  A0_UP_RD127        = 5'b01010;
  localparam  A0_UP_RD127_TFRWO  = 5'b01011;
  localparam  A0_UP_RD127_TFRRD  = 5'b01100;
  localparam  A0_UP_RD127_TFRACK = 5'b01101;
  localparam  A0_UP_WAIT_VALID   = 5'b01110;
  localparam  A0_PG_UPDT         = 5'b01111;
  localparam  A0_TFRWR           = 5'b10000;
  localparam  A0_TFRWO           = 5'b10001;
  localparam  A0_TFRRD           = 5'b10010;
  localparam  A0_TFRACK          = 5'b10011;
  localparam  A0_RDDATA          = 5'b10100;
  localparam  A0_DONE            = 5'b10101;


  localparam  TFR_WR_CTRL_A0 = 10'b1010100000; //0x2A0 value to be written in TFR register to initiate write with i2c slave
  localparam  TFR_RD_CTRL_A0 = 10'b1010100001; //0x2A1 value to be written in TFR register to initiate read with i2c slave
  localparam  TFR_RD_ACK     = 10'b0000000000; //0x000 TFR register value to send ack for i2c reads
  localparam  TFR_RD_NACK    = 10'b0100000000; //0x100 TFR register value to send nack for i2c reads
 
  localparam  a0_word_page   = A0_PAGE_END_ADDR  >> 3;
  
  logic  [7:0]  page_support [3:0] = {8'h03, 8'h02, 8'h01, 8'h00}; // current design supports pages 0, 1 and 2 of A0 device
  //logic  [7:0]  page_support [3:0] = {8'h00, 8'h00, 8'h00, 8'h00}; //NA
  logic  [4:0]  a0_state_prsnt, a0_state_nxt , a0_up_pg_rd, a0_pg_rd;
  logic  [7:0]  curr_page, a0_addr, a0_slave_address, page_strt_addr, page_num, page_range;
  logic  [2:0]  a0_bytecnt; 
  logic  [2:0]  pg_cnt; 
  logic  [31:0] a0_delay_csr_in_cnt; 
  logic                          a0_sink_valid, a0_lp_0_rd_done, a0_src_ready;
  logic                          a0_mem_wren;
  logic [MEM_DATA_WIDTH-1:0]     a0_mem_wdata;
  logic [MEM_DATA_WIDTH/8-1:0]   a0_mem_byteenable;
  logic                          a0_mem_chipsel;
  logic [MEM_ADDR_WIDTH-1:0]     a0_mem_waddr;
  logic [SINK_DATA_WIDTH-1:0]    a0_sink_data;
  logic [7:0]                    a0_rxdata;

  assign slave_address   = a0_slave_address;
  assign curr_rd_addr    = a0_addr           ;
  assign curr_rd_page    = page_support[pg_cnt];                         ;
  assign curr_fsm_state  = a0_state_prsnt     ;
  assign mem_wren        = a0_mem_wren        ;
  assign mem_wdata       = a0_mem_wdata       ;
  assign mem_byteenable  = a0_mem_byteenable  ;
  assign mem_chipsel     = a0_mem_chipsel     ;
  assign mem_waddr       = a0_mem_waddr       ;
  assign sink_data       = a0_sink_data       ;
  assign sink_valid      = a0_sink_valid      ;
  assign src_ready       = a0_src_ready       ;
  assign rxdata          = a0_rxdata          ;
  assign lower_page_rd_compl =  a0_lp_0_rd_done;  
 
//present state to next state assignment
  always@(posedge clk or posedge reset)
    if(reset)
      a0_state_prsnt <= '0;
    else
      a0_state_prsnt <=  a0_state_nxt   ;
 
always@(posedge clk)
  begin
    if(reset)
    begin
      a0_delay_csr_in_cnt           <= 32'h0000_FFFF;
      status_a0_update_rdy_to_start <= 0;
      status_a0_update_in_progress  <= 0;  
      status_a0_page_read_complete  <= 0;  
      status_a0_page_read_error     <= 0;  
 	  switch_to_next_qsfp           <= 0;
      reset_a0_update_config_bit    <= 0;
      a0_bytecnt                    <= 0;
      a0_src_ready                  <= 0;
      a0_sink_data                  <= '0;
      a0_sink_valid                 <= 0;
      a0_mem_wren                   <= 0;
      a0_mem_wdata                  <= '0; 
      a0_mem_byteenable             <= '0; 
      a0_mem_waddr                  <= '0;
      a0_mem_chipsel                <= 0;
	  a0_up_pg_rd                   <= A0_UP_TFRWR;
      a0_pg_rd                      <= A0_TFRWR;
      a0_addr                       <= 0;
      curr_page                     <= '0;
      a0_rxdata                     <= '0;
	  pg_cnt                        <= '0;
	  a0_lp_0_rd_done               <= 0;
	  a0_slave_address              <= 8'hA0;
	  page_num                      <= 8'h0;
	  page_range                    <= a0_word_page;
    end
  else 
    begin
      case (a0_state_prsnt)
	  A0_IDLE: 
          begin
            a0_sink_data                  <= '0;
            a0_sink_valid                 <= 0;
			switch_to_next_qsfp           <= 0;
            status_a0_update_rdy_to_start <= 0;
            status_a0_update_in_progress  <= 0;  
            status_a0_page_read_complete  <= 0;  
            status_a0_page_read_error     <= 0;  
			reset_a0_update_config_bit    <= 0;
            a0_bytecnt                    <= 0;
            a0_src_ready                  <= 0;
	        a0_up_pg_rd                   <= A0_UP_TFRWR;
            a0_pg_rd                      <= A0_TFRWR;
            a0_delay_csr_in_cnt           <= 32'h0000_FFFF; 
			a0_lp_0_rd_done               <= 0;
	        pg_cnt                        <= '0;
			page_strt_addr                <= '0;
            a0_slave_address              <= 8'hA0;
			page_range                    <= a0_word_page;
          end		  
        A0_UPDT_STRT:
          begin
            status_a0_update_rdy_to_start <= 1;
			switch_to_next_qsfp           <= 1'b0;
          end   
          
        A0_INIT: 
          begin
			a0_delay_csr_in_cnt    <= delay_csr_in;
            a0_src_ready           <= 1;
            switch_to_next_qsfp    <= 1'b0;
            if (csr_write && csr_addr == 12'h040 && sink_ready) // assuming sink is ready always 
              begin
                a0_sink_data  <= {6'b0,csr_wdata};
                a0_sink_valid <= 1;
              end
            else
              begin
                a0_sink_valid <= 0;
                a0_sink_data  <= '0;
              end
          end
          
        A0_WAIT_INIT:
          begin
            a0_delay_csr_in_cnt <= a0_delay_csr_in_cnt - 1;
          end
        
        A0_WR_AVMM:
          begin
		    switch_to_next_qsfp           <= 1'b0;
			a0_slave_address[7:0]         <= 8'hA0;
			reset_a0_update_config_bit    <= 0;
            a0_src_ready                  <= 1;
            if (csr_write && csr_addr == 12'h040 && sink_ready) 
              begin
                a0_sink_data  <= {6'b0,csr_wdata};
                a0_sink_valid <= 1;
              end
            else
              begin
                a0_sink_valid <= 0;
                a0_sink_data  <= '0;
              end
            
            if (src_valid)
              a0_rxdata <= src_data; 

          end

		A0_PG_DISCV:
          begin
		    switch_to_next_qsfp           <= 1'b0;
            status_a0_update_in_progress  <= 1; 
            a0_sink_valid                 <= 0;
            a0_slave_address[7:0]         <= TFR_WR_CTRL_A0[7:0];
            a0_src_ready                  <= 1;
            a0_mem_wren                   <= 0;
            a0_mem_chipsel                <= 0;
            if (a0_lp_0_rd_done)
               page_strt_addr <= 8'h80;
			else
			   page_strt_addr <= 8'b0;
			   
            if (sink_ready)
              begin
                case (a0_up_pg_rd)
                  A0_UP_TFRWR:
                    begin
                      a0_sink_data   <= TFR_WR_CTRL_A0; //0x2A0
                      a0_sink_valid  <= 1;
                      a0_up_pg_rd <= A0_UP_TFRWO;
                    end
                  A0_UP_TFRWO:
                    begin
                      a0_sink_data   <= 16'h007F; // offset 127 
                      a0_sink_valid  <= 1;
                      a0_up_pg_rd <= A0_UP_TFRACK;
                    end
                  A0_UP_TFRACK:
                    begin
                      a0_sink_data  <= {8'h01,page_support[pg_cnt]}; // write the page number you want to read and then stop
                      a0_sink_valid <= 1;
					  a0_delay_csr_in_cnt <= delay_csr_in;
                      a0_up_pg_rd   <= A0_UP_DLY;
                    end
                  A0_UP_DLY: // wait for sometime before reading the location 127
                    begin
                      a0_sink_data  <= '0;
                      a0_sink_valid <= 0;
					  if (a0_delay_csr_in_cnt == 0)
                        a0_up_pg_rd   <= A0_UP_RD127;
                      else
                        a0_delay_csr_in_cnt <= a0_delay_csr_in_cnt - 1;
                    end
				  A0_UP_RD127:
                    begin
                      a0_sink_data   <= TFR_WR_CTRL_A0; //0x2A0
                      a0_sink_valid  <= 1;
                      a0_up_pg_rd <= A0_UP_RD127_TFRWO;
		              end		
                  A0_UP_RD127_TFRWO:
                    begin
                      a0_sink_data  <= 16'h007F; //offset
                      a0_sink_valid <= 1;
                      a0_up_pg_rd   <= A0_UP_RD127_TFRRD;
                    end
                  A0_UP_RD127_TFRRD:
                    begin
                      a0_sink_data  <= TFR_RD_CTRL_A0; //0x2A3 reading
                      a0_sink_valid <= 1;				        
                      a0_up_pg_rd   <= A0_UP_RD127_TFRACK;
                    end
                  A0_UP_RD127_TFRACK:
                    begin
                      a0_sink_data  <= TFR_RD_NACK; //0x100
                      a0_sink_valid <= 1;
                      a0_up_pg_rd   <= A0_UP_WAIT_VALID;
                    end
                  A0_UP_WAIT_VALID:
                    begin
                      a0_sink_data  <= '0;
					  a0_sink_valid <= 0;
					  if (src_valid)
					  begin
					    page_num    <= src_data;
						a0_pg_rd    <= A0_TFRWR;
						a0_up_pg_rd <= A0_UP_TFRWR;
					  end
                    end
				  default : begin end
				endcase
			end
		end
		
        A0_PG_UPDT:
          begin
		    switch_to_next_qsfp           <= 1'b0;
            status_a0_update_in_progress  <= 1; 
            a0_sink_valid                 <= 0;
            a0_slave_address[7:0]         <= TFR_WR_CTRL_A0[7:0];
            a0_src_ready                  <= 1;
            a0_up_pg_rd                   <= A0_UP_TFRWR; // page discovery is in loop until state changes to A0_PG_UPDT
            if (sink_ready)
              begin
                case (a0_pg_rd)
                  A0_TFRWR:
                    begin
                      a0_sink_data  <= TFR_WR_CTRL_A0;
                      a0_sink_valid <= 1;
                      a0_pg_rd   <= A0_TFRWO;
                    end
                  A0_TFRWO:
                    begin
                      a0_sink_data  <= page_strt_addr;
                      a0_sink_valid <= 1;
                      a0_pg_rd   <= A0_TFRRD;
                    end
                  A0_TFRRD:
                    begin
                      a0_sink_data  <= TFR_RD_CTRL_A0;
                      a0_sink_valid <= 1;
                      a0_pg_rd   <= A0_TFRACK;
                    end
                  A0_TFRACK:
                    begin
                      a0_sink_data  <= TFR_RD_ACK;
                      a0_sink_valid <= 1;
					  if (a0_lp_0_rd_done)
					  begin
						page_range <= page_range + 8'h10;
						//page_range <= page_range + 8'h1; // NA
					  end
					  else
					  begin
						page_range <= a0_word_page;
					  end
                      a0_pg_rd   <= A0_RDDATA;
                    end
                  A0_RDDATA:
                    begin
                      if (src_valid) 
                       begin
                           if (a0_bytecnt == 7)
                           begin
                            a0_bytecnt <= 0;
                            a0_addr <= a0_addr + 1;
                           end
                           else  
                           begin
                            a0_bytecnt <= a0_bytecnt + 1;
                           end
                              
                           if ((a0_addr == (page_range -1)) && (a0_bytecnt == 6)) 
                           begin
                             a0_sink_data  <= TFR_RD_NACK;
                             a0_sink_valid <= 1;
                           end
                           else if ((a0_addr == (page_range -1)) && (a0_bytecnt == 7)) 
                           begin
                             a0_sink_data  <= '0;
                             a0_sink_valid <= 0;
							 a0_lp_0_rd_done <= 1;
			                 pg_cnt        <= pg_cnt + 1;
							 a0_pg_rd      <= A0_TFRWR;
                           end
                           else
                           begin
                             a0_sink_data  <= TFR_RD_ACK;
                             a0_sink_valid <= 1;
                           end

                           a0_mem_wdata [(8*a0_bytecnt) +:8] <= src_data; 
                           a0_mem_byteenable[a0_bytecnt]     <= 1'b1; 
                           a0_mem_waddr   <= a0_addr;
                           if (a0_bytecnt == 7)
                           begin
                             a0_mem_wren    <= 1;
                             a0_mem_chipsel <= 1;
                           end
                           else
                             a0_mem_wren    <= 0;
                             a0_mem_chipsel <= 0;
                           end
                      else 
                      begin
                        a0_mem_wren    <= 0;
                        a0_mem_chipsel <= 0;
                        if (a0_mem_byteenable == 8'hff)
                          a0_mem_byteenable <= 8'h00;
                      end
                    end
                endcase
              end
          end        

    	A0_DONE:
          begin
			status_a0_update_in_progress <= 0;
			status_a0_page_read_complete <= 1;
            a0_bytecnt                   <= 0;
            a0_addr                      <= 0;
            a0_mem_wren                  <= 0;
            a0_mem_chipsel               <= 0;
            a0_mem_wdata                 <= '0; 
            a0_mem_byteenable            <= '0; 
            a0_mem_waddr                 <= '0;
            a0_sink_data                 <= '0;
            a0_sink_valid                <= 0;
            a0_pg_rd                     <= A0_TFRWR;
			a0_up_pg_rd                  <= A0_UP_TFRWR;
            page_strt_addr               <= '0; 
			a0_lp_0_rd_done              <= 0;
            a0_src_ready                 <= 0;
            a0_delay_csr_in_cnt          <= 32'h0000_FFFF; 
	        pg_cnt                       <= '0;
            a0_slave_address             <= 8'hA0;
			page_range                   <= a0_word_page;
			switch_to_next_qsfp          <= 1'b1;
          end		  
		default: begin end
      endcase         
    end
  end
 
 
// next state assignment
always_comb
  begin
    case (a0_state_prsnt)
      A0_IDLE: 
	  begin
        if (!mod_det)

          a0_state_nxt = A0_UPDT_STRT;
        else
          a0_state_nxt = A0_IDLE;
      end

      A0_UPDT_STRT: 
      begin
        if (!mod_det)
          a0_state_nxt = A0_INIT;
        else
          a0_state_nxt = A0_IDLE;
      end
  
      A0_INIT: 
      begin
        if (!mod_det)
          if (init_done)
            a0_state_nxt = A0_WAIT_INIT;
          else
            a0_state_nxt = A0_INIT;
        else
          a0_state_nxt = A0_IDLE;
      end
      
      A0_WAIT_INIT: 
      begin
        if (!mod_det)
          if (a0_delay_csr_in_cnt == 0) 
            if (poll_en)
              a0_state_nxt = A0_PG_UPDT;
            else
              a0_state_nxt = A0_WR_AVMM;
          else
            a0_state_nxt = A0_WAIT_INIT;
        else
          a0_state_nxt = A0_IDLE;
      end
  
      A0_WR_AVMM:
      begin
        if (!mod_det)
          if (poll_en)
		    a0_state_nxt = A0_PG_UPDT;
          else
            a0_state_nxt = A0_WR_AVMM;
        else
          a0_state_nxt = A0_IDLE;
      end

      A0_PG_UPDT: 
      begin
        if (!mod_det)
          if ((a0_pg_rd == A0_RDDATA) && (a0_addr == (page_range -1)) && (a0_bytecnt == 7) && src_valid)
		     if (pg_cnt == NUM_PG_SUPPORT)
               a0_state_nxt = A0_DONE;
		     else
		       a0_state_nxt = A0_PG_DISCV;
		  else
		    a0_state_nxt = A0_PG_UPDT;
        else
          a0_state_nxt = A0_IDLE;
      end
	  
      A0_PG_DISCV: 
      begin
        if (!mod_det)
		  if ((a0_up_pg_rd ==  A0_UP_WAIT_VALID) && src_valid)
		    if (page_support[pg_cnt] == src_data) //A0 lower page 127 location read data compared with expected data
              a0_state_nxt = A0_PG_UPDT;
		    else
		      a0_state_nxt = A0_PG_DISCV;
		  else
		    a0_state_nxt = A0_PG_DISCV;
        else
          a0_state_nxt = A0_IDLE;
      end
	  
      A0_DONE: 
      begin
        if (!mod_det)
		  if (poll_en)
            a0_state_nxt = A0_PG_UPDT;
		  else
		    a0_state_nxt = A0_DONE;
        else
          a0_state_nxt = A0_IDLE;
      end

      default: 
      begin 
        a0_state_nxt = A0_IDLE;
      end
     endcase
  end

  endmodule
