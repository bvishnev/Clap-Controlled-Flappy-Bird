`timescale 1ns / 1ps

// This code is original

module cloud(
    input logic Reset, 
    input logic frame_clk,
    
    input logic dead,
    
    output logic [7:0] cloud1_width, cloud2_width,
    output logic [9:0] cloud1_height, cloud2_height, // bottom part
    output logic signed [11:0] cloud1_xpos, cloud2_xpos,cloud1_ypos, cloud2_ypos // left edge
);

	 
    parameter [9:0] X_Min = 0;       // Leftmost point on the X axis
    parameter [9:0] X_Max = 639;     // Rightmost point on the X axis
    parameter [9:0] Y_Min = 0;       // Topmost point on the Y axis
    parameter [9:0] Y_Max = 479;     // Bottommost point on the Y axis

    logic signed [11:0] X_next1, X_next2, H_next1, H_next2, W_next1, W_next2, Y_next1, Y_next2;
    
    logic [7:0] randh1, randh2, randw1, randw2, randy1, randy2;
    
    rand_gen_8 rgh1 (
        .reset(Reset),
        .clk(frame_clk),
        .seed(8'b01100101),
        .rand_num(randh1)
    );
    
    rand_gen_8 rgh2 (
        .reset(Reset),
        .clk(frame_clk),
        .seed(8'b00011111),
        .rand_num(randh2)
    );

    rand_gen_8 rgw1 (
        .reset(Reset),
        .clk(frame_clk),
        .seed(8'b01101101),
        .rand_num(randw1)
    );
    
    rand_gen_8 rgw2 (
        .reset(Reset),
        .clk(frame_clk),
        .seed(8'b10100101),
        .rand_num(randw2)
    );
    
    rand_gen_8 rgy1 (
        .reset(Reset),
        .clk(frame_clk),
        .seed(8'b01111101),
        .rand_num(randy1)
    );
    
    rand_gen_8 rgy2 (
        .reset(Reset),
        .clk(frame_clk),
        .seed(8'b01100001),
        .rand_num(randy2)
    );
    

    always_comb begin
      
        if ( $signed(cloud1_xpos) <= $signed(X_Min - cloud1_width) ) begin
             X_next1 = X_Max;
             H_next1 = {2'b0, randh1} / 4 + 10'd20;
             W_next1 = {2'b0, randw1} / 2 + 10'd50;
             Y_next1 = {2'b0, randy1} + 10'd128;
        end else begin
             X_next1 = cloud1_xpos - 1;
             H_next1 = cloud1_height;
             W_next1 = cloud1_width;
             Y_next1 = cloud1_ypos;
        end
        
        if ( $signed(cloud2_xpos) <= $signed(X_Min - cloud2_width) ) begin
             X_next2 = X_Max;
             H_next2 = {2'b0, randh2} / 4 + 10'd20;
             W_next2 = {2'b0, randw2} / 2 + 10'd50;
             Y_next2 = {2'b0, randy2} + 10'd128;
        end else begin
             X_next2 = cloud2_xpos - 1;
             H_next2 = cloud2_height;
             W_next2 = cloud2_width;
             Y_next2 = cloud2_ypos;
        end
        

   end
   
    always_ff @(posedge frame_clk) 
    begin: Move
        if (Reset)
        begin 

         
			cloud1_xpos <= X_Max;
			cloud2_xpos <= X_Max + (X_Max / 2);
			cloud1_height <= Y_Max / 2;
			cloud2_height <= Y_Max / 2;
        end
        else if(~dead)
        begin 


            cloud1_xpos <= X_next1;  // Update position
            cloud2_xpos <= X_next2;
            cloud1_height <= H_next1;
            cloud2_height <= H_next2;
            cloud1_width <= W_next1;
            cloud2_width <= W_next2;
            cloud1_ypos <= Y_next1;
            cloud2_ypos <= Y_next2;
		end  
    end
    
endmodule
