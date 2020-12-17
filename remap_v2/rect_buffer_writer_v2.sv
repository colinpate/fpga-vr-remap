module rect_buffer_writer_v2
    #(
    parameter buffer_w           = 2048,
    parameter buffer_h           = 32,
    parameter buffer_size        = buffer_w * buffer_h,
    parameter buf_length        = buffer_size / 4,
    parameter buf_len_log       = $clog2(buf_length))
    (
        input                   reset,
        
        input                   st_clk,
        input [15:0]            st_data,
        input                   st_data_valid,
        
        input                   frame_start,
        
        output logic [63:0]     buf_data,
        output logic [59:0]     buf_address,
        output logic [3:0]      buf_write,
        output logic [15:0]     buf_row
    );
    
    parameter line_inc      = buffer_w;
    parameter blk_h_bits    = $clog2(buffer_h);
    
    logic [blk_h_bits - 1:0]    buffer_row_short;
    assign buffer_row_short = buf_row[blk_h_bits - 1:0];
    
    logic buf_index_i;
    logic [15:0]                                            buf_addr_even;
    logic [15:0]                                            buf_addr_odd;
    logic [3:0][14:0]                                       buf_addr_i;
    logic [3:0]                                             buf_write_i;
    logic [15:0]                                            st_data_i;
    logic [15:0]                                            buf_data_i;
    
    assign st_data_i    = st_data;
    assign buf_data     = {buf_data_i, buf_data_i, buf_data_i, buf_data_i};
    
    assign buf_write    = buf_write_i;
    
    assign buf_addr_i   = {buf_addr_odd[15:1], buf_addr_odd[15:1], buf_addr_even[15:1], buf_addr_even[15:1]};
    assign buf_address  = buf_addr_i;
    
    logic [11:0] pixel_col;
    
    typedef enum {ST_EVENROW, ST_ODDROW} statetype;
    statetype state;
    
    always_comb begin
        buf_write_i = 0;
        buf_data_i = 0;
        case (state)
            ST_EVENROW: buf_write_i = {2'b00, st_data_valid & (buf_addr_even[0]), st_data_valid & (!buf_addr_even[0])};
            ST_ODDROW:  buf_write_i = {st_data_valid & (buf_addr_odd[0]), st_data_valid & (!buf_addr_odd[0]), 2'b00};
        endcase
        
        buf_data_i = st_data_i;
    end
    
    always @(posedge st_clk)
    begin
        if (reset || frame_start) begin
            state           <= ST_EVENROW;
            pixel_col       <= 0;
            buf_addr_even   <= 0;
            buf_addr_odd    <= 0;
            buf_row         <= 0;
        end else begin
            case (state)
                ST_EVENROW: begin
                    if (st_data_valid) begin
                        buf_addr_even   <= buf_addr_even + 1;
                        if (pixel_col == (line_inc - 1)) begin
                            pixel_col       <= 0;
                            buf_row         <= buf_row + 1;
                            state           <= ST_ODDROW;
                        end else begin
                            pixel_col <= pixel_col + 1;
                        end
                    end
                end
                
                ST_ODDROW: begin
                    if (st_data_valid) begin
                        buf_addr_odd <= buf_addr_odd + 1;
                        if (pixel_col == (line_inc - 1)) begin
                            pixel_col   <= 0;
                            state       <= ST_EVENROW;
                            if (buffer_row_short == (buffer_h - 1)) begin
                                buf_addr_even   <= 0;
                                buf_addr_odd    <= 0;
                            end
                            buf_row         <= buf_row + 1;
                        end else begin
                            pixel_col <= pixel_col + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule