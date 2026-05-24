`timescale 1ns / 1ps

// Generates a pseudorandom sequence of 8-bit numbers using a linear feedback shift register (LFSR)
// More info: https://www.physics.otago.ac.nz/reports/electronics/ETR2012-1.pdf

module rand_gen_8(
    input logic reset,
    input logic clk,
    input logic [7:0] seed,
    output logic [7:0] rand_num
);
    
    logic [7:0] shift_reg;
    logic feedback;
    
    // from table in above link
    assign feedback = shift_reg[7] ^ shift_reg[5] ^ shift_reg[4] ^ shift_reg[3];

    always_ff @(posedge clk) begin 
        if(reset) begin
            shift_reg <= seed;
        end
        else begin
            shift_reg <= {feedback, shift_reg[7:1]};
        end
    end
    
    assign rand_num = shift_reg;
    
endmodule
