//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//
// Description
//-----------------------------------------------------------------------------
//
//  Definition of AXI-5 Memory Mapped Interfaces used in CoreFIM
//  This interface is parameterized with FIM-specific bus widths.
//
//-----------------------------------------------------------------------------

interface axi4lite_if #(
   parameter AWADDR_WIDTH = 32,
   parameter WDATA_WIDTH  = 32,
   parameter ARADDR_WIDTH = 32,
   parameter RDATA_WIDTH  = 32
   )();

   // Write address channel
   logic                       awready;
   logic                       awvalid;
   logic [AWADDR_WIDTH-1:0]    awaddr;
   logic [2:0]                 awprot;

   // Write data channel
   logic                       wready;
   logic                       wvalid;
   logic [WDATA_WIDTH-1:0]     wdata;
   logic [(WDATA_WIDTH/8-1):0] wstrb;

   // Write response channel
   logic                       bready;
   logic                       bvalid;
   logic [1:0]                 bresp;

   // Read address channel
   logic                       arready;
   logic                       arvalid;
   logic [ARADDR_WIDTH-1:0]    araddr;
   logic [2:0]                 arprot;

   // Read response channel
   logic                       rready;
   logic                       rvalid;
   logic [RDATA_WIDTH-1:0]     rdata;
   logic [1:0]                 rresp;

   // AFU <-> MemSS Modports, clock & reset are native from EMIF
   modport master (
        input  awready, wready,
               bvalid, bresp,
               arready,
               rvalid, rdata, rresp,
        output awvalid, awaddr, 
               awprot,
               wvalid, wdata, wstrb, 
               bready, 
               arvalid, araddr, 
               arprot,
               rready
   );

   modport slave (
        output awready, wready,
               bvalid, bresp,
               arready, 
               rvalid, rdata, rresp, 
        input  awvalid, awaddr,
               awprot,
               wvalid, wdata, wstrb,
               bready,
               arvalid, araddr, 
               arprot,
               rready
   );

   modport req (
        input  awready,
               wready,
               arready,
               bvalid, bready,
               rvalid, rready,
        output awvalid, awaddr, awprot,
               wvalid, wdata, wstrb,
               arvalid, araddr, arprot
   );

   modport rsp (
        input  bvalid, bresp,
               rvalid, rdata, rresp,
        output bready,
               rready
   );

endinterface : axi4lite_if
