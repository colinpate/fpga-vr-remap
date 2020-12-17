module gray_horiz_downsample(
        input               clk,
        input               reset,
        input [7:0]         pixel_in,
        input               pixel_in_valid,
        output logic [7:0]  pixel_out,
        output logic        pixel_out_valid
    );
    
    logic [7:0]     prev_pixel;
    logic           prev_pixel_valid;
    logic [8:0]     sum;
    
    assign pixel_out = sum[8:1];
    
    always @(posedge clk) begin
        if (reset) begin
            prev_pixel_valid    <= 0;
            pixel_out_valid     <= 0;
        end else begin
            if (pixel_in_valid) begin
                if (prev_pixel_valid) begin
                    prev_pixel_valid    <= 0;
                    sum                 <= pixel_in + prev_pixel;
                    pixel_out_valid     <= 1;
                end else begin
                    prev_pixel_valid    <= 1;
                    prev_pixel          <= pixel_in;
                    pixel_out_valid     <= 0;
                end
            end else begin
                pixel_out_valid <= 0;
            end
        end
    end
endmodule