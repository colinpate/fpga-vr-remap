module rect_buffer_module
    (
        input           clk,
        
        input  [59:0]   read_address,
        output [63:0]   read_readdata,
        
        input  [59:0]   write_address,
        input  [63:0]   write_writedata,
        input  [3:0]    write_write
    );
    
    logic [3:0][13:0] write_address_i;
    logic [3:0][13:0] read_address_i;
    
    assign write_address_i[0] = write_address[14:0];
    assign write_address_i[1] = write_address[29:15];
    assign write_address_i[2] = write_address[44:30];
    assign write_address_i[3] = write_address[59:45];
    
    assign read_address_i[0] = read_address[14:0];
    assign read_address_i[1] = read_address[29:15];
    assign read_address_i[2] = read_address[44:30];
    assign read_address_i[3] = read_address[59:45];
    
    remap_buffer	remap_buffer_inst[3:0] (
        .clock ( clk ),
        .data ( write_writedata ),
        .rdaddress ( read_address_i ),
        .wraddress ( write_address_i ),
        .wren ( write_write ),
        .q ( read_readdata )
	);
endmodule