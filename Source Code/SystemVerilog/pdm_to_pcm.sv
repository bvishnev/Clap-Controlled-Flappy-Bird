`timescale 1ns / 1ps

// This code is original


// Simple moving average implementation

module pdm_to_pcm(
    input logic reset,
    input logic clk,
    input logic clk_en, // allows use of 100 MHZ clock to avoid CDC
    input logic pdm_data,
    output logic [6:0] pcm_data,
    output logic new_pcm_sample
);

    //original single-clock domain implementation
    logic [5:0] count;
    logic [6:0] accumulator, pcm_uncentered;
    
    always_ff @(posedge clk) begin
        if(reset) begin
            count <= 6'd0;
            accumulator <= 7'd0;
            new_pcm_sample <= 1'b0;
        end
        else if(clk_en) begin
            if(count == 6'd63) begin
                pcm_uncentered <= accumulator + pdm_data;
                count <= 6'd0;
                accumulator <= 7'd0;
                new_pcm_sample <= 1'b1;
            end
            else begin
                count <= count + 1;
                accumulator <= accumulator + pdm_data;
                new_pcm_sample <= 1'b0;
            end
        end
        else if(new_pcm_sample == 1'b1) begin
            new_pcm_sample <= 1'b0;
        end
    end
    
    assign pcm_data = pcm_uncentered - 7'd32; // center around 0 (twos complement ranging from -32 to 31)

endmodule
