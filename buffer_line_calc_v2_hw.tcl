# TCL File Generated by Component Editor 18.1
# Sat May 25 17:01:29 PDT 2019
# DO NOT MODIFY


# 
# buffer_line_calc_v2 "buffer_line_calc_v2" v1.0
#  2019.05.25.17:01:29
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module buffer_line_calc_v2
# 
set_module_property DESCRIPTION ""
set_module_property NAME buffer_line_calc_v2
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME buffer_line_calc_v2
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL buffer_line_calc
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file buffer_line_calc_v2.sv SYSTEM_VERILOG PATH remap_v2/buffer_line_calc_v2.sv TOP_LEVEL_FILE
add_fileset_file icbm.v VERILOG PATH remap_v2/icbm.v

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL buffer_line_calc
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE true
add_fileset_file buffer_line_calc_v2.sv SYSTEM_VERILOG PATH remap_v2/buffer_line_calc_v2.sv
add_fileset_file icbm.v VERILOG PATH remap_v2/icbm.v


# 
# parameters
# 
add_parameter wr_blk_w INTEGER 32
set_parameter_property wr_blk_w DEFAULT_VALUE 32
set_parameter_property wr_blk_w DISPLAY_NAME wr_blk_w
set_parameter_property wr_blk_w TYPE INTEGER
set_parameter_property wr_blk_w UNITS None
set_parameter_property wr_blk_w ALLOWED_RANGES -2147483648:2147483647
set_parameter_property wr_blk_w HDL_PARAMETER true
add_parameter wr_blk_h INTEGER 32
set_parameter_property wr_blk_h DEFAULT_VALUE 32
set_parameter_property wr_blk_h DISPLAY_NAME wr_blk_h
set_parameter_property wr_blk_h TYPE INTEGER
set_parameter_property wr_blk_h UNITS None
set_parameter_property wr_blk_h ALLOWED_RANGES -2147483648:2147483647
set_parameter_property wr_blk_h HDL_PARAMETER true
add_parameter wr_frame_w INTEGER 736
set_parameter_property wr_frame_w DEFAULT_VALUE 736
set_parameter_property wr_frame_w DISPLAY_NAME wr_frame_w
set_parameter_property wr_frame_w TYPE INTEGER
set_parameter_property wr_frame_w UNITS None
set_parameter_property wr_frame_w ALLOWED_RANGES -2147483648:2147483647
set_parameter_property wr_frame_w HDL_PARAMETER true
add_parameter wr_frame_h INTEGER 1920
set_parameter_property wr_frame_h DEFAULT_VALUE 1920
set_parameter_property wr_frame_h DISPLAY_NAME wr_frame_h
set_parameter_property wr_frame_h TYPE INTEGER
set_parameter_property wr_frame_h UNITS None
set_parameter_property wr_frame_h ALLOWED_RANGES -2147483648:2147483647
set_parameter_property wr_frame_h HDL_PARAMETER true
add_parameter coord_frac_bits INTEGER 2
set_parameter_property coord_frac_bits DEFAULT_VALUE 2
set_parameter_property coord_frac_bits DISPLAY_NAME coord_frac_bits
set_parameter_property coord_frac_bits TYPE INTEGER
set_parameter_property coord_frac_bits ENABLED false
set_parameter_property coord_frac_bits UNITS None
set_parameter_property coord_frac_bits ALLOWED_RANGES -2147483648:2147483647
set_parameter_property coord_frac_bits HDL_PARAMETER true


# 
# display items
# 


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock ""
set_interface_property reset synchronousEdges NONE
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset reset Input 1


# 
# connection point clock_sink
# 
add_interface clock_sink clock end
set_interface_property clock_sink clockRate 0
set_interface_property clock_sink ENABLED true
set_interface_property clock_sink EXPORT_OF ""
set_interface_property clock_sink PORT_NAME_MAP ""
set_interface_property clock_sink CMSIS_SVD_VARIABLES ""
set_interface_property clock_sink SVD_ADDRESS_GROUP ""

add_interface_port clock_sink st_clk clk Input 1


# 
# connection point blk_read_sink
# 
add_interface blk_read_sink avalon_streaming end
set_interface_property blk_read_sink associatedClock clock_sink
set_interface_property blk_read_sink associatedReset reset
set_interface_property blk_read_sink dataBitsPerSymbol 168
set_interface_property blk_read_sink errorDescriptor ""
set_interface_property blk_read_sink firstSymbolInHighOrderBits true
set_interface_property blk_read_sink maxChannel 0
set_interface_property blk_read_sink readyLatency 0
set_interface_property blk_read_sink ENABLED true
set_interface_property blk_read_sink EXPORT_OF ""
set_interface_property blk_read_sink PORT_NAME_MAP ""
set_interface_property blk_read_sink CMSIS_SVD_VARIABLES ""
set_interface_property blk_read_sink SVD_ADDRESS_GROUP ""

add_interface_port blk_read_sink blk_read_in data Input 168
add_interface_port blk_read_sink blk_read_ready ready Output 1
add_interface_port blk_read_sink blk_read_valid valid Input 1


# 
# connection point blk_request_source
# 
add_interface blk_request_source avalon_streaming start
set_interface_property blk_request_source associatedClock clock_sink
set_interface_property blk_request_source associatedReset reset
set_interface_property blk_request_source dataBitsPerSymbol 16
set_interface_property blk_request_source errorDescriptor ""
set_interface_property blk_request_source firstSymbolInHighOrderBits true
set_interface_property blk_request_source maxChannel 0
set_interface_property blk_request_source readyLatency 0
set_interface_property blk_request_source ENABLED true
set_interface_property blk_request_source EXPORT_OF ""
set_interface_property blk_request_source PORT_NAME_MAP ""
set_interface_property blk_request_source CMSIS_SVD_VARIABLES ""
set_interface_property blk_request_source SVD_ADDRESS_GROUP ""

add_interface_port blk_request_source blk_request_data data Output 16
add_interface_port blk_request_source blk_request_valid valid Output 1


# 
# connection point read_coord_source
# 
add_interface read_coord_source avalon_streaming start
set_interface_property read_coord_source associatedClock clock_sink
set_interface_property read_coord_source associatedReset reset
set_interface_property read_coord_source dataBitsPerSymbol 66
set_interface_property read_coord_source errorDescriptor ""
set_interface_property read_coord_source firstSymbolInHighOrderBits true
set_interface_property read_coord_source maxChannel 0
set_interface_property read_coord_source readyLatency 0
set_interface_property read_coord_source ENABLED true
set_interface_property read_coord_source EXPORT_OF ""
set_interface_property read_coord_source PORT_NAME_MAP ""
set_interface_property read_coord_source CMSIS_SVD_VARIABLES ""
set_interface_property read_coord_source SVD_ADDRESS_GROUP ""

add_interface_port read_coord_source coord_out_ready ready Input 1
add_interface_port read_coord_source coords_out data Output 66
add_interface_port read_coord_source coords_out_valid valid Output 1


# 
# connection point write_coord_source
# 
add_interface write_coord_source avalon_streaming start
set_interface_property write_coord_source associatedClock clock_sink
set_interface_property write_coord_source associatedReset reset
set_interface_property write_coord_source dataBitsPerSymbol 35
set_interface_property write_coord_source errorDescriptor ""
set_interface_property write_coord_source firstSymbolInHighOrderBits true
set_interface_property write_coord_source maxChannel 0
set_interface_property write_coord_source readyLatency 0
set_interface_property write_coord_source ENABLED true
set_interface_property write_coord_source EXPORT_OF ""
set_interface_property write_coord_source PORT_NAME_MAP ""
set_interface_property write_coord_source CMSIS_SVD_VARIABLES ""
set_interface_property write_coord_source SVD_ADDRESS_GROUP ""

add_interface_port write_coord_source write_coords_out data Output 35
add_interface_port write_coord_source write_coords_out_valid valid Output 1


# 
# connection point frame_start_conduit
# 
add_interface frame_start_conduit avalon_streaming end
set_interface_property frame_start_conduit associatedClock clock_sink
set_interface_property frame_start_conduit associatedReset reset
set_interface_property frame_start_conduit dataBitsPerSymbol 1
set_interface_property frame_start_conduit errorDescriptor ""
set_interface_property frame_start_conduit firstSymbolInHighOrderBits true
set_interface_property frame_start_conduit maxChannel 0
set_interface_property frame_start_conduit readyLatency 0
set_interface_property frame_start_conduit ENABLED true
set_interface_property frame_start_conduit EXPORT_OF ""
set_interface_property frame_start_conduit PORT_NAME_MAP ""
set_interface_property frame_start_conduit CMSIS_SVD_VARIABLES ""
set_interface_property frame_start_conduit SVD_ADDRESS_GROUP ""

add_interface_port frame_start_conduit frame_start data Input 1


# 
# connection point buffer_row_conduit
# 
add_interface buffer_row_conduit conduit end
set_interface_property buffer_row_conduit associatedClock clock_sink
set_interface_property buffer_row_conduit associatedReset ""
set_interface_property buffer_row_conduit ENABLED true
set_interface_property buffer_row_conduit EXPORT_OF ""
set_interface_property buffer_row_conduit PORT_NAME_MAP ""
set_interface_property buffer_row_conduit CMSIS_SVD_VARIABLES ""
set_interface_property buffer_row_conduit SVD_ADDRESS_GROUP ""

add_interface_port buffer_row_conduit buf_writer_row buffer_row Input 16


# 
# connection point write_coord_source_2
# 
add_interface write_coord_source_2 avalon_streaming start
set_interface_property write_coord_source_2 associatedClock clock_sink
set_interface_property write_coord_source_2 associatedReset reset
set_interface_property write_coord_source_2 dataBitsPerSymbol 34
set_interface_property write_coord_source_2 errorDescriptor ""
set_interface_property write_coord_source_2 firstSymbolInHighOrderBits true
set_interface_property write_coord_source_2 maxChannel 0
set_interface_property write_coord_source_2 readyLatency 0
set_interface_property write_coord_source_2 ENABLED true
set_interface_property write_coord_source_2 EXPORT_OF ""
set_interface_property write_coord_source_2 PORT_NAME_MAP ""
set_interface_property write_coord_source_2 CMSIS_SVD_VARIABLES ""
set_interface_property write_coord_source_2 SVD_ADDRESS_GROUP ""

add_interface_port write_coord_source_2 write_coords_out_2 data Output 34
add_interface_port write_coord_source_2 write_coords_out_valid_2 valid Output 1
