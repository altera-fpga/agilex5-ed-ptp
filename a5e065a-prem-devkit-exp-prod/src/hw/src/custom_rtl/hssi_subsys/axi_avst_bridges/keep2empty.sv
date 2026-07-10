//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

// ==========================================================================
// Project           : HSSI Subsystem 
// Module            : keep2empty.sv
// Description       : 
// Author            : 
// Created           : 
// Changes           : 
//                   : 
// ==========================================================================


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on


module keep2empty #(
    parameter EMPTY_BITS         = 3,
    parameter NO_OF_BYTES        = 8 
    
) (
    input                                clk, 
    // input                                rst_n, 
    // input      [NO_OF_BYTES-1:0] keep_bits_in, 
    input      [63:0] keep_bits_in, 
    output  [EMPTY_BITS-1:0]  empty_bits_out_d1

);

//***********************************************************
//***********************************************************
//reg [11:0] empty_bits_out = '0;
wire [11:0] empty_bits_out;

reg [63:0] keep_bits_in_d1 = '0;

assign empty_bits_out_d1 = empty_bits_out[EMPTY_BITS-1:0];
//reg [NO_OF_BYTES-1:0] keep_reg;
//reg [NO_OF_BYTES-1:0] empty_bytes;

// always @(posedge clk or negedge rst_n)     //* remove reset
// begin
    // if (~rst_n)
        // empty_bits_out_d1 <= {EMPTY_BITS{1'b0}};
    // else 
        // empty_bits_out_d1 <= empty_bytes(keep_bits_in);
// end

always @(posedge clk)     //* remove reset
begin
//   empty_bits_out <= tkeep2empty_64(keep_bits_in);
keep_bits_in_d1 <= keep_bits_in;
end

assign empty_bits_out = tkeep2empty_64(keep_bits_in_d1);
    
  function [11:0] tkeep2empty_64 ;
  
    input  logic [63:0] tkeep ;
      begin
      /* case (tkeep)
 
          64'h0000_0000_0000_0000 : tkeep2empty_64 = 12'd0 ;  //'d8 ;
          64'h0000_0000_0000_0001 : tkeep2empty_64 = 12'd63;  //'d7 ;  //'d15 //'d31
          64'h0000_0000_0000_0003 : tkeep2empty_64 = 12'd62;  //'d6 ;  //'d14 //'d30
          64'h0000_0000_0000_0007 : tkeep2empty_64 = 12'd61;  //'d5 ;  //'d13 //'d29
          64'h0000_0000_0000_000F : tkeep2empty_64 = 12'd60;  //'d4 ;  //'d12 //'d28
          64'h0000_0000_0000_001F : tkeep2empty_64 = 12'd59;  //'d3 ;  //'d11 //'d27
          64'h0000_0000_0000_003F : tkeep2empty_64 = 12'd58;  //'d2 ;  //'d10 //'d26
          64'h0000_0000_0000_007F : tkeep2empty_64 = 12'd57;  //'d1 ;  //'d9  //'d25
          64'h0000_0000_0000_00FF : tkeep2empty_64 = 12'd56;  //'d0 ;  //'d8  //'d24
          64'h0000_0000_0000_01FF : tkeep2empty_64 = 12'd55;           //'d7  //'d23
          64'h0000_0000_0000_03FF : tkeep2empty_64 = 12'd54;           //'d6  //'d22
          64'h0000_0000_0000_07FF : tkeep2empty_64 = 12'd53;           //'d5  //'d21
          64'h0000_0000_0000_0FFF : tkeep2empty_64 = 12'd52;           //'d4  //'d20
          64'h0000_0000_0000_1FFF : tkeep2empty_64 = 12'd51;           //'d3  //'d19
          64'h0000_0000_0000_3FFF : tkeep2empty_64 = 12'd50;           //'d2  //'d18
          64'h0000_0000_0000_7FFF : tkeep2empty_64 = 12'd49;           //'d1  //'d17
          64'h0000_0000_0000_FFFF : tkeep2empty_64 = 12'd48;           //'d0  //'d16
          64'h0000_0000_0001_FFFF : tkeep2empty_64 = 12'd47;                  //'d15 
          64'h0000_0000_0003_FFFF : tkeep2empty_64 = 12'd46;                  //'d14 
          64'h0000_0000_0007_FFFF : tkeep2empty_64 = 12'd45;                  //'d13 
          64'h0000_0000_000F_FFFF : tkeep2empty_64 = 12'd44;                  //'d12 
          64'h0000_0000_001F_FFFF : tkeep2empty_64 = 12'd43;                  //'d11 
          64'h0000_0000_003F_FFFF : tkeep2empty_64 = 12'd42;                  //'d10 
          64'h0000_0000_007F_FFFF : tkeep2empty_64 = 12'd41;                  //'d9  
          64'h0000_0000_00FF_FFFF : tkeep2empty_64 = 12'd40;                  //'d8  
          64'h0000_0000_01FF_FFFF : tkeep2empty_64 = 12'd39;                  //'d7  
          64'h0000_0000_03FF_FFFF : tkeep2empty_64 = 12'd38;                  //'d6  
          64'h0000_0000_07FF_FFFF : tkeep2empty_64 = 12'd37;                  //'d5  
          64'h0000_0000_0FFF_FFFF : tkeep2empty_64 = 12'd36;                  //'d4  
          64'h0000_0000_1FFF_FFFF : tkeep2empty_64 = 12'd35;                  //'d3  
          64'h0000_0000_3FFF_FFFF : tkeep2empty_64 = 12'd34;                  //'d2  
          64'h0000_0000_7FFF_FFFF : tkeep2empty_64 = 12'd33;                  //'d1  
          64'h0000_0000_FFFF_FFFF : tkeep2empty_64 = 12'd32;                  //'d0  
          64'h0000_0001_FFFF_FFFF : tkeep2empty_64 = 12'd31;
          64'h0000_0003_FFFF_FFFF : tkeep2empty_64 = 12'd30;
          64'h0000_0007_FFFF_FFFF : tkeep2empty_64 = 12'd29;
          64'h0000_000F_FFFF_FFFF : tkeep2empty_64 = 12'd28;
          64'h0000_001F_FFFF_FFFF : tkeep2empty_64 = 12'd27;
          64'h0000_003F_FFFF_FFFF : tkeep2empty_64 = 12'd26;
          64'h0000_007F_FFFF_FFFF : tkeep2empty_64 = 12'd25;
          64'h0000_00FF_FFFF_FFFF : tkeep2empty_64 = 12'd24;
          64'h0000_01FF_FFFF_FFFF : tkeep2empty_64 = 12'd23;
          64'h0000_03FF_FFFF_FFFF : tkeep2empty_64 = 12'd22;
          64'h0000_07FF_FFFF_FFFF : tkeep2empty_64 = 12'd21;
          64'h0000_0FFF_FFFF_FFFF : tkeep2empty_64 = 12'd20;
          64'h0000_1FFF_FFFF_FFFF : tkeep2empty_64 = 12'd19;
          64'h0000_3FFF_FFFF_FFFF : tkeep2empty_64 = 12'd18;
          64'h0000_7FFF_FFFF_FFFF : tkeep2empty_64 = 12'd17;
          64'h0000_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd16;
          64'h0001_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd15;
          64'h0003_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd14;
          64'h0007_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd13;
          64'h000F_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd12;
          64'h001F_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd11;
          64'h003F_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd10;
          64'h007F_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd9 ; 
          64'h00FF_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd8 ; 
          64'h01FF_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd7 ; 
          64'h03FF_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd6 ; 
          64'h07FF_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd5 ; 
          64'h0FFF_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd4 ; 
          64'h1FFF_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd3 ;
          64'h3FFF_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd2 ;
          64'h7FFF_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd1 ;
          64'hFFFF_FFFF_FFFF_FFFF : tkeep2empty_64 = 12'd0 ;
          default                 : tkeep2empty_64 = 12'd0 ;   
 
        endcase
                */
             case(1)
                 tkeep[63] : tkeep2empty_64 = 12'd0 ;
                 tkeep[62] : tkeep2empty_64 = 12'd1 ; 
                 tkeep[61] : tkeep2empty_64 = 12'd2 ; 
                 tkeep[60] : tkeep2empty_64 = 12'd3 ; 
                 tkeep[59] : tkeep2empty_64 = 12'd4 ;
                 tkeep[58] : tkeep2empty_64 = 12'd5 ; 
                 tkeep[57] : tkeep2empty_64 = 12'd6 ; 
                 tkeep[56] : tkeep2empty_64 = 12'd7 ; 
                 tkeep[55] : tkeep2empty_64 = 12'd8 ; 
                 tkeep[54] : tkeep2empty_64 = 12'd9 ; 

                 tkeep[53] : tkeep2empty_64 = 12'd10 ; 
                 tkeep[52] : tkeep2empty_64 = 12'd11 ;
                 tkeep[51] : tkeep2empty_64 = 12'd12 ; 
                 tkeep[50] : tkeep2empty_64 = 12'd13 ; 
                 tkeep[49] : tkeep2empty_64 = 12'd14 ; 
                 tkeep[48] : tkeep2empty_64 = 12'd15 ;
                 tkeep[47] : tkeep2empty_64 = 12'd16 ; 
                 tkeep[46] : tkeep2empty_64 = 12'd17 ; 
                 tkeep[45] : tkeep2empty_64 = 12'd18 ; 
                 tkeep[44] : tkeep2empty_64 = 12'd19 ; 

                 tkeep[43] : tkeep2empty_64 = 12'd20 ; 
                 tkeep[42] : tkeep2empty_64 = 12'd21 ;
                 tkeep[41] : tkeep2empty_64 = 12'd22 ; 
                 tkeep[40] : tkeep2empty_64 = 12'd23 ; 
                 tkeep[39] : tkeep2empty_64 = 12'd24 ; 
                 tkeep[38] : tkeep2empty_64 = 12'd25 ;
                 tkeep[37] : tkeep2empty_64 = 12'd26 ; 
                 tkeep[36] : tkeep2empty_64 = 12'd27 ; 
                 tkeep[35] : tkeep2empty_64 = 12'd28 ; 
                 tkeep[34] : tkeep2empty_64 = 12'd29 ; 

                 tkeep[33] : tkeep2empty_64 = 12'd30 ; 
                 tkeep[32] : tkeep2empty_64 = 12'd31 ;
                 tkeep[31] : tkeep2empty_64 = 12'd32 ; 
                 tkeep[30] : tkeep2empty_64 = 12'd33 ; 
                 tkeep[29] : tkeep2empty_64 = 12'd34 ; 
                 tkeep[28] : tkeep2empty_64 = 12'd35 ;
                 tkeep[27] : tkeep2empty_64 = 12'd36 ; 
                 tkeep[26] : tkeep2empty_64 = 12'd37 ; 
                 tkeep[25] : tkeep2empty_64 = 12'd38 ; 
                 tkeep[24] : tkeep2empty_64 = 12'd39 ; 

                 tkeep[23] : tkeep2empty_64 = 12'd40 ; 
                 tkeep[22] : tkeep2empty_64 = 12'd41 ;
                 tkeep[21] : tkeep2empty_64 = 12'd42 ; 
                 tkeep[20] : tkeep2empty_64 = 12'd43 ; 
                 tkeep[19] : tkeep2empty_64 = 12'd44 ; 
                 tkeep[18] : tkeep2empty_64 = 12'd45 ;
                 tkeep[17] : tkeep2empty_64 = 12'd46 ; 
                 tkeep[16] : tkeep2empty_64 = 12'd47 ; 
                 tkeep[15] : tkeep2empty_64 = 12'd48 ; 
                 tkeep[14] : tkeep2empty_64 = 12'd49 ; 

                 tkeep[13] : tkeep2empty_64 = 12'd50 ; 
                 tkeep[12] : tkeep2empty_64 = 12'd51 ;
                 tkeep[11] : tkeep2empty_64 = 12'd52 ; 
                 tkeep[10] : tkeep2empty_64 = 12'd53 ; 
                 tkeep[9]  : tkeep2empty_64 = 12'd54 ; 
                 tkeep[8]  : tkeep2empty_64 = 12'd55 ;
                 tkeep[7]  : tkeep2empty_64 = 12'd56 ; 
                 tkeep[6]  : tkeep2empty_64 = 12'd57 ; 
                 tkeep[5]  : tkeep2empty_64 = 12'd58 ; 
                 tkeep[4]  : tkeep2empty_64 = 12'd59 ; 
                           
                 tkeep[3]  : tkeep2empty_64 = 12'd60 ; 
                 tkeep[2]  : tkeep2empty_64 = 12'd61 ;
                 tkeep[1]  : tkeep2empty_64 = 12'd62 ; 
                 tkeep[0]  : tkeep2empty_64 = 12'd63 ; 
                 default   : tkeep2empty_64 = 12'd0  ;
             endcase
             end
    endfunction 

        /*function [EMPTY_BITS-1:0] empty_bytes;
             input [NO_OF_BYTES-1:0] keep;
             integer i;
             begin
                 empty_bytes = {EMPTY_BITS{1'b0}};
                 for (i=0;i<NO_OF_BYTES;i=i+1) begin
                    if (!keep[i])
                        empty_bytes = empty_bytes + 1'b1;
                 end
             end
        endfunction*/
        
endmodule
