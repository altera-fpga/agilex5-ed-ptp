//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


`timescale 1 ps / 1 ps

module eth_f_pkt_gen_dyn_25G #(
	parameter WORDS = 1,
	parameter WIDTH = 64,
	parameter EMPTY_WIDTH = 5,
	parameter SOP_ON_LANE0       = 1'b0
)(
	input arst,
	input tx_pkt_gen_en,

	input [1:0] pattern_mode, //00,random, 01, fixed, 10 , incr
	input [13:0] start_addr, //also fixed addr
	input [13:0] end_addr,
	input [31:0] pkt_num, //number of packets to send in one start_pkt_gen pulse
	input end_sel,		//0, controled by stop_pkt_gen, 1 , controlled by pkt_num
	input ipg_sel,    //0, gap is random, 1, no gap between packets
	input [7:0] ipg_cycles,  // number of cycles to be used as inter packet gap cycles
	input [47:0] DEST_ADDR,
	input [47:0] SRC_ADDR,
	
	// TX to Ethernet
	input clk_tx,
	input tx_ack,
	output [WIDTH*WORDS-1:0] tx_data,
	output  tx_start,
	output tx_end_pos,
	output tx_valid,
	output [EMPTY_WIDTH-1:0] tx_empty,
	
	//---csr interface---
  input  logic          stat_tx_cnt_clr,
  output logic          stat_tx_cnt_vld,
  output logic [7:0]    stat_tx_sop_cnt,
  output logic [7:0]    stat_tx_eop_cnt,
  output logic [7:0]    stat_tx_err_cnt
);

//---------------------------------------------
//
//---------------------------------------------

eth_f_pkt_stat_counter stat_counter (
       .i_clk            (clk_tx),
       .i_rst            (arst),

        //---MAC AVST---
       .i_valid          (tx_valid & tx_ack),
       .i_sop            (tx_start),
       .i_eop            (tx_end_pos),
       .i_error          ('d0),

        //---MAC segmented---
       .i_mac_valid      ('0),
       .i_mac_inframe    ('0),
       .i_mac_error      ('0),

        //---csr interface---
       .stat_cnt_clr        (stat_tx_cnt_clr),
       .stat_cnt_vld        (stat_tx_cnt_vld),
       .stat_sop_cnt        (stat_tx_sop_cnt),
       .stat_eop_cnt        (stat_tx_eop_cnt),
       .stat_err_cnt        (stat_tx_err_cnt)
);
defparam    stat_counter.CLIENT_IF_TYPE     = 1;
defparam    stat_counter.WORDS              = 1;
defparam    stat_counter.AVST_ERR_WIDTH     = 1;

///////////////////////////////////////////////////////////////
// stop and restart the ack
///////////////////////////////////////////////////////////////

wire reset_sync = arst;

///////////////////////////////////////////////////////////////
// Packet generator
///////////////////////////////////////////////////////////////
wire tx_pkt_gen_en_sync;
 
//assign tx_empty         = alt_aeuex_wide_encode64to6(tx_end_pos);

eth_f_pkt_gen_dyn_tx_25G ps (
	.clk(clk_tx),
	.reset(reset_sync),
	.ena(tx_ack),
	.idle(!tx_pkt_gen_en_sync),
	.pattern_mode(pattern_mode),
	.start_addr(start_addr),
	.end_addr(end_addr),
	.pkt_num (pkt_num),
	.end_sel(end_sel),
	.ipg_sel(ipg_sel),
	.ipg_cycles(ipg_cycles),
	.SRC_ADDR(SRC_ADDR),
	.DEST_ADDR(DEST_ADDR),
		
	.sop(tx_start),
	.eop(tx_end_pos),
	.dout(tx_data),
	.empty(tx_empty),
	.valid(tx_valid)

);
defparam ps  .WORDS = WORDS;
defparam ps  .WIDTH = WIDTH;
defparam ps  .SOP_ON_LANE0 = SOP_ON_LANE0;

reg [3:0] tx_ctrls = 4'b0101;
alt_aeuex_pkt_gen_sync ss0 (
	.clk(clk_tx),
	.din(tx_pkt_gen_en),
	.dout(tx_pkt_gen_en_sync)
);
defparam ss0 .WIDTH = 1;


//------------------------------------------------------
endmodule

//------------------------------------------------------
//------------------------------------------------------
//------------------------------------------------------
//------------------------------------------------------
//------------------------------------------------------
//------------------------------------------------------
`timescale 1 ps / 1 ps
// baeckler - 06-09-2010
// altera message_off 10199 10230
module eth_f_pkt_gen_dyn_tx_25G #(
	parameter WORDS = 1,
	parameter WIDTH = 64,
	parameter MORE_SPACING = 1'b1,
	parameter CNTR_PAYLOAD = 1'b0,
	parameter EMPTY_WIDTH = 3,
    parameter SOP_ON_LANE0 = 1'b0
)(
	input clk,
	input reset,
	input ena,//ack
	input idle, //~(pkt gen enable)

	input [1:0] pattern_mode, //00,random, 01, fixed, 10 , incr
	input [13:0] start_addr, //also fixed addr
	input [13:0] end_addr,
	input [31:0] pkt_num, //number of packets to send,
	input end_sel,		//0, controled by stop_pkt_gen, 1 , controlled by pkt_num
	input ipg_sel,    //0, gap is random, 1, fixed gap
	input [7:0] ipg_cycles,  // gap cycles when ipg_sel=1
	input [47:0] DEST_ADDR,
	input [47:0] SRC_ADDR,
		
	output reg sop,
	output reg eop,
	output reg [WORDS*WIDTH-1:0] dout,
	output reg [EMPTY_WIDTH-1:0] empty,
	output reg valid	

);

/////////////////////////////////////////////////
// build some semi reasonable random bits

reg [31:0] cntr = 0;
always @(posedge clk) begin
	if (ena) cntr <= cntr + 1'b1;
end

wire [31:0] poly0 = 32'h8000_0241;
reg [31:0] prand0 = 32'hffff_ffff;
always @(posedge clk) begin
	prand0 <= {prand0[30:0],1'b0} ^ ((prand0[31] ^ cntr[31]) ? poly0 : 32'h0);
end

wire [31:0] poly1 = 32'h8deadfb3;
reg [31:0] prand1 = 32'hffff_ffff;
always @(posedge clk) begin
	prand1 <= {prand1[30:0],1'b0} ^ ((prand1[31] ^ cntr[30]) ? poly1 : 32'h0);
end

reg [15:0] prand2 = 0;
always @(posedge clk) begin
	prand2 <= cntr[23:8] ^ prand0[15:0] ^ prand1[15:0];
end

// mostly 1
reg prand3 = 1'b0;
always @(posedge clk) begin
	prand3 <= |(prand0[17:16] ^ prand1[17:16] ^ cntr[25:24]);
end

/////////////////////////////////////////////////

//    localparam DEST_ADDR = 48'h123456780ADD;
 //   localparam SRC_ADDR =  48'h876543210ADD;
    // States
    localparam IDLE        = 0,  // Idle state: 
               SOP       = 1,  // SOP stage
               DATA        = 2,  // DATA state
               DATA2        = 4,  // DATA2 state
	       EOP	 =3; 	//EOP

reg [2:0] state=0 ;
reg [13:0] packet_length= 0; //total length -4, no CRC in data
reg [13:0] payload_length; //total length -18, no CRC in data
reg [15:0] index;

reg [7:0] tx_ipg_counter;
reg nextpacket=0;
   always @(posedge clk) begin
        if (reset)   begin
          nextpacket <= 1'b0;
          tx_ipg_counter <= 0;
        end else if(!ipg_sel) begin
          nextpacket <= prand3; 
          tx_ipg_counter <= 0;
        end else begin
          nextpacket <= (tx_ipg_counter<=1); 
          if(state == SOP) 
            tx_ipg_counter <= ipg_cycles;
          else if(|tx_ipg_counter & ((state == IDLE) || (state == EOP))) 
            tx_ipg_counter <= tx_ipg_counter - 1'b1;
        end
		  //else nextpacket <= ipg_sel ? 1'b1: prand3;
	end

//wire nextpacket= ~prand3;
reg [2:0] state_next;
reg [13:0] packet_length_next =0;
reg [13:0]  payload_length_next=0;
reg [WORDS*WIDTH-1:0] dout_next=0;
reg [EMPTY_WIDTH-1:0] empty_next=0;
reg [EMPTY_WIDTH-1:0] empty_next_int=0;
reg [15:0] index_next=0;
reg sop_next=0;
reg eop_next=0;
reg valid_next=0;
reg [13:0] packet_length_saved_next;
reg [13:0] packet_length_saved=0;
reg unused_pktlength_flag_next;
reg unused_pktlength_flag=0;

reg [13:0] packet_length_cfg =0;
reg [31:0] pkt_cnt =0;
reg idle_dly =0 ;
wire end_pulse  = idle&(~idle_dly);
wire start_pulse = (~idle)&idle_dly;
reg sleep;
reg carry_int;

wire incr_pulse =  state == SOP &  ena & ~sleep  ;
    always @(posedge clk) begin
        if (reset)    begin
		sleep <= 1'b1;
	end
	else if(end_sel) sleep <= idle;  //pkt_gen control, free running
	else if (start_pulse) sleep <=0;	//start_pkt_gen to trigger start
	
	else if ((pkt_cnt==(pkt_num-1)) & ((state==IDLE)&nextpacket|state==SOP) & ena ) sleep <=1;	//pkt counter to trigger end		
   end

    always @(posedge clk) begin
        if (reset)    begin
		idle_dly <= 1'b0;
	end
	else idle_dly <= idle;
   end

    always @(posedge clk) begin
        if (reset)    begin
		packet_length_cfg <= start_addr;	
	end
        else  if(pattern_mode==2'b01)  packet_length_cfg <= start_addr;  //fixed mode, start_addr is the pakcet length
        else  if(pattern_mode==2'b00)  packet_length_cfg <= (prand2[13:0]> 14'd9600 ) ? 14'd9600 : ((prand2[13:0]<14'd64) ? 14'd64  : prand2[13:0] ); //random mode 64-9600
	else  if(pattern_mode==2'b10)  begin //incr mode, from start_addr to end_addr, increase 1 per packet
		if(start_pulse) packet_length_cfg <= start_addr;
		else if(incr_pulse && (packet_length_cfg==end_addr)) packet_length_cfg <= start_addr; //go back to start address
	
		else if(incr_pulse) {carry_int,packet_length_cfg} <= packet_length_cfg+1;
	
	end
    end

    wire [32:0] pkt_cnt_tmp=pkt_cnt+1;

    always @(posedge clk) begin
        if (reset)    begin
		pkt_cnt <= 32'h0;
	end
	else if (start_pulse) pkt_cnt <= 32'h0;
	else if (incr_pulse) pkt_cnt <= pkt_cnt_tmp[31:0];
    end


reg [WIDTH-1:0] rjunk;
//always @(posedge clk) begin
//	rjunk <= (rjunk << 4'hf) ^ prand2;
//end
always @(posedge clk) begin
  if(reset) rjunk <= 64'h11223344_10203040;

  //else if(valid_next & ~sop_next & ~sop & ena) rjunk <= rjunk+1;// added for controlling data when ready desert
  else if(valid_next & ena) 
    begin
	  if (state == SOP)
	    rjunk <= rjunk;
	  else
        rjunk <= rjunk+1;// added for controlling data when ready desert
	end
end


    always @(posedge clk) begin
        if (reset)    begin
		state <= IDLE;
		packet_length <= 14'h0;
		payload_length <= 14'h0;
		
		dout <= {WORDS*WIDTH{1'b0}};
		empty <={EMPTY_WIDTH{1'b0}};
		index <=16'h0;
		sop <= 1'b0;
		eop <= 1'b0;
		valid <= 1'b0;
	
		unused_pktlength_flag<=1'b0;
		packet_length_saved<=14'h0;
	end
        else       begin
		 state <= state_next; 
		packet_length <= packet_length_next;
		payload_length <= payload_length_next;
		
		dout <= dout_next;
		empty <= empty_next;
		index <= index_next;
		sop <= sop_next;
		eop <= eop_next;
		valid <=valid_next;
		
		unused_pktlength_flag<=unused_pktlength_flag_next;
		packet_length_saved<=packet_length_saved_next;
	end
    end  
 
    //-------------------------------------------------------------------------    
    // Next-state and output logic
    always @(*) begin
        state_next     = IDLE;  // Default next state 

	eop_next = eop;
	sop_next =sop;    
	valid_next =valid;   
	index_next = index; 
	empty_next = empty; 
	packet_length_next= packet_length;
	payload_length_next = payload_length;
	dout_next = dout;
	packet_length_saved_next=packet_length_saved;
	unused_pktlength_flag_next=unused_pktlength_flag;
        case (state)
            IDLE :  begin
                if (!ena ) begin
    				state_next = IDLE;
                    //eop_next = 1'b0;
                    //sop_next = 1'b0;
                    //valid_next = 1'b0;	
                  end
                else begin
                    eop_next = 1'b0;
                    sop_next =1'b0;
                    valid_next =1'b0;
                    //dout_next <= {WORDS*WIDTH{1'b0}};
                    if (sleep) state_next = IDLE;
                    else if(nextpacket) begin  
                        state_next = SOP;
                        
                        packet_length_next= (unused_pktlength_flag & pattern_mode==2'b10 )? packet_length_saved : packet_length_cfg;
                        
                        payload_length_next = (unused_pktlength_flag & pattern_mode==2'b10 )? packet_length_saved-14'd18 : packet_length_cfg -14'd18;
                       
                        unused_pktlength_flag_next=1'b0;	
                    end
                end
            end     
                         
            SOP : begin
				if (!ena) begin
					 state_next = SOP; 

				end

				else begin
                        dout_next  = {DEST_ADDR, SRC_ADDR[47:32]};
                        eop_next = 1'b0;
                        sop_next =1'b1;
                        valid_next =1'b1;
                        state_next = DATA2;
                        packet_length_next= packet_length - 14'd8;
                        empty_next_int = 6'd8-packet_length[2:0]+6'd4;
                        empty_next = empty_next_int;
                    end
            end
            DATA2: begin         
                if (!ena) state_next = DATA2;                        
                else  begin
                    sop_next = 1'b0;
                    eop_next = 1'b0;
                    valid_next =1'b1;
                    state_next = DATA;
                    packet_length_next= packet_length - 14'd8;
                    dout_next  = {SRC_ADDR[31:0], {2'b00,payload_length},index};
                end
            end 
            DATA: begin         
                if (!ena) state_next = DATA;                        
                else  begin
                    sop_next = 1'b0;
                    eop_next = 1'b0;
                    valid_next =1'b1;
                    if (packet_length <= 14'd20) begin
                        state_next = EOP;   
                        index_next = index + 1'b1;
                        dout_next = rjunk;
                    end
                    else    begin 
                        state_next = DATA;   				
                        packet_length_next= packet_length - 14'd8;
                        dout_next = rjunk;
                    end
                end
            end 
            EOP: begin   
			if (!ena) state_next = EOP;        
                        else begin
                eop_next = 1'b1;
                sop_next = 1'b0;
                valid_next =1'b1;	
                dout_next = rjunk;
                if (sleep)  state_next = IDLE;
                else  begin
                    if (nextpacket)   begin
                        state_next = SOP;      
                        packet_length_next= packet_length_cfg;
						payload_length_next = packet_length_cfg -14'd18;
                      
                    end
                    else begin
                        packet_length_saved_next= packet_length_cfg;//for incr mode only
                        unused_pktlength_flag_next = 1'b1;
                        state_next = IDLE;
                    end
                end
            end
        end
        endcase
    end

endmodule

//-------------------------------------------------
module alt_aeuex_pkt_gen_sync #(
        parameter WIDTH = 32
)(
        input clk,
        input [WIDTH-1:0] din,
        output [WIDTH-1:0] dout
);

reg [WIDTH-1:0] sync_0 = 0 /* synthesis preserve_syn_only */;
reg [WIDTH-1:0] sync_1 = 0 /* synthesis preserve_syn_only */;

always @(posedge clk) begin
        sync_0 <= din;
        sync_1 <= sync_0;
end
assign dout = sync_1;

endmodule
