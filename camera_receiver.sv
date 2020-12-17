module camera_receiver
    #(
    parameter frame_lines = 1540,
    parameter frame_width = 2300
    )
    (
        input               pclk,
        input               reset,
        
        input [9:0]         pixel_data,
        input               vs,
        input               hs,
        
        output logic [9:0]  pixel_out,
        output logic        pixel_valid,
        
        output logic        sof
        
        //output logic [1:0]  frame_error
    );
    
    parameter frame_length = frame_lines * frame_width;
    
    logic [23:0] frame_pixel_counter;
    logic [11:0] frame_line_counter;
    
    logic vs_flop, vs_flop_d1, vs_flop_d2;
    logic hs_flop, hs_flop_d1, hs_flop_d2;
    logic [9:0] pixel_flop_0;
    logic [9:0] pixel_flop_1;
    logic [9:0] pixel_flop_2;
    logic sof_sent;
    logic [31:0] sof_sreg;
    
    logic hs_or_vs_d1, hs_or_vs_d2;
    assign hs_or_vs_d1 = hs_flop_d1 | vs_flop_d1;
    assign hs_or_vs_d2 = hs_flop_d2 | vs_flop_d2;
    
    typedef enum {ST_IDLE, ST_WAIT_FRAME, ST_FRAME_ACTIVE, ST_IN_LINE} statetype;
    statetype state;
    
    assign pixel_out    = pixel_flop_2;
    assign sof          = sof_sreg[31];
    
    always @(posedge pclk) begin
        vs_flop_d2      <= vs_flop_d1;
        vs_flop_d1      <= vs_flop;
        vs_flop         <= vs;
        hs_flop_d2      <= hs_flop_d1;
        hs_flop_d1      <= hs_flop;
        hs_flop         <= hs;
        pixel_flop_2    <= pixel_flop_1;
        pixel_flop_1    <= pixel_flop_0;
        pixel_flop_0    <= pixel_data;
        
        if (reset) begin
            frame_pixel_counter <= 0;
            frame_line_counter  <= 0;
            
            sof_sreg            <= 0;
            //frame_error         <= 0;
            
            state               <= ST_IDLE;
            
            sof_sent            <= 0;
            pixel_valid         <= 0;
        end else begin
            sof_sreg[31:1]  <= sof_sreg[30:0];
            sof_sreg[0]     <= (!hs_or_vs_d1) & hs_or_vs_d2;
            
            pixel_valid     <= hs_flop_d1 & sof_sent;
            
            if (sof_sreg[31]) begin
                sof_sent            <= 1;
                frame_pixel_counter <= 0;
                //frame_error         <= frame_pixel_counter[23:22];
            end else begin
                if (pixel_valid) begin
                    frame_pixel_counter <= frame_pixel_counter + 1;
                end
            end
        end
    end
endmodule