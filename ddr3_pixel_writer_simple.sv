//`define SIM

module ddr3_pixel_writer_simple
    #(parameter in_width = 8,
    parameter burst_len = 8,
    parameter burst_log = $clog2(burst_len)
    )
    (
    input                   pclk,
    input [in_width-1:0]    pixel,
    input                   hs,
    input                   vs,
    input                   reset,
	
    input                       ddr3_clk,
    output logic [26:0]         ddr3_write_address,
    output logic [255:0]        ddr3_write_data,
    output logic                ddr3_write,
    input                       ddr3_waitrequest,
    output logic [burst_log:0]  ddr3_burstcount,
	
    output logic            fifo_full_latch,
    output logic [8:0]      fifo_level
    );
    
    parameter pixels_per_write = 256 / in_width;
    parameter pix_per_wr_log = $clog2(pixels_per_write);
    assign ddr3_burstcount = burst_len;
    
    const logic [31:0] start_address_i  = 32'h36000000;
    const logic [31:0] frame_end_i      = 32'h3634E000;
    
    typedef enum {ST_IDLE, ST_WAIT_FIFO, ST_FIRST_READ, ST_WAIT_WRITE} statetype;
    statetype state;
    
    typedef enum {ST_WAIT_WRITER, ST_WAIT_SOF, ST_WRITE_BUF} buf_statetype;
    buf_statetype buf_state;
    
    logic [255:0]                    pixel_sreg;
    logic [pix_per_wr_log - 1:0]     pixel_index;
    
    logic           fifo_write;
    logic           fifo_read;
    logic           fifo_read_ena;
    logic           fifo_empty;
    logic           fifo_wrfull;
    logic           fifo_rdfull;
    logic [255:0]   fifo_data;
    logic           fifo_aclr;
    logic           sof_flop, sof_flop_old;
    logic           wait_sof, wait_sof_flop;
    logic           got_sof, got_sof_flop;
    logic [26:0]    this_frame_end;
    
    logic [burst_log - 1:0] burst_index;
    
    ddr3_writer_fifo ddr3_write_fifo_inst(
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
    
    assign ddr3_write_data = fifo_data;
    assign fifo_read    = ((state == ST_FIRST_READ) || ((fifo_read_ena) && (ddr3_write) && (!ddr3_waitrequest)));
    assign ddr3_write   = (state == ST_WAIT_WRITE);
    
    always @(posedge pclk)
    begin
        if (reset) begin
            pixel_index     <= 0;
            fifo_write      <= 0;
            sof_flop_old    <= 1;
            got_sof         <= 0;
            fifo_full_latch <= 0;
            wait_sof_flop   <= 0;
            buf_state       <= ST_WAIT_WRITER;
            fifo_aclr       <= 1;
        end else begin
            wait_sof_flop   <= wait_sof;
            sof_flop_old    <= sof_flop;
            sof_flop        <= vs;
            
            if (fifo_wrfull) fifo_full_latch <= 1;
            
            case (buf_state)
                ST_WAIT_WRITER: begin
                    if (wait_sof_flop) begin //writer is done
                        buf_state   <= ST_WAIT_SOF;
                        fifo_aclr   <= 1;
                    end
                end
                
                ST_WAIT_SOF: begin
                    if ({sof_flop, sof_flop_old} == 2'b10)  begin
                        fifo_aclr   <= 0;
                        got_sof     <= 1;
                        buf_state   <= ST_WRITE_BUF;
                    end
                end
                
                ST_WRITE_BUF: begin
                    if (vs) begin
                        if (hs) begin
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
                    end else begin
                        got_sof     <= 0;
                        buf_state   <= ST_WAIT_WRITER;
                    end
                end
            endcase
        end
    end
    
    always @(posedge ddr3_clk)
    begin
        if (reset) begin
            state               <= ST_IDLE;
            wait_sof            <= 0;
            got_sof_flop        <= 0;
            ddr3_write_address  <= 0;
        end else begin
            got_sof_flop <= got_sof;
            
            case (state)
                ST_IDLE: begin
                    if (got_sof_flop) begin
                        state           <= ST_WAIT_FIFO;
                        
                        ddr3_write_address  <= start_address_i[31:5];
                        this_frame_end      <= frame_end_i[31:5] - burst_len;
                        
                        burst_index     <= 0;
                        fifo_read_ena   <= 0;
                        
                        wait_sof        <= 0;
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
                    if (!ddr3_waitrequest) begin
                        if (burst_index == (burst_len - 1)) begin
                            if ((ddr3_write_address >= this_frame_end) || (!got_sof_flop)) begin
                                state               <= ST_IDLE;
                            end else begin
                                state               <= ST_WAIT_FIFO;
                                ddr3_write_address  <= ddr3_write_address + burst_len;
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