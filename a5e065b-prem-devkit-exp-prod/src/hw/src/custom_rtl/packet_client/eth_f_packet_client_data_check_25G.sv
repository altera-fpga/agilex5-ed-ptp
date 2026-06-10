//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

`timescale 1 ps / 1 ps

module eth_f_packet_client_data_check_25G #(
//  parameter ROM_ADDR_WIDTH = 16,
  parameter WORDS           = 8,
  parameter EMPTY_WIDTH     = 6,
  parameter WIDTH           = 64
  //parameter PKT_ROM_INIT_FILE       = "eth_f_hw_pkt_gen_rom_init.hex"
)(
        input   logic                   i_reset,
        input   logic                   i_clk,
        input   logic                   i_rx_sop,
        input   logic                   i_rx_eop,
        input   logic                   i_rx_valid,
        input   logic [EMPTY_WIDTH-1:0] i_rx_empty,
        input   logic [(WORDS*WIDTH)-1:0]    i_rx_data,
		  input   logic [6:0]             i_rx_error,

        input   logic                   i_tx_sop,
        input   logic                   i_tx_eop,
        input   logic                   i_tx_valid,
        input   logic [(WORDS*WIDTH)-1:0]    i_tx_data,
        input   logic [EMPTY_WIDTH-1:0] i_tx_empty,
        input   logic                   i_tx_ready,

        input                           i_cfg_pkt_gen_tx_en,         // 1: start sending pkt; 0: stop sending pkt;
        input                           i_cfg_pkt_gen_cont_mode,    // 1: Continuous Mode; 0: One Shot Mode;
        input                           i_cfg_tx_select_pkt_gen,
        input         [31:0]            i_dyn_pkt_num_sync,
        
        output  logic                   o_data_error,
        output  logic                   o_pkt_cnt_error,
        output  logic [31:0]            o_packet_cnt,
        
        //---csr interface---
        input  logic                   stat_rx_cnt_clr,
        output logic                   stat_rx_cnt_vld,
        output logic [7:0]             stat_rx_sop_cnt,
        output logic [7:0]             stat_rx_eop_cnt,
        output logic [7:0]             stat_rx_err_cnt,

	    output logic [63:0]            rx_byte_cnt,
	    output logic [63:0]            tx_byte_cnt,
	    output logic [63:0]            tx_num_ticks,
	    output logic [63:0]            rx_num_ticks,
        output logic [63:0]            tx_bw_cnt,
        output logic [63:0]            rx_bw_cnt

    );

wire [(WORDS*WIDTH)-1:0]         tx_data_q;
wire                             tx_sop_q;
wire                             tx_eop_q;
wire [(WORDS*WIDTH)-1:0]         rx_data_q;
wire                             rx_sop_q;
wire                             rx_eop_q;
wire                             rx_fifo_empty;
reg [2:0]                        chkr_next_state;              
reg [2:0]                        chkr_state;  
wire                             pop_fifo_state; 
wire                             latch_data_state;
reg                              compare_data_pipe2_state;
reg [(WORDS*WIDTH)-1:0]          rx_data_reg;  
reg [(WORDS*WIDTH)-1:0]          tx_data_reg;  
reg                              rx_eop_reg;   
reg                              rx_eop_reg2;  
reg                              rx_sop_reg;
reg [(WORDS*WIDTH)-1:0]          rx_mask_reg;
reg                              data_not_matched_reg2;
reg                              data_err_reg; 
reg [31:0]                       rx_packet_cnt;
reg [31:0]                       tx_packet_cnt;
logic [3:0]                      rx_empty_q;
logic [(WORDS*WIDTH)-1:0]        data_mask;
logic [(WORDS*WIDTH)-1:0]        ref_data;
logic [WIDTH-1:0]                inc_data;
logic               checker_done;
logic               compare_data_pipe3_state_rising_edge_pulse;
logic               rx_packet_error_pulse;
logic               compare_data_pipe3_state;

always_ff @ (posedge i_clk) begin
if(i_rx_valid)
    begin
            rx_data_reg  <= i_rx_data & data_mask;
            rx_eop_reg   <= i_rx_eop;
			if (WORDS == 1)
            rx_mask_reg <= (i_rx_sop | rx_sop_reg)? data_mask >> WIDTH*WORDS : data_mask; 
	      else			
            rx_mask_reg <= (i_rx_sop)? data_mask >> WIDTH*WORDS : data_mask;    
     end
     compare_data_pipe2_state <= i_rx_valid;
     rx_sop_reg   <= i_rx_sop;
end



/// data masking

always @(i_rx_empty)
begin

data_mask= ({(WORDS*WIDTH){1'b1}}<<(i_rx_empty*8));

end


always_ff @ (posedge i_clk)
            rx_eop_reg2   <= rx_eop_reg;

logic hdr_valid;
logic sop_valid;

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset) begin
    inc_data <= 64'h11223344_10203040;
    sop_valid <= 1'b0;
  end else if(i_cfg_tx_select_pkt_gen) begin
    if(sop_valid)
      inc_data <= i_rx_data;
    else if(compare_data_pipe2_state & ~rx_sop_reg & ~sop_valid) 
	  inc_data <= inc_data + 1;
	  
    if(compare_data_pipe2_state) 
	  sop_valid <= rx_sop_reg;
  end
end

//assign hdr_valid =   sop_valid |  (rx_sop_reg && compare_data_pipe2_state)  ;    
assign hdr_valid =   0 ;    
assign ref_data = i_cfg_tx_select_pkt_gen? {WORDS{inc_data}} :'d0;// rom_rdata[ROM_DATA_WIDTH-1 : (CTRL_BCNT)*8]; // reference data is rom or junk

always_ff @ (posedge i_clk)
    data_not_matched_reg2 <= i_cfg_tx_select_pkt_gen? compare_data_pipe2_state & ((rx_data_reg & rx_mask_reg) != (ref_data & rx_mask_reg)) :
                                                      compare_data_pipe2_state & (rx_data_reg != (ref_data & rx_mask_reg));


always_ff @ (posedge i_clk or posedge i_reset)
    if(i_reset)
        data_err_reg <= 1'b0;
    else if(data_not_matched_reg2 )
        data_err_reg <= 1'b1;

assign o_data_error = data_err_reg;


always_ff @ (posedge i_clk or posedge i_reset)
    if(i_reset)
        rx_packet_cnt[31:0] <= 32'h0;
    else if(compare_data_pipe2_state & rx_eop_reg)
        rx_packet_cnt[31:0] <= rx_packet_cnt[31:0] + 1'b1;

assign o_pkt_cnt_error = 1'b0;// (rx_packet_cnt[12:0] != (i_cfg_test_loop_cnt*6'd16)) ;

assign o_packet_cnt = rx_packet_cnt;

always_ff @ (posedge i_clk or posedge i_reset)
    if(i_reset)
        tx_packet_cnt[31:0] <= 32'h0;
    else if(i_cfg_pkt_gen_tx_en && i_tx_eop)
        tx_packet_cnt[31:0] <= tx_packet_cnt[31:0] + 1'b1;
        
//---------------------------------------------
//
//---------------------------------------------

eth_f_pkt_stat_counter stat_counter (
       .i_clk            (i_clk),
       .i_rst            (i_reset),

        //---MAC AVST---
       .i_valid          (i_rx_valid),
       .i_sop            (i_rx_sop),
       .i_eop            (i_rx_eop),
       .i_error          ({i_rx_error,{data_not_matched_reg2}}),//(rx_data_error),

        //---MAC segmented---
       .i_mac_valid      ('0),
       .i_mac_inframe    ('0),
       .i_mac_error      ('0),

        //---csr interface---
       .stat_cnt_clr        (stat_rx_cnt_clr),
       .stat_cnt_vld        (stat_rx_cnt_vld),
       .stat_sop_cnt        (stat_rx_sop_cnt),
       .stat_eop_cnt        (stat_rx_eop_cnt),
       .stat_err_cnt        (stat_rx_err_cnt)
);
defparam    stat_counter.CLIENT_IF_TYPE     = 1;
defparam    stat_counter.WORDS              = 1;
defparam    stat_counter.AVST_ERR_WIDTH     = 1;


//---------------------------------------------
//
//---------------------------------------------
logic        tx_valid_dlyd, tx_ready_dlyd;
logic        tx_clk_en;
logic        rx_clk_en;
real         tx_perf_data;
real         rx_perf_data;
reg          tx_done;        
reg          rx_done;

always @(posedge i_clk) begin
  tx_done  <= i_cfg_tx_select_pkt_gen? (tx_packet_cnt==i_dyn_pkt_num_sync) : 'd0;//(tx_packet_cnt==(i_cfg_test_loop_cnt*6'd16));
  rx_done  <= i_cfg_tx_select_pkt_gen? (rx_packet_cnt==i_dyn_pkt_num_sync) : 'd0;//(rx_packet_cnt==(i_cfg_test_loop_cnt*6'd16));
end

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset)
    tx_valid_dlyd <= 1'b0;
  else begin
    tx_valid_dlyd <= i_tx_valid;
	 tx_ready_dlyd <= i_tx_ready; end
end

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset)
    tx_clk_en <= 1'b0;
  else if(!i_cfg_pkt_gen_tx_en)
    tx_clk_en <= 1'b0;
  else if(i_cfg_pkt_gen_tx_en && i_tx_valid && i_tx_ready)
    tx_clk_en <= 1'b1;
  else
    tx_clk_en <= 1'b0;
end

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset)
    tx_num_ticks <= 0;
  else if (!i_cfg_pkt_gen_tx_en)
    tx_num_ticks <= 0;
  else if(tx_clk_en && !tx_done)
    tx_num_ticks <= tx_num_ticks + 1;
end

reg [63:0] cnt_1s;
reg        update_tx_bw_csr, update_rx_bw_csr;
reg [63:0] tx_word_cnt_in_1s, rx_word_cnt_in_1s;

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset)
    tx_bw_cnt <= 64'h0;
  else if (update_tx_bw_csr)
    tx_bw_cnt <= tx_word_cnt_in_1s;
end

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset)
    rx_bw_cnt <= 64'h0;
  else if (update_rx_bw_csr)
    rx_bw_cnt <= rx_word_cnt_in_1s;
end
	
always @(posedge i_clk or posedge i_reset) begin
  if(i_reset) begin
      cnt_1s <= 64'h0;
      update_tx_bw_csr <= 1'b0;
      update_rx_bw_csr <= 1'b0;
    end
  else begin
    if(cnt_1s == 64'h00000000099AB10C) begin //1sec  -- clock frequency 161.1328125 MHz
        cnt_1s <= 64'h0;
        update_tx_bw_csr <= 1'b1;
        update_rx_bw_csr <= 1'b1;
	  end
    else begin
      cnt_1s <= cnt_1s + 1;
      update_tx_bw_csr <= 1'b0;
      update_rx_bw_csr <= 1'b0;
	end 
  end
end

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset)
    tx_word_cnt_in_1s <= 64'h0;
  else if(update_tx_bw_csr)
    tx_word_cnt_in_1s <= 64'h0;
  else if (!i_cfg_pkt_gen_tx_en)  
      tx_word_cnt_in_1s <= 64'h0;
  else if(i_cfg_pkt_gen_tx_en && i_tx_valid && i_tx_ready)
    tx_word_cnt_in_1s <= tx_word_cnt_in_1s + 1;
end

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset)
    rx_word_cnt_in_1s <= 64'h0;
  else if(update_rx_bw_csr)
    rx_word_cnt_in_1s <= 64'h0;
//  else if (!i_cfg_pkt_gen_tx_en)  
//      rx_word_cnt_in_1s <= 64'h0;
//  else if(i_cfg_pkt_gen_tx_en && i_rx_valid)
  else if(i_rx_valid)
    rx_word_cnt_in_1s <= rx_word_cnt_in_1s + 1;
end

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset)
    rx_clk_en <= 1'b0;
 // else if(!i_cfg_pkt_gen_tx_en)
 //   rx_clk_en <= 1'b0;
  //else if(i_cfg_pkt_gen_tx_en && compare_data_pipe2_state)
  else if(compare_data_pipe2_state)
    rx_clk_en <= 1'b1;
end

always @(posedge i_clk or posedge i_reset) begin
  if(i_reset)
    rx_num_ticks <= 0;
//  else if (!i_cfg_pkt_gen_tx_en)
//    rx_num_ticks <= 0;
  else if(rx_clk_en && !rx_done)
    rx_num_ticks <= rx_num_ticks + 1;
end

always_ff @ (posedge i_clk or posedge i_reset)
  if(i_reset)
    tx_byte_cnt <= 64'h0;
 // else if (!i_cfg_pkt_gen_tx_en)
 //   tx_byte_cnt <= 64'h0;
  else if(tx_valid_dlyd && tx_ready_dlyd)
    tx_byte_cnt <= tx_byte_cnt + 8;

always_ff @ (posedge i_clk or posedge i_reset)
  if(i_reset)
    rx_byte_cnt <= 64'h0;
 // else if(!i_cfg_pkt_gen_tx_en)
 //   rx_byte_cnt <= 64'h0;
  else if(compare_data_pipe2_state)
    rx_byte_cnt <= rx_byte_cnt + 8;

// synthesis translate_off

/*always @(posedge tx_done) begin
  #1;
  tx_perf_data = (tx_byte_cnt*8) / (2.5 * tx_num_ticks);
  $display("*** TX PERFORMANCE MEASUREMENT *** ", $psprintf("no. of bytes = 0x%0h no. of packets = 0x%0h num_ticks = 0x%0h perf_data = %.4f Gb/s", tx_byte_cnt, tx_packet_cnt, tx_num_ ticks, tx_perf_data));
end

always @(posedge rx_done) begin
  #1;
  rx_perf_data = (rx_byte_cnt*8) / (2.5 * rx_num_ticks);
  $display("*** RX PERFORMANCE MEASUREMENT *** ", $psprintf("no. of bytes = 0x%0h no. of packets = 0x%0h num_ticks = 0x%0h perf_data = %.4f Gb/s", rx_byte_cnt, rx_packet_cnt, rx_num_  ticks, rx_perf_data));
  end*/
// synthesis translate_on

endmodule


