module bilinear_interpolate_2pixels(
    input               clk,
    
    output logic [7:0]  pixel_out,
    output logic        pixel_out_valid,
    
    input   [15:0]      pixel_in,
    input               pixel_in_valid,
    
    input   [1:0]       fraction
    );
    
    logic [1:0][7:0] pixel_in_i;
    assign pixel_in_i = pixel_in;
    
    logic [3:0][7:0] interpolated_pixel;
    
    assign interpolated_pixel[0] = pixel_in_i[0];
    assign interpolated_pixel[1] = pixel_in_i[0] - (pixel_in_i[0] >> 2) + (pixel_in_i[1] >> 2);
    assign interpolated_pixel[2] = (pixel_in_i[0] >> 1) + (pixel_in_i[1] >> 1);
    assign interpolated_pixel[3] = pixel_in_i[1] - (pixel_in_i[1] >> 2) + (pixel_in_i[0] >> 2);
    
    always @(posedge clk) begin
        pixel_out_valid <= pixel_in_valid;
        case(fraction)
            2'b00:
                pixel_out <= interpolated_pixel[0];
            2'b01:
                pixel_out <= interpolated_pixel[1];
            2'b10:
                pixel_out <= interpolated_pixel[2];
            2'b11:
                pixel_out <= interpolated_pixel[3];
        endcase
    end
endmodule