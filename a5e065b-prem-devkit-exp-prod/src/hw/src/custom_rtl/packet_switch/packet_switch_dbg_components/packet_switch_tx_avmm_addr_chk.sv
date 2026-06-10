//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 

module packet_switch_tx_avmm_addr_chk #(
   parameter INST_ID          = 0
  ,parameter BASE_ADDR        = 'h0
  ,parameter ADDR_WIDTH       = 8
  ,parameter DATA_WIDTH       = 32
) (
   input var logic                        clk
  ,input var logic                        rst

  ,input var logic [ADDR_WIDTH-1:0]       avmm_address
  ,input var logic                        avmm_read
  ,input var logic                        avmm_write
  ,input var logic [DATA_WIDTH-1:0]       avmm_writedata
  ,input var logic [(DATA_WIDTH/8)-1:0]   avmm_byteenable

  ,output var logic [ADDR_WIDTH-1:0]      avmm_address_c1
  ,output var logic                       avmm_read_c1
  ,output var logic                       avmm_write_c1
  ,output var logic [DATA_WIDTH-1:0]      avmm_writedata_c1
  ,output var logic [(DATA_WIDTH/8)-1:0]  avmm_byteenable_c1
);

always_ff @ (posedge clk) begin
  avmm_byteenable_c1 <= avmm_byteenable;
end

generate
  if (INST_ID == 0) begin
    // Region TX_0
    always_ff @ (posedge clk) begin
      if ( (avmm_address >= 'h8218 && avmm_address <= 'h8234)
          ) begin
        avmm_read_c1 <= avmm_read;
        avmm_write_c1 <= avmm_write;
        avmm_writedata_c1 <= avmm_writedata;
        avmm_address_c1 <= avmm_address - BASE_ADDR;
      end else begin
        avmm_read_c1 <= '0;
        avmm_write_c1 <= '0;
      end

      if (rst) begin
        avmm_read_c1 <= '0;
        avmm_write_c1 <= '0;
      end

    end // always_ff
  end else begin
   // Region TX_1
   always_ff @ (posedge clk) begin
     if ( (avmm_address >= 'h8238 && avmm_address <= 'h8254)
         ) begin
       avmm_read_c1 <= avmm_read;
       avmm_write_c1 <= avmm_write;
       avmm_writedata_c1 <= avmm_writedata;
       avmm_address_c1 <= avmm_address - BASE_ADDR;
     end else begin
       avmm_read_c1 <= '0;
       avmm_write_c1 <= '0;
     end
 
     if (rst) begin
       avmm_read_c1 <= '0;
       avmm_write_c1 <= '0;
     end
 
   end // always_ff
  end
endgenerate

endmodule

