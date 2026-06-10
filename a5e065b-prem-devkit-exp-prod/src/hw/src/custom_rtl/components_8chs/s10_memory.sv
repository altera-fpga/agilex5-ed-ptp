//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module s10_memory #(
   CAPACITY = 16,
   DATA_WIDTH = 32,
   ADDRESS_WIDTH = CAPACITY >= 2 ? $clog2(CAPACITY) : 1
) (
   input  logic                     read_areset,
   input  logic                     write_clk,
   input  logic                     write_enable,
   input  logic [ADDRESS_WIDTH-1:0] write_pointer,
   input  logic [DATA_WIDTH-1:0]    write_data,
   input  logic                     read_clk,
   input  logic                     read_ready,
   input  logic                     read_enable,
   input  logic [ADDRESS_WIDTH-1:0] read_pointer,
   output logic [DATA_WIDTH-1:0]    read_data
);

   logic [DATA_WIDTH-1:0] read_data_reg, read_data_sig;
   //logic rd_reg0 = '0, rd_reg1 = '0, rd_reg2 = '0; // 
   logic rd_reg0, rd_reg1, rd_reg2;

   always_comb begin
      if(rd_reg2) begin
         read_data = read_data_reg;
      end else begin
         read_data = read_data_sig;
      end
   end

   always_ff @(posedge read_clk) begin
      rd_reg0 <= read_enable;
      if(rd_reg0 || read_ready) begin
         rd_reg1 <= rd_reg0;
      end

      if(!read_ready && rd_reg0 && rd_reg1) begin
         rd_reg2 <= rd_reg1;
      end else if(read_ready && rd_reg1 && rd_reg2) begin
         rd_reg2 <= '1;
      end else if(read_ready) begin
         rd_reg2 <= '0;
      end
   end

   always_ff @(posedge read_clk) begin
      if(read_ready && rd_reg1 && rd_reg2) begin
         read_data_reg <= read_data_sig;
      end else if(!read_ready && rd_reg1 && !rd_reg2) begin
         read_data_reg <= read_data_sig;
      end
   end

   altera_syncram altera_syncram_component (
      .aclr1 (read_areset),
      .address_a (write_pointer),
      .address_b (read_pointer),
      //.address2_a(1'b0),
      //.address2_b(1'b0),
      .clock0 (write_clk),
      .clock1 (read_clk),
      .clocken1 (1'b1),
      //.clocken3 (1'b1),
      .data_a (write_data),
      .wren_a (write_enable),
      .q_b (read_data_sig),
      .aclr0 (1'b0),
      .addressstall_a (1'b0),
      .addressstall_b (1'b0),
      .byteena_a (1'b1),
      .byteena_b (1'b1),
      .clocken0 (1'b1),
      .clocken2 (1'b1),
      .data_b ({DATA_WIDTH{1'b1}}),
      .eccencbypass (1'b0),
      .eccencparity (8'b0),
      .eccstatus (),
      .q_a (),
      .rden_a (1'b1),
      .rden_b (read_enable),
      .sclr (1'b0),
      .wren_b (1'b0));
   defparam
      //altera_syncram_component.address_aclr_b  = "CLEAR1",
      altera_syncram_component.address_reg_b  = "CLOCK1",
      altera_syncram_component.clock_enable_input_a  = "BYPASS",
      altera_syncram_component.clock_enable_input_b  = "BYPASS",
      altera_syncram_component.clock_enable_output_a  = "BYPASS",
      altera_syncram_component.clock_enable_output_b  = "BYPASS",
      altera_syncram_component.lpm_type  = "altera_syncram",
      altera_syncram_component.numwords_a  = CAPACITY,
      altera_syncram_component.numwords_b  = CAPACITY,
      altera_syncram_component.operation_mode  = "DUAL_PORT",
      altera_syncram_component.outdata_aclr_b  = "CLEAR1",
      altera_syncram_component.outdata_sclr_b  = "NONE",
      altera_syncram_component.outdata_reg_b  = "CLOCK1",
      altera_syncram_component.power_up_uninitialized  = "FALSE",
      altera_syncram_component.widthad_a  = ADDRESS_WIDTH,
      altera_syncram_component.widthad_b  = ADDRESS_WIDTH,
      altera_syncram_component.width_a  = DATA_WIDTH,
      altera_syncram_component.width_b  = DATA_WIDTH,
      altera_syncram_component.width_byteena_a  = 1,
      altera_syncram_component.read_during_write_mode_port_a  = "DONT_CARE",
      altera_syncram_component.read_during_write_mode_port_b  = "DONT_CARE";

endmodule
