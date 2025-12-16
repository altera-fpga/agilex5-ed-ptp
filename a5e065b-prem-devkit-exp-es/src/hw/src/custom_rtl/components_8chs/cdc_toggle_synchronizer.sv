//# ######################################################################## 
//# Copyright (C) 2025 Altera Corporation.
//# SPDX-License-Identifier: MIT
//# ######################################################################## 


module cdc_toggle_synchronizer 
(
    input  in_clk,
    input  in_reset,
    input  out_clk,
    input  in_pulse,
    output out_pulse
);
    
logic toggled_signal;
logic toggled_signal_synced;
logic RG_toggled_signal_synced;

always_ff @(posedge in_clk) begin
    if (in_reset) begin
        toggled_signal <= 1'b0; 
    end
    else if (in_pulse) begin
        toggled_signal <= !toggled_signal; 
    end
end

cdc_synchronizer #(
    .WIDTH(1)
)
inst_cdc_sync_for_rst (
    .out_clk(out_clk),
    .out_reset(1'b0),
    .in_data(in_reset),
    .out_data(out_reset)
);

cdc_synchronizer #(
    .WIDTH(1)
)
inst_cdc_sync (
    .out_clk(out_clk),
    .out_reset(out_reset),
    .in_data(toggled_signal),
    .out_data(toggled_signal_synced)
);

always_ff @(posedge out_clk) begin
    if (out_reset) begin
        RG_toggled_signal_synced <= 1'b0;
    end
    else begin
        RG_toggled_signal_synced <= toggled_signal_synced;
    end
end

assign out_pulse = toggled_signal_synced ^ RG_toggled_signal_synced;

endmodule
