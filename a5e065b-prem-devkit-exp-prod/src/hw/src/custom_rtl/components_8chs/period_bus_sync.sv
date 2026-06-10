//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

module period_bus_sync #(
   parameter BUS_SIZE = 8
)
(
    input logic [BUS_SIZE-1:0]      in_data
   ,output logic [BUS_SIZE-1:0]     out_data
   ,input logic                     in_clk
   ,input logic                     in_reset
   ,input logic                     out_clk
   ,input logic                     out_reset
);
   localparam SYNC_CNT_WIDTH = 4;

   logic [BUS_SIZE-1:0] reg_in, reg_out;
   logic                in_valid;
   logic                out_valid;
   logic                resp_valid;
   logic [SYNC_CNT_WIDTH - 1:0] sync_cnt;

   cdc_toggle_synchronizer toggle_in(
      .in_clk          (in_clk     )
      ,.in_reset       (in_reset   )
      ,.out_clk        (out_clk    )
      ,.in_pulse       (in_valid   )
      ,.out_pulse      (out_valid  )
   );

   cdc_synchronizer #(
      .WIDTH            (BUS_SIZE      )
   ) sync (
      .out_clk          (out_clk       )
      ,.out_reset       (out_reset     )
      ,.in_data         (reg_in        )
      ,.out_data        (reg_out       )
);

   enum {get_data, reset_valid, wait_for_resp} state;
   always_ff @(posedge in_clk) begin
         if (in_reset) begin
            state <= get_data;
            in_valid <= '0;
         end else begin
            case (state) 
               get_data: begin 
                     reg_in <= in_data;
                     in_valid <= '1;
                     state <= reset_valid;
                     sync_cnt <= '0;
               end
               reset_valid: begin
                     in_valid <= '0;
                     state <= wait_for_resp;
               end
               wait_for_resp: begin
                  sync_cnt <= sync_cnt + 1'b1;
                  if (&sync_cnt) begin
                     state <= get_data;
                  end
               end
            endcase
         end
   end
   always_ff @(posedge out_clk) begin
      if (out_reset) begin
         out_data <= '0;
      end else begin
         if(out_valid) begin
            out_data <= reg_out;
         end
      end
   end
endmodule 