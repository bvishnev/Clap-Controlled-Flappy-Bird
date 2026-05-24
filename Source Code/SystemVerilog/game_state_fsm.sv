`timescale 1ns / 1ps

// This code is original


module game_state_fsm(
    input logic frame_clk, reset,
    input logic clap, crash,
    output logic start, active, dead
);

    typedef enum logic [1:0] {START, ACTIVE, DEAD} STATE;
    STATE state, next_state;
    
    always_comb begin
        case(state)
            START: next_state = clap ? ACTIVE : START;
            ACTIVE: next_state = crash ? DEAD : ACTIVE;
            DEAD: next_state = clap ? START : DEAD;
            default: next_state = START;
        endcase
    end
    
    always_ff @(posedge frame_clk) begin
        if(reset) begin
            state <= START;
        end else begin
            state <= next_state;
        end
    end
    
    assign start = (next_state == START);
    assign active = (next_state == ACTIVE);
    assign dead = (next_state == DEAD);

endmodule
