module rect_buffer_coord_calc_v2
    #(
    parameter wr_blk_w = 32,
    parameter wr_blk_h = 32,
    parameter coord_frac_bits = 2
    )
    (
        input                           reset,
        
        input logic                     st_clk,
        
        input logic                     coords_in_valid,
        input logic       [65:0]        coords_in,
        output logic                    coords_in_ready,
        
        output logic        [32:0]      coords_out,
        output logic                    coords_out_valid,
        
        input logic                     writer_fifo_almost_full
    );
    
    parameter wr_blk_w_log      = $clog2(wr_blk_w);
    parameter wr_blk_h_log      = $clog2(wr_blk_h);
    typedef struct packed // 12 int
    {
        logic signed [12 + coord_frac_bits + wr_blk_w_log:0] x;
        logic signed [12 + coord_frac_bits + wr_blk_h_log:0] y;
    } abs_coords_accum;
    
    typedef struct packed // 12 int
    {
        logic [12 + coord_frac_bits - 1:0] x;
        logic [12 + coord_frac_bits - 1:0] y;
    } abs_coords_in;
    
    typedef struct packed // 1 sign 6 int
    {
        logic signed [7 + coord_frac_bits - 1:0] x;
        logic signed [7 + coord_frac_bits - 1:0] y;
    } rel_coords_in;
    
    typedef struct packed
    {
        abs_coords_in  start_coords;
        rel_coords_in  end_coords;
    } in_coords;
    
    logic               coords_in_gray;
    logic               coords_in_short;
    logic               coords_out_gray;
    logic               coords_out_short;
    in_coords           coords_in_i;
    abs_coords_accum    coords_out_i;
    rel_coords_in       rel_coords_i;
    rel_coords_in       rel_coords_short_in;
    
    logic [wr_blk_w_log - 1:0]  column;
    logic [wr_blk_w_log - 1:0]  column_end;
    
    typedef enum {ST_IDLE, ST_OUTPUT_COORDS} statetype;
    statetype state;
    
    always @(posedge st_clk) begin
        if (reset) begin
            state               <= ST_IDLE;
            coords_out_valid    <= 0;
            coords_in_ready     <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (coords_in_valid && (!writer_fifo_almost_full)) begin
                        column              <= 0;
                        coords_out_valid    <= 1;
                        coords_out_i.x      <= coords_in_i.start_coords.x << wr_blk_w_log;
                        coords_out_i.y      <= coords_in_i.start_coords.y << wr_blk_w_log;
                        coords_out_gray     <= coords_in_gray;
                        coords_out_short    <= coords_in_short;
                        rel_coords_i        <= coords_in_short ? rel_coords_short_in : coords_in_i.end_coords;
                        
                        coords_in_ready     <= 1;
                        state               <= ST_OUTPUT_COORDS;
                    end
                end
                        
                ST_OUTPUT_COORDS: begin
                    coords_in_ready <= 0;
                    
                    if (column == column_end)  begin
                        coords_out_valid    <= 0;
                        state               <= ST_IDLE;
                    end else begin
                        coords_out_valid    <= 1;
                        column              <= column + 1;
                        coords_out_i.x      <= coords_out_i.x + rel_coords_i.x;
                        coords_out_i.y      <= coords_out_i.y + rel_coords_i.y;
                    end
                end
            endcase
        end
    end
    
    always_comb begin
        column_end          = coords_out_short ? ((wr_blk_w / 2) - 1) : (wr_blk_w - 1);
    
        coords_out[15:0]    = coords_out_i.x >> wr_blk_w_log;
        coords_out[31:16]   = coords_out_i.y >> wr_blk_w_log;
        coords_out[32]      = coords_out_gray;
        
        coords_in_i.start_coords.x  = coords_in[15:0];
        coords_in_i.start_coords.y  = coords_in[31:16];
        coords_in_i.end_coords.x    = coords_in[47:32];
        coords_in_i.end_coords.y    = coords_in[63:48];
        
        rel_coords_short_in.x       = coords_in_i.end_coords.x <<< 1;
        rel_coords_short_in.y       = coords_in_i.end_coords.y <<< 1;
        
        coords_in_short             = coords_in[64];
        coords_in_gray              = coords_in[65];
    end
endmodule