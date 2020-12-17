//`define SIM

module ddr3_pix_wr_gray_remap #(
        parameter min_x = 240,
        parameter max_x = 720,
        parameter rotate_buffers = 0,
        parameter horiz = 1
        )(
        input                   pclk,
        input                   pclk_reset,
        
        input [7:0]             pixel_data,
        input                   pixel_valid,
        
        input [33:0]            coords_in,
        input                   coords_in_valid,
        
        input                   ddr3_clk,
        input                   ddr3clk_reset,
        output logic [26:0]     ddr3_write_address,
        output logic [255:0]    ddr3_write_data,
        output logic            ddr3_write,
        input                   ddr3_waitrequest,
        output logic [31:0]     ddr3_byteenable,
        
        input   [31:0]          start_address_i,
        
        output logic [1:0]      pointer_data,
        output logic            pointer_valid,
        
        output [26:0]           start_out
    );
    
    assign start_out = start_address_i[31:5];
    
    localparam in_width = 8;
    localparam pixels_per_write = 64 / 8;
    localparam pix_per_wr_log = $clog2(pixels_per_write);
    
    typedef enum {ST_IDLE, ST_FIRST_READ, ST_SECOND_READ, ST_WAIT_WRITE, ST_WAIT_DATA} statetype;
    statetype state;
    
    logic [31:0] coords_in_i;
    assign coords_in_i  = {coords_in[31:2], coords_in[33], coords_in[32]};
    
    logic               coord_fifo_read;
    logic [31:0]        coord_fifo_q;
    logic [15:0]        write_x;
    logic [15:0]        write_x_i;
    logic [15:0]        write_y;
    logic [15:0]        write_y_i;
    logic               write_short, short_d1, short_d2, short_i;
    logic               end_of_frame, eof_d1, eof_d2;
    
    assign write_x      = {coord_fifo_q[15:2], 2'b00};
    assign write_y      = coord_fifo_q[31:16];
    assign write_short  = coord_fifo_q[0];
    assign end_of_frame = coord_fifo_q[1];
    
    logic [26:0]    write_address_row;
    logic [26:0]    write_address_final;
    logic [31:0]    write_address_be;
    logic           fifo_aclr;
    logic           coords_in_bounds, coords_in_bounds_i;
    
    remap_coord_fifo remap_coord_fifo_inst( //show-ahead dual clock 256-word 32-bit FIFO
        .aclr       ( fifo_aclr ),
        .data       ( coords_in_i ),
        .rdclk      ( ddr3_clk ),
        .rdreq      ( coord_fifo_read ),
        .wrclk      ( pclk ),
        .wrreq      ( coords_in_valid ),
        .q          ( coord_fifo_q )
    );
    
    logic [7:0]                     pixel;
    logic [63:0]                    pixel_sreg;
    logic [pix_per_wr_log - 1:0]    pixel_index;
    assign pixel = pixel_data;
    
    logic           fifo_write;
    logic           fifo_read;
    logic           fifo_read_ena;
    logic           fifo_empty;
    logic           fifo_wrfull;
    logic           fifo_rdfull;
    logic [63:0]    fifo_data;
    logic [7:0]     fifo_level;
    logic [7:0]     fifo_min;
    logic           fifo_almost_full;
    
    ddr3_gray_writer_fifo ddr3_gray_write_fifo_inst( //dual clock 256-word 64-bit FIFO
        .aclr       ( fifo_aclr ),
        .data       ( pixel_sreg ),
        .rdclk      ( ddr3_clk ),
        .rdreq      ( fifo_read ),
        .wrclk      ( pclk ),
        .wrreq      ( fifo_write ),
        .q          ( fifo_data ),
        .rdempty    ( fifo_empty ),
        .rdusedw    ( fifo_level ),
        .wrfull     ( fifo_wrfull ),
        .rdfull     ( fifo_rdfull )
    );
    
    logic [63:0] out_reg;
    assign ddr3_write_data  = short_i ? {fifo_data, fifo_data, fifo_data, fifo_data} : {fifo_data, out_reg, fifo_data, out_reg};
    assign fifo_read        = (state == ST_FIRST_READ) || (state == ST_SECOND_READ);
    assign coord_fifo_read  = (state == ST_FIRST_READ);
    assign ddr3_write       = (state == ST_WAIT_WRITE);
    assign fifo_min         = short_d2 ? 0 : 1;
    assign fifo_almost_full = (fifo_level[7] && fifo_level[6]) || fifo_rdfull;
    
    always @(posedge pclk)
    begin
        if (pclk_reset) begin
            pixel_index     <= 0;
            fifo_write      <= 0;
            fifo_aclr       <= 1;
        end else begin
            fifo_aclr       <= 0;
            
            if (pixel_valid) begin
                pixel_sreg  <= {pixel, pixel_sreg[63:in_width]}; //ARGB
                pixel_index <= pixel_index + 1;
                if (pixel_index == (pixels_per_write - 1)) begin
                    fifo_write <= 1;
                end else begin
                    fifo_write <= 0;
                end
            end else begin
                fifo_write <= 0;
            end
        end
    end
    
    logic [3:0][26:0] start_addresses;
    
    logic [26:0] negative_shift_offset;
    assign negative_shift_offset = horiz ? (min_x << 5) - (min_x << 3) : 0; 
    
    always @(posedge ddr3_clk)
    begin
        if (ddr3clk_reset) begin
            state               <= ST_IDLE;
            ddr3_write_address  <= 0;
            pointer_valid       <= 0;
            
            start_addresses[0]  <= start_address_i[31:5] + 16'h0000 - negative_shift_offset; //480w * 720h * 1byte/pix / 32byte/write
            start_addresses[1]  <= start_address_i[31:5] + 16'h4000 - negative_shift_offset;
            start_addresses[2]  <= start_address_i[31:5] + 16'h8000 - negative_shift_offset;
            start_addresses[3]  <= start_address_i[31:5] + 16'hC000 - negative_shift_offset;
        end else begin
            if (horiz) begin
                write_address_row   <= start_addresses[0] + (write_y << 5) - (write_y << 3); // y address = (y * 1024 - y * 256) / 32 pix_per_address - 768 wide lines
                write_x_i           <= write_x;
                write_y_i           <= write_y - min_x;
            end else begin
                write_address_row   <= start_addresses[0] + (write_y << 4) - write_y; // y address = (y * 512 - y * 32) / 32 pix_per_address - 480 wide lines
                write_x_i           <= write_x - min_x; 
                write_y_i           <= write_y;
            end
            eof_d1              <= end_of_frame;
            short_d1            <= write_short;
            
            write_address_final <= write_address_row + (write_x_i >> 5); // pix address = y address + (x / 32) (pixel column / (256 / 8))
            //write_address_be    <= write_x_i[4] ? 32'hFFFF0000 : 32'h0000FFFF;
            case ({short_d1, write_x_i[4]})
                2'b00: write_address_be <= 32'h0000FFFF;
                2'b01: write_address_be <= 32'hFFFF0000;
                2'b10: write_address_be <= (write_x_i[3] ? 32'h0000FF00 : 32'h000000FF);
                2'b11: write_address_be <= (write_x_i[3] ? 32'hFF000000 : 32'h00FF0000);
            endcase
            if (horiz) begin
                coords_in_bounds    <= write_y_i < (max_x - min_x);
            end else begin
                coords_in_bounds    <= write_x_i < (max_x - min_x);
            end
            eof_d2              <= eof_d1;
            short_d2            <= short_d1;
            
            case (state)
                ST_IDLE: begin
                    if ((fifo_level > fifo_min) || (fifo_rdfull)) begin
                        state               <= ST_FIRST_READ;
                        
                        ddr3_write_address  <= write_address_final;
                        ddr3_byteenable     <= write_address_be;
                        coords_in_bounds_i  <= coords_in_bounds;
                        short_i             <= short_d2;
                        if ((eof_d2) && (rotate_buffers == 1)) begin
                            start_addresses     <= {start_addresses[0], start_addresses[3:1]};
                            
                            pointer_data        <= start_addresses[0][15:14];
                            pointer_valid       <= 1;
                        end
                    end
                end
                
                ST_FIRST_READ: begin
                    pointer_valid   <= 0;
                    if (short_i) begin //writedata is fifo q
                        state   <= (coords_in_bounds_i && (!fifo_almost_full)) ? ST_WAIT_WRITE : ST_WAIT_DATA;
                    end else begin
                        state   <= ST_SECOND_READ;
                    end
                end
                
                ST_SECOND_READ: begin
                    out_reg         <= fifo_data;
                    state           <= (coords_in_bounds_i && (!fifo_almost_full)) ? ST_WAIT_WRITE : ST_WAIT_DATA;
                end
                
                ST_WAIT_WRITE: begin
                    if (!ddr3_waitrequest) begin
                        state <= ST_WAIT_DATA;
                    end
                end
                
                ST_WAIT_DATA: begin
                    state   <= ST_IDLE;
                end
            endcase
        end
    end
endmodule