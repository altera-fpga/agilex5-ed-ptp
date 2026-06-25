//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//
// Description
//-----------------------------------------------------------------------------
//
//  This package contains the parameter and struct definition for 
//  SM-PTP System reference design
//
//----------------------------------------------------------------------------
package sm_ptp_pkg;
//localparam NON_PTP_ETHERNET =1;
localparam NUM_CHANNELS = 2;
//localparam NUM_MACSEC_INST = 2;
localparam PORT_PROFILE = "10GbE"; //speed
localparam EN_PPS_ADV = 1;
//localparam MAC_SRD_CFG_25G =1;
 
localparam TDATA_WIDTH = 64;
localparam TID = 1;
//localparam NO_OF_BYTES = 8;

localparam PTP_TX_CLASSIFIER_ENABLE = 0;

localparam FIFO_DEPTH = 12;
localparam DEBUG_ENABLE =1;

localparam TX_EGRESS = 128;
localparam RX_INGRESS = 96;

localparam PTP_FP_WIDTH =32;

//Packet Client
localparam AVST_DATA_W         = 64;
localparam DATA_WIDTH   	   = 64;
localparam EMPTY_WIDTH = $clog2(DATA_WIDTH/8)+1;
localparam WORDS   = DATA_WIDTH/AVST_DATA_W;
localparam PKT_CYL = 1;
localparam CLIENT_IF_TYPE = 1;
localparam READY_LATENCY = 0;


localparam DMA_DATA_WIDTH   = 64;
localparam USER_DATA_WIDTH  = 64;
localparam HSSI_DATA_WIDTH  = 64;

localparam PTP_WIDTH = 94;
localparam USER_NUM_OF_SEG = 1;
localparam RX_CLIENT_WIDTH = 7;

localparam AXIST_CTRL_USER_W   = 10;
localparam STS_WIDTH = 4; //5;
localparam STS_EXT_WIDTH = 32;
localparam TX_CLIENT_WIDTH = 2;
//localparam USER_PORT = 2;

//PTP bridge 
localparam TXEGR_TS_DW     = TX_EGRESS;
localparam RXIGR_TS_DW     = 96 ;
localparam PTP_EXT_WIDTH   = 328;
localparam TS_REQ_FP_WIDTH = 20;

localparam DMA_NUM_OF_SEG   = 1;
localparam HSSI_NUM_OF_SEG  = 1;
localparam PTP_BRDG_AWADDR_WIDTH = 16;
localparam PTP_BRDG_WDATA_WIDTH = 32;

localparam PTP_BRDG_HSSI_IGR_FIFO_DEPTH = 2048;
localparam PTP_BRDG_USER_IGR_FIFO_DEPTH = 512;
localparam PTP_BRDG_DMA_IGR_FIFO_DEPTH  = 512;

localparam SM_TCAM_KEY_WIDTH = 492; //112;
localparam SM_TCAM_RESULT_WIDTH = 32;
localparam SM_TCAM_ENTRIES = 64; //16;
localparam SM_TCAM_USERMETADATA_WIDTH = 1;

localparam IGR_DMA_BYTE_ROTATE = 0;
localparam IGR_USER_BYTE_ROTATE = 0;
localparam IGR_HSSI_BYTE_ROTATE = 1;

localparam EGR_DMA_BYTE_ROTATE = 1;
localparam EGR_USER_BYTE_ROTATE = 1;
localparam EGR_HSSI_BYTE_ROTATE = 0;

localparam DBG_CNTR_EN = 1;

endpackage : sm_ptp_pkg
