//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 
//
`timescale 1ns/1ps
module srd_rst_seq (
  input                i_clk,
  input                i_pwrgood_rst_n,
  input                i_rst_n,
  output logic         o_rst_n,
  input                i_rst_ack_n,
  output logic         o_rst_done
);

  //----------------------------------------------
  // Signals
  //----------------------------------------------

  localparam IDLE                 = 3'b000;
  localparam RST_N_ASSERTED       = 3'b001;
  localparam RST_ACK_N_ASSERTED   = 3'b010;
  localparam RST_ACK_N_DEASSERTED = 3'b011;
  localparam RST_SEQ_COMPLETE     = 3'b100;
  
  logic [2:0] state;
  logic       rst_n_dlyd;
  logic       rst_n_negedge;

  //----------------------------------------------
  // Req-Ack FSM
  //----------------------------------------------

  // synopsys translate_off
  initial begin
    state = IDLE;
    o_rst_n <= 1'b1;
    o_rst_done <= 1'b0;
  end
  // synopsys translate_on

  always @(posedge i_clk) begin
      rst_n_dlyd <= i_rst_n;
  end

  assign rst_n_negedge = ~i_rst_n & rst_n_dlyd;
  
  always @(posedge i_clk) begin
    if(!i_pwrgood_rst_n) begin
      state <= IDLE;
      o_rst_n <= 1'b1;
      o_rst_done <= 1'b0;
    end else begin
      case(state)
      IDLE: begin
        state <= RST_N_ASSERTED;
        o_rst_n <= 1'b0;
        o_rst_done <= 1'b0;
      end
      RST_N_ASSERTED: begin
        if(!i_rst_ack_n) begin
          state <= RST_ACK_N_ASSERTED;
          o_rst_n <= 1'b1;
          o_rst_done <= 1'b0;
        end
      end
      RST_ACK_N_ASSERTED: begin
        if(i_rst_ack_n) begin
          state <= RST_ACK_N_DEASSERTED;
        end
      end
      RST_ACK_N_DEASSERTED: begin
        state <= RST_SEQ_COMPLETE;
        o_rst_done <= 1'b1;
      end
      RST_SEQ_COMPLETE: begin
        if(!rst_n_negedge) begin
          state <= RST_SEQ_COMPLETE;
          o_rst_done <= 1'b1;
        end else begin
          state <= RST_N_ASSERTED;
          o_rst_n <= 1'b0;
          o_rst_done <= 1'b0;
        end
      end
      default: begin
        state <= IDLE;
        o_rst_n <= 1'b1;
        o_rst_done <= 1'b0;
      end
      endcase
    end
  end

endmodule
//---------------------------------------------------------------------
//
// End srd_rst_seq
//
//---------------------------------------------------------------------
