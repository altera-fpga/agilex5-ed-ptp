//########################################################################
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//#########################################################################

// `define SVT_AXI_MAX_NUM_MASTERS_1
// `define SVT_AXI_MAX_NUM_SLAVES_1
// 
// `define SVT_AXI_MAX_ADDR_WIDTH 64
// 
// `define SVT_AXI_MAX_DATA_WIDTH 256

`define SVT_AXI_WSTRB_WIDTH 16

`define SVT_AXI_MAX_BURST_LENGTH_WIDTH 10

// TBD: place holder for PTP TS check
`define SM_PTP_TS_TOLERANCE 5

`ifndef SM_PTP_AXI_SYS_SEQUENCER
  `define SM_PTP_AXI_SYS_SEQUENCER env.axi_system_env.sequencer
`endif

`ifndef SM_PTP_AXI_MST_SEQUENCER
  `define SM_PTP_AXI_MST_SEQUENCER axi_system_env.master[0].sequencer
`endif

`ifndef SM_PTP_AXI_SLV_SEQUENCER
  `define SM_PTP_AXI_SLV_SEQUENCER axi_system_env.slave[0].sequencer
`endif

`ifndef SM_PTP_QSYS_TOP
  `define SM_PTP_QSYS_TOP tb_top.dut.soc_inst
`endif

`ifndef SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4
  `define SM_PTP_QSYS_TOP_MM_INT_SS_F2H_AXI4(sig) `SM_PTP_QSYS_TOP.mm_interconnect_2_subsys_hps_f2sdram_adapter_axi4_sub_``sig``
`endif

`ifndef SM_PTP_DUT_IOPLL
  `define SM_PTP_DUT_IOPLL `SM_PTP_QSYS_TOP.iopll_0
`endif

`ifndef SM_PTP_SSGDMA_PATH
  `define SM_PTP_SSGDMA_PATH `SM_PTP_QSYS_TOP.subsys_ssgdma.ssgdma
`endif

`ifndef SM_PTP_HSSI_SS0_PATH
  `define SM_PTP_HSSI_SS0_PATH tb_top.dut.gen_mulit_inst[0].hssi_ss_top
`endif

`ifndef SM_PTP_MOD_DEVKIT
`ifndef SM_PTP_HSSI_SS1_PATH
  `define SM_PTP_HSSI_SS1_PATH tb_top.dut.gen_mulit_inst[1].hssi_ss_top
`endif
`endif

`ifndef SM_PTP_EHIP_PORT0
  `define SM_PTP_EHIP_PORT0 `SM_PTP_HSSI_SS0_PATH.u0
`endif

`ifndef SM_PTP_EHIP_PORT1
  `define SM_PTP_EHIP_PORT1 `SM_PTP_HSSI_SS1_PATH.u0
`endif

`ifndef SM_PTP_F2H_CLK
  // `define SM_PTP_F2H_CLK dut.clk_bdg_100_clk
  `define SM_PTP_F2H_CLK dut.soc_inst.iopll_0.outclk_2
`endif

`ifndef SM_PTP_H2F_CLK
  `define SM_PTP_H2F_CLK dut.clk_bdg_125_clk
`endif

`ifndef SM_PTP_NUM_PORTS
  `define SM_PTP_NUM_PORTS 2
`endif

`ifndef SM_PTP_MAX_PORTS
  `define SM_PTP_MAX_PORTS 2
`endif

`ifndef SM_MSGDMA_NUM_CHANN_PER_PORT
  `define SM_MSGDMA_NUM_CHANN_PER_PORT 2
`endif

`ifndef SM_MSGDMA_MAX_CHANN_PER_PORT
  `define SM_MSGDMA_MAX_CHANN_PER_PORT 2
`endif

`ifndef SM_PTP_QSFP_DUT_PATH
  `define SM_PTP_QSFP_DUT_PATH tb_top.dut.qsfp_top_inst
`endif

// -------------------------MSGDMA CSR ---------------------------------------
`ifndef SM_PTP_MSGDMA_TX_PREF_P0_CH0_CSR
  `define SM_PTP_MSGDMA_TX_PREF_P0_CH0_CSR 'h0500_0000
`endif

`ifndef SM_PTP_MSGDMA_TX_DISP_P0_CH0_CSR
  `define SM_PTP_MSGDMA_TX_DISP_P0_CH0_CSR 'h0500_0020
`endif

`ifndef SM_PTP_MSGDMA_RX_PREF_P0_CH0_CSR
  `define SM_PTP_MSGDMA_RX_PREF_P0_CH0_CSR 'h0500_0080
`endif

`ifndef SM_PTP_MSGDMA_RX_DISP_P0_CH0_CSR
  `define SM_PTP_MSGDMA_RX_DISP_P0_CH0_CSR 'h0500_00A0
`endif

`ifndef SM_PTP_MSGDMA_TX_PREF_P0_CH1_CSR
  `define SM_PTP_MSGDMA_TX_PREF_P0_CH1_CSR 'h0500_0100
`endif

`ifndef SM_PTP_MSGDMA_TX_DISP_P0_CH1_CSR
  `define SM_PTP_MSGDMA_TX_DISP_P0_CH1_CSR 'h0500_0120
`endif

`ifndef SM_PTP_MSGDMA_RX_PREF_P0_CH1_CSR
  `define SM_PTP_MSGDMA_RX_PREF_P0_CH1_CSR 'h0500_0180
`endif

`ifndef SM_PTP_MSGDMA_RX_DISP_P0_CH1_CSR
  `define SM_PTP_MSGDMA_RX_DISP_P0_CH1_CSR 'h0500_01A0
`endif

`ifndef SM_PTP_MSGDMA_TX_PREF_P1_CH0_CSR
  `define SM_PTP_MSGDMA_TX_PREF_P1_CH0_CSR 'h0500_0200
`endif

`ifndef SM_PTP_MSGDMA_TX_DISP_P1_CH0_CSR
  `define SM_PTP_MSGDMA_TX_DISP_P1_CH0_CSR 'h0500_0220
`endif

`ifndef SM_PTP_MSGDMA_RX_PREF_P1_CH0_CSR
  `define SM_PTP_MSGDMA_RX_PREF_P1_CH0_CSR 'h0500_0280
`endif

`ifndef SM_PTP_MSGDMA_RX_DISP_P1_CH0_CSR
  `define SM_PTP_MSGDMA_RX_DISP_P1_CH0_CSR 'h0500_02A0
`endif

`ifndef SM_PTP_MSGDMA_TX_PREF_P1_CH1_CSR
  `define SM_PTP_MSGDMA_TX_PREF_P1_CH1_CSR 'h0500_0300
`endif

`ifndef SM_PTP_MSGDMA_TX_DISP_P1_CH1_CSR
  `define SM_PTP_MSGDMA_TX_DISP_P1_CH1_CSR 'h0500_0320
`endif

`ifndef SM_PTP_MSGDMA_RX_PREF_P1_CH1_CSR
  `define SM_PTP_MSGDMA_RX_PREF_P1_CH1_CSR 'h0500_0380
`endif

`ifndef SM_PTP_MSGDMA_RX_DISP_P1_CH1_CSR
  `define SM_PTP_MSGDMA_RX_DISP_P1_CH1_CSR 'h0500_03A0
`endif
// -------------------------MSGDMA CSR ---------------------------------------

// Device port CSR offsets
// addr [10:0]  register offset for ports
// addr [14:11] port number
// addr [17:15] reserved
// addr [19:18] 0 - d2h st, 1 h2d st

`ifndef SM_PTP_DMA_H2D0_DA
  `define SM_PTP_DMA_H2D0_DA 'h0011_2233
`endif

`ifndef SM_PTP_DMA_H2D0_SA
  `define SM_PTP_DMA_H2D0_SA 'h0022_3344
`endif

`ifndef SM_PTP_DMA_H2D1_DA
  `define SM_PTP_DMA_H2D1_DA 'h1111_2233
`endif

`ifndef SM_PTP_DMA_H2D1_SA
  `define SM_PTP_DMA_H2D1_SA 'h1122_3344
`endif

`ifndef SM_PTP_DMA_D2H0_DA
  `define SM_PTP_DMA_D2H0_DA 'h1122_2233
`endif

`ifndef SM_PTP_DMA_D2H0_SA
  `define SM_PTP_DMA_D2H0_SA 'h1133_3344
`endif

`ifndef SM_PTP_DMA_D2H1_DA
  `define SM_PTP_DMA_D2H1_DA 'h2211_2233
`endif

`ifndef SM_PTP_DMA_D2H1_SA
  `define SM_PTP_DMA_D2H1_SA 'h2222_3344
`endif

`ifndef SM_PTP_ETH_TYPE
  `define SM_PTP_ETH_TYPE 'h800
`endif

// --------HSSI---------------------------------------------------------------
`ifndef SM_PTP_HSSI_CSR_PORT0_SOFT_IP_BASE
  `define SM_PTP_HSSI_CSR_PORT0_SOFT_IP_BASE 'h4030_0100
`endif

`ifndef SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP
  `define SM_PTP_HSSI_CSR_PORT0_SOFT_IP_PTP 'h4030_0800
`endif

`ifndef SM_PTP_HSSI_CSR_PORT0_HARD_IP
  `define SM_PTP_HSSI_CSR_PORT0_HARD_IP 'h0032_0000
`endif

`ifndef SM_PTP_HSSI_CSR_PORT0_HARD_IP_EMAC
  `define SM_PTP_HSSI_CSR_PORT0_HARD_IP_EMAC 'h4035_0000
`endif

`ifndef SM_PTP_HSSI_CSR_PORT1_SOFT_IP_BASE
  `define SM_PTP_HSSI_CSR_PORT1_SOFT_IP_BASE 'h0050_0100
`endif

`ifndef SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP
  `define SM_PTP_HSSI_CSR_PORT1_SOFT_IP_PTP 'h4050_0800
`endif

`ifndef SM_PTP_HSSI_CSR_PORT1_HARD_IP
  `define SM_PTP_HSSI_CSR_PORT1_HARD_IP 'h0052_0000
`endif

`ifndef SM_PTP_HSSI_CSR_PORT1_HARD_IP_EMAC
  `define SM_PTP_HSSI_CSR_PORT1_HARD_IP_EMAC 'h0055_0000
`endif

// --------ETH BRIDGE / PKT CLIENT--------------------------------------------
`ifndef SM_PTP_BRIDGE_CSR_BASE
  `define SM_PTP_BRIDGE_CSR_BASE 'h1001_0000
`endif

`ifndef SM_PTP_BRIDGE_TCAM0_CSR_BASE
  `define SM_PTP_BRIDGE_TCAM0_CSR_BASE (`SM_PTP_BRIDGE_CSR_BASE + 'h100)
`endif

`ifndef SM_PTP_BRIDGE_TCAM0_CSR_LAST_ADDR
  `define SM_PTP_BRIDGE_TCAM0_CSR_LAST_ADDR (`SM_PTP_BRIDGE_CSR_BASE + 'h40FC)
`endif

`ifndef SM_PTP_BRIDGE_TCAM0_KEY_CSR_ADDR
 `define SM_PTP_BRIDGE_TCAM0_KEY_CSR_ADDR (`SM_PTP_BRIDGE_TCAM0_CSR_BASE+'h1000)
`endif

`ifndef SM_PTP_BRIDGE_TCAM0_RESULT_CSR_ADDR
 `define SM_PTP_BRIDGE_TCAM0_RESULT_CSR_ADDR (`SM_PTP_BRIDGE_TCAM0_CSR_BASE+'h2000)
`endif

`ifndef SM_PTP_BRIDGE_TCAM0_MASK_CSR_ADDR
 `define SM_PTP_BRIDGE_TCAM0_MASK_CSR_ADDR (`SM_PTP_BRIDGE_TCAM0_CSR_BASE+'h3000)
`endif

`ifndef SM_PTP_BRIDGE_TCAM1_CSR_BASE
  `define SM_PTP_BRIDGE_TCAM1_CSR_BASE (`SM_PTP_BRIDGE_CSR_BASE + 'h4200)
`endif

`ifndef SM_PTP_BRIDGE_TCAM1_CSR_LAST_ADDR
  `define SM_PTP_BRIDGE_TCAM1_CSR_LAST_ADDR (`SM_PTP_BRIDGE_CSR_BASE + 'h81FC)
`endif

`ifndef SM_PTP_BRIDGE_TCAM1_KEY_CSR_ADDR
 `define SM_PTP_BRIDGE_TCAM1_KEY_CSR_ADDR (`SM_PTP_BRIDGE_TCAM1_CSR_BASE+'h1000)
`endif

`ifndef SM_PTP_BRIDGE_TCAM1_RESULT_CSR_ADDR
 `define SM_PTP_BRIDGE_TCAM1_RESULT_CSR_ADDR (`SM_PTP_BRIDGE_TCAM1_CSR_BASE+'h2000)
`endif

`ifndef SM_PTP_BRIDGE_TCAM1_MASK_CSR_ADDR
 `define SM_PTP_BRIDGE_TCAM1_MASK_CSR_ADDR (`SM_PTP_BRIDGE_TCAM1_CSR_BASE+'h3000)
`endif

`ifndef SM_PTP_PKT_CLIENT_0_CSR_BASE
  `define SM_PTP_PKT_CLIENT_0_CSR_BASE 'h1000_0000
`endif

`ifndef SM_PTP_PKTCLI0_CFG_PKT_CL_CTRL
  `define SM_PTP_PKTCLI0_CFG_PKT_CL_CTRL (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h00)
`endif

`ifndef SM_PTP_PKTCLI0_DYN_DMAC_ADDR_U
 `define SM_PTP_PKTCLI0_DYN_DMAC_ADDR_U (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h0C)
`endif

`ifndef SM_PTP_PKTCLI0_DYN_DMAC_ADDR_L
 `define SM_PTP_PKTCLI0_DYN_DMAC_ADDR_L (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h10)
`endif

`ifndef SM_PTP_PKTCLI0_DYN_SMAC_ADDR_U
 `define SM_PTP_PKTCLI0_DYN_SMAC_ADDR_U (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h14)
`endif

`ifndef SM_PTP_PKTCLI0_DYN_SMAC_ADDR_L
 `define SM_PTP_PKTCLI0_DYN_SMAC_ADDR_L (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h18)
`endif

`ifndef SM_PTP_PKTCLI0_DYN_PKT_NUM
 `define SM_PTP_PKTCLI0_DYN_PKT_NUM (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h1C)
`endif

`ifndef SM_PTP_PKTCLI0_DYN_PKT_SIZE_CFG
 `define SM_PTP_PKTCLI0_DYN_PKT_SIZE_CFG (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h20)
`endif

`ifndef SM_PTP_PKTCLI0_STAT_TX_SOP_CNT_L
  `define SM_PTP_PKTCLI0_STAT_TX_SOP_CNT_L (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h24)
`endif

`ifndef SM_PTP_PKTCLI0_STAT_TX_SOP_CNT_U
  `define SM_PTP_PKTCLI0_STAT_TX_SOP_CNT_U (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h28)
`endif

`ifndef SM_PTP_PKTCLI0_STAT_TX_EOP_CNT_L
  `define SM_PTP_PKTCLI0_STAT_TX_EOP_CNT_L (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h2C)
`endif

`ifndef SM_PTP_PKTCLI0_STAT_TX_EOP_CNT_U
  `define SM_PTP_PKTCLI0_STAT_TX_EOP_CNT_U (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h30)
`endif

`ifndef SM_PTP_PKTCLI0_STAT_RX_SOP_CNT_L
  `define SM_PTP_PKTCLI0_STAT_RX_SOP_CNT_L (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h3C)
`endif

`ifndef SM_PTP_PKTCLI0_STAT_RX_SOP_CNT_U
  `define SM_PTP_PKTCLI0_STAT_RX_SOP_CNT_U (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h40)
`endif

`ifndef SM_PTP_PKTCLI0_STAT_RX_EOP_CNT_L
  `define SM_PTP_PKTCLI0_STAT_RX_EOP_CNT_L (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h44)
`endif

`ifndef SM_PTP_PKTCLI0_STAT_RX_EOP_CNT_U
  `define SM_PTP_PKTCLI0_STAT_RX_EOP_CNT_U (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h48)
`endif

`ifndef SM_PTP_PKTCLI0_STAT_CHK_MISC
  `define SM_PTP_PKTCLI0_STAT_CHK_MISC (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h58)
`endif

`ifndef SM_PTP_PKTCLI0_STAT_CHK_CNT
  `define SM_PTP_PKTCLI0_STAT_CHK_CNT (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h5c)
`endif

`ifndef SM_PTP_PKT_CLIENT_0_RX_BYTE_CNT_L
  `define SM_PTP_PKT_CLIENT_0_RX_BYTE_CNT_L (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h60)
`endif

`ifndef SM_PTP_PKT_CLIENT_0_RX_BYTE_CNT_U
  `define SM_PTP_PKT_CLIENT_0_RX_BYTE_CNT_U (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h64)
`endif

`ifndef SM_PTP_PKT_CLIENT_0_TX_BYTE_CNT_L
  `define SM_PTP_PKT_CLIENT_0_TX_BYTE_CNT_L (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h68)
`endif

`ifndef SM_PTP_PKT_CLIENT_0_TX_BYTE_CNT_U
  `define SM_PTP_PKT_CLIENT_0_TX_BYTE_CNT_U (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h6C)
`endif

`ifndef SM_PTP_PKT_CLIENT_0_TX_NUM_TICKS_L
  `define SM_PTP_PKT_CLIENT_0_TX_NUM_TICKS_L (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h70)
`endif

`ifndef SM_PTP_PKT_CLIENT_0_TX_NUM_TICKS_U
  `define SM_PTP_PKT_CLIENT_0_TX_NUM_TICKS_U (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h74)
`endif

`ifndef SM_PTP_PKT_CLIENT_0_RX_NUM_TICKS_L
  `define SM_PTP_PKT_CLIENT_0_RX_NUM_TICKS_L (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h78)
`endif

`ifndef SM_PTP_PKT_CLIENT_0_RX_NUM_TICKS_U
  `define SM_PTP_PKT_CLIENT_0_RX_NUM_TICKS_U (`SM_PTP_PKT_CLIENT_0_CSR_BASE+'h7C)
`endif

`ifndef SM_PTP_PKT_CLIENT_1_CSR_BASE
  `define SM_PTP_PKT_CLIENT_1_CSR_BASE 'h1000_1000
`endif

`ifndef SM_PTP_PKTCLI1_CFG_PKT_CL_CTRL
 `define SM_PTP_PKTCLI1_CFG_PKT_CL_CTRL (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h00)
`endif

`ifndef SM_PTP_PKTCLI1_DYN_DMAC_ADDR_U
 `define SM_PTP_PKTCLI1_DYN_DMAC_ADDR_U (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h0C)
`endif

`ifndef SM_PTP_PKTCLI1_DYN_DMAC_ADDR_L
 `define SM_PTP_PKTCLI1_DYN_DMAC_ADDR_L (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h10)
`endif

`ifndef SM_PTP_PKTCLI1_DYN_SMAC_ADDR_U
 `define SM_PTP_PKTCLI1_DYN_SMAC_ADDR_U (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h14)
`endif

`ifndef SM_PTP_PKTCLI1_DYN_SMAC_ADDR_L
 `define SM_PTP_PKTCLI1_DYN_SMAC_ADDR_L (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h18)
`endif

`ifndef SM_PTP_PKTCLI1_DYN_PKT_NUM
 `define SM_PTP_PKTCLI1_DYN_PKT_NUM (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h1C)
`endif

`ifndef SM_PTP_PKTCLI1_DYN_PKT_SIZE_CFG
 `define SM_PTP_PKTCLI1_DYN_PKT_SIZE_CFG (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h20)
`endif

`ifndef SM_PTP_PKTCLI1_STAT_TX_SOP_CNT_L
  `define SM_PTP_PKTCLI1_STAT_TX_SOP_CNT_L (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h24)
`endif

`ifndef SM_PTP_PKTCLI1_STAT_TX_SOP_CNT_U
  `define SM_PTP_PKTCLI1_STAT_TX_SOP_CNT_U (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h28)
`endif

`ifndef SM_PTP_PKTCLI1_STAT_TX_EOP_CNT_L
  `define SM_PTP_PKTCLI1_STAT_TX_EOP_CNT_L (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h2C)
`endif

`ifndef SM_PTP_PKTCLI1_STAT_TX_EOP_CNT_U
  `define SM_PTP_PKTCLI1_STAT_TX_EOP_CNT_U (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h30)
`endif

`ifndef SM_PTP_PKTCLI1_STAT_RX_SOP_CNT_L
  `define SM_PTP_PKTCLI1_STAT_RX_SOP_CNT_L (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h3C)
`endif

`ifndef SM_PTP_PKTCLI1_STAT_RX_SOP_CNT_U
  `define SM_PTP_PKTCLI1_STAT_RX_SOP_CNT_U (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h40)
`endif

`ifndef SM_PTP_PKTCLI1_STAT_RX_EOP_CNT_L
  `define SM_PTP_PKTCLI1_STAT_RX_EOP_CNT_L (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h44)
`endif

`ifndef SM_PTP_PKTCLI1_STAT_RX_EOP_CNT_U
  `define SM_PTP_PKTCLI1_STAT_RX_EOP_CNT_U (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h48)
`endif

`ifndef SM_PTP_PKTCLI1_STAT_CHK_MISC
  `define SM_PTP_PKTCLI1_STAT_CHK_MISC (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h58)
`endif

`ifndef SM_PTP_PKTCLI1_STAT_CHK_CNT
  `define SM_PTP_PKTCLI1_STAT_CHK_CNT (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h5c)
`endif

`ifndef SM_PTP_PKT_CLIENT_1_RX_BYTE_CNT_L
  `define SM_PTP_PKT_CLIENT_1_RX_BYTE_CNT_L (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h60)
`endif

`ifndef SM_PTP_PKT_CLIENT_1_RX_BYTE_CNT_U
  `define SM_PTP_PKT_CLIENT_1_RX_BYTE_CNT_U (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h64)
`endif

`ifndef SM_PTP_PKT_CLIENT_1_TX_BYTE_CNT_L
  `define SM_PTP_PKT_CLIENT_1_TX_BYTE_CNT_L (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h68)
`endif

`ifndef SM_PTP_PKT_CLIENT_1_TX_BYTE_CNT_U
  `define SM_PTP_PKT_CLIENT_1_TX_BYTE_CNT_U (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h6C)
`endif

`ifndef SM_PTP_PKT_CLIENT_1_TX_NUM_TICKS_L
  `define SM_PTP_PKT_CLIENT_1_TX_NUM_TICKS_L (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h70)
`endif

`ifndef SM_PTP_PKT_CLIENT_1_TX_NUM_TICKS_U
  `define SM_PTP_PKT_CLIENT_1_TX_NUM_TICKS_U (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h74)
`endif

`ifndef SM_PTP_PKT_CLIENT_1_RX_NUM_TICKS_L
  `define SM_PTP_PKT_CLIENT_1_RX_NUM_TICKS_L (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h78)
`endif

`ifndef SM_PTP_PKT_CLIENT_1_RX_NUM_TICKS_U
  `define SM_PTP_PKT_CLIENT_1_RX_NUM_TICKS_U (`SM_PTP_PKT_CLIENT_1_CSR_BASE+'h7C)
`endif
// --------PTP BRIDGE / PKT CLIENT--------------------------------------------

// --------USER SPACE CSR--------------------------------------------
`ifndef SM_PTP_USER_CSR
  `define SM_PTP_USER_CSR  'h4020_0000
`endif

`ifndef SM_PTP_USER_CSR_CTRL_REG
  `define SM_PTP_USER_CSR_CTRL_REG `SM_PTP_USER_CSR
`endif

`ifndef SM_PTP_USER_CSR_ERROR_REG
  `define SM_PTP_USER_CSR_ERROR_REG (`SM_PTP_USER_CSR+'h4)
`endif

`ifndef SM_PTP_USER_CSR_STATUS_REG
  `define SM_PTP_USER_CSR_STATUS_REG (`SM_PTP_USER_CSR+'h8)
`endif
// --------USER SPACE CSR--------------------------------------------

//------------------------SFP/QSFP-----------------------------//
`ifndef SM_PTP_QSFP0_SYSTEM_OFFSET
  `define SM_PTP_QSFP0_SYSTEM_OFFSET 'h4404_0000
`endif

`ifndef SM_PTP_QSFP1_SYSTEM_OFFSET
  `define SM_PTP_QSFP1_SYSTEM_OFFSET 'h4404_2000
`endif

`ifndef SM_PTP_QSFP0_CFG_REG
  `define SM_PTP_QSFP0_CFG_REG (`SM_PTP_QSFP0_SYSTEM_OFFSET + 'h20)
`endif

`ifndef SM_PTP_QSFP1_CFG_REG
  `define SM_PTP_QSFP1_CFG_REG (`SM_PTP_QSFP1_SYSTEM_OFFSET + 'h20)
`endif

`ifndef SM_PTP_QSFP0_TFR_CMD
  `define SM_PTP_QSFP0_TFR_CMD (`SM_PTP_QSFP0_SYSTEM_OFFSET + 'h40)
`endif

`ifndef SM_PTP_QSFP1_TFR_CMD
  `define SM_PTP_QSFP1_TFR_CMD (`SM_PTP_QSFP1_SYSTEM_OFFSET + 'h40)
`endif

`ifndef SM_MSGDMA_DESCR_LENGTH
  `define SM_MSGDMA_DESCR_LENGTH 512
`endif

//------------------------SFP/QSFP-----------------------------//
// dma addressing: [31]   : 0;
//                 [30:28]: DESCR/DMA_DATA;
//                 [27]   : H2D/D2H
//                 [26:25]: CH#;
//                 [24:23]: PORT#;
//                 [22:0] : $
`define D2H_ST_AGENT 1'd0
`define H2D_ST_AGENT 1'd1

`define DESCR	   3'd1
`define DMA_DATA 3'd2
`define RESP     3'd3

parameter PORT0_TXDMA_ADDR 			= 32'h2400_0000;
parameter PORT0_RXDMA_ADDR 			= 32'h2000_0000;
parameter PORT0_SA				= 48'hAAAA_AAAA_AAAA;
parameter PORT0_DA				= 48'hDDDD_DDDD_DDDD;
parameter PORT0_START_DESC_CTRL		        = 32'hC000_1300;
parameter PORT0_END_DESC_CTRL			= 32'h8000_1300;
parameter PORT1_START_DESC_CTRL	        	= 32'hC000_1301;
parameter PORT1_END_DESC_CTRL			= 32'h8000_1301;
parameter PORT2_START_DESC_CTRL	        	= 32'hC000_1302;
parameter PORT2_END_DESC_CTRL			= 32'h8000_1302;
parameter PORT3_START_DESC_CTRL	        	= 32'hC000_1303;
parameter PORT3_END_DESC_CTRL			= 32'h8000_1303;
parameter DMA_PORT0_BASE_TXDMA_PREF_ADDR       = 64'h448_0000;
parameter DMA_PORT0_BASE_TXDMA_CSR_ADDR        = 64'h448_0020;
parameter DMA_PORT0_BASE_RXDMA_PREF_ADDR       = 64'h448_0080;
parameter DMA_PORT0_BASE_RXDMA_CSR_ADDR        = 64'h448_00A0;
parameter DMA_PORT0_BASE_ADDR       = 64'h448_0000;
parameter PORT0_TXDESC_BASE_ADDR      = 64'h1400_0000;
parameter PORT0_RXDESC_BASE_ADDR      = 64'h1000_0000;

//-----------------------------------------------------------//
`define SM_PTP_HOST_WAIT_FOR_ALL_DESCR_WRBKS(h2d_port, h2d_ch, d2h_port, d2h_ch) \
begin \
  int considered_h2d_desc; \
  int considered_d2h_desc; \
\
  considered_h2d_desc = (h2d_descr_poll_en[h2d_port][h2d_ch] == 1) ? \
                        h2d_max_desc[h2d_port][h2d_ch] : h2d_max_desc[h2d_port][h2d_ch]-1; \
  considered_d2h_desc = (d2h_descr_poll_en[d2h_port][d2h_ch] == 1) ? \
                        d2h_max_desc[d2h_port][d2h_ch] : d2h_max_desc[d2h_port][d2h_ch]-1; \
\
  if (considered_d2h_desc > considered_h2d_desc) begin \
    `uvm_info(get_full_name(), \
              $sformatf("wait for d2h_desc_wrbk_cntr[%0d][%0d] == considered_h2d_desc(%0d)", \
                        d2h_port, d2h_ch, considered_h2d_desc), \
              UVM_DEBUG) \
    wait (d2h_desc_wrbk_cntr[d2h_port][d2h_ch] == considered_h2d_desc); \
  end else if (considered_d2h_desc <= considered_h2d_desc) begin \
    `uvm_info(get_full_name(), \
              $sformatf("wait for d2h_desc_wrbk_cntr[%0d][%0d] == considered_d2h_desc(%0d)", \
                        d2h_port, d2h_ch, considered_d2h_desc), \
              UVM_DEBUG) \
    wait (d2h_desc_wrbk_cntr[d2h_port][d2h_ch] == considered_d2h_desc); \
    // allow all h2d reads from DMA to complete \
  end \
  wait (h2d_desc_wrbk_cntr[h2d_port][h2d_ch] ==  considered_h2d_desc); \
end \

