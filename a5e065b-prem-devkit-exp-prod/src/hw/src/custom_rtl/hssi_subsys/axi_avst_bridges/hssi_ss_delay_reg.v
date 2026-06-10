//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module hssi_ss_delay_reg #(
    parameter CYCLES = 3,
    parameter WIDTH = 1
) (
    input              clk,
    input  [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i=i+1) begin : bit_loop
            hssi_ss_delay_reg_1b #(
                .CYCLES (CYCLES)
            ) delay_1b (
                .clk    (clk),
                .din    (din[i]),
                .dout   (dout[i])
            );
        end
    endgenerate
endmodule

module hssi_ss_delay_reg_1b #(
    parameter CYCLES = 1
) (
    input   clk,
    input   din,
    output  dout
);

    generate
        if (CYCLES == 0) begin
            assign dout = din;
        end else if (CYCLES == 1) begin
            reg state;
            always @(posedge clk) state <= din;
            assign dout = state;
        end else begin
            reg [CYCLES-1:0] state;
            always @(posedge clk) state <= {din, state[CYCLES-1:1]};
            assign dout = state[0];
        end
    endgenerate
endmodule
