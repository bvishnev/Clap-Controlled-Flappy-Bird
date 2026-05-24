// This file is loosely based on provided code from ECE 385 at UIUC (documented
// below), though significant modifications have been made.
//
//-------------------------------------------------------------------------
//    Ball.sv                                                            --
//    Viral Mehta                                                        --
//    Spring 2005                                                        --
//                                                                       --
//    Modified by Stephen Kempf     03-01-2006                           --
//                                  03-12-2007                           --
//    Translated by Joe Meng        07-07-2013                           --
//    Modified by Zuofu Cheng       08-19-2023                           --
//    Modified by Satvik Yellanki   12-17-2023                           --
//    Fall 2024 Distribution                                             --
//                                                                       --
//    For use with ECE 385 USB + HDMI Lab                                --
//    UIUC ECE Department                                                --
//-------------------------------------------------------------------------


module  ball 
( 
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic        clap,
    input  logic        start, active, dead,

    output logic [9:0]  BallX, 
    output logic signed [9:0]  BallY, 
    output logic [9:0]  BallS 
);
    

	 
    parameter [9:0] Ball_X_Center=320;  // Center position on the X axis
    parameter [9:0] Ball_Y_Center=240;  // Center position on the Y axis
    parameter [9:0] Ball_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] Ball_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] Ball_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] Ball_Y_Max=479;     // Bottommost point on the Y axis
    parameter [9:0] Ball_X_Step=1;      // Step size on the X axis
    parameter [9:0] Ball_Y_Step=1;      // Step size on the Y axis
    
    parameter [9:0] gravity = 10'd1; // m/s/s
    
    parameter [9:0] jump = -10'd14; // m/s

    logic [9:0] Ball_X_Motion;
    logic [9:0] Ball_X_Motion_next;
    logic [9:0] Ball_Y_Motion;
    logic [9:0] Ball_Y_Motion_next;
    
    logic [9:0] Ball_Y_Velocity;
    logic [9:0] Ball_Y_Velocity_next;

    logic [9:0] Ball_X_next;
    logic [9:0] Ball_Y_next;
    
    logic prev_active, active_posedge;
    
    always_ff @(posedge frame_clk) begin
        prev_active <= active;
    end
    assign active_posedge = ~prev_active & active;

    always_comb begin
        Ball_X_Motion_next = Ball_X_Motion;

        //control ball motion with the clap
        if (clap || active_posedge) begin
                Ball_Y_Velocity_next = jump;
        end else begin
            Ball_Y_Velocity_next = (Ball_Y_Velocity) + gravity;
        end
        
        // motion equations to make ball bounce up and down
        Ball_Y_Motion_next = Ball_Y_Velocity;//(~ (Ball_Y_Step) + 1'b1);  // set to -1 via 2's complement.
        
        if ( $signed(BallY + BallS) > $signed(Ball_Y_Max)) // Ball is at the bottom edge, BOUNCE!
        begin
            Ball_Y_next = Ball_Y_Max - BallS;
            if (Ball_Y_Velocity_next>10'd0) begin 
                Ball_Y_Velocity_next = 10'd0;
            end
      end
        else if ( $signed(BallY - BallS) < $signed(Ball_Y_Min) )  // Ball is at the top edge, BOUNCE!
        begin
            Ball_Y_next = Ball_Y_Min + BallS;
            if (Ball_Y_Velocity_next < 10'd0) begin 
                Ball_Y_Velocity_next = gravity;//(~ (Ball_Y_Velocity) + 1'b1);
            end
        end else begin
            Ball_Y_next = (BallY + Ball_Y_Motion_next);
        end

        // motion equations to make ball bounce left and right
        if ( (BallX + BallS) >= Ball_X_Max )  // Ball is at the bottom edge, BOUNCE!
        begin
            Ball_X_Motion_next = (~ (Ball_X_Step) + 1'b1);  // set to -1 via 2's complement.
        end
        else if ( (BallX - BallS) <= Ball_X_Min )  // Ball is at the top edge, BOUNCE!
        begin
            Ball_X_Motion_next = Ball_X_Step;
        end
        
        
        BallS = 16;  // default ball size
        
        Ball_X_next = (BallX + Ball_X_Motion_next);
        
    end
   
    always_ff @(posedge frame_clk) //make sure the frame clock is instantiated correctly
    begin: Move_Ball
        if (Reset)
        begin 
            Ball_Y_Motion <= 10'd0; //Ball_Y_Step;
			Ball_X_Motion <= 10'd0; //Ball_X_Step;
			Ball_Y_Velocity <= 10'd0;
            
			BallY <= Ball_Y_Center;
			BallX <= Ball_X_Center;
        end
        else 
        begin 
            if(active) begin
                Ball_Y_Motion <= Ball_Y_Motion_next; 
                Ball_X_Motion <= Ball_X_Motion_next; 
                Ball_Y_Velocity <= Ball_Y_Velocity_next;
                BallY <= Ball_Y_next;  // Update ball position
                BallX <= Ball_X_next;
            end
            else if(dead) begin
                Ball_Y_Motion <= 0; 
                Ball_X_Motion <= 0; 
                Ball_Y_Velocity <= 0;
                BallY <= BallY;  // Update ball position
                BallX <= BallX;
            end
            else begin // start
                Ball_Y_Motion <= 0; 
                Ball_X_Motion <= 0; 
                Ball_Y_Velocity <= 0;
                BallY <= Ball_Y_Max / 2;  // Update ball position
                BallX <= Ball_X_Max / 2;
            end
			
		end  
    end
    
endmodule
