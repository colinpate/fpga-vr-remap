module rect_buffer_reader
    #(
    parameter buffer_w = 2048,
    parameter buffer_h = 32,
    parameter block_size = buffer_w * buffer_h,
    parameter buf_length = block_size / 4,
    parameter buf_len_log = $clog2(buf_length)
    )
    (
        input reset,
        
        input [32:0]                read_coord_in,
        input                       read_coord_valid,
        
        input        [63:0]         buf_data,
        output logic [59:0]         buf_address,
        input                       buf_read_clk,
        
        output logic [64:0]         pix_to_inter,
        output logic [3:0]          read_coord_frac_to_inter,
        output logic                pix_to_inter_valid
    );
    
    parameter row_shift         = $clog2(buffer_w / 2);
    parameter valid_row_bits    = $clog2(buffer_h);
    parameter frac_bits = 2;
    parameter pixel_in_width = 16;
    
    logic coords_in_gray, coords_in_gray_d1, coords_in_gray_d2, coords_in_gray_out;
    logic [1:0][15:0] read_coord_in_i;
    assign read_coord_in_i  = read_coord_in[31:0];
    assign coords_in_gray   = read_coord_in[32];
    
    logic read_coord_valid_d1;
    logic read_coord_valid_d2;
    
    logic buf_index_i;
    logic [3:0][14:0]                   buf_addr_i;
    logic [3:0][pixel_in_width - 1:0]   buf_data_i;
    
    logic [1:0][1:0][pixel_in_width - 1:0]   pix_to_inter_i;
    assign pix_to_inter[63:0]   = pix_to_inter_i;
    assign pix_to_inter[64]     = coords_in_gray_out;
    
    assign buf_data_i   = buf_data;
    assign buf_address  = buf_addr_i;
    
    /*buffers:
    0 1 (0, 0) (0, 1)
    2 3 (1, 0) (1, 1)
    
    even row, even col
    0 1
    2 3
    addr[1:0] = (row * w / 2) + col[7:1]
    addr[3:2] = (row * w / 2) + col[7:1]
    
    odd row, even col
    2 3
    0 1
    addr[1:0] = ((row + 1) * w / 2) + col[7:1]
    addr[3:2] = (row * w / 2) + col[7:1]
    
    even row, odd col
    1 0
    3 2
    addr[1:0] = {(row * w / 2) + col[7:1],              (row * w / 2) + col[7:1] + 1}
    addr[3:2] = {(row * w / 2) + col[7:1],              (row * w / 2) + col[7:1] + 1}
    
    odd row, odd col
    3 2
    1 0
    addr[1:0] = {((row + 1) * w / 2) + col[7:1],        ((row + 1) * w / 2) + col[7:1] + 1}
    addr[3:2] = {(row * w / 2) + col[7:1]               (row * w / 2) + col[7:1] + 1}
    
    odd rows make addr [1:0] be added to
    odd cols make addrs 0 and 2 be added to
    */
    
    parameter int_bits = 15 - frac_bits;
    
    logic read_addr_valid, read_data_valid;
    logic [1:0] coord_lsb_d1;
    logic [1:0] coord_lsb_d2;
    logic [1:0][frac_bits - 1:0]    read_coord_frac_d1;
    logic [1:0][frac_bits - 1:0]    read_coord_frac_d2;
    logic [1:0][frac_bits - 1:0]    read_coord_frac;
    logic [1:0][15 - frac_bits:0]   read_coord_integer;
    
    assign read_coord_frac[0]       = read_coord_in_i[0][frac_bits - 1:0];
    assign read_coord_frac[1]       = read_coord_in_i[1][frac_bits - 1:0];
    assign read_coord_integer[0]    = read_coord_in_i[0][15:frac_bits];
    assign read_coord_integer[1]    = read_coord_in_i[1][valid_row_bits + frac_bits - 1:frac_bits];
    
    logic [buf_len_log - 1:0] row_addr;
    logic [buf_len_log - 1:0] row_addr_odd;
    logic [buf_len_log - 1:0] col_addr;
    logic [buf_len_log - 1:0] col_addr_odd;
    
    assign row_addr         = read_coord_integer[1][int_bits:1] << row_shift;
    assign row_addr_odd     = (read_coord_integer[1][int_bits:1] + 1) << row_shift;
    assign col_addr         = read_coord_integer[0][int_bits:1];
    assign col_addr_odd     = col_addr + 1;
    
    logic [buf_len_log - 1:0] row_addr_reg;
    logic [buf_len_log - 1:0] row_addr_odd_reg;
    logic [buf_len_log - 1:0] col_addr_reg;
    logic [buf_len_log - 1:0] col_addr_odd_reg;
    
    always_comb begin
        buf_addr_i[0] = row_addr_reg + col_addr_reg;
        buf_addr_i[1] = row_addr_reg + col_addr_reg;
        buf_addr_i[2] = row_addr_reg + col_addr_reg;
        buf_addr_i[3] = row_addr_reg + col_addr_reg;
        
        case (coord_lsb_d1) //LSbits of row and col
            2'b01: begin //even row, odd col
                buf_addr_i[0] = row_addr_reg + col_addr_odd_reg;
                buf_addr_i[2] = row_addr_reg + col_addr_odd_reg;
            end
            
            2'b10: begin //odd row, even col
                buf_addr_i[0] = row_addr_odd_reg + col_addr_reg;
                buf_addr_i[1] = row_addr_odd_reg + col_addr_reg;
            end
            
            2'b11: begin //odd row, odd col
                buf_addr_i[0] = row_addr_odd_reg + col_addr_odd_reg;
                buf_addr_i[1] = row_addr_odd_reg + col_addr_reg;
                buf_addr_i[2] = row_addr_reg + col_addr_odd_reg;
            end
        endcase
    end
    
    always @(posedge buf_read_clk) begin
        if (reset) begin
            pix_to_inter_valid  <= 0;
            read_data_valid     <= 0;
        end else begin
            // Pipeline stage 1
            read_addr_valid             <= read_coord_valid;
            coord_lsb_d1                <= {read_coord_integer[1][0], read_coord_integer[0][0]};
            read_coord_frac_d1          <= read_coord_frac;
            coords_in_gray_d1           <= coords_in_gray;
            
            row_addr_reg                <= row_addr;
            row_addr_odd_reg            <= row_addr_odd;
            col_addr_reg                <= col_addr;
            col_addr_odd_reg            <= col_addr_odd;
            
            // Pipeline stage 2
            read_data_valid             <= read_addr_valid;
            coord_lsb_d2                <= coord_lsb_d1;
            read_coord_frac_d2          <= read_coord_frac_d1;
            coords_in_gray_d2           <= coords_in_gray_d1;
            
            // Pipeline stage 3
            read_coord_frac_to_inter    <= read_coord_frac_d2;
            coords_in_gray_out          <= coords_in_gray_d2;
            pix_to_inter_valid          <= read_data_valid;
            
            case (coord_lsb_d2)
                2'b00: begin
                    pix_to_inter_i[0][0] <= buf_data_i[0];
                    pix_to_inter_i[0][1] <= buf_data_i[1];
                    pix_to_inter_i[1][0] <= buf_data_i[2];
                    pix_to_inter_i[1][1] <= buf_data_i[3];
                end
                
                2'b01: begin
                    pix_to_inter_i[0][0] <= buf_data_i[1];
                    pix_to_inter_i[0][1] <= buf_data_i[0];
                    pix_to_inter_i[1][0] <= buf_data_i[3];
                    pix_to_inter_i[1][1] <= buf_data_i[2];
                end
                
                2'b10: begin
                    pix_to_inter_i[0][0] <= buf_data_i[2];
                    pix_to_inter_i[0][1] <= buf_data_i[3];
                    pix_to_inter_i[1][0] <= buf_data_i[0];
                    pix_to_inter_i[1][1] <= buf_data_i[1];
                end
                
                2'b11: begin
                    pix_to_inter_i[0][0] <= buf_data_i[3];
                    pix_to_inter_i[0][1] <= buf_data_i[2];
                    pix_to_inter_i[1][0] <= buf_data_i[1];
                    pix_to_inter_i[1][1] <= buf_data_i[0];
                end
            endcase
        end
    end
endmodule