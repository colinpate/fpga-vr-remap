module coord_blk_reader
    //#(
    //parameter [31:0] base_address = 32'h21000000
    //)
    (
        input                   pclk,
        input                   reset,
        
        input [15:0]            blk_request_data,
        input                   blk_request_data_valid,
        
        input                   ddr3_clk,
        output logic [26:0]     ddr3_address,
        input [255:0]           ddr3_readdata,
        output logic            ddr3_read,
        input                   ddr3_waitrequest,
        input                   ddr3_readdatavalid,
        
        output logic [167:0]    blk_out_data,
        output logic            blk_out_valid,
        input                   blk_out_ready,
        
        input [31:0]            base_address
    );
    
    logic [15:0]    fifo_q;
    logic           fifo_read;
    logic           fifo_empty;
    logic [5:0]     x_read_coord;
    logic [5:0]     y_read_coord;
    logic [7:0]     x_out;
    logic [7:0]     y_out;
    assign x_read_coord = fifo_q[5:0];
    assign y_read_coord = fifo_q[13:8];
    assign ddr3_address = base_address[31:5] + (y_read_coord << 6) + x_read_coord;
    
    blk_request_fifo blk_request_fifo_inst(
        .aclr       ( reset ),
        .data       ( blk_request_data ),
        .wrreq      ( blk_request_data_valid ),
        .rdclk      ( ddr3_clk ),
        .rdreq      ( fifo_read ),
        .rdempty    ( fifo_empty ),
        .wrclk      ( pclk ),
        .q          ( fifo_q )
    );
    
    typedef enum {ST_IDLE, ST_READ_FIFO, ST_READ_MEMORY, ST_WAIT_MEMORY, ST_WAIT_OUT} statetype;
    statetype state;
    
    assign fifo_read        = (state == ST_READ_FIFO);
    assign ddr3_read        = (state == ST_READ_MEMORY);
    assign blk_out_valid    = (state == ST_WAIT_OUT);
    
    always @(posedge ddr3_clk)
    begin
        if (reset) begin
            state       <= ST_IDLE;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (!fifo_empty) begin
                        state   <= ST_READ_FIFO;
                    end
                end
                
                ST_READ_FIFO: begin
                    state           <= ST_READ_MEMORY;
                end
                
                ST_READ_MEMORY: begin
                    x_out           <= x_read_coord;
                    y_out           <= y_read_coord;
                    if (!ddr3_waitrequest) begin
                        state   <= ST_WAIT_MEMORY;
                    end
                end
                
                ST_WAIT_MEMORY: begin
                    if (ddr3_readdatavalid) begin
                        blk_out_data    <= {y_out, x_out, ddr3_readdata[151:0]};
                        state           <= ST_WAIT_OUT;
                    end
                end
                
                ST_WAIT_OUT: begin
                    if (blk_out_ready) begin
                        if (!fifo_empty) begin
                            state   <= ST_READ_FIFO;
                        end else begin
                            state   <= ST_IDLE;
                        end
                    end
                end
            endcase
        end
    end
endmodule