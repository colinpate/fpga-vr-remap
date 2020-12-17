module debayer
    #(
    parameter line_length = 2304
    )
    (
        input               clk,
        input               reset,
        input               sof_in,
        
        input [9:0]         pixel_data,
        input               pixel_data_valid,
        
        output logic [15:0] pixel_out_data,
        output logic        pixel_out_data_valid,
        
        output logic        sof,
        output logic        sof_2
        
        //output logic [9:0]  raw_pixel,
        //output logic        raw_pixel_valid
    );
    
    assign sof_2 = sof;
    
    typedef enum {ST_WAITFIRSTLINES, ST_WAITFIRSTPIX, ST_G_B, ST_G_R, ST_R, ST_B} statetype_debayer;
    statetype_debayer db_state;
    statetype_debayer last_db_state;
    
    logic [23:0]    pixels_received;
    logic [3:0][23:0] pixels_recd_delay;
    logic [9:0]     pixel;
    logic [5:0]     pixel_valid;
    
    logic flip_bit_old;
    
    logic [3:0]         fifo_wr;
    logic [3:0]         fifo_rd;
    logic [3:0]         fifo_rd_data_valid;
    logic [3:0][9:0]    fifo_wr_data;
    logic [3:0][9:0]    fifo_out;
    logic [2:0][9:0]    colors;    
    
    logic [9:0] buf_pixel;
    logic [9:0] buf2_pixel;
    
    //assign raw_pixel = pixel;
    //assign raw_pixel_valid = pixel_valid[0];
    
    logic [4:0][4:0][9:0]   pix_sreg;
    logic [19:0]            center_pix_buf;
    logic [31:0]            pixel_x;
    logic [15:0]            line_num;
    
    
    logic [9:0]     gatrb;
    logic [11:0]    gatrb_4x1accum;
    logic [11:0]    gatrb_1x4accum;
    logic [12:0]    gatrb_4x2accum;
    logic [14:0]    gatrb_accum;
    
    logic [9:0]     ratg_r_b;
    logic [12:0]    ratg_r_b_2x4_accum;
    logic [12:0]    ratg_r_b_1x5_accum;
    logic [12:0]    ratg_r_b_6x1_accum;
    logic [12:0]    ratg_r_b_2x0p5_accum;
    logic [14:0]    ratg_r_b_accum;
    
    logic [9:0]     ratg_b_r;
    logic [12:0]    ratg_b_r_2x4_accum;
    logic [12:0]    ratg_b_r_6x1_accum;
    logic [12:0]    ratg_b_r_2x0p5_accum;
    logic [14:0]    ratg_b_r_accum;
    
    logic [9:0]     ratb_b_b;
    logic [12:0]    ratb_b_b_4x2_accum;
    logic [12:0]    ratb_b_b_1x6_accum;
    logic [12:0]    ratb_b_b_4x1p5_accum_neg;
    logic [14:0]    ratb_b_b_accum;
    
    logic [9:0]     batg_b_r; //same as ratg_r_b
    logic [9:0]     batg_r_b; //same as ratg_b_r
    
    logic [29:0] rgb_pixel;
    logic        rgb_pixel_valid;
    assign rgb_pixel = {colors[2], colors[1], colors[0]}; //colors[1] is red, colors[0] and [2] are the same
    
    logic sclr;
    logic [3:0][7:0] fifo_out_i;
    assign fifo_out[0] = {fifo_out_i[0], 2'b10};
    assign fifo_out[1] = {fifo_out_i[1], 2'b10};
    assign fifo_out[2] = {fifo_out_i[2], 2'b10};
    assign fifo_out[3] = {fifo_out_i[3], 2'b10};
    
    line_buf line_bufs[3:0] (
        .clock(clk),
        .data ( {fifo_wr_data[3][9:2], fifo_wr_data[2][9:2], fifo_wr_data[1][9:2], fifo_wr_data[0][9:2]} ),
        .rdreq ( fifo_rd ),
        .wrreq ( fifo_wr ),
        .q ( fifo_out_i ),
        .sclr( sclr )
        );
        
    /*debayer_pix_getter debayer_pix_getter_inst(
        .clk(clk),
        .reset(reset),
        .pixel_ar_clock(pixel_ar_clock),
        .pixel_ar_valid(pixel_ar_valid),
        .pixel_ar(pixel_ar),
        .pixel(pixel),
        .pixel_valid(pixel_valid[0])
    );*/
    assign pixel = pixel_data;
    assign pixel_valid[0] = pixel_data_valid;
    
    logic [15:0] rgb_pix_count;
    
    always @(posedge clk)
    begin
        if ((reset) || (sof_in)) begin
            db_state            <= ST_WAITFIRSTLINES;
            pixels_received     <= 0;
            pixels_recd_delay   <= 0;
            fifo_wr             <= 0;
            fifo_rd             <= 0;
            pixel_x             <= 0;
            line_num            <= 0;
            
            pixel_valid[5:1]    <= 0;
            rgb_pix_count       <= 0;
            sclr                <= 1;
            
            // Outputs
            sof                     <= 0;
            pixel_out_data_valid    <= 0;
            rgb_pixel_valid         <= 0;
        end else begin
            pixel_out_data_valid    <= rgb_pixel_valid;
            pixel_out_data          <= {rgb_pixel[29:25], rgb_pixel[19:14], rgb_pixel[9:5]};
        
            sclr <= 0;
        
            if (rgb_pixel_valid) rgb_pix_count <= rgb_pix_count + 1;
            
            /*pixel_read          <= pixel_write; //pixel available at main input, line buf read asserted
            pixel_valid         <= pixel_read; //input pixel shifted
            pixel_valid_delay1  <= pixel_valid; //shifted input pixel written to fifos, fifo outputs valid
            pixel_valid_delay2  <= pixel_valid_delay1;
            pixel_valid_delay3  <= pixel_valid_delay2;*/
            
            pixel_valid[5:1]    <= pixel_valid[4:0];
            pixels_recd_delay   <= {pixels_recd_delay[2:0], pixels_received};
            
            buf_pixel           <= pixel;
            buf2_pixel          <= buf_pixel;
            
            center_pix_buf[19:10] <= pix_sreg[2][2];
            center_pix_buf[9:0]   <= center_pix_buf[19:10];
            
            fifo_rd <= 0;
            if (pixel_valid[0]) begin
                pixels_received     <= pixels_received + 1;
                //Here is the delay for the pixels to be primed
                if (pixels_received > (line_length - 2)) begin //-3 cuz there's a 2-cycle delay after the read
                    fifo_rd[3]      <= 1;
                    if (pixels_received > (line_length * 2 - 7)) begin
                        fifo_rd[2]  <= 1;
                        if (pixels_received > (line_length * 3 - 12)) begin
                            fifo_rd[1] <= 1;
                            if (pixels_received > (line_length * 4 - 17))
                                fifo_rd[0] <= 1;
                        end
                    end
                end
                
                /*if (pixels_received > 4) begin
                    fifo_wr[3]          <= 1;
                    fifo_wr_data[3]     <= pix_sreg[4][0];
                end
            end else begin 
                fifo_wr[3] <= 0;*/
            end
            
            if (pixel_valid[2]) begin
                pix_sreg[4][4]      <= buf2_pixel;
                pix_sreg[4][3:0]    <= pix_sreg[4][4:1];
                    
                if (pixels_recd_delay[0] > 4) begin
                    fifo_wr[3]          <= 1;
                    fifo_wr_data[3]     <= pix_sreg[4][0];
                end
            end else begin 
                fifo_wr[3] <= 0;
            end
            
            if (pixel_valid[4]) begin
                //val_pixels_received <= val_pixels_received + 1;
                if (pixels_recd_delay[2] == (line_length * 4 + 5)) begin
                    db_state <= ST_G_R;//switch ? ST_R : ST_G_R;
                    sof      <= 1;
                end
            end
            
            for (int i = 0; i < 4; i++) begin
                if (fifo_rd[i]) begin
                    fifo_rd_data_valid[i]   <= 1;
                end else fifo_rd_data_valid[i] <= 0;
                
                if (fifo_rd_data_valid[i]) begin
                    pix_sreg[i][4]      <= fifo_out[i];
                    pix_sreg[i][3:0]    <= pix_sreg[i][4:1];
                    if (i > 0) begin
                        fifo_wr_data[i - 1] <= pix_sreg[i][0];
                        fifo_wr[i - 1]      <= 1;
                    end
                end else if (i > 0) fifo_wr[i - 1] <= 0;
            end
            
            case (db_state)
                ST_WAITFIRSTLINES: begin
                    rgb_pixel_valid <= 0;
                end
            
                ST_R: begin
                    sof <= 0;
                    
                    //r
                    colors[0] <= center_pix_buf[9:0];
                    //g
                    colors[1] <= gatrb;
                    //b
                    colors[2] <= ratb_b_b;
                    
                    if (pixel_valid[5]) begin
                        rgb_pixel_valid <= 1;
                        
                        if (pixel_x == (line_length - 6)) begin
                            db_state        <= ST_WAITFIRSTPIX;
                            last_db_state   <= ST_R;
                            pixel_x         <= pixel_x + 2;
                        end else begin
                            db_state    <= ST_G_R;
                            pixel_x     <= pixel_x + 2;
                        end
                    end else rgb_pixel_valid    <= 0;
                end
                    
                ST_G_R: begin
                    //r
                    colors[0] <= ratg_r_b;
                    //g
                    colors[1] <= center_pix_buf[9:0];
                    //b
                    colors[2] <= batg_r_b;
                    
                    if (pixel_valid[5]) begin
                        rgb_pixel_valid      <= 1;
                        db_state             <= ST_R;
                        
                        /*if (pixel_x == (line_length - 6)) begin
                            db_state        <= ST_WAITFIRSTPIX;
                            last_db_state   <= ST_G_R;
                            pixel_x         <= pixel_x + 2;
                        end else begin
                            db_state    <= ST_R;
                            pixel_x     <= pixel_x + 2;
                        end*/
                    end else rgb_pixel_valid <= 0;
                end
                    
                ST_G_B: begin
                    //r
                    colors[0] <= ratg_b_r;
                    //g
                    colors[1] <= center_pix_buf[9:0];
                    //b
                    colors[2] <= batg_b_r;
                    
                    if (pixel_valid[5]) begin
                        rgb_pixel_valid     <= 1;
                        
                        if (pixel_x == (line_length - 6)) begin
                            db_state        <= ST_WAITFIRSTPIX;
                            last_db_state   <= ST_G_B;
                            pixel_x         <= pixel_x + 2;
                        end else begin
                            db_state    <= ST_B;
                            pixel_x     <= pixel_x + 2;
                        end
                    end else rgb_pixel_valid    <= 0;
                end
                
                ST_B: begin //blue is dim
                    //r
                    colors[0] <= ratb_b_b;
                    //g
                    colors[1] <= gatrb; //not this
                    //b
                    colors[2] <= center_pix_buf[9:0];
                    
                    if (pixel_valid[5]) begin
                        rgb_pixel_valid      <= 1;
                        db_state            <= ST_G_B;
                        
                    end else rgb_pixel_valid <= 0;
                end
                
                ST_WAITFIRSTPIX: begin
                    rgb_pixel_valid <= 0;
                    if (pixel_valid[5]) begin
                        if (pixel_x == (line_length - 1)) begin
                            pixel_x     <= 0;
                            if (last_db_state == ST_G_B)
                                db_state    <= ST_G_R;
                            else
                                db_state    <= ST_B;
                        end else pixel_x <= pixel_x + 1;
                    end
                    /*if (pixel_valid[5]) begin
                        rgb_pixel_valid <= 1;
                        
                        if (pixel_x == (line_length - 1)) begin
                            pixel_x     <= 0;
                            if (last_db_state == ST_B)
                                db_state    <= ST_R;
                            else
                                db_state    <= ST_G_B;
                        end else pixel_x <= pixel_x + 1;
                    end else rgb_pixel_valid <= 0;*/
                end
            endcase
        end
    end
    
    always @(posedge clk) begin
        gatrb_1x4accum  <= pix_sreg[2][2] << 2;
        gatrb_4x2accum  <= (pix_sreg[1][2] + pix_sreg[2][1] + pix_sreg[2][3] + pix_sreg[3][2]) << 1;
        gatrb_4x1accum  <= pix_sreg[0][2] + pix_sreg[2][0] + pix_sreg[2][4] + pix_sreg[4][2];
        gatrb_accum     <= (gatrb_1x4accum + gatrb_4x2accum - gatrb_4x1accum); //4 + 8 - 4
        
        ratg_r_b_1x5_accum  <= (pix_sreg[2][2] << 2) + pix_sreg[2][2];
        ratg_r_b_2x4_accum  <= (pix_sreg[2][1] + pix_sreg[2][3]) << 2;
        ratg_r_b_6x1_accum  <= pix_sreg[2][0] + pix_sreg[1][1] + pix_sreg[3][1] + pix_sreg[1][3] + pix_sreg[2][4] + pix_sreg[3][3];
        ratg_r_b_2x0p5_accum <= (pix_sreg[0][2] + pix_sreg[4][2]) >> 1;
        ratg_r_b_accum      <= ratg_r_b_1x5_accum + ratg_r_b_2x4_accum + ratg_r_b_2x0p5_accum - ratg_r_b_6x1_accum; //5 + 8 + 1 - 6
        
        ratg_b_r_2x4_accum  <= (pix_sreg[1][2] + pix_sreg[3][2]) << 2;
        ratg_b_r_2x0p5_accum <= (pix_sreg[2][0] + pix_sreg[2][4]) >> 1;
        ratg_b_r_6x1_accum  <= pix_sreg[0][2] + pix_sreg[1][1] + pix_sreg[3][1] + pix_sreg[1][3] + pix_sreg[4][2] + pix_sreg[3][3];
        ratg_b_r_accum      <= ratg_r_b_1x5_accum + ratg_b_r_2x4_accum + ratg_b_r_2x0p5_accum - ratg_b_r_6x1_accum; //5 + 8 + 1 - 6
        
        ratb_b_b_1x6_accum      <= (pix_sreg[2][2] << 2) + (pix_sreg[2][2] << 1);
        ratb_b_b_4x2_accum      <= (pix_sreg[1][1] + pix_sreg[1][3] + pix_sreg[3][1] + pix_sreg[3][3]) << 1;
        ratb_b_b_4x1p5_accum_neg  <= (pix_sreg[0][2] + (pix_sreg[0][2] >> 1))
                                    + (pix_sreg[2][0] + (pix_sreg[2][0] >> 1))
                                    + (pix_sreg[2][4] + (pix_sreg[2][4] >> 1))
                                    + (pix_sreg[4][2] + (pix_sreg[4][2] >> 1));
        ratb_b_b_accum          <= ratb_b_b_1x6_accum + ratb_b_b_4x2_accum - ratb_b_b_4x1p5_accum_neg; //6 + 8 - 6
    end
    
    always_comb begin
        ratb_b_b    = ratb_b_b_accum[14] ? 0 : (ratb_b_b_accum[13] ? 10'h3FF : ratb_b_b_accum[12:3]);
        ratg_b_r    = ratg_b_r_accum[14] ? 0 : (ratg_b_r_accum[13] ? 10'h3FF : ratg_b_r_accum[12:3]);
        ratg_r_b    = ratg_r_b_accum[14] ? 0 : (ratg_r_b_accum[13] ? 10'h3FF : ratg_r_b_accum[12:3]);
        gatrb       = gatrb_accum[14] ? 0 : (gatrb_accum[13] ? 10'h3FF : gatrb_accum[12:3]);
        batg_b_r    = ratg_r_b; //same as ratg_r_b
        batg_r_b    = ratg_b_r; //same as ratg_b_r
    end
    
endmodule