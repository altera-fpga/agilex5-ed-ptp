//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

`timescale 1 ps / 1 ps
module axi4lite2avmm_bridge #(
  parameter      USE_AVMM_RESPONSE = 0
)(
  input                            i_clk,
  input                            i_rstn,
  axi4lite_if.slave                axilite_slv,
  avmm_if.master                   avmm_mst
);

  //------------------------------------------------------
  // Internal signals
  //------------------------------------------------------

  logic [axilite_slv.AWADDR_WIDTH-1:0]  waddr;
  logic [axilite_slv.AWADDR_WIDTH-1:0]  raddr;
  logic [axilite_slv.WDATA_WIDTH-1:0]   wdata;
  logic [axilite_slv.RDATA_WIDTH-1:0]   rdata;
  logic [axilite_slv.WDATA_WIDTH/8-1:0] wstrb;
  logic                                 awreq;
  logic                                 awrdy;
  logic                                 wreq;
  logic                                 wrdy;
  logic                                 arreq;
  logic                                 arrdy;
  logic                                 wr_complete;
  logic                                 wr_resp_complete;
  logic                                 rd_complete;
  logic                                 rd_resp_complete;

  //-----------------------------------------------
  // Write address channel
  //-----------------------------------------------
  
  always @(posedge i_clk) begin
    if(!i_rstn) begin
       waddr <= {axilite_slv.AWADDR_WIDTH{1'b0}};
    end else begin
      if(axilite_slv.awvalid && axilite_slv.awready)
        waddr <= axilite_slv.awaddr;
    end
  end

  always @(posedge i_clk) begin
    if(!i_rstn) begin
      awreq <= 1'b0;
      awrdy <= 1'b0;
    end else begin
      awreq <= (awreq | (axilite_slv.awvalid && axilite_slv.awready)) & ~wr_complete;
      awrdy <= (awrdy | (axilite_slv.awvalid && axilite_slv.awready)) & ~wr_resp_complete;
    end
  end

  assign axilite_slv.awready = ~awrdy;

  //-----------------------------------------------
  // Write data channel
  //-----------------------------------------------

  always @(posedge i_clk) begin
    if(!i_rstn) begin
       wdata <= {axilite_slv.WDATA_WIDTH{1'b0}};
       wstrb <= {(axilite_slv.WDATA_WIDTH/8){1'b0}};
    end else begin
      if(axilite_slv.wvalid && axilite_slv.wready) begin
        wdata <= axilite_slv.wdata;
        wstrb <= axilite_slv.wstrb;
      end
    end
  end

  always @(posedge i_clk) begin
    if(!i_rstn) begin
      wreq <= 1'b0;
      wrdy <= 1'b0;
    end else begin
      wreq <= (wreq | (axilite_slv.wvalid && axilite_slv.wready)) & ~wr_complete;
      wrdy <= (wrdy | (axilite_slv.wvalid && axilite_slv.wready)) & ~wr_resp_complete;
    end
  end

  assign axilite_slv.wready = ~wrdy;

  //-----------------------------------------------
  // Read address channel
  //-----------------------------------------------
  
  always @(posedge i_clk) begin
    if(!i_rstn) begin
       raddr <= {axilite_slv.ARADDR_WIDTH{1'b0}};
    end else begin
      if(axilite_slv.arvalid && axilite_slv.arready)
        raddr <= axilite_slv.araddr;
    end
  end

  always @(posedge i_clk) begin
    if(!i_rstn) begin
      arreq <= 1'b0;
      arrdy <= 1'b0;
    end else begin
      arreq <= (arreq | (axilite_slv.arvalid && axilite_slv.arready)) & ~rd_complete;
      arrdy <= (arrdy | (axilite_slv.arvalid && axilite_slv.arready)) & ~rd_resp_complete;
    end
  end

  assign axilite_slv.arready = ~arrdy;

  //-----------------------------------------------
  // AVMM request channel
  //-----------------------------------------------

  always_comb begin
    case(1)
      awreq & wreq : begin
        avmm_mst.address    = waddr;
        avmm_mst.write      = 1;
        avmm_mst.read       = 0;
        avmm_mst.writedata  = wdata;
        avmm_mst.byteenable = wstrb;
        avmm_mst.burstcount = 1;
      end
      arreq : begin
        avmm_mst.address    = raddr;
        avmm_mst.write      = 0;
        avmm_mst.read       = 1;
        avmm_mst.writedata  = 0;
        avmm_mst.byteenable = 0;
        avmm_mst.burstcount = 1;
      end
      default : begin
        avmm_mst.address    = 0;
        avmm_mst.write      = 0;
        avmm_mst.read       = 0;
        avmm_mst.writedata  = 0;
        avmm_mst.byteenable = 0;
        avmm_mst.burstcount = 0;
      end
    endcase
  end

generate if (USE_AVMM_RESPONSE==0) begin: no_avmm_response_valid
  assign wr_complete = avmm_mst.write & ~avmm_mst.waitrequest;
  assign rd_complete = avmm_mst.read  & ~avmm_mst.waitrequest;
end else begin : use_avmm_response_valid
  assign wr_complete = avmm_mst.writeresponsevalid;
  assign rd_complete = avmm_mst.readdatavalid;
end endgenerate

  //-----------------------------------------------
  // Write response channel
  //-----------------------------------------------

  always @(posedge i_clk) begin
    if(!i_rstn) begin
      axilite_slv.bvalid <= 1'b0;
    end else begin
      axilite_slv.bvalid <= (axilite_slv.bvalid & ~axilite_slv.bready) | wr_complete ;
    end
  end

  assign wr_resp_complete = axilite_slv.bvalid & axilite_slv.bready;

generate if (USE_AVMM_RESPONSE==0) begin: no_avmm_wrresponse
  assign axilite_slv.bresp = 0;
end else begin: use_avmm_wrresponse
  assign axilite_slv.bresp = avmm_mst.response;
end endgenerate

  //-----------------------------------------------
  // Read response channel
  //-----------------------------------------------

  always @(posedge i_clk) begin
    if(!i_rstn) begin
      axilite_slv.rvalid <= 1'b0;
      axilite_slv.rdata <= 0;
    end else begin
      axilite_slv.rvalid <= (axilite_slv.rvalid & ~axilite_slv.rready) | avmm_mst.readdatavalid;
      axilite_slv.rdata <= avmm_mst.readdata[31:0];
    end
  end

  assign rd_resp_complete = axilite_slv.rvalid & axilite_slv.rready;

generate if (USE_AVMM_RESPONSE==0) begin: no_avmm_rdresponse
  assign axilite_slv.rresp = 0;
end else begin: use_avmm_rdresponse
  assign axilite_slv.rresp = avmm_mst.response;
end endgenerate
  
endmodule
