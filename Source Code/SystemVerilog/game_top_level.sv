`timescale 1ns / 1ps

// this code is original

module game_top_level (
    input logic clk_100MHz, reset,
    input logic MIC_DATA,
    output logic MIC_CLK, 
    
     //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0] hdmi_tmds_data_n,
    output logic [2:0] hdmi_tmds_data_p
    
);

    
    // Generate ~3MHz clock for microphone
    logic [5:0] counter;
    logic clk_3MHz, clk_3MHz_prev;
    logic pdm_clk_rising_edge;
    logic new_pcm_sample;
    
    
    always_ff @(posedge clk_100MHz) begin
        if(reset) begin
            counter <= 6'd0;
            clk_3MHz <= 1'b0;
        end
        else if(counter == 6'd15) begin
            clk_3MHz <= ~clk_3MHz;
            counter <= 6'd0;
        end
        else
            counter <= counter + 1;
            
        clk_3MHz_prev <= clk_3MHz;
    end 
    
    always_ff @(posedge clk_100MHz) begin
        if(reset) begin
            pdm_clk_rising_edge <= 1'b0;
        end
        else if(clk_3MHz == 1'b0 && clk_3MHz_prev == 1'b1) begin // actually falling edge
            pdm_clk_rising_edge <= 1'b1;
        end
        else begin
            pdm_clk_rising_edge <= 1'b0;
        end
    end
       
    assign MIC_CLK = clk_3MHz; 

  
    logic [6:0] mic_data_pcm;
    logic sigma_delta_output;
    
    pdm_to_pcm filter (
        .reset(reset),
        .clk(clk_100MHz), // original: 100 mhz
        .clk_en(pdm_clk_rising_edge),
        .pdm_data(MIC_DATA),
        .pcm_data(mic_data_pcm),
        .new_pcm_sample(new_pcm_sample)
    );
    
    
    logic [15:0] pcm_out;
    
    
    logic [26:0] sample_counter;
    logic [6:0] pcm_sample;
    
    always_ff @(posedge clk_100MHz) begin
        if(sample_counter == 27'd5000000) begin
            pcm_sample <= mic_data_pcm;
            sample_counter <= '0;
        end else
            sample_counter <= sample_counter + 1;
    end
    
    logic [6:0] amplitude_display;
    assign amplitude_display = pcm_sample[6] ? -pcm_sample : pcm_sample;
    
    logic [6:0] amplitude_sample;
    assign amplitude_sample = mic_data_pcm[6] ? -mic_data_pcm : mic_data_pcm;
    
    logic [26:0] debounce;
    
    logic clapped;
    always_ff @(posedge clk_100MHz) begin
        if(reset) begin
            debounce <= '0;
        end else begin
            if (debounce < 27'd10000000) begin
                debounce <= debounce + 1;
            end
            if(new_pcm_sample) begin
               if (amplitude_sample>=7'd4 && debounce >= 27'd10000000) begin
                    debounce <= '0;
                    clapped <= 1'b1;
               end else if (amplitude_sample<7'd4 && debounce >= 27'd10000000) begin
                    clapped <= 1'b0;
               end
            end
        end
    end    
    
    logic [13:0] score;
    logic [15:0] score_bcd;
    
    bin2bcd score_converter (
        .bin(score),
        .bcd(score_bcd)
    );
 
    logic clk_25MHz, clk_125MHz;
    logic locked;
    logic [9:0] drawX, drawY, ballxsig, ballysig, ballsizesig;
    
    logic [7:0] pipe_width;
    logic [9:0] pipe1_height, pipe2_height; // bottom part
    logic [9:0] pipe_gap;
    logic signed [11:0] pipe1_xpos, pipe2_xpos; // left edge
    

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
        
    logic clapped_prev;
    always_ff @(negedge vsync) begin
        clapped_prev <= clapped;
    end    
    logic clapped_rising_edge;
    assign clapped_rising_edge = ~clapped_prev & clapped;
     
     
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset),
        .locked(locked),
        .clk_in1(clk_100MHz)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    
    
    logic crash, start, active, dead;
    
    game_state_fsm gsfsm (
        .frame_clk(~vsync),
        .reset(reset),
        .clap(clapped_rising_edge),
        .crash(crash),
        .start(start),
        .active(active),
        .dead(dead)
    );
    
    //Ball Module
    ball ball_instance(
        .Reset(reset),
        .frame_clk(~vsync),              
        .clap(clapped_rising_edge),    
        .BallX(ballxsig),
        .BallY(ballysig),
        .BallS(ballsizesig),
        .start(start),
        .active(active),
        .dead(dead)
    );
    
    pipe pipe_instance(
        .Reset(reset),
        .frame_clk(~vsync),
        .start(start),
        .dead(dead),
        .pipe_width(pipe_width),
        .pipe1_height(pipe1_height),
        .pipe2_height(pipe2_height),
        .pipe_gap(pipe_gap),
        .pipe1_xpos(pipe1_xpos),
        .pipe2_xpos(pipe2_xpos),
        .score(score)
    );
        
    logic [7:0] cloud1_width, cloud2_width;
    logic [9:0] cloud1_height, cloud2_height; // bottom part
    logic signed [11:0] cloud1_xpos, cloud2_xpos,cloud1_ypos, cloud2_ypos; // left edge
    
    cloud cloud_instance (
        .Reset(reset),
        .frame_clk(~vsync),
        .*
    );
    

    
    //Color Mapper Module   
    color_mapper color_instance(
        .BallX(ballxsig),
        .BallY(ballysig),
        .DrawX(drawX),
        .DrawY(drawY),
        .Ball_size(ballsizesig),
        .pipe_width(pipe_width),
        .pipe1_height(pipe1_height),
        .pipe2_height(pipe2_height),
        .pipe_gap(pipe_gap),
        .pipe1_xpos(pipe1_xpos),
        .pipe2_xpos(pipe2_xpos),
        .crash(crash),
        .start(start),
        .active(active),
        .pixel_clk(clk_25MHz),
        .new_frame(~vsync),
        .reset(reset),
        .score_bcd(score_bcd),
        .dead(dead),
        .Red(red),
        .Green(green),
        .Blue(blue),
        .* // cloud ports
    );
    
   
   
    
    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(reset),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );
    
endmodule
