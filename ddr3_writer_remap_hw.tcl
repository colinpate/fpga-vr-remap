# TCL File Generated by Component Editor 18.1
# Fri Nov 15 16:44:41 PST 2019
# DO NOT MODIFY


# 
# ddr3_writer_remap "ddr3_writer_remap" v1.0
#  2019.11.15.16:44:41
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module ddr3_writer_remap
# 
set_module_property DESCRIPTION ""
set_module_property NAME ddr3_writer_remap
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME ddr3_writer_remap
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL ddr3_pixel_writer_remap
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file ddr3_pixel_writer_remap.sv SYSTEM_VERILOG PATH remap_v2/ddr3_pixel_writer_remap.sv TOP_LEVEL_FILE
add_fileset_file remap_coord_fifo.v VERILOG PATH remap_v2/remap_coord_fifo.v
add_fileset_file ddr3_writer_fifo.v VERILOG PATH ddr3_writer_fifo.v

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL ddr3_pixel_writer_remap
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE true
add_fileset_file ddr3_pixel_writer_remap.sv SYSTEM_VERILOG PATH remap_v2/ddr3_pixel_writer_remap.sv
add_fileset_file remap_coord_fifo.v VERILOG PATH remap_v2/remap_coord_fifo.v
add_fileset_file ddr3_writer_fifo.v VERILOG PATH ddr3_writer_fifo.v


# 
# parameters
# 
add_parameter in_width INTEGER 8
set_parameter_property in_width DEFAULT_VALUE 8
set_parameter_property in_width DISPLAY_NAME in_width
set_parameter_property in_width TYPE INTEGER
set_parameter_property in_width ENABLED false
set_parameter_property in_width UNITS None
set_parameter_property in_width ALLOWED_RANGES -2147483648:2147483647
set_parameter_property in_width HDL_PARAMETER true
add_parameter rotate_buffers INTEGER 0
set_parameter_property rotate_buffers DEFAULT_VALUE 0
set_parameter_property rotate_buffers DISPLAY_NAME rotate_buffers
set_parameter_property rotate_buffers TYPE INTEGER
set_parameter_property rotate_buffers UNITS None
set_parameter_property rotate_buffers ALLOWED_RANGES -2147483648:2147483647
set_parameter_property rotate_buffers HDL_PARAMETER true
add_parameter burst_log INTEGER 2
set_parameter_property burst_log DEFAULT_VALUE 2
set_parameter_property burst_log DISPLAY_NAME burst_log
set_parameter_property burst_log TYPE INTEGER
set_parameter_property burst_log UNITS None
set_parameter_property burst_log ALLOWED_RANGES -2147483648:2147483647
set_parameter_property burst_log HDL_PARAMETER true
add_parameter horiz INTEGER 1
set_parameter_property horiz DEFAULT_VALUE 1
set_parameter_property horiz DISPLAY_NAME horiz
set_parameter_property horiz TYPE INTEGER
set_parameter_property horiz UNITS None
set_parameter_property horiz HDL_PARAMETER true


# 
# display items
# 


# 
# connection point avalon_master
# 
add_interface avalon_master avalon start
set_interface_property avalon_master addressUnits WORDS
set_interface_property avalon_master associatedClock ddr3_clk_sink
set_interface_property avalon_master associatedReset ddr3clk_reset
set_interface_property avalon_master bitsPerSymbol 8
set_interface_property avalon_master burstOnBurstBoundariesOnly false
set_interface_property avalon_master burstcountUnits WORDS
set_interface_property avalon_master doStreamReads false
set_interface_property avalon_master doStreamWrites false
set_interface_property avalon_master holdTime 0
set_interface_property avalon_master linewrapBursts false
set_interface_property avalon_master maximumPendingReadTransactions 0
set_interface_property avalon_master maximumPendingWriteTransactions 0
set_interface_property avalon_master readLatency 0
set_interface_property avalon_master readWaitTime 1
set_interface_property avalon_master setupTime 0
set_interface_property avalon_master timingUnits Cycles
set_interface_property avalon_master writeWaitTime 0
set_interface_property avalon_master ENABLED true
set_interface_property avalon_master EXPORT_OF ""
set_interface_property avalon_master PORT_NAME_MAP ""
set_interface_property avalon_master CMSIS_SVD_VARIABLES ""
set_interface_property avalon_master SVD_ADDRESS_GROUP ""

add_interface_port avalon_master ddr3_burstcount burstcount Output 2
add_interface_port avalon_master ddr3_waitrequest waitrequest Input 1
add_interface_port avalon_master ddr3_write write Output 1
add_interface_port avalon_master ddr3_write_address address Output 27
add_interface_port avalon_master ddr3_write_data writedata Output 256


# 
# connection point ddr3_clk_sink
# 
add_interface ddr3_clk_sink clock end
set_interface_property ddr3_clk_sink clockRate 0
set_interface_property ddr3_clk_sink ENABLED true
set_interface_property ddr3_clk_sink EXPORT_OF ""
set_interface_property ddr3_clk_sink PORT_NAME_MAP ""
set_interface_property ddr3_clk_sink CMSIS_SVD_VARIABLES ""
set_interface_property ddr3_clk_sink SVD_ADDRESS_GROUP ""

add_interface_port ddr3_clk_sink ddr3_clk clk Input 1


# 
# connection point pclk_sink
# 
add_interface pclk_sink clock end
set_interface_property pclk_sink clockRate 0
set_interface_property pclk_sink ENABLED true
set_interface_property pclk_sink EXPORT_OF ""
set_interface_property pclk_sink PORT_NAME_MAP ""
set_interface_property pclk_sink CMSIS_SVD_VARIABLES ""
set_interface_property pclk_sink SVD_ADDRESS_GROUP ""

add_interface_port pclk_sink pclk clk Input 1


# 
# connection point pixel_sink
# 
add_interface pixel_sink avalon_streaming end
set_interface_property pixel_sink associatedClock pclk_sink
set_interface_property pixel_sink associatedReset ddr3clk_reset
set_interface_property pixel_sink dataBitsPerSymbol 17
set_interface_property pixel_sink errorDescriptor ""
set_interface_property pixel_sink firstSymbolInHighOrderBits true
set_interface_property pixel_sink maxChannel 0
set_interface_property pixel_sink readyLatency 0
set_interface_property pixel_sink ENABLED true
set_interface_property pixel_sink EXPORT_OF ""
set_interface_property pixel_sink PORT_NAME_MAP ""
set_interface_property pixel_sink CMSIS_SVD_VARIABLES ""
set_interface_property pixel_sink SVD_ADDRESS_GROUP ""

add_interface_port pixel_sink pixel_data data Input 17
add_interface_port pixel_sink pixel_valid valid Input 1


# 
# connection point coord_sink
# 
add_interface coord_sink avalon_streaming end
set_interface_property coord_sink associatedClock pclk_sink
set_interface_property coord_sink associatedReset ddr3clk_reset
set_interface_property coord_sink dataBitsPerSymbol 35
set_interface_property coord_sink errorDescriptor ""
set_interface_property coord_sink firstSymbolInHighOrderBits true
set_interface_property coord_sink maxChannel 0
set_interface_property coord_sink readyLatency 0
set_interface_property coord_sink ENABLED true
set_interface_property coord_sink EXPORT_OF ""
set_interface_property coord_sink PORT_NAME_MAP ""
set_interface_property coord_sink CMSIS_SVD_VARIABLES ""
set_interface_property coord_sink SVD_ADDRESS_GROUP ""

add_interface_port coord_sink coords_in data Input 35
add_interface_port coord_sink coords_in_valid valid Input 1


# 
# connection point avalon_streaming_source
# 
add_interface avalon_streaming_source avalon_streaming start
set_interface_property avalon_streaming_source associatedClock pclk_sink
set_interface_property avalon_streaming_source associatedReset ddr3clk_reset
set_interface_property avalon_streaming_source dataBitsPerSymbol 1
set_interface_property avalon_streaming_source errorDescriptor ""
set_interface_property avalon_streaming_source firstSymbolInHighOrderBits true
set_interface_property avalon_streaming_source maxChannel 0
set_interface_property avalon_streaming_source readyLatency 0
set_interface_property avalon_streaming_source ENABLED true
set_interface_property avalon_streaming_source EXPORT_OF ""
set_interface_property avalon_streaming_source PORT_NAME_MAP ""
set_interface_property avalon_streaming_source CMSIS_SVD_VARIABLES ""
set_interface_property avalon_streaming_source SVD_ADDRESS_GROUP ""

add_interface_port avalon_streaming_source fifo_almost_full data Output 1


# 
# connection point ddr3clk_reset
# 
add_interface ddr3clk_reset reset end
set_interface_property ddr3clk_reset associatedClock ""
set_interface_property ddr3clk_reset synchronousEdges NONE
set_interface_property ddr3clk_reset ENABLED true
set_interface_property ddr3clk_reset EXPORT_OF ""
set_interface_property ddr3clk_reset PORT_NAME_MAP ""
set_interface_property ddr3clk_reset CMSIS_SVD_VARIABLES ""
set_interface_property ddr3clk_reset SVD_ADDRESS_GROUP ""

add_interface_port ddr3clk_reset ddr3clk_reset reset Input 1


# 
# connection point pclk_reset
# 
add_interface pclk_reset reset end
set_interface_property pclk_reset associatedClock pclk_sink
set_interface_property pclk_reset synchronousEdges DEASSERT
set_interface_property pclk_reset ENABLED true
set_interface_property pclk_reset EXPORT_OF ""
set_interface_property pclk_reset PORT_NAME_MAP ""
set_interface_property pclk_reset CMSIS_SVD_VARIABLES ""
set_interface_property pclk_reset SVD_ADDRESS_GROUP ""

add_interface_port pclk_reset pclk_reset reset Input 1


# 
# connection point start
# 
add_interface start conduit end
set_interface_property start associatedClock ddr3_clk_sink
set_interface_property start associatedReset ""
set_interface_property start ENABLED true
set_interface_property start EXPORT_OF ""
set_interface_property start PORT_NAME_MAP ""
set_interface_property start CMSIS_SVD_VARIABLES ""
set_interface_property start SVD_ADDRESS_GROUP ""

add_interface_port start start_address_i address Input 32
