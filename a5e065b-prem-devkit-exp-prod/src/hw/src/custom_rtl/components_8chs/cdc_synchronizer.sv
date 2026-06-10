//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module cdc_synchronizer #(
    WIDTH = 8
) (
    input out_clk,
    input out_reset,
    input [WIDTH-1:0] in_data,
    output [WIDTH-1:0] out_data
);
    logic [WIDTH-1:0] in_data_meta /* synthesis preserve dont_replicate */;
    logic [WIDTH-1:0] q /* synthesis preserve dont_replicate */;

    always_ff @(posedge out_clk) begin
        if (out_reset) begin
            in_data_meta <= '0;
            q <= '0;
        end
        else begin
            in_data_meta <= in_data;
            q <= in_data_meta;
        end
    end

    assign out_data = q;
endmodule
