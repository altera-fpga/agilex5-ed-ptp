//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


//
// Description:  This logic check the i2c initialization completion and write 1 value to 0x090 of common csr. 

module i2c_init_done_check #(
   parameter ADDR_WIDTH = 4,
   parameter DATA_WIDTH = 32

)(
 input  logic                   clk,
 input  logic                   reset,
// Snooping only the write channel of I2C csr 
 input  logic [ADDR_WIDTH-1:0]  i2c_0_csr_address_snoop,
 input  logic                   i2c_0_csr_write_snoop,
 input  logic [DATA_WIDTH-1:0]  i2c_0_csr_writedata_snoop,
 output logic                   init_done
 
);
// Reg to store the write value of each I2C regs during initialization
// Currently regs are I2C_SCL_LOW,I2C_SCL_HIGH,I2C_SDA_HOLD,I2C_ISER
// But here, including writes to all regs. But for init_done generation, anding only required reg writes.
logic [15:0]i2c_mstr_reg_write;

always @(posedge clk) begin
  if (reset)  begin
   i2c_mstr_reg_write <= '0;
  end
  else if(i2c_0_csr_write_snoop)begin
   case (i2c_0_csr_address_snoop)
     4'h0: begin   // TFR_CMD 
             i2c_mstr_reg_write[0] <= 1;
           end
     4'h1: begin   // RX_DATA 
             i2c_mstr_reg_write[1] <= 1;
           end
     4'h2: begin   // CTRL 
             i2c_mstr_reg_write[2] <= 1;
           end
     4'h3: begin   // ISER 
             i2c_mstr_reg_write[3] <= 1;
           end
     4'h4: begin   // ISR 
             i2c_mstr_reg_write[4] <= 1;
           end
     4'h5: begin   // STATUS 
             i2c_mstr_reg_write[5] <= 1;
           end
     4'h6: begin   // TFR_CMD_FIFO_LVL 
             i2c_mstr_reg_write[6] <= 1;
           end
     4'h7: begin   // RX_DATA_FIFO_LVL 
             i2c_mstr_reg_write[7] <= 1;
           end
     4'h8: begin   // SCL_LOW
             i2c_mstr_reg_write[8] <= 1;
           end
     4'h9: begin   // SCL_HIGH 
             i2c_mstr_reg_write[9] <= 1;
           end
     4'hA: begin   // SDA_HOLD 
             i2c_mstr_reg_write[10] <= 1;
           end
    default: begin end
    endcase
    end     
  end

  // Generate init_done after cntrl, scl_low, scl_high, sda_hold have been configured first timee
 always @(posedge clk) begin
   if (reset)  begin
        init_done <= 1'b0;
   end
   else if(i2c_mstr_reg_write[2] && i2c_mstr_reg_write[8] && i2c_mstr_reg_write[9] && i2c_mstr_reg_write[10] ) 
     init_done <= 1'b1;
  
end
endmodule
