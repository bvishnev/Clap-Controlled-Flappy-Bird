`timescale 1ns / 1ps

// This code is original

module pipe (
    input logic Reset, 
    input logic frame_clk,
    
    input logic start, dead,
    
    output logic [7:0] pipe_width,
    output logic [9:0] pipe1_height, pipe2_height, // bottom part
    output logic [9:0] pipe_gap,
    output logic signed [11:0] pipe1_xpos, pipe2_xpos, // left edge
    
    output logic [13:0] score
);

	 
    parameter [9:0] X_Min = 0;       // Leftmost point on the X axis
    parameter [9:0] X_Max = 639;     // Rightmost point on the X axis
    parameter [9:0] Y_Min = 0;       // Topmost point on the Y axis
    parameter [9:0] Y_Max = 479;     // Bottommost point on the Y axis

    assign pipe_width = 8'd96;
    assign pipe_gap = 10'd192;

    logic signed [11:0] X_next1, X_next2, H_next1, H_next2;
    
    logic [7:0] rand1, rand2;
    
    rand_gen_8 rg1 (
        .reset(Reset),
        .clk(frame_clk),
        .seed(8'b01100101),
        .rand_num(rand1)
    );
    
    rand_gen_8 rg2 (
        .reset(Reset),
        .clk(frame_clk),
        .seed(8'b00011110),
        .rand_num(rand2)
    );

    always_comb begin
      
        if ( $signed(pipe1_xpos) <= $signed(X_Min - pipe_width) ) begin
             X_next1 = X_Max;
             H_next1 = {2'b0, rand1} + 10'd16;
        end else begin
             X_next1 = pipe1_xpos - 2;
             H_next1 = pipe1_height;
        end
        
        if ( $signed(pipe2_xpos) <= $signed(X_Min - pipe_width) ) begin
             X_next2 = X_Max;
             H_next2 = {2'b0, rand2} + 10'd16;
        end else begin
             X_next2 = pipe2_xpos - 2;
             H_next2 = pipe2_height;
        end

   end
   
    always_ff @(posedge frame_clk)
    begin: Move
        if (Reset || start)
        begin 
			pipe1_xpos <= X_Max;
			pipe2_xpos <= X_Max + (X_Max / 2);
			pipe1_height <= Y_Max / 2;
			pipe2_height <= Y_Max / 2;
        end
        else if(~dead)
        begin 
            pipe1_xpos <= X_next1;  // Update position
            pipe2_xpos <= X_next2;
            pipe1_height <= H_next1;
            pipe2_height <= H_next2;
		end  
    end    
    
    always_ff @(posedge frame_clk) begin
        if(start) begin
            score <= '0;
        end else if(~dead) begin
            if((pipe1_xpos + (pipe_width/2) > (X_Max/2)) && (X_next1 + (pipe_width/2) <= (X_Max/2))) begin
                score <= score + 1;
            end
            if((pipe2_xpos + (pipe_width/2) > (X_Max/2)) && (X_next2 + (pipe_width/2) <= (X_Max/2))) begin
                score <= score + 1;
            end
        end
    end
    
endmodule
