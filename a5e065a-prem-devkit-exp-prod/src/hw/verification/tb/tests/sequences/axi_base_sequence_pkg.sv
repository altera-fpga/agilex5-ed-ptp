//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//########################################################################
//#All user defined structs for TB are defined here.
//########################################################################
package axi_base_sequence_pkg; // package name


typedef enum logic      {H2D , D2H} e_direction;

typedef enum logic      { D2H_ST_AGENT = 1'd0,
                          H2D_ST_AGENT = 1'd1
                        } e_agent_type; //
				
typedef enum logic[1:0] {
                         PORT_0 =	2'd0,
                         PORT_1	=	2'd1,
                         PORT_2	=	2'd2,
                         PORT_3	=	2'd3
                        } e_agent_port;

typedef enum logic [1:0] {
                          CHANN_0 = 2'b00,
                          CHANN_1 = 2'b01,
                          CHANN_2 = 2'b10,
                          CHANN_3 = 2'b11
                         } e_agent_channel;

typedef enum logic[2:0] {
              CSR      =        3'd0,
                                                        DESCR      =    3'd1,
                                                        DMA_DATA =      3'd2,
                                                        RESP     =      3'd3,
                                                        MSIX     =      3'd4,
                                                        BAM          =  3'd5
                                                }       e_address_type;

typedef struct packed {       
  logic [15:0] data3; // 2B
  logic [127:0] data2; // 16B           
  logic [127:0] data1; // 16B           
  logic [127:0] data0; // 16B           
  logic [15:0] len; // 2B       
  logic [47:0] sa;  // 6B
  logic [47:0] da;  // 6B
              
} eth_pkt;



typedef struct packed {
  bit   	Go;
  bit   	OwnedbyHW;
  bit[3:0]      Rsvd;
  bit   	WaitfrWriteResp;
  bit   	Earlydoneenable;
  bit[7:0]    	TrErrIRQEnable; 
  bit   	EarlyTerIRQEnable; 
  bit   	TransferCompIRQEnable; 
  bit           reserved;
  bit           EndonEOP;
  bit           ParkWrites;
  bit           ParkReads;
  bit           GenerateEOP;
  bit           GenerateSOP;
  bit		TransmitChannel;
} controlFieldMM_s;

typedef struct packed {
  bit   	desc_valid;
  bit [2:0] reserved_1;
  bit    	eop; // 0=H2D, 1=D2H
  bit     	sop;
  bit		irq_en;
  bit		reserved_0;
} controlFieldST_s;

//  controlFieldMM_s      Control;
typedef struct packed {
  bit [31:0]            Control;
  bit [95:0]            Reserved;
  bit [31:0]            NextDescptrU;
  bit [31:0]            WriteAddressU;
  bit [31:0]            ReadAddressU;
  bit [31:0]            Stride;
  bit [31:0]            BurstSeqnumber;
  bit [31:0]            Reserved1;
  bit [31:0]            Status; // 31:16 Reserved
  bit [31:0]            ActualBytesTransfered;
  bit [31:0]            NextDescptrL;
  bit [31:0]            Length;
  bit [31:0]            WriteAddressL;
  bit [31:0]            ReadAddressL;

} t_h2d_st_descriptor;

endpackage
