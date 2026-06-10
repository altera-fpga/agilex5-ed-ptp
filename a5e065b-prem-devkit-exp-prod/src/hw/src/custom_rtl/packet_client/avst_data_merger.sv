//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//
//////////////////////////////////////////////////////////////////////////////////////////
//
// Limitations
// - Ready allowance value expected is 16. This module implements 4-5 stages of pipeline.
//   If USE_RDY_ALLOWANCE is defined, it will implement Buffer logic to support ready_
//   allowance. Otherwise, ready is byapassed from Tx to Rx, assuming the Sink module will
//   take care of additional 4-5 cycles of latency.
//
// - Module is tested with a random sequence of packets, with 512-bit wide data bus.
//   Testing for other configurations are yet to be done
//

module avst_data_merger #(
  parameter     READY_ALLOWANCE = 16,              // AVST Ready allowance. Supported only if USE_RDY_ALLOWANCE is defined
  parameter             WIDTH = 64, 
  parameter             WORDS = 4,   
  parameter             CWIDTH = 2,                // Channel Width
  parameter             DWIDTH = WIDTH*WORDS   ,   // Data width, Possible values are 512, 256
  parameter             EWIDTH = $clog2(DWIDTH/8)+1 // Empty Width
  )(
  input                         clk_i,
  input                         rst_n_i,
  
  input                         rx_st_sop_i,
  input                         rx_st_eop_i,
  input                         rx_st_valid_i,
  input            [DWIDTH-1:0] rx_st_data_i,
  input            [EWIDTH-1:0] rx_st_empty_i,
  input            [CWIDTH-1:0] rx_st_channel_i,
  output                        rx_st_ready_o,
  
  output                        tx_st_sop_o,
  output                        tx_st_eop_o,
  output                        tx_st_valid_o,
  output           [DWIDTH-1:0] tx_st_data_o,
  output                        tx_st_eop_sync_with_macsec_tuser_error,
  //output           [EWIDTH-1:0] tx_st_empty_o,
  output           [EWIDTH*WORDS-1:0] tx_st_empty_o,
  output           [CWIDTH-1:0] tx_st_channel_o,
  input                         tx_st_ready_i
);

  //--------------------------------------------
  // Signals & Setting
  //--------------------------------------------
  
  localparam BWIDTH = $clog2(DWIDTH/8)+1; // Number of bytes
  localparam FIFO_ENTRIES = 32;
  localparam FIFO_WIDTH   = CWIDTH+EWIDTH+DWIDTH+1+1;
  localparam RDY_PIPE     = READY_ALLOWANCE-7;
  
  logic [FIFO_WIDTH-1:0]   rx_fifo_dout;
  
  logic                rx_fifo_st_sop;
  logic                rx_fifo_st_eop;
  logic                rx_fifo_st_val;
  logic [DWIDTH-1:0]   rx_fifo_st_dat;
  logic [EWIDTH-1:0]   rx_fifo_st_emp;
  logic [CWIDTH-1:0]   rx_fifo_st_chn;
  logic                rx_fifo_full;
  logic                rx_fifo_empty;
  logic                rx_fifo_almost_full;
  
  logic [DWIDTH/8-1:0] rx_st_ben;
  
  logic                rx_st_sop_stg0;
  logic                rx_st_eop_stg0;
  logic                rx_st_val_stg0;
  logic [DWIDTH-1:0]   rx_st_dat_stg0;
  logic [EWIDTH-1:0]   rx_st_emp_stg0;
  logic [CWIDTH-1:0]   rx_st_chn_stg0;
  logic [BWIDTH-1:0]   rx_st_wbc_stg0;
  
  logic                rx_st_sop_stg1;
  logic                rx_st_eop_stg1;
  logic                rx_st_val_stg1;
  logic [DWIDTH*2-1:0] rx_st_dat_stg1;
  logic [EWIDTH-1:0]   rx_st_emp_stg1;
  logic [CWIDTH-1:0]   rx_st_chn_stg1;
  logic [BWIDTH-1:0]   rx_st_wbc_stg1;
  
  logic                rx_st_sop_stg2;
  logic                rx_st_eop_stg2;
  logic                rx_st_val_stg2;
  logic [DWIDTH*2-1:0] rx_st_dat_stg2;
  logic [EWIDTH-1:0]   rx_st_emp_stg2;
  logic [CWIDTH-1:0]   rx_st_chn_stg2;
  logic [BWIDTH-1:0]   rx_st_wbc_stg2;
  logic [DWIDTH*2-1:0] rx_st_mask_stg2;
  
  logic                tx_st_sop_stg0;
  logic                tx_st_eop_stg0;
  logic                tx_st_val_stg0;
  logic [EWIDTH-1:0]   tx_st_emp_stg0;
  logic [DWIDTH-1:0]   tx_st_dat_stg0;
  logic [CWIDTH-1:0]   tx_st_chn_stg0;
  
  logic                tx_st_sop_stg1;
  logic                tx_st_eop_stg1;
  logic                tx_st_val_stg1;
  logic [EWIDTH-1:0]   tx_st_emp_stg1;
  logic [DWIDTH-1:0]   tx_st_dat_stg1;
  logic [CWIDTH-1:0]   tx_st_chn_stg1;
  
  logic                tx_st_buf_nempty;
  logic                tx_st_buf_pop;
  logic                tx_st_buf_pop_pre;
  logic                tx_st_buf_pop_mask;
  
  logic [RDY_PIPE-1:0] tx_st_ready_pipe;
  logic                tx_st_fifo_en;
  logic                tx_st_pipe_en;
  
  logic [31:EWIDTH] extra_bits_r2;
  
  //--------------------------------------------
  // Ready Allowance Control FIFO
  //--------------------------------------------
  
`ifdef USE_RDY_ALLOWANCE

  // Ready allowance is 16. Backpressoure source when FIFO does not have space for 16 entries.
  // Source is expected to deassert valid within 16 cycles after ready deassertion. This prevents
  // Buffer write when fifo is slowly drained at read side.
  scfifo #(
    .intended_device_family  ( "AGILEX" ),
    .lpm_numwords            ( FIFO_ENTRIES ),
    .lpm_showahead           ( "OFF" ),
    .lpm_type                ( "scfifo" ),
    .lpm_width               ( FIFO_WIDTH ),
    .lpm_widthu              ( $clog2(FIFO_ENTRIES) ),
    .almost_full_value       ( FIFO_ENTRIES - READY_ALLOWANCE ),
    .overflow_checking       ( "ON" ),
    .underflow_checking      ( "ON" ),
    .use_eab                 ( "OFF" ),
    .add_ram_output_register ( "OFF" )
  ) rx_rdy_allow_buf (
    .clock                   ( clk_i ),
    .sclr                    ( ~rst_n_i ),
    .aclr                    ( 1'b0 ),
    .data                    ( {rx_st_channel_i,rx_st_empty_i,rx_st_data_i,rx_st_eop_i,rx_st_sop_i} ),
    .wrreq                   ( rx_st_valid_i & ~ rx_fifo_full),
    .full                    ( rx_fifo_full ),
    .almost_full             ( rx_fifo_almost_full ),
    .usedw                   (  ),
    .rdreq                   ( ~rx_fifo_empty & tx_st_fifo_en),
    .q                       ( rx_fifo_dout ),
    .empty                   ( rx_fifo_empty ),
    .almost_empty            (  ),
    .eccstatus               (  )
  );
  
  always @(posedge clk_i) begin
    if(!rst_n_i) begin
      rx_fifo_st_val <= 1'b0;
    end else begin
      rx_fifo_st_val <= ~rx_fifo_empty & tx_st_fifo_en;
    end
  end
  
  // Ready allowance is 16. Aggregate tready signals in to a shift register and use this
  // OR-ed version as fifo read enable signal. When ready is deasserted, it stays in SHR
  // for 12 cycles, resulting in reading 12 more data. There may be data available in 
  // four stage pipeline as well. As a result, 16 more data beats may be presented when
  // ready is deasserted.
  
  always @(posedge clk_i) begin
    tx_st_ready_pipe <= {tx_st_ready_i,tx_st_ready_pipe[RDY_PIPE-1:1]};
    tx_st_fifo_en    <= |tx_st_ready_pipe;
  end
  
  assign {rx_fifo_st_chn,rx_fifo_st_emp,rx_fifo_st_dat,rx_fifo_st_eop,rx_fifo_st_sop} = rx_fifo_dout;
  assign tx_st_pipe_en = 1'b1;
  assign rx_st_ready_o = ~(rx_fifo_almost_full | rx_fifo_full);
  
`else

  assign rx_fifo_st_sop = rx_st_sop_i;
  assign rx_fifo_st_eop = rx_st_eop_i;
  assign rx_fifo_st_dat = rx_st_data_i;
  assign rx_fifo_st_emp = rx_st_empty_i;
  assign rx_fifo_st_chn = rx_st_channel_i;
  assign rx_fifo_st_val = rx_st_valid_i;
  assign tx_st_pipe_en = tx_st_ready_i;//1'b1;
  assign rx_st_ready_o = tx_st_ready_i;

`endif
  //--------------------------------------------
  // Rx Pipeline Stage 0 - Delay inputs
  //--------------------------------------------
  
  // Calculate byte strobe based on empty bytes value. For fragmented interface, it
  // is valid to have non-zero empty value at any beat position
  assign rx_st_ben = {(DWIDTH/8){1'b1}} >> rx_fifo_st_emp;
  
  // Pipeline Stage 0
  // Flop all the inputs inorder to ease timing, and it gives synthesis tool
  // freedom to retime these stages as hyper-registers.
        
  always @(posedge clk_i) begin
    if(!rst_n_i) begin
      rx_st_sop_stg0 <= 1'b0;
      rx_st_eop_stg0 <= 1'b0;
      rx_st_val_stg0 <= 1'b0;
      rx_st_dat_stg0 <= {2*DWIDTH{1'b0}};
      rx_st_emp_stg0 <= {EWIDTH{1'b0}};
      rx_st_chn_stg0 <= {CWIDTH{1'b0}};
      rx_st_wbc_stg0 <= {BWIDTH{1'b0}};
    end else begin
      if( rx_fifo_st_val && tx_st_pipe_en ) begin
        
        rx_st_sop_stg0 <= rx_fifo_st_sop;
        rx_st_eop_stg0 <= rx_fifo_st_eop;
        rx_st_emp_stg0 <= rx_fifo_st_emp;
        rx_st_chn_stg0 <= rx_fifo_st_chn;
        
        // Precalculate number of bytes in every beat in-order to use in next stage
        // Empty signal is also used.But byte count is more useful during shift 
        // operation as well as finding pointers
        //
        {extra_bits_r2,rx_st_wbc_stg0} <= (DWIDTH/8) - rx_fifo_st_emp;
        
        // Sample only valid data bytes to avoid junk data in data register. Data 
        // Reg is packetd with data bytes using OR operation at stage 1. Hence better 
        // to nullify any invalid bytes of input
        //
        for(int i=0;i<DWIDTH/8;i++) begin
          rx_st_dat_stg0[(i*8) +: 8] <= rx_st_ben[i]? rx_fifo_st_dat[(i*8) +: 8] : 8'h0;
        end
      end
      rx_st_val_stg0 <= (rx_st_val_stg0 & ~tx_st_pipe_en ) | rx_fifo_st_val;
    end
  end
  
  //--------------------------------------------
  // Rx Pipeline Stage 1 
  //--------------------------------------------
  
  // Pipeline Stage 1
  // Flop all the stage0 outputs inorder to ease timing, and it gives synthesis tool
  // freedom to retime these stages as hyper-registers. Do any precalculation for 
  // stage2 combination logic and flop it through stag1.
  
  always @(posedge clk_i) begin
    if(!rst_n_i) begin
      rx_st_sop_stg1 <= 1'b0;
      rx_st_eop_stg1 <= 1'b0;
      rx_st_val_stg1 <= 1'b0;
      rx_st_chn_stg1 <= {CWIDTH{1'b0}};
      rx_st_dat_stg1 <= {2*DWIDTH{1'b0}};
    end else begin
      if( tx_st_pipe_en ) begin
        rx_st_sop_stg1 <= rx_st_sop_stg0;
        rx_st_eop_stg1 <= rx_st_eop_stg0;
        rx_st_chn_stg1 <= rx_st_chn_stg0;
        
        // Shifting of current data & packing in to the shift register is expected to 
        // be done at stage2. Since both actions involve a combinational logic for up 
        // to 512-bits and it may create a gate cloud & lead to timing issues.
        // Do the shifting operation at stage1 as we already have number of bytes and
        // Data. packing will be done at stage2. The position for shift is calculated 
        // by accumulating byte counts.
        
        rx_st_dat_stg1 <= rx_st_dat_stg0 << (rx_st_wbc_stg1[BWIDTH-2:0]*8);
      end
      rx_st_val_stg1 <= (rx_st_val_stg1 & ~tx_st_pipe_en) | rx_st_val_stg0;
    end
  end 
  
  //--------------------------------------------
  // Rx Write Bytes Counter Stage 1
  //--------------------------------------------
  
  // Logic implements a accumulating counter (rx_st_wbc_stg1) from start of packet to end of packet
  // During SOP,rx_st_wbc_stg1[BWIDTH-2:0] will be loaded with number of bytes in first beat.
  // For every following beats, accummulate number of bytes in stage0 to rx_st_wbc_stg1[BWIDTH-1:0]. 
  // Once the counter overflows, rx_st_wbc_stg1[BWIDTH-1] toggles, and can be used to indicate a full 
  // or packed data availability. rx_st_wbc_stg1[BWIDTH-2:0] indicates the pointer for data shift & 
  // pack logic. Accumulation continues till EOP. 
  // During EOP, reset the counter & also manage rx_st_wbc_stg1[BWIDTH-1] to notify SHR read logic.
  logic [28:0] extra_bits_r1;
  reg tx_st_buf_pop_next;
  always @(posedge clk_i) begin
    if(!rst_n_i) begin
      rx_st_wbc_stg1 <= {BWIDTH{1'b0}};
      rx_st_emp_stg1 <= {EWIDTH{1'b0}};
      tx_st_buf_pop_mask <= 1'b0;
      tx_st_buf_pop_next <= 0;
    end else begin
      if( tx_st_pipe_en) begin
      
        // Stage 0 SOP=1,EOP=0 
        // Use stage0 counter as reset value. MSB Bit can be kept for tx logic to manage selection of buffer. 
        // Reset Stage 1 empty value to 0. Empty is allowed to be 0 only during EOP cycle
        
        if(rx_st_sop_stg0 && rx_st_val_stg0 && !rx_st_eop_stg0) begin
          rx_st_wbc_stg1 <= (~tx_st_buf_pop_next & rx_st_emp_stg0==0)?{~rx_st_wbc_stg1[BWIDTH-1],rx_st_wbc_stg0[BWIDTH-2:0]} : {rx_st_wbc_stg1[BWIDTH-1],rx_st_wbc_stg0[BWIDTH-2:0]};;
          rx_st_emp_stg1 <= {EWIDTH{1'b0}};
          tx_st_buf_pop_mask <= 1'b0;
          tx_st_buf_pop_next <= tx_st_buf_pop_next & ~(rx_st_val_stg0 & (rx_st_emp_stg0!=0));
          
        // Stage 0 SOP=1,EOP=1 
        // Use stage0 counter as reset value. MSB Bit is toggled to indicate data availability.
        // Reset Stage 1 empty value to 0. Empty is allowed to be 0 only during EOP cycle  
        end else if(rx_st_sop_stg0 && rx_st_val_stg0 && rx_st_eop_stg0) begin
          rx_st_wbc_stg1 <= tx_st_buf_pop_next ? {rx_st_wbc_stg1[BWIDTH-1],{(BWIDTH-1){1'b0}}} : {~rx_st_wbc_stg1[BWIDTH-1],{(BWIDTH-1){1'b0}}};
          rx_st_emp_stg1 <= rx_st_emp_stg0;
          tx_st_buf_pop_mask <= (rx_st_val_stg1 & ~tx_st_buf_pop_mask & rx_st_eop_stg1) ? 1'b0 : 1'b1;
          tx_st_buf_pop_next <= tx_st_buf_pop_next;//(rx_st_val_stg1 & ~tx_st_buf_pop_mask & rx_st_eop_stg1);
          
        // Stage 0 SOP=0,EOP=1
        // if end of packet is received, commit current packed buffer to tx, no further packing is needed.
        // Toggle rx_st_wbc_stg1[BWIDTH-1] such that frame packing always works in ping-pong way.
        // rx_st_wbc_stg1[BWIDTH-1] will be used in next stages as an indication of TX Data availability.
        // Empty value at stage1 EOP is calculated from current accumulator value & bytes during stage0 EOP.
        // An additional mask signal is generated to indiate TX logic that bytes from Stage 0 can be packed
        // to the current empty bytes or need additional cycle to push remaining data.
       /* 
        end else if(rx_st_eop_stg0 && rx_st_val_stg0) begin
          rx_st_wbc_stg1 <= tx_st_buf_pop_next? {rx_st_wbc_stg1[BWIDTH-1],{(BWIDTH-1){1'b0}}} : {~rx_st_wbc_stg1[BWIDTH-1],{(BWIDTH-1){1'b0}}};;
        {extra_bits_r1,rx_st_emp_stg1} <= DWIDTH/8 - rx_st_wbc_stg1[BWIDTH-2:0] - rx_st_wbc_stg0;
          tx_st_buf_pop_mask <= (rx_st_wbc_stg1[BWIDTH-2:0] <= rx_st_emp_stg0);
          tx_st_buf_pop_next <= tx_st_buf_pop_next | (rx_st_wbc_stg1[BWIDTH-2:0] > rx_st_emp_stg0);//~(rx_st_wbc_stg1[BWIDTH-2:0] <= rx_st_emp_stg0);
          */
		    
        end else if(rx_st_eop_stg0 && rx_st_val_stg0) begin
          rx_st_wbc_stg1 <= tx_st_buf_pop_next? {rx_st_wbc_stg1[BWIDTH-1],{(BWIDTH-1){1'b0}}} : {~rx_st_wbc_stg1[BWIDTH-1],{(BWIDTH-1){1'b0}}};;
        {extra_bits_r1,rx_st_emp_stg1} <= (tx_st_buf_pop_next |(rx_st_wbc_stg1[BWIDTH-2:0] > rx_st_emp_stg0)) ? ( rx_st_wbc_stg0 + rx_st_wbc_stg1[BWIDTH-2:0])- DWIDTH/8 :DWIDTH/8 - rx_st_wbc_stg1[BWIDTH-2:0] - rx_st_wbc_stg0;
          tx_st_buf_pop_mask <= (rx_st_wbc_stg1[BWIDTH-2:0] <= rx_st_emp_stg0);
          tx_st_buf_pop_next <= tx_st_buf_pop_next | (rx_st_wbc_stg1[BWIDTH-2:0] > rx_st_emp_stg0);//~(rx_st_wbc_stg1[BWIDTH-2:0] <= rx_st_emp_stg0);
          
        // Stage 0 SOP=0,EOP=0
        // Accumulate counter value with available byte count from stage 0. [BWIDTH-2:0] will give number of
        // bytes in current beat, and [BWIDTH-1] can be used as a pointer to ping-pong Data buffer(SHR)
        
        end else if(rx_st_val_stg0) begin
          rx_st_wbc_stg1 <= rx_st_wbc_stg1 + rx_st_wbc_stg0;
          rx_st_emp_stg1 <= {EWIDTH{1'b0}};
          tx_st_buf_pop_mask <= 1'b0;
          tx_st_buf_pop_next <= 1'b0;
          
        end else begin
          tx_st_buf_pop_next <= 1'b0;
        end
      end
    end
  end 
    
  //--------------------------------------------
  // Rx Pipeline Stage 2
  //--------------------------------------------
  
  always @(posedge clk_i) begin
    if(!rst_n_i) begin
      rx_st_sop_stg2 <= 1'b0;
      rx_st_eop_stg2 <= 1'b0;
      rx_st_val_stg2 <= 1'b0;
      rx_st_chn_stg2 <= {CWIDTH{1'b0}};
      rx_st_dat_stg2 <= {2*DWIDTH{1'b0}};
      rx_st_wbc_stg2 <= {BWIDTH{1'b0}};
      rx_st_emp_stg2 <= {EWIDTH{1'b0}};
    end else begin
      if( tx_st_pipe_en) begin
      
        // Latch stage1 sop & eop in to stage2. Since we are waiting for the buffer to be filled,
        // Keep the flops set until next packed data is 
        // sampled by Tx Stage 0. Clear when we are sure that Data, Valid, Sop, Eop are gone
        // out. tx_st_buf_nempty is used to clear as the same bit is used at Tx Stage 0 to 
        // pop packed buffer data.
        
        rx_st_sop_stg2 <= (rx_st_sop_stg2 & ~(tx_st_buf_pop | tx_st_buf_pop_pre)) | (rx_st_val_stg1 & rx_st_sop_stg1 & ~tx_st_buf_pop_pre);
        rx_st_eop_stg2 <= (rx_st_eop_stg2 & ~(tx_st_buf_pop | tx_st_buf_pop_pre)) | (rx_st_val_stg1 & rx_st_eop_stg1);
        rx_st_chn_stg2 <= rx_st_chn_stg1;
        rx_st_wbc_stg2 <= rx_st_wbc_stg1;
        //rx_st_emp_stg2 <= rx_st_emp_stg1;
        rx_st_emp_stg2 <= (tx_st_buf_pop_next)? DWIDTH/8 - rx_st_emp_stg1 :rx_st_emp_stg1;
        
        // The pointer rx_st_wbc_stg1[BWIDTH-1] is toggled whenever the number of bytes equals DWIDTH/8
        // indicating packed buffer is ready. rx_st_wbc_stg1[BWIDTH-1] can be used as the pointer to 
        // ping-pong shift register.
        
        // Data buffer is implemented as a packed register with twice the width (buf[2*DWIDTH-1:0]). rx_st_wbc_stg2[BWIDTH-1] 
        // is used as the rx buffer pointer. If this bit is false, pack the shifted data to buf[0+:DWIDTH]. If this bit is 
        // true, pack the shifted data to buf[DWIDTH+:DWIDTH]. When Bytes are packed, some of the bytes from current beat are 
        // expected to fill empty spaces in packing buffer, and the remaining bytes needs to be placed in the next buffer. 
        // Hence the input bytes are always shifted to buf[2*DWIDTH-1:0] when pointer is 0, or to {buf[DWIDTH-1:0],buf[DWIDTH-1:0]} 
        // when pointer is 1.
        // Shifting of input data to correct byte position is handled in stage1 to reduce combinational logic.
        
        if(!rx_st_wbc_stg2[BWIDTH-1])
          rx_st_dat_stg2 <= (rx_st_dat_stg2 & rx_st_mask_stg2) | rx_st_dat_stg1;
        else 
          {rx_st_dat_stg2[0+:DWIDTH],rx_st_dat_stg2[DWIDTH+:DWIDTH]} <= ({rx_st_dat_stg2[0 +: DWIDTH],rx_st_dat_stg2[DWIDTH+:DWIDTH]} & rx_st_mask_stg2) | rx_st_dat_stg1;
      end
      rx_st_val_stg2 <= (rx_st_val_stg2 & ~tx_st_buf_nempty) | rx_st_val_stg1;
    end
  end 
  
  // Since we are using OR operation to pack in data at correct posiiton, it may get OR-ed with older content & create junk data
  // Mask existing content at target byte positions before OR-ing new data input.
  assign rx_st_mask_stg2 = ~({DWIDTH{1'b1}} << {rx_st_wbc_stg2[BWIDTH-2:0],3'b000});
   
  //--------------------------------------------
  // Tx Data Mux Control
  //--------------------------------------------
  
  // When there is difference in stage1 & stage2 pointers MSB bits, it indicates availability of packed data or EOP reception
  // Use this signal to latch bufer content to tx stages
  assign tx_st_buf_nempty  = (rx_st_wbc_stg2[BWIDTH-1] ^ rx_st_wbc_stg1[BWIDTH-1]);
  assign tx_st_buf_pop_pre = tx_st_buf_nempty;
  
  // When EOP is received, it can result in packing of bytes in to current half, or it may span over two buffers
  // depending onnumber of bytes in EOP cycle & number of empty locations available in the half-buffer.
  // This signal indicates if some of the EOP bytes are packed in to next buffer location, in addition to filling 
  // current buffer empty positions. Us ethis signal to select tx data out.
  
  always @(posedge clk_i) begin
   if(!rst_n_i) begin
     tx_st_buf_pop <= 1'b0;
   end else begin
     tx_st_buf_pop <= tx_st_buf_pop_next;
//      tx_st_buf_pop <= ((rx_st_wbc_stg2[BWIDTH-1] ^ rx_st_wbc_stg1[BWIDTH-1]) | (rx_st_val_stg1 & rx_st_eop_stg1 & rx_st_sop_stg1) ) & 
//                       rx_st_eop_stg1 & (~tx_st_buf_pop_mask); 
   end
  end 
   
  //--------------------------------------------
  // Tx Pipeline Stage 0
  //--------------------------------------------
  logic [255:0] extra_bits;
  always @(posedge clk_i) begin
    if(!rst_n_i) begin
      tx_st_sop_stg0 <= 1'b0;
      tx_st_eop_stg0 <= 1'b0;
      tx_st_val_stg0 <= 1'b0;
      tx_st_dat_stg0 <= {DWIDTH{1'b0}};
      tx_st_chn_stg0 <= {CWIDTH{1'b0}};
      tx_st_emp_stg0 <= {EWIDTH{1'b0}};
    end else begin
      if (tx_st_pipe_en ) begin
        // Remaining Bytes of EOP beat are present in stage2 buffer register. Select data from buffer 
        // register based on the pointer position. Only excess bytes should be considered here. Other 
        // bytes of EOP cycle, which are filled in Empty locations are expected to be out on prv cycle.
        // Use SOP,EOP from stage2
        if(tx_st_buf_pop) begin
          tx_st_val_stg0 <= 1'b1;
          tx_st_chn_stg0 <= rx_st_chn_stg2;
          tx_st_sop_stg0 <= rx_st_sop_stg2;
          tx_st_emp_stg0 <= rx_st_emp_stg2;
          tx_st_eop_stg0 <= rx_st_eop_stg2;
          
          if(!rx_st_wbc_stg2[BWIDTH-1])
            tx_st_dat_stg0 <= rx_st_dat_stg2[0 +: DWIDTH];
          else 
            tx_st_dat_stg0 <= rx_st_dat_stg2[DWIDTH +: DWIDTH];
            
        // Current beat is expected to fill empty bytes in buffer register. 
        // Pack input data & pre-packed data from buffer register based on the pointer position
        // Packing stage2 buffer content with stage1 input data saves one cycle, and make it easier
        // to manage during EOP cycles when it has more bytes than current empty positions.
        // Use SOP,EOP from stage1
        end else if(tx_st_buf_pop_pre) begin

          tx_st_val_stg0 <= 1'b1;
          tx_st_chn_stg0 <= rx_st_chn_stg1;
          tx_st_sop_stg0 <= (rx_st_sop_stg2) | rx_st_sop_stg1;
          tx_st_eop_stg0 <= tx_st_buf_pop_mask? rx_st_eop_stg1  : 1'b0;
          tx_st_emp_stg0 <= tx_st_buf_pop_mask & rx_st_eop_stg1? rx_st_emp_stg1: {EWIDTH{1'b0}};
          
          if(!rx_st_wbc_stg2[BWIDTH-1])
           {extra_bits, tx_st_dat_stg0} <= (rx_st_dat_stg2 & rx_st_mask_stg2) | rx_st_dat_stg1;
          else 
          {extra_bits,  tx_st_dat_stg0} <= ({rx_st_dat_stg2[0 +: DWIDTH],rx_st_dat_stg2[DWIDTH +: DWIDTH]} & rx_st_mask_stg2) | rx_st_dat_stg1;
            
        end else begin
          tx_st_val_stg0 <= 1'b0;
        end
      end
    end
  end 
  
  //--------------------------------------------
  // Tx Pipeline Stage 1
  //--------------------------------------------
  
  // Additional pipeline stage before output to ease timing due to combo logic in last stage
  always @(posedge clk_i) begin
    if(!rst_n_i) begin
      tx_st_sop_stg1 <= 1'b0;
      tx_st_eop_stg1 <= 1'b0;
      tx_st_val_stg1 <= 1'b0;
      tx_st_dat_stg1 <= {DWIDTH{1'b0}};
      tx_st_chn_stg1 <= {CWIDTH{1'b0}};
      tx_st_emp_stg1 <= {EWIDTH{1'b0}};
    end else begin
      if( tx_st_pipe_en ) begin
        tx_st_sop_stg1 <= tx_st_sop_stg0;
        tx_st_eop_stg1 <= tx_st_eop_stg0;
        tx_st_val_stg1 <= tx_st_val_stg0;
        tx_st_dat_stg1 <= tx_st_dat_stg0;
        tx_st_chn_stg1 <= tx_st_chn_stg0;
        tx_st_emp_stg1 <= tx_st_emp_stg0;
      end
    end
  end
  
  //--------------------------------------------
  // Tx Output assignments from Stage 1
  //--------------------------------------------
  
  assign tx_st_sop_o     = tx_st_sop_stg1;
  assign tx_st_eop_o     = tx_st_eop_stg1;
  assign tx_st_valid_o   = tx_st_val_stg1;
  assign tx_st_data_o    = tx_st_dat_stg1;
  assign tx_st_empty_o   = tx_st_emp_stg1;
  assign tx_st_channel_o = tx_st_chn_stg1;
  assign tx_st_eop_sync_with_macsec_tuser_error = tx_st_eop_stg0;
endmodule
//---------------------------------------------------------------------
//
//  End avst_data_masrger.sv
//
//---------------------------------------------------------------------
