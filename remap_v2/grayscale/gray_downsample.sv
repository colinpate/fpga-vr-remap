module gray_downsample #(
    parameter wr_blk_w = 32,
    parameter wr_frame_w = 2048
    )(
    input               clk,
    input               reset,
    
    input [33:0]        coords_in,
    input               coords_in_valid,
    
    input [7:0]         pixel_in,
    input               pixel_in_valid,
    
    output logic [33:0] coords_out,
    output logic        coords_out_valid,
    
    output logic [7:0]  pixel_out,
    output logic        pixel_out_valid
    );
    
    parameter frame_blk_w   = wr_frame_w / wr_blk_w;
    parameter blk_bits      = $clog2(wr_blk_w) - 1;
    parameter fr_bits       = $clog2(wr_frame_w) - 1;
    
    logic           coord_fifo_read;
    logic [31:0]    coord_fifo_q;
    
    gray_remap_coord_fifo gray_remap_coord_fifo_inst( //show-ahead single clock 32-bit FIFO
        .sclr       ( reset ),
        .data       ( {coords_in[31:2], coords_in[32], coords_in[33]} ),
        .clock      ( clk ),
        .rdreq      ( coord_fifo_read ),
        .wrreq      ( coords_in_valid ),
        .q          ( coord_fifo_q )
    );
    
    logic [15:0]    read_row;
    logic [15:0]    read_col;
    logic           read_short;
    logic           read_eof;
    assign read_row = coord_fifo_q[31:16];
    assign read_col = {coord_fifo_q[15:2], 2'b00};
    assign read_short   = coord_fifo_q[1];
    assign read_eof     = coord_fifo_q[0];
    
    logic [7:0] ds_pixel;
    logic       ds_pixel_valid;
    
    gray_horiz_downsample gray_horiz_downsample_inst(
        .clk            (clk),
        .reset          (reset),
        .pixel_in       (pixel_in),
        .pixel_in_valid (pixel_in_valid),
        .pixel_out      (ds_pixel),
        .pixel_out_valid(ds_pixel_valid)
    );
    
    logic [7:0]             ram_q;
    logic [fr_bits - 1:0]   ram_addr;
    logic [fr_bits - 1:0]   end_addr;
    logic                   ram_wr;
    
    grayscale_remap_ram grayscale_remap_ram_inst(
        .data   (ds_pixel),
        .address({16'h0, ram_addr}),
        .wren   (ram_wr),
        .q      (ram_q),
        .clock  (clk)
    );
    
    typedef enum {ST_IDLE, ST_LINE} statetype;
    statetype state;
    
    logic       line_odd;
    logic [8:0] pixel_sum;
    
    always @(posedge clk) begin
        if (reset) begin
            state            <= ST_IDLE;
            coord_fifo_read  <= 0;
            coords_out_valid <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (pixel_in_valid) begin
                        ram_addr        <= read_col >> 1; // div by 2
                        end_addr        <= read_short ? ((read_col >> 1) + 7) : ((read_col >> 1) + 15);
                        coord_fifo_read <= 1;
                        
                        coords_out       <= {read_eof, read_short, 1'b0, read_row[15:1], 1'b0, read_col[15:1]};
                        coords_out_valid <= read_row[0];
                    
                        line_odd         <= read_row[0];
                        state            <= ST_LINE;
                    end
                end
                
                ST_LINE: begin
                    coord_fifo_read     <= 0;
                    coords_out_valid    <= 0;
                    if (ds_pixel_valid) begin
                        if (ram_addr == end_addr) begin
                            state       <= ST_IDLE;
                        end else begin
                            ram_addr    <= ram_addr + 1;
                        end
                    end
                end
            endcase
        end
    end
    
    always_comb begin
        pixel_out_valid = (state == ST_LINE) & line_odd & ds_pixel_valid;
        pixel_sum       = ram_q + ds_pixel;
        pixel_out       = pixel_sum[8:1];
        
        ram_wr = (state == ST_LINE) & (!line_odd) & ds_pixel_valid;
    end
endmodule