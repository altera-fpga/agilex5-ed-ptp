
 module irq_count(input logic irq, input logic rstn, output logic[31:0] irq_counter);
 
 always@(posedge irq)
 begin
  if(!rstn)
  irq_counter <='0;
  else irq_counter <=irq_counter+1;
end 
endmodule 
