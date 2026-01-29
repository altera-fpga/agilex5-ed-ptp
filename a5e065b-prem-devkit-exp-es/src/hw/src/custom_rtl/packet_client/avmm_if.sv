//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


`ifndef __AVMM_IF_SV__
`define __AVMM_IF_SV__

//
// This is a private interface defining the platform-specific local memory
// controller interface.  This interface is used in the transition from
// AXI Lite to AVMM inside Altera-provided logic.  The interface is subject
// to change.
//

interface avmm_if
  #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 64,
    parameter BURSTCOUNT_WIDTH = 7
    )();

    // Number of bytes in a data line
    localparam DATA_N_BYTES = DATA_WIDTH / 8;

    // There is no reset, no clk.  Waitrequest will be active when no requests
    // are permitted.

    // Signals
    logic                        waitrequest;
    logic [DATA_WIDTH-1:0]       readdata;
    logic                        readdatavalid;

    logic [BURSTCOUNT_WIDTH-1:0] burstcount;
    logic [DATA_WIDTH-1:0]       writedata;
    logic [ADDR_WIDTH-1:0]       address;
    logic                        write;
    logic                        read;
    logic [DATA_N_BYTES-1:0]     byteenable;
    logic              [1:0]     response;
    logic                        writeresponsevalid;


    //
    // Connection to the master
    //
    modport master
       (
        input  waitrequest,
        input  readdata,
        input  readdatavalid,
        input  response,
        input  writeresponsevalid,

        output burstcount,
        output writedata,
        output address,
        output write,
        output read,
        output byteenable

        );


    //
    // Connection to the slave
    //
    modport slave 
       (
        output waitrequest,
        output readdata,
        output readdatavalid,
        output response,
        output writeresponsevalid,

        input  burstcount,
        input  writedata,
        input  address,
        input  write,
        input  read,
        input  byteenable

        );


endinterface : avmm_if //

`endif // __AVMM_IF_SV__
