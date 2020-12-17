module rgb_to_gray(
    input               clk,
    input [15:0]        pixel_in,
    input               pixel_in_valid,
    output logic [7:0]  pixel_out,
    output logic        pixel_out_valid
    );
    
    logic [6:0]     sum;
    logic           sum_valid;
    logic [8:0]     accum_5x;
    logic           accum_5x_valid;
    
    always @(posedge clk) begin
        sum         <= pixel_in[15:11] + pixel_in[10:6] + pixel_in[4:0]; //5 bits * 3 = 7 bits
        sum_valid   <= pixel_in_valid;
        
        accum_5x        <= (sum << 2) + sum; // 5 bits * 15 = 9 bits
        accum_5x_valid  <= sum_valid;
        
        pixel_out       <= accum_5x[8:1]; // 9 bits / 2 = 8 bits
        pixel_out_valid <= accum_5x_valid;
    end
endmodule