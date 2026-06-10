// (C) 2001-2025 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


`timescale 1 ns / 1 ns
module intel_eth_gts_ptp_pps(
    clk,
    reset,

    time_of_day_96b,
    pulse_per_second
);
    // --------------------------------------------------
    // Parameters
    // --------------------------------------------------
    // Number of clock cycles the pulse_per_second output will be asserted
    parameter PULSE_CYCLE = 156250;
    
    // --------------------------------------------------
    // Local Parameters
    // --------------------------------------------------
    localparam TIME_OF_DAY_96B_WIDTH = 96;
    localparam PULSE_COUNTER_WIDTH = log2ceil(PULSE_CYCLE);
    
    // --------------------------------------------------
    // Ports
    // --------------------------------------------------
    input                               clk;
    input                               reset;
    
    input  [TIME_OF_DAY_96B_WIDTH-1:0]  time_of_day_96b;
    output                              pulse_per_second;
    
    // --------------------------------------------------
    // Internal Signals
    // --------------------------------------------------
    wire                                second_lsb;
    reg                                 second_lsb_reg;
    wire                                second_toggle;
    reg                                 pps_reg;
    
    reg  [PULSE_COUNTER_WIDTH-1:0]      pulse_counter;
    
    // --------------------------------------------------
    // Logics
    // --------------------------------------------------
    assign second_lsb = time_of_day_96b[48];
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            second_lsb_reg <= 1'b0;
        end
        else begin
            second_lsb_reg <= second_lsb;
        end
    end
    
    assign second_toggle = second_lsb_reg ^ second_lsb;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pulse_counter <= {PULSE_COUNTER_WIDTH{1'b1}};
            pps_reg <= 1'b0;
        end
        else begin
            if(second_toggle) begin
                pulse_counter <= {PULSE_COUNTER_WIDTH{1'b0}} + 1;
                pps_reg <= 1'b1;
            end
            else if(pulse_counter >= PULSE_CYCLE - 1) begin
                pulse_counter <= pulse_counter;
                pps_reg <= 1'b0;
            end
            else begin
                pulse_counter <= pulse_counter + 1'b1;
                pps_reg <= 1'b1;
            end
        end
    end
    
    assign pulse_per_second = pps_reg | second_toggle;
    
    //---------------------------------------------------------------------------------------------------
    // Function - Calculates the log2ceil of the input value
    //---------------------------------------------------------------------------------------------------
    function integer log2ceil;
        input integer val;
        integer i;
        
        begin
            i = 1;
            log2ceil = 0;
            
            while (i < val) begin
                log2ceil = log2ceil + 1;
                i = i << 1; 
            end
        end
    endfunction
    
endmodule
`ifdef QUESTA_INTEL_OEM
`pragma questa_oem_00 "mXypBqYlC5tPHKvGSz/OgELAzHpeDTMVm92T/G3Tu+Mtj/QKjdPq2C/7YjmBqURd42eqxLEPm5ROnJvj36ncaaR8Sspj9hTF+smYtFdsh6vMrIn7I2ujp7BRjzYw5I2AvAOQAp7snnaPLlJ7h0AspRt5h+aoUWOpH7IAlafE9plfycmjleDqZQRYeY5Pocjbv9fsy1/Wfhpiv3JjywCi+32tfuLfNErYoFt3ZHZNJfG3gpxJfzxAxnFMRIw8Q1DD8W3AdfXYu1ETOpiF0HOCVFMyqDlbyGfUuo9wTCXKJr2ePJSZwueiEjj2l13XPnKGFo3LrSLW/UCEpV9s0RDEKM1+wtOLgdDbPt08UQuCjO49GyCy5qexbJ6bY6j0wcdsJxTKZqiPyBT7pHoZmu5YfUFyfREqGqCmjYBec52BdylPSyT0ciYWuG987poTHJAjJJvnk3hSNlRvGcnJ5Zd9sH72cEGkRV0I94xn04JT/mm1y4hO7HTPQzedzJyTx9FHLgyH3jXp6GJHcTfOZ+UFOZ2EyVVvxrzmQZJyHzUwT4/uiBlM9NpLOrQPIgDsKMUl0EWEL3bik4BKFtXkr4Gl0RYf1LehLhMWzteC3OP+WrIJSiqg62HjxsrPxC8m4nzC636KlQQAQQk0G69dRtuRgAEhEEVuJglfwLpjlqPDyBfl5YzqXkRMKYk+OpN1+5Bw+f917ckB7Qbur1yyLbuuB4oeyRiOJcVY2GWybNVOXCrMEzjJkLSIhTwquu06lXEcga2JKQvsi1tlPTcUorHrKcD7rwEyMXk75V53jsi1VETl6paLR2//ZeOF3peiXYMYV7C+c0xVPwoqy27irJdRw8Ezf3cselOWUQMnQwz2RdiqaNdb/kiWQNha08wCTm4q/jCZu49UhOF2hhBSp90kUT6LFZyoY9JeaSf+vC8EVOmluGqWBU1q20NdiPHboXK34GMnKvapydmrNZOeipfOa7ukKXyT4pXH/3hM9+W/t4Hbk/pPyN9XVyfU2Fb7C6q1"
`endif