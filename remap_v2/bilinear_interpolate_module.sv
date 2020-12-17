module bilinear_interpolate_module(
    input               clk,
    
    output logic [16:0] pixel_out,
    output logic        pixel_out_valid,
    
    output logic [15:0] pixel_out_2,
    output logic        pixel_out_valid_2,
    
    input   [64:0]      pixel_in,
    input               pixel_in_valid,
    
    input   [3:0]       fraction
    );
    
    assign pixel_out_2          = pixel_out[15:0];
    assign pixel_out_valid_2    = pixel_out_valid;
    
    logic [2:0][1:0][1:0][7:0]  pixel_in_i;
    logic [3:0][15:0]           pixel_in_i_partial;
    
    logic [2:0][1:0][7:0]       lr_interpolated_pixels;
    logic [2:0][1:0]            lr_interpolated_pixels_valid;
    logic [2:0][7:0]            pixel_out_i;
    logic [2:0]                 pixel_out_valid_i;
    
    assign pixel_in_i_partial = pixel_in[63:0];
    logic pixel_in_gray, pixel_in_gray_d1, pixel_out_gray;
    assign pixel_in_gray = pixel_in[64];
    
    logic [1:0] x_fraction_d1;
    always @(posedge clk) begin
        x_fraction_d1 <= fraction[1:0];
        
        pixel_in_gray_d1    <= pixel_in_gray;
        pixel_out_gray      <= pixel_in_gray_d1;
    end
    
    
    assign pixel_in_i[0][0][0] = {pixel_in_i_partial[0][4:0], 3'b100};
    assign pixel_in_i[1][0][0] = {pixel_in_i_partial[0][10:5], 2'b10};
    assign pixel_in_i[2][0][0] = {pixel_in_i_partial[0][15:11], 3'b100};
    assign pixel_in_i[0][0][1] = {pixel_in_i_partial[1][4:0], 3'b100};
    assign pixel_in_i[1][0][1] = {pixel_in_i_partial[1][10:5], 2'b10};
    assign pixel_in_i[2][0][1] = {pixel_in_i_partial[1][15:11], 3'b100};
    assign pixel_in_i[0][1][0] = {pixel_in_i_partial[2][4:0], 3'b100};
    assign pixel_in_i[1][1][0] = {pixel_in_i_partial[2][10:5], 2'b10};
    assign pixel_in_i[2][1][0] = {pixel_in_i_partial[2][15:11], 3'b100};
    assign pixel_in_i[0][1][1] = {pixel_in_i_partial[3][4:0], 3'b100};
    assign pixel_in_i[1][1][1] = {pixel_in_i_partial[3][10:5], 2'b10};
    assign pixel_in_i[2][1][1] = {pixel_in_i_partial[3][15:11], 3'b100};
    
    assign pixel_out = {pixel_out_gray, pixel_out_i[2][7:3], pixel_out_i[1][7:2], pixel_out_i[0][7:3]}; //{pixel_out_gray, pixel_out_i[1][7:2], 10'h200};//
    assign pixel_out_valid = |pixel_out_valid_i;
    
    genvar i;
    generate
        for (i = 0; i < 3; i++) begin : bwafw
            bilinear_interpolate_2pixels bpi2_left(
                .clk             (clk),
                
                .pixel_out       (lr_interpolated_pixels[i][0]),
                .pixel_out_valid (lr_interpolated_pixels_valid[i][0]),
                
                .pixel_in        ({pixel_in_i[i][1][0], pixel_in_i[i][0][0]}),
                .pixel_in_valid  (pixel_in_valid),
                
                .fraction        (fraction[3:2])
            );
            
            bilinear_interpolate_2pixels bpi2_right(
                .clk             (clk),
                
                .pixel_out       (lr_interpolated_pixels[i][1]),
                .pixel_out_valid (lr_interpolated_pixels_valid[i][1]),
                
                .pixel_in        ({pixel_in_i[i][1][1], pixel_in_i[i][0][1]}),
                .pixel_in_valid  (pixel_in_valid),
                
                .fraction        (fraction[3:2])
            );
            
            bilinear_interpolate_2pixels bpi2(
                .clk             (clk),
                
                .pixel_out       (pixel_out_i[i]),
                .pixel_out_valid (pixel_out_valid_i[i]),
                
                .pixel_in        (lr_interpolated_pixels[i]),
                .pixel_in_valid  (|lr_interpolated_pixels_valid),
                
                .fraction        (x_fraction_d1)
            );
        end
    endgenerate
endmodule