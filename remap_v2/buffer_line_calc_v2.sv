module buffer_line_calc
    #(
    parameter wr_blk_w          = 32,
    parameter wr_blk_h          = 32,
    parameter wr_frame_w        = 736,
    parameter wr_frame_h        = 1920,
    parameter coord_frac_bits   = 2
    )
    (
        input                           reset,
        
        input logic                     st_clk,
        
        input logic                     frame_start,
        
        input logic [15:0]              buf_writer_row,
        
        output logic [15:0]             blk_request_data,
        output logic                    blk_request_valid,
        
        input logic                     blk_read_valid,
        input logic [167:0]             blk_read_in,
        output logic                    blk_read_ready,
        
        input logic                     coord_out_ready,
        output logic [65:0]             coords_out,
        output logic                    coords_out_valid,
        
        output logic [34:0]             write_coords_out,
        output logic                    write_coords_out_valid,
        
        output logic [33:0]             write_coords_out_2,
        output logic                    write_coords_out_valid_2
    );
    
    parameter wr_blk_w_log      = $clog2(wr_blk_w);
    parameter wr_blk_h_log      = $clog2(wr_blk_h);
    parameter wr_frame_blk_h    = wr_frame_h / wr_blk_h;
    parameter wr_fr_b_h_bits    = $clog2(wr_frame_blk_h) - 1;
    parameter wr_fr_h_bits      = $clog2(wr_frame_h) - 1;
    parameter wr_frame_blk_w    = wr_frame_w / wr_blk_w;
    parameter icbm_addr_w       = $clog2(wr_frame_blk_w) - 1;
    
    typedef struct packed // 12 int
    {
        logic [12 + coord_frac_bits - 1:0] x;
        logic [12 + coord_frac_bits - 1:0] y;
    } abs_coords_out;
    
    typedef struct packed // 1 sign 6 int
    {
        logic signed [7 + coord_frac_bits - 1:0] x;
        logic signed [7 + coord_frac_bits - 1:0] y;
    } rel_coords_out;
    
    typedef struct packed //1 sign 12 int
    {
        logic signed [12 + coord_frac_bits + wr_blk_w_log:0] x;
        logic signed [12 + coord_frac_bits + wr_blk_h_log:0] y;
    } abs_coords_accum;
    
    typedef struct packed // 1 sign 6 int
    {
        logic signed [7 + coord_frac_bits + wr_blk_w_log - 1:0] x;
        logic signed [7 + coord_frac_bits + wr_blk_h_log - 1:0] y;
    } rel_coords_accum;
    
    typedef struct packed // 1 sign 6 int
    {
        logic signed [7 + coord_frac_bits - 1:0] x;
        logic signed [7 + coord_frac_bits - 1:0] y;
    } rel_rel_coords;
    
    typedef struct packed
    {
        abs_coords_accum    start_coords; //S0 20 bits*2 (2 frac 5 blk)
        rel_coords_accum    end_coords; //E0-S0 14 bits*2 (2 frac 5 blk)
        rel_rel_coords      start_coords_inc; //S1-S0 9 bits*2 (2 frac)
        rel_rel_coords      end_coords_inc; //(E1-S1)-(E0-S0) 9 bits*2 (2 frac)
    } icbm_coords; //104 bits
    
    typedef struct packed
    {
        abs_coords_out  start_coords;
        rel_coords_out  end_coords;
        rel_rel_coords  start_coords_inc;
        rel_rel_coords  end_coords_inc;
    } coord_blk;
    
    typedef struct packed
    {
        abs_coords_out  start_coords;
        rel_coords_out  end_coords;
    } out_coords;
    
    typedef struct packed
    {
        icbm_coords                     coords; //104 bits
        logic [wr_fr_h_bits:0]          write_row; //11 bits
        logic [7:0]                     blk_wr_col; //8 bits
        logic [wr_fr_b_h_bits:0]        blk_row; //5 bits (32)
        logic                           blk_valid; //1 bit
        logic                           blk_gray; //1 bit
        logic                           blk_last; //1 bit
        logic                           blk_short; //1 bit
    } icbm_data; //132 bits
    
    typedef enum {ST_RESET_WAIT, ST_IDLE, ST_INIT_BLOCKS, ST_WAIT_FRAME, ST_WAIT_READ, ST_CHECK_BLOCK, ST_GET_NEW_BLOCK, ST_WRITE_BLOCK} statetype;
    statetype state;
    
    logic [icbm_addr_w:0]           icbm_addr;
    logic [icbm_addr_w:0]           next_icbm_addr;
    logic [15:0]                    write_col;
    logic [15:0]                    write_row;
    logic                           icbm_wren;
    logic                           blk_valid;
    logic [7:0]                     row_in_blk;
    
    logic       coords_out_gray;
    logic       coords_out_short;
    
    logic [7:0][15:0]   blk_read_in_i;
    logic [7:0]         blk_read_col;
    logic [7:0]         blk_read_row;
    logic [7:0]         blk_read_wr_col;
    logic [7:0]         blk_read_wr_row;
    logic               blk_read_gray, blk_read_last, blk_read_short;
    logic [7:0]         blk_request_col;
    logic [7:0]         blk_request_row;
    logic               blk_request_val_i;
    
    /*logic debug_signal;
    assign debug_signal = blk_read_ready && (blk_read_col == 8'h12);
    logic bad_signal;
    assign bad_signal = icbm_wren && (icbm_wr_data.coords.start_coords.y < icbm_rd_data.coords.start_coords.y);
    logic [15:0] miss_counter;
    logic [15:0] all_counter;*/
    
    assign blk_read_in_i            = blk_read_in[127:0];
    assign blk_read_wr_col          = blk_read_in[135:128];
    assign blk_read_wr_row          = blk_read_in[143:136];
    assign blk_read_gray            = blk_read_in[144];
    assign blk_read_last            = blk_read_in[145];
    assign blk_read_short           = blk_read_in[146];
    assign blk_read_col             = blk_read_in[159:152];
    assign blk_read_row             = blk_read_in[167:160];
    assign blk_request_data[7:0]    = blk_request_col;
    assign blk_request_data[15:8]   = blk_request_row;
    assign blk_request_valid        = (state == ST_INIT_BLOCKS) || blk_request_val_i;
   
    icbm_data                       icbm_rd_data;
    icbm_data                       icbm_wr_data;
    
    icbm icbm_inst(
        .data   (icbm_wr_data),
        .q      (icbm_rd_data),
        .wren   (icbm_wren),
        .clock  (st_clk),
        .address({2'b0, icbm_addr})
    );
    
    icbm_coords                     icbm_rd_coords;
    icbm_coords                     icbm_rd_coords_nxt;
    icbm_coords                     new_coords;
    
    out_coords                      icbm_rd_out;
    out_coords                      new_coords_out;
    out_coords                      coords_out_i;
    
    coord_blk                       blk_read;
    
    assign icbm_rd_coords   = icbm_rd_data.coords;
    assign blk_valid        = icbm_rd_data.blk_valid;
    assign row_in_blk       = icbm_rd_data.write_row[wr_blk_h_log - 1:0];
    
    //assign icbm_wr_data.blk_valid           = icbm_wr_data.blk_valid;
    assign icbm_wren = (state == ST_WRITE_BLOCK) || (state == ST_INIT_BLOCKS);
    
    logic [7:0]                 blks_complete;
    logic                       line_available;
    logic                       end_available;
    logic [11:0]                start_coords_y_int;
    logic [6:0]                 end_coords_y_int;
    logic                       done;
    logic [5:0]                 reset_counter;
    logic [15:0]                buf_row_adj;
    
    always @(posedge st_clk) begin
        if (reset) begin
            state                   <= ST_RESET_WAIT;
            
            blk_request_val_i       <= 0;
            blk_request_row         <= 0;
            
            blk_read_ready          <= 0;
            
            icbm_addr               <= 0;
            coords_out_valid        <= 0;
            write_coords_out_valid  <= 0;
            coords_out_gray         <= 0;
            done                    <= 0;
            reset_counter           <= 0;
            blks_complete           <= 0;
            //miss_counter            <= 0;
            //all_counter             <= 0;
        end else begin
            //if (write_coords_out_valid && ((start_coords_y_int + 16) < buf_writer_row)) miss_counter <= miss_counter + 1;
            //if (write_coords_out_valid) all_counter <= all_counter + 1;
            
            case (state)
                ST_RESET_WAIT: begin
                    reset_counter   <= reset_counter + 1;
                    if (reset_counter == 6'b111111) begin
                        state           <= ST_IDLE;
                    end
                end
                
                ST_IDLE: begin
                    icbm_wr_data.blk_valid  <= 0;
                    icbm_addr               <= 0;
                    blk_request_col         <= 0;
                    blk_request_row         <= 0;
                    state                   <= ST_INIT_BLOCKS;
                end
                
                ST_INIT_BLOCKS: begin
                    if (icbm_addr != (wr_frame_blk_w - 1)) begin
                        icbm_addr           <= icbm_addr + 1;
                        blk_request_col     <= icbm_addr + 1;
                    end else begin
                        state               <= ST_WAIT_FRAME;
                    end
                end
                
                ST_WAIT_FRAME: begin
                    blks_complete   <= 0;
                    if (frame_start) begin
                        done        <= 0;
                        icbm_addr   <= 0;
                        state       <= ST_WAIT_READ;
                    end
                end
                
                ST_WAIT_READ: begin
                    buf_row_adj <= buf_writer_row - 1;
                    state       <= ST_CHECK_BLOCK;
                end
                
                ST_CHECK_BLOCK: begin
                    if (!blk_valid) begin // If this block has been fully read, wait for update
                        state <= ST_GET_NEW_BLOCK;
                    end else begin
                        if (line_available && end_available) begin //if this line can be read
                            if (row_in_blk == (wr_blk_h - 1)) begin //the last line will now be read, so request an update
                                if (icbm_rd_data.blk_last) begin // if this is the last block in this column
                                    blk_request_val_i   <= 0; //don't request a new block
                                    
                                    blks_complete       <= blks_complete + 1;
                                    if (blks_complete == (wr_frame_blk_w - 1)) begin // if all blocks have been completely read, this frame is done
                                        done    <= 1;
                                    end
                                end else begin // if we're not at the bottom, proceed as usual
                                    blk_request_val_i   <= 1; //do request a new block
                                end
                                
                                blk_request_col         <= icbm_addr;
                                blk_request_row         <= icbm_rd_data.blk_row + 1;
                                icbm_wr_data.blk_valid  <= 0;
                            end else begin
                                icbm_wr_data.blk_valid  <= 1;
                            end
                            
                            //Output read coords to the pixel buffer coordinate calculator
                            coords_out_i        <= icbm_rd_out;
                            coords_out_valid    <= 1;
                            coords_out_gray     <= icbm_rd_data.blk_gray;
                            coords_out_short    <= icbm_rd_data.blk_short;
                            
                            //Output write coords to the DDR3 writer
                            write_col               <= icbm_rd_data.blk_wr_col << 3; //mult by 8 for simplicity
                            write_row               <= icbm_rd_data.write_row;
                            write_coords_out_valid  <= 1;
                            
                            //Store updated stuff in the ICBM
                            icbm_wr_data.blk_row    <= icbm_rd_data.blk_row;
                            icbm_wr_data.coords     <= icbm_rd_coords_nxt;
                            icbm_wr_data.blk_gray   <= icbm_rd_data.blk_gray;
                            icbm_wr_data.blk_last   <= icbm_rd_data.blk_last;
                            icbm_wr_data.blk_short  <= icbm_rd_data.blk_short;
                            icbm_wr_data.blk_wr_col <= icbm_rd_data.blk_wr_col;
                            icbm_wr_data.write_row  <= icbm_rd_data.write_row + 1;
                            
                            state               <= ST_WRITE_BLOCK;
                        end else begin
                            icbm_addr           <= next_icbm_addr;
                            
                            state               <= ST_WAIT_READ;
                        end
                    end
                end
                
                ST_GET_NEW_BLOCK: begin
                    if ((blk_read_valid) && (blk_read_col == icbm_addr)) begin //If the new block data is available
                        //Store new stuff in the ICBM
                        icbm_wr_data.blk_valid  <= 1;
                        icbm_wr_data.blk_row    <= blk_read_row;
                        icbm_wr_data.coords     <= new_coords;
                        icbm_wr_data.blk_gray   <= blk_read_gray;
                        icbm_wr_data.blk_last   <= blk_read_last;
                        icbm_wr_data.blk_short  <= blk_read_short;
                        icbm_wr_data.blk_wr_col <= blk_read_wr_col;
                        icbm_wr_data.write_row  <= blk_read_wr_row << wr_blk_w_log;
                        blk_read_ready          <= 1;
                        state                   <= ST_WRITE_BLOCK;
                    end else begin
                        icbm_addr           <= next_icbm_addr;
                        state               <= ST_WAIT_READ;
                    end
                end
                
                ST_WRITE_BLOCK: begin
                    write_coords_out_valid  <= 0;
                    blk_read_ready          <= 0;
                    blk_request_val_i       <= 0;
                    if ((coord_out_ready) || (!coords_out_valid)) begin
                        coords_out_valid    <= 0;
                        if (done) begin
                            state           <= ST_IDLE;
                        end else begin
                            icbm_addr       <= next_icbm_addr;
                            state           <= ST_WAIT_READ;
                        end
                    end
                end
            endcase
        end
    end
    
    always_comb begin
        new_coords_out.start_coords = blk_read.start_coords;
        new_coords_out.end_coords   = blk_read.end_coords;
        
        icbm_rd_out.start_coords.x  = icbm_rd_coords.start_coords.x >>> wr_blk_w_log;
        icbm_rd_out.start_coords.y  = icbm_rd_coords.start_coords.y >>> wr_blk_h_log;
        icbm_rd_out.end_coords.x    = icbm_rd_coords.end_coords.x >>> wr_blk_w_log;
        icbm_rd_out.end_coords.y    = icbm_rd_coords.end_coords.y >>> wr_blk_h_log;
        
        icbm_rd_coords_nxt.start_coords.x = icbm_rd_coords.start_coords.x + icbm_rd_coords.start_coords_inc.x;
        icbm_rd_coords_nxt.start_coords.y = icbm_rd_coords.start_coords.y + icbm_rd_coords.start_coords_inc.y;
        icbm_rd_coords_nxt.start_coords_inc.x = icbm_rd_coords.start_coords_inc.x;
        icbm_rd_coords_nxt.start_coords_inc.y = icbm_rd_coords.start_coords_inc.y;
        icbm_rd_coords_nxt.end_coords.x = icbm_rd_coords.end_coords.x + icbm_rd_coords.end_coords_inc.x;
        icbm_rd_coords_nxt.end_coords.y = icbm_rd_coords.end_coords.y + icbm_rd_coords.end_coords_inc.y;
        icbm_rd_coords_nxt.end_coords_inc.x = icbm_rd_coords.end_coords_inc.x;
        icbm_rd_coords_nxt.end_coords_inc.y = icbm_rd_coords.end_coords_inc.y;
        
        new_coords.start_coords.x = blk_read.start_coords.x << wr_blk_w_log;
        new_coords.start_coords.y = blk_read.start_coords.y << wr_blk_h_log;
        new_coords.start_coords_inc.x = blk_read.start_coords_inc.x;
        new_coords.start_coords_inc.y = blk_read.start_coords_inc.y;
        new_coords.end_coords.x = blk_read.end_coords.x << wr_blk_w_log;
        new_coords.end_coords.y = blk_read.end_coords.y << wr_blk_h_log;
        new_coords.end_coords_inc.x = blk_read.end_coords_inc.x;
        new_coords.end_coords_inc.y = blk_read.end_coords_inc.y;
        
        coords_out[15:0]    = coords_out_i.start_coords.x;
        coords_out[31:16]   = coords_out_i.start_coords.y;
        coords_out[47:32]   = coords_out_i.end_coords.x;
        coords_out[63:48]   = coords_out_i.end_coords.y;
        coords_out[64]      = coords_out_short;
        coords_out[65]      = coords_out_gray;
        
        write_coords_out[15:0]  = write_col;
        write_coords_out[31:16] = write_row;
        write_coords_out[32]    = coords_out_short;
        write_coords_out[33]    = coords_out_gray;
        write_coords_out[34]    = done; // indicates EOF for ddr3 writer
        
        write_coords_out_2[15:0]    = write_col;
        write_coords_out_2[31:16]   = write_row;
        write_coords_out_2[32]      = coords_out_short;
        write_coords_out_2[33]      = done; // indicates EOF for ddr3 writer
        write_coords_out_valid_2    = write_coords_out_valid;
        
        blk_read.start_coords.x     = blk_read_in_i[0];
        blk_read.start_coords.y     = blk_read_in_i[1];
        blk_read.end_coords.x       = blk_read_in_i[2];
        blk_read.end_coords.y       = blk_read_in_i[3];
        blk_read.start_coords_inc.x = blk_read_in_i[4];
        blk_read.start_coords_inc.y = blk_read_in_i[5];
        blk_read.end_coords_inc.x   = blk_read_in_i[6];
        blk_read.end_coords_inc.y   = blk_read_in_i[7];
        
        start_coords_y_int  = icbm_rd_coords.start_coords.y[11 + coord_frac_bits + wr_blk_h_log:coord_frac_bits + wr_blk_h_log];
        end_coords_y_int    = icbm_rd_coords.end_coords.y[6 + coord_frac_bits + wr_blk_h_log:coord_frac_bits + wr_blk_h_log];
        line_available  =  ( start_coords_y_int < buf_row_adj );
        end_available   = (end_coords_y_int[6]) || ( ( start_coords_y_int + end_coords_y_int ) < buf_row_adj );
        
        next_icbm_addr = (icbm_addr == (wr_frame_blk_w - 1)) ? 0 : icbm_addr + 1;
    end
endmodule