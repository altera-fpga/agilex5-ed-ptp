module irq_bypass(input logic interrupt_receiver_irq, output logic interrupt_sender_irq);
assign interrupt_sender_irq = interrupt_receiver_irq;
endmodule