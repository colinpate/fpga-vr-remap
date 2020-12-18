//`define SIM

module ddr3_reader_grayout
    #(parameter in_width = 8,
    parameter frame_width = 480,
    parameter frame_lines = 720,
    parameter burst_per_line = 2,
    parameter frame_real_width = 720,
    parameter burst_len = frame_width / (32 * burst_per_line), // half a line
    parameter burst_log = $clog2(burst_len),
    parameter test_pattern = 0,
    parameter no_input = 0
    )
    (
        input                   pclk,
        input                   pclk_reset,
        
        output logic [7:0]      pixel_data,
        output                  pixel_valid,
        output logic            pixel_outclk,
        
        input                   ddr3clk,
        input                   ddr3clk_reset,
        
        output logic [26:0]     ddr3_address,
        input [255:0]           ddr3_readdata,
        output logic            ddr3_read,
        input                   ddr3_waitrequest,
        input                   ddr3_readdatavalid,
        output logic [4:0]      ddr3_burstcount,
        
        input                   wait_for_remap,
        
        input [26:0]            start_0,
        input [1:0]             pointer_0_data,
        input                   pointer_0_valid,
        input [26:0]            start_1,
        input [1:0]             pointer_1_data,
        input                   pointer_1_valid,
        input [26:0]            start_2,
        input [1:0]             pointer_2_data,
        input                   pointer_2_valid,
        input [26:0]            start_3,
        input [1:0]             pointer_3_data,
        input                   pointer_3_valid
    );
    
    parameter pixels_per_rd = 256 / in_width;
    parameter pix_rd_log = $clog2(pixels_per_rd);
    parameter reads_per_frame = frame_lines * 4 * (frame_width / 32); // 32 pixels per read, 4 frames per frame
    assign ddr3_burstcount = burst_len;
    
    typedef enum {ST_CLEAR_FIFO, ST_IDLE, ST_WAIT_FIFO, ST_READ} statetype;
    statetype state;
    
    typedef enum {OST_IDLE, OST_SEND_HEADER, OST_WAIT_FIFO, OST_WAIT_READ, OST_SEND_FRAME} statetype_out;
    statetype_out out_state;
    
    logic [255:0]   fifo_q;
    logic           fifo_rdempty;
    logic           fifo_rd;
    logic [7:0]     fifo_wrlevel;
    logic           fifo_aclr;
    logic           fifo_wrfull;
    logic           fifo_almost_full;
    logic           fifo_wrempty;
    logic [7:0]     frame_number;
    logic           write_header;
    
    logic [31:0]    ddr3addr_in;
    logic [8:0]    fifo_cnt;
    
    ddr3reader_dcfifo ddr3reader_dcfifo_inst( //256-bit, at least 256-word, dual clock FIFO, show ahead
        .wrclk          (ddr3clk),
        .rdclk          (pclk),
        .aclr           (fifo_aclr),
        .wrreq          (ddr3_readdatavalid || write_header),
        .rdreq          (fifo_rd),
        .wrusedw        (fifo_wrlevel),
        .rdempty        (fifo_rdempty),
        //.data           ({ddr3_readdata[255:72], fifo_wrlevel, line_number, fifo_cnt, ddr3addr_in}),
        .data           (write_header ? {8'h71, 8'h8E, 8'hE8, 8'h17, 224'd0} : ddr3_readdata),
        //.data           (write_header ? {64'hFFFF, 8'h71, 8'h8E, 8'hE8, 8'h17, 160'd0} : ddr3_readdata),
        .q              (fifo_q),
        .wrfull         (fifo_wrfull),
        .wrempty        (fifo_wrempty)
        );
    
    logic [15:0]    send_count;
    logic [255:0]   fifo_pixout;
    
    assign fifo_pixout = fifo_q[255:0];
    
    logic [255:0]               pix_sreg;
    logic [pix_rd_log - 1:0]    pix_index;
    logic                       fifo_rdv;
    logic [3:0]                 header_counter;
    logic [4:0][7:0]            header_sreg;
    logic [9:0]                 pix_x;
    logic [7:0]                 output_val;
    
    assign output_val = pix_sreg[7:0]; // (pix_x < frame_real_width) ? pix_sreg[7:0] : pix_x[7:0];
    assign pixel_data = output_val; // (out_state == OST_SEND_FRAME) ? (test_pattern ? pix_x[7:0] : output_val ) : header_sreg[0];
    assign pixel_valid = (out_state == OST_SEND_FRAME) || (out_state == OST_SEND_HEADER);
    
    always @(posedge pclk)
    begin
        if (pclk_reset) begin
            //fifo_aclr           <= 1;
            fifo_rd             <= 0;
            out_state           <= OST_IDLE;
            pixel_outclk        <= 0;
            frame_number        <= 0;
            pix_x               <= 0;
            header_sreg         <= 0;
            pix_sreg            <= 0;
            pix_index           <= 0;
        end else begin
            //fifo_aclr           <= 0;
            fifo_rdv            <= fifo_rd && (!fifo_rdempty);
            pixel_outclk        <= !pixel_outclk;
            fifo_rd             <= 0;
            
            case (out_state)
                OST_IDLE: begin
                    //if (!fifo_rdempty) begin
                        //out_state           <= OST_SEND_HEADER;
                        out_state           <= OST_WAIT_FIFO;
                        header_counter      <= 0;
                        //header_sreg         <= {frame_number, 8'h71, 8'h8E, 8'hE8, 8'h17};
                        frame_number        <= frame_number + 1;
                        send_count          <= 0;
                        pix_x               <= 0;
                    //end
                end
                
                /*OST_SEND_HEADER: begin
                    if (header_counter == 4) begin
                        //out_state   <= OST_WAIT_READ;
                        //fifo_rd     <= 1;
                        out_state   <= OST_WAIT_FIFO;
                    end
                    header_counter  <= header_counter + 1;
                    header_sreg     <= {8'h00, header_sreg[4:1]};
                end*/
                
                OST_WAIT_FIFO: begin
                    if (!fifo_rdempty) begin
                        //out_state   <= OST_WAIT_READ;
                        out_state       <= OST_SEND_FRAME;
                        fifo_rd         <= 1; // Ack the FIFO because it's a show-ahead
                        pix_index       <= 0;
                        pix_sreg        <= fifo_pixout;
                    end
                end
                
                /*OST_WAIT_READ: begin
                    fifo_rd <= 0;
                    if (fifo_rdv) begin
                        out_state   <= OST_SEND_FRAME;
                        pix_index   <= 0;
                        pix_sreg    <= fifo_pixout;
                    end
                end*/
                
                OST_SEND_FRAME: begin
                    fifo_rd     <= 0;
                    if (pix_index == (pixels_per_rd - 1)) begin
                        pix_index   <= 0;
                        if (send_count == (reads_per_frame - 1)) begin
                            out_state   <= OST_IDLE;
                        end else begin
                            send_count  <= send_count + 1;
                            if (fifo_rdempty) begin
                                out_state   <= OST_WAIT_FIFO;
                            end else begin
                                pix_sreg        <= fifo_pixout;
                                fifo_rd         <= 1;
                            end
                        end
                    end else begin
                        pix_index   <= pix_index + 1;
                        pix_sreg    <= pix_sreg[255:in_width];
                    end
                    
                    if (pix_x == (frame_width - 1)) begin
                        pix_x <= 0;
                    end else begin
                        pix_x <= pix_x + 1;
                    end
                end
            endcase
        end
    end
    
    logic [3:0]         ptrfifo_rdempty;
    logic               ptrfifo_rd;
    logic [3:0][1:0]    ptrfifo_q;
    
    gray_ptr_fifo gray_ptr_fifo_inst[3:0]( //2-bit, 4-word, single clock, show-ahead FIFO
        .clock          (ddr3clk),
        .sclr           (ddr3clk_reset),
        .wrreq          ({pointer_3_valid, pointer_2_valid, pointer_1_valid, pointer_0_valid}),
        .rdreq          (ptrfifo_rd),
        .empty          (ptrfifo_rdempty),
        .data           ({pointer_3_data, pointer_2_data, pointer_1_data, pointer_0_data}),
        .q              (ptrfifo_q)
        );
    
    logic [3:0][26:0]   start_addresses;
    logic [3:0][26:0]   rd_addresses;
    
    assign start_addresses[0] = start_0;// + (ptrfifo_q[0] << 14);
    assign start_addresses[1] = start_1;// + (ptrfifo_q[1] << 14);
    assign start_addresses[2] = start_2;// + (ptrfifo_q[2] << 14);
    assign start_addresses[3] = start_3;// + (ptrfifo_q[3] << 14);
    
    logic [1:0]     cam_index;
    logic [15:0]    line_number;
    logic [7:0]                 clear_fifo_count;
    
    assign ddr3_read = (state == ST_READ);
    
    always @(posedge ddr3clk)
    begin
        if (ddr3clk_reset) begin
            state               <= ST_CLEAR_FIFO;
            ptrfifo_rd          <= 0;
            ddr3addr_in         <= 0;
            fifo_cnt            <= 0;
            write_header        <= 0;
            fifo_aclr           <= 1;
            clear_fifo_count    <= 0;
        end else begin
            fifo_aclr   <= 0;
            if (ddr3_read && (!ddr3_waitrequest)) begin
                if (ddr3_readdatavalid) begin
                    fifo_cnt  <= fifo_cnt + burst_len - 1;
                end else begin
                    fifo_cnt  <= fifo_cnt + burst_len;
                end
            end else begin
                if (ddr3_readdatavalid) begin
                    if (fifo_cnt != 0) begin
                        fifo_cnt    <= fifo_cnt - 1;
                    end
                end
            end
            write_header    <= 0;
            case (state)
                ST_CLEAR_FIFO: begin
                    if (clear_fifo_count == 8'h30) begin
                        state   <= ST_IDLE;
                    end else begin
                        clear_fifo_count    <= clear_fifo_count + 1;
                    end
                end
                
                ST_IDLE: begin
                    if ((((!(|ptrfifo_rdempty)) && (!wait_for_remap)) || no_input) && (fifo_cnt == 0) && (fifo_wrempty)) begin
                        state           <= ST_WAIT_FIFO;
                        rd_addresses    <= start_addresses;
                        cam_index       <= 0;
                        line_number     <= 0;
                        ptrfifo_rd      <= 1;
                        write_header    <= 1;
                    end
                end
                
                ST_WAIT_FIFO: begin
                    ptrfifo_rd  <= 0;
                    if (fifo_wrlevel < burst_len) begin
                        state                   <= ST_READ;
                        ddr3_address            <= rd_addresses[0];
                        rd_addresses[0]         <= rd_addresses[0] + burst_len;
                    end
                end
                
                ST_READ: begin
                    if (!ddr3_waitrequest) begin
                        ddr3addr_in <= ddr3_address << 5;
                        if (line_number == ((frame_lines * burst_per_line) - 1)) begin
                            if (cam_index == 3) begin
                                state   <= ST_IDLE;
                            end else begin
                                state                   <= ST_WAIT_FIFO;
                                
                                cam_index               <= cam_index + 1;
                                line_number             <= 0;
                                rd_addresses[2:0]       <= rd_addresses[3:1];
                            end
                        end else begin
                            state       <= ST_WAIT_FIFO;
                            
                            line_number <= line_number + 1;
                        end
                    end
                end
            endcase
        end
    end
endmodule