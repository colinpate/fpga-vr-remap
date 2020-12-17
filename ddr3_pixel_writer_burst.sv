//`define SIM

module ddr3_pixel_writer_burst
    #(parameter in_width = 32,
    parameter burst_len = 8
    )
    (
    input                   pclk,
    input [in_width-1:0]    pixel,
    input                   pixel_valid,
    input                   sof,
    input                   reset,
    input                   ddr3clk,
    output logic [26:0]     write_address,
    output logic [255:0]    write_data,
    output logic            write,
    input                   waitrequest,
    output logic            addr_error,
    output logic            fifo_full_latch,
    output logic [8:0]      fifo_level
    );
    
    parameter pixels_per_write = 256 / in_width;
    parameter pix_per_wr_log = $clog2(pixels_per_write);
    parameter burst_log = $clog2(burst_len);
    
    //const logic [3:0][31:0] start_address = {32'h36000000, 32'h34000000, 32'h32000000, 32'h30000000};
    const logic [3:0][31:0] frame_end = {start_address[3] + 32'h01F95000, start_address[2] + 32'h01F95000, start_address[1] + 32'h01F95000, start_address[0] + 32'h01F95000};
    
    logic [3:0][26:0] start_address_i;
    logic [3:0][26:0] frame_end_i;
    
    typedef enum {ST_IDLE, ST_WAIT_FIFO, ST_FIRST_READ, ST_WAIT_WRITE} statetype;
    statetype state;
    
    logic [255:0]                    pixel_sreg;
    logic [pix_per_wr_log - 1:0]     pixel_index;
    
    logic           fifo_write;
    logic           fifo_read;
    logic           fifo_read_ena;
    logic           fifo_empty;
    logic           fifo_wrfull;
    logic           fifo_rdfull;
    logic [255:0]   fifo_data;
    logic           sof_flop, sof_old;
    logic           wait_sof, wait_sof_flop;
    logic           got_sof, got_sof_flop;
    logic [26:0]    this_frame_end;
    
    logic [burst_log - 1:0] burst_index;
    
    ddr3_writer_fifo ddr3_write_fifo_inst(
        .aclr       ( wait_sof ),
        .data       ( pixel_sreg ),
        .rdclk      ( ddr3clk ),
        .rdreq      ( fifo_read ),
        .wrclk      ( pclk ),
        .wrreq      ( fifo_write ),
        .q          ( fifo_data ),
        .rdempty    ( fifo_empty ),
        .rdusedw    ( fifo_level ),
        .wrfull     ( fifo_wrfull ),
        .rdfull     ( fifo_rdfull )
    );
    
    assign write_data = fifo_data;
    assign fifo_read    = ((state == ST_FIRST_READ) || ((fifo_read_ena) && (write) && (!waitrequest)));
    assign write        = (state == ST_WAIT_WRITE);
    
    always @(posedge pclk)
    begin
        if (reset) begin
            pixel_index     <= 0;
            fifo_write      <= 0;
            sof_old         <= 1;
            got_sof         <= 0;
            fifo_full_latch <= 0;
            wait_sof_flop   <= 1;
        end else begin
            wait_sof_flop   <= wait_sof;
        
            if (fifo_wrfull) fifo_full_latch <= 1;
        
            if (wait_sof_flop) begin // synchronizing to slower clock
                if ({sof_flop, sof_old} == 2'b10)  begin
                    got_sof <= 1;
                end
            end else begin
                got_sof <= 0;
            end
            
            sof_old     <= sof_flop;
            sof_flop    <= sof;
            
            if (pixel_valid && !wait_sof_flop) begin
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
    
    always @(posedge ddr3clk)
    begin
        if (reset) begin
            state               <= ST_IDLE;
            wait_sof            <= 1;
            got_sof_flop        <= 0;
            write_address       <= 0;
            addr_error          <= 0;
            
            start_address_i     <= {start_address[3][31:5], start_address[2][31:5], start_address[1][31:5], start_address[0][31:5]};
            frame_end_i         <= {frame_end[3][31:5], frame_end[2][31:5], frame_end[1][31:5], frame_end[0][31:5]};
        end else begin
            got_sof_flop <= got_sof;
            
            case (state)
                ST_IDLE: begin
                    if (got_sof_flop) begin
                        state         <= ST_WAIT_FIFO;
                        
                        write_address   <= start_address_i[0];
                        this_frame_end  <= frame_end_i[0] - burst_len;
                        
                        burst_index     <= 0;
                        fifo_read_ena   <= 0;
                        
                        start_address_i <= {start_address_i[2:0], start_address_i[3]};
                        frame_end_i     <= {frame_end_i[2:0], frame_end_i[3]};
                        
                        wait_sof      <= 0;
                    end else begin
                        wait_sof  <= 1;
                    end
                end
                
                ST_WAIT_FIFO: begin
                    if ((fifo_level > (burst_len - 1)) || (fifo_rdfull)) begin
                        state   <= ST_FIRST_READ;
                    end
                end
                
                ST_FIRST_READ: begin
                    state           <= ST_WAIT_WRITE;
                    fifo_read_ena   <= 1;
                end
                
                ST_WAIT_WRITE: begin
                    if (!waitrequest) begin
                        if (burst_index == (burst_len - 1)) begin
                            if ((write_address >= this_frame_end) || (addr_error)) begin
                                state           <= ST_IDLE;
                                addr_error      <= 0;
                            end else begin
                                state           <= ST_WAIT_FIFO;
                                write_address   <= write_address + burst_len;
                            end
                        end else begin
                            if (burst_index == (burst_len - 2)) begin
                                fifo_read_ena   <= 0;
                            end
                        end
                        burst_index     <= burst_index + 1;
                    end
                end
            endcase
        end
    end
endmodule