//`define SIM

module ddr3_pixel_writer_remap
    #(parameter in_width = 8,
    //parameter burst_len = 2,
    parameter rotate_buffers = 0,
    parameter burst_log = 2,
    parameter horiz = 1
    )
    (
        input                   pclk,
        input                   pclk_reset,
        
        input [16:0]            pixel_data,
        input                   pixel_valid,
        
        input [34:0]            coords_in,
        input                   coords_in_valid,
        
        input                       ddr3_clk,
        input                       ddr3clk_reset,
        output logic [26:0]         ddr3_write_address,
        output logic [255:0]        ddr3_write_data,
        output logic                ddr3_write,
        input                       ddr3_waitrequest,
        output logic [1:0]          ddr3_burstcount,
        
        //output logic            fifo_full_latch,
        //output logic [5:0]      fifo_level,
        
        output logic            fifo_almost_full,
        
        input   [31:0]          start_address_i
    );
    
    //Horizontal mode:
    //Write a frame of 960 wide 2-byte pixels
    //Vertical mode:
    //Write a frame of 1920 wide 2-byte pixels
    //Read_coords are the write coordinates X and Y of the 16- or 32-pixel line
    //If the write coordinate Y is 512 or greater, subtract E100 from the address 
    //  (equivalent to moving the frame up 480 lines of 1920 wide)
    //This works cuz write coordinates go from 0 to 479 (14 32-pixel high blocks)
    //  and then jump to 960 because blocks in between are converted to grayscale
    //  and ignored by the color writer
    
    parameter pixels_per_write = 256 / in_width;
    parameter pix_per_wr_log = $clog2(pixels_per_write);
    
    logic [1:0] burst_len;
    assign ddr3_burstcount = burst_len;
    
    typedef enum {ST_IDLE, ST_WAIT_FIFO, ST_FIRST_READ, ST_WAIT_WRITE, ST_WAIT_DATA} statetype;
    statetype state;
    
    logic [31:0]    coords_in_i;
    logic           coords_in_gray;
    logic           coords_in_short;
    logic           coords_in_eof;
    assign coords_in_i      = coords_in[31:0];
    assign coords_in_short  = coords_in[32];
    assign coords_in_gray   = coords_in[33];
    assign coords_in_eof    = coords_in[34];
    
    logic               coord_fifo_read;
    logic [31:0]        coord_fifo_q;
    logic [1:0][15:0]   read_coords;
    logic               read_coords_second_half;
    logic               read_eof, eof_d1, eof_d2;
    logic               read_short, short_d1, short_d2;
    
    assign read_coords  = {coord_fifo_q[31:2], 2'b00};
    assign read_coords_second_half = horiz ? (read_coords[0][10] | read_coords[0][9]) : (read_coords[1][10] | read_coords[1][9]); // Check if we're >= 512 (x coord if horizontal, y if vertical)
    assign read_eof     = coord_fifo_q[0];
    assign read_short   = coord_fifo_q[1];
    
    logic [26:0]    write_address_row;
    logic [26:0]    write_address_x;
    logic [26:0]    write_address_final;
    logic           fifo_aclr;
    
    remap_coord_fifo remap_coord_fifo_inst( //show-ahead dual clock 32-bit 256-word FIFO
        .aclr       ( fifo_aclr ),
        .data       ( {coords_in_i[31:2], coords_in_short, coords_in_eof} ),
        .rdclk      ( ddr3_clk ),
        .rdreq      ( coord_fifo_read ),
        .wrclk      ( pclk ),
        .wrreq      ( (coords_in_valid) && (!coords_in_gray) ),
        .q          ( coord_fifo_q )
    );
    
    logic [15:0]                     pixel;
    logic                            pixel_gray;
    logic [255:0]                    pixel_sreg;
    logic [pix_per_wr_log - 1:0]     pixel_index;
    assign pixel = pixel_data[15:0];
    assign pixel_gray = pixel_data[16];
    
    logic           fifo_write;
    logic           fifo_read;
    logic           fifo_read_ena;
    logic           fifo_empty;
    logic           fifo_wrfull;
    logic           fifo_rdfull;
    logic [255:0]   fifo_data;
    logic [5:0]     fifo_wrlevel;
    logic [5:0]     fifo_level;
    logic [7:0]     fifo_min;
    assign fifo_almost_full = fifo_wrlevel[5] && fifo_wrlevel[4];
    assign fifo_min         = short_d2 ? 0 : 1;
    
    ddr3_writer_fifo ddr3_write_fifo_inst( //256-bit dual clock 64-word FIFO
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
        .rdfull     ( fifo_rdfull ),
        .wrusedw    ( fifo_wrlevel )
    );
    
    logic [burst_log - 1:0] burst_index;
    
    assign ddr3_write_data = fifo_data;
    assign fifo_read    = ((state == ST_FIRST_READ) || ((fifo_read_ena) && (ddr3_write) && (!ddr3_waitrequest)));
    assign coord_fifo_read = (state == ST_FIRST_READ);
    assign ddr3_write   = (state == ST_WAIT_WRITE);
    
    always @(posedge pclk)
    begin
        if (pclk_reset) begin
            pixel_index     <= 0;
            fifo_write      <= 0;
            //fifo_full_latch <= 0;
            fifo_aclr           <= 1;
        end else begin
            fifo_aclr           <= 0;
            
            //if (fifo_wrfull) fifo_full_latch <= 1;
            
            if ((pixel_valid) && (!pixel_gray)) begin
                pixel_sreg  <= {pixel, pixel_sreg[255:in_width]}; //ARGB
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
    
    logic [3:0][26:0]   start_addresses;
    logic [26:0]        back_start_address;
    
    always @(posedge ddr3_clk)
    begin
        if (ddr3clk_reset) begin
            state               <= ST_IDLE;
            ddr3_write_address  <= 0;
            
            if (horiz) begin
                back_start_address  <= start_address_i[31:5] - 20'h1E; //1E is 480 pixels / (32 pixels / 2 bytes) to shift left 480 pix
            end else begin
                back_start_address  <= start_address_i[31:5] - 20'h0E100; //E100 is 480 lines * 1920 pixels / (32 pixels / 2 bytes) to shift up 480 pix
            end
            start_addresses[0]  <= start_address_i[31:5] + 20'h00000; //1920w * 960h * 2bytes/pix / 32byte/write
            start_addresses[1]  <= start_address_i[31:5] + 20'h40000;
            start_addresses[2]  <= start_address_i[31:5] + 20'h80000;
            start_addresses[3]  <= start_address_i[31:5] + 20'hC0000;
        end else begin
            if (horiz) begin
                write_address_row   <= (read_coords[1] << 6) - (read_coords[1] << 2);  // Multiply by 960 divided by (32/2); y_address = y*(1024-64)pix/(32bytesperword / 2bytesperpix)
            end else begin
                write_address_row   <= (read_coords[1] << 7) - (read_coords[1] << 3); // Multiply by 1920 divided by (32/2); y_address = y*(2048-128)pix/(32bytesperword / 2bytesperpix)
            end
            write_address_x     <= (read_coords_second_half ? back_start_address : start_addresses[0]) + read_coords[0][15:4]; // Divide x coordiante by (32/2) and add to the address offset (address is negative offset if we're in the second half)
            eof_d1              <= read_eof; // end of frame marker, comes with coordinates
            short_d1            <= read_short;
            
            write_address_final <= write_address_row + write_address_x; //y address + x/16;
            eof_d2              <= eof_d1;
            short_d2            <= short_d1;
            
            case (state)
                ST_IDLE: begin
                    if ((fifo_level > fifo_min) || (fifo_rdfull)) begin
                        state           <= ST_FIRST_READ;
                        
                        ddr3_write_address  <= write_address_final;
                        if ((eof_d2) && (rotate_buffers == 1)) begin
                            start_addresses     <= {start_addresses[0], start_addresses[3:1]};
                            back_start_address  <= start_addresses[1] - (horiz ? 20'h1E : 20'h0E100);
                        end
                        if (short_d2) begin
                            burst_len   <= 2'b01;
                        end else begin
                            burst_len   <= 2'b10;
                        end
                        
                        burst_index     <= 0;
                        fifo_read_ena   <= 0;
                    end
                end
                
                ST_FIRST_READ: begin
                    state           <= ST_WAIT_WRITE;
                    if (burst_len == 2'b10) begin
                        fifo_read_ena   <= 1;
                    end
                end
                
                ST_WAIT_WRITE: begin
                    if (!ddr3_waitrequest) begin
                        if (burst_index == (burst_len - 1)) begin
                            state               <= ST_WAIT_DATA;
                        end else begin
                            if (burst_index == (burst_len - 2)) begin
                                fifo_read_ena   <= 0;
                            end
                        end
                        burst_index     <= burst_index + 1;
                    end
                end
                
                ST_WAIT_DATA: begin
                    state   <= ST_IDLE;
                end
            endcase
        end
    end
endmodule