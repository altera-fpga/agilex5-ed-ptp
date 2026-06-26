//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

//
// Description
//-----------------------------------------------------------------------------
//
// AXI Streaming Interface that complies with system reference design
//
//-----------------------------------------------------------------------------

interface axis_if #(
    parameter TID = 1,
    parameter DATA_W = 64
)(
   input wire clk,
   input wire rst_n
);

    localparam  KEEP_W = DATA_W/8;
/* 	
typedef struct packed {
  logic [6:0] client;
  logic [7:0] last_segment; 
} t_tuser;
 */

    logic               tvalid;
    logic               tlast;
    logic [TID-1:0]     tid;
    //t_tuser             tuser;
    logic [DATA_W-1:0]  tdata;
    logic [KEEP_W-1:0]  tkeep;
    logic               tready;
	

    modport source (

        output tvalid,
        output tlast,
        output tid,
        output tdata,
        output tkeep,
        input  tready
    );

    modport sink (

        input  tvalid,
        input  tlast,
        input  tid,
        input  tdata,
        input  tkeep,
        output tready
    );

`ifdef ASSERT_OFF
   `define AXIS_IF_ASSERT_OFF
`endif  // ASSERT_OFF

`ifndef AXIS_IF_ASSERT_OFF
// synopsys translate_off
   logic enable_assertion;

   initial begin
      enable_assertion = 1'b0;
      repeat(2)
         @(posedge clk);

      wait (rst_n === 1'b0);
      wait (rst_n === 1'b1);

      enable_assertion = 1'b1;
   end

   assert_tvalid_undef_when_not_in_reset:
      assert property (@(posedge clk) disable iff (~rst_n || ~enable_assertion) (!$isunknown(tvalid)))
      else $fatal(0,$psprintf("%8t: %m ASSERTION_ERROR, rx.tvalid is undefined", $time));

   assert_tready_undef_when_not_in_reset:
      assert property (@(posedge clk) disable iff (~rst_n || ~enable_assertion) (!$isunknown(tready)))
      else $fatal(0,$psprintf("%8t: %m ASSERTION_ERROR, tready is undefined", $time));

   /*assert_tdata_undef_when_tvalid_high:
      assert property (@(posedge clk) disable iff (~rst_n || ~enable_assertion) (tvalid |-> !$isunknown(tdata)))
      else $fatal(0,$psprintf("%8t: %m ASSERTION_ERROR, tdata is undefined when tvalid is asserted", $time));   */

   assert_tlast_undef_when_tvalid_high:
      assert property (@(posedge clk) disable iff (~rst_n || ~enable_assertion) (tvalid |-> !$isunknown(tlast)))
      else $fatal(0,$psprintf("%8t: %m ASSERTION_ERROR, tlast is undefined when tvalid is asserted", $time));

   assert_tkeep_undef_when_tvalid_high:
      assert property (@(posedge clk) disable iff (~rst_n || ~enable_assertion) (tvalid |-> !$isunknown(tkeep)))
      else $fatal(0,$psprintf("%8t: %m ASSERTION_ERROR, tid is undefined when tvalid is asserted", $time));

   assert_tid_undef_when_tvalid_high:
      assert property (@(posedge clk) disable iff ( ~rst_n || ~enable_assertion) (tvalid |-> !$isunknown(tid)))
      else $fatal(0,$psprintf("%8t: %m ASSERTION_ERROR, tid is undefined when tvalid is asserted", $time));

   assert_tvalid_tready_handshake:
      assert property (@(posedge clk) disable iff (~rst_n || ~enable_assertion) ( (tvalid && ~tready) |-> ##1 tvalid))
      else $fatal(0,$psprintf("%8t: %m ASSERTION_ERROR, tvalid is dropped before acknowledged by tready", $time));

// synopsys translate_on
`endif  // _AXIS_IF_ASSERT_OFF

endinterface : axis_if
