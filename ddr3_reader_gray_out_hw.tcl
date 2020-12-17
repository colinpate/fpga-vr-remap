# TCL File Generated by Component Editor 18.1
# Wed Apr 01 20:31:34 PDT 2020
# DO NOT MODIFY


# 
# ddr3_reader_gray_out "ddr3_reader_gray_out" v1.0
#  2020.04.01.20:31:34
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module ddr3_reader_gray_out
# 
set_module_property DESCRIPTION ""
set_module_property NAME ddr3_reader_gray_out
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME ddr3_reader_gray_out
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL ddr3_reader_grayout
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file ddr3_reader_grayout.sv SYSTEM_VERILOG PATH grayscale_output/ddr3_reader_grayout.sv TOP_LEVEL_FILE
add_fileset_file ddr3reader_dcfifo.v VERILOG PATH grayscale_output/ddr3reader_dcfifo.v
add_fileset_file gray_ptr_fifo.v VERILOG PATH grayscale_output/gray_ptr_fifo.v

add_fileset SIM_VERILOG SIM_VERILOG "" ""
set_fileset_property SIM_VERILOG TOP_LEVEL ddr3_reader_grayout
set_fileset_property SIM_VERILOG ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property SIM_VERILOG ENABLE_FILE_OVERWRITE_MODE true
add_fileset_file ddr3_reader_grayout.sv SYSTEM_VERILOG PATH grayscale_output/ddr3_reader_grayout.sv
add_fileset_file ddr3reader_dcfifo.v VERILOG PATH grayscale_output/ddr3reader_dcfifo.v
add_fileset_file gray_ptr_fifo.v VERILOG PATH grayscale_output/gray_ptr_fifo.v


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
add_parameter frame_width INTEGER 480
set_parameter_property frame_width DEFAULT_VALUE 480
set_parameter_property frame_width DISPLAY_NAME frame_width
set_parameter_property frame_width TYPE INTEGER
set_parameter_property frame_width UNITS None
set_parameter_property frame_width ALLOWED_RANGES -2147483648:2147483647
set_parameter_property frame_width HDL_PARAMETER true
add_parameter frame_lines INTEGER 720
set_parameter_property frame_lines DEFAULT_VALUE 720
set_parameter_property frame_lines DISPLAY_NAME frame_lines
set_parameter_property frame_lines TYPE INTEGER
set_parameter_property frame_lines UNITS None
set_parameter_property frame_lines ALLOWED_RANGES -2147483648:2147483647
set_parameter_property frame_lines HDL_PARAMETER true
add_parameter frame_real_width INTEGER 720
set_parameter_property frame_real_width DEFAULT_VALUE 720
set_parameter_property frame_real_width DISPLAY_NAME frame_real_width
set_parameter_property frame_real_width TYPE INTEGER
set_parameter_property frame_real_width UNITS None
set_parameter_property frame_real_width ALLOWED_RANGES -2147483648:2147483647
set_parameter_property frame_real_width HDL_PARAMETER true
add_parameter test_pattern INTEGER 0
set_parameter_property test_pattern DEFAULT_VALUE 0
set_parameter_property test_pattern DISPLAY_NAME test_pattern
set_parameter_property test_pattern TYPE INTEGER
set_parameter_property test_pattern UNITS None
set_parameter_property test_pattern ALLOWED_RANGES -2147483648:2147483647
set_parameter_property test_pattern HDL_PARAMETER true
add_parameter no_input INTEGER 0
set_parameter_property no_input DEFAULT_VALUE 0
set_parameter_property no_input DISPLAY_NAME no_input
set_parameter_property no_input TYPE INTEGER
set_parameter_property no_input UNITS None
set_parameter_property no_input ALLOWED_RANGES -2147483648:2147483647
set_parameter_property no_input HDL_PARAMETER true


# 
# display items
# 


# 
# connection point ddr3_read_master
# 
add_interface ddr3_read_master avalon start
set_interface_property ddr3_read_master addressUnits WORDS
set_interface_property ddr3_read_master associatedClock ddr3clk_sink
set_interface_property ddr3_read_master associatedReset ddr3clk_reset_sink
set_interface_property ddr3_read_master bitsPerSymbol 8
set_interface_property ddr3_read_master burstOnBurstBoundariesOnly false
set_interface_property ddr3_read_master burstcountUnits WORDS
set_interface_property ddr3_read_master doStreamReads false
set_interface_property ddr3_read_master doStreamWrites false
set_interface_property ddr3_read_master holdTime 0
set_interface_property ddr3_read_master linewrapBursts false
set_interface_property ddr3_read_master maximumPendingReadTransactions 0
set_interface_property ddr3_read_master maximumPendingWriteTransactions 0
set_interface_property ddr3_read_master readLatency 0
set_interface_property ddr3_read_master readWaitTime 1
set_interface_property ddr3_read_master setupTime 0
set_interface_property ddr3_read_master timingUnits Cycles
set_interface_property ddr3_read_master writeWaitTime 0
set_interface_property ddr3_read_master ENABLED true
set_interface_property ddr3_read_master EXPORT_OF ""
set_interface_property ddr3_read_master PORT_NAME_MAP ""
set_interface_property ddr3_read_master CMSIS_SVD_VARIABLES ""
set_interface_property ddr3_read_master SVD_ADDRESS_GROUP ""

add_interface_port ddr3_read_master ddr3_address address Output 27
add_interface_port ddr3_read_master ddr3_readdata readdata Input 256
add_interface_port ddr3_read_master ddr3_read read Output 1
add_interface_port ddr3_read_master ddr3_waitrequest waitrequest Input 1
add_interface_port ddr3_read_master ddr3_readdatavalid readdatavalid Input 1
add_interface_port ddr3_read_master ddr3_burstcount burstcount Output 5


# 
# connection point ddr3clk_sink
# 
add_interface ddr3clk_sink clock end
set_interface_property ddr3clk_sink clockRate 0
set_interface_property ddr3clk_sink ENABLED true
set_interface_property ddr3clk_sink EXPORT_OF ""
set_interface_property ddr3clk_sink PORT_NAME_MAP ""
set_interface_property ddr3clk_sink CMSIS_SVD_VARIABLES ""
set_interface_property ddr3clk_sink SVD_ADDRESS_GROUP ""

add_interface_port ddr3clk_sink ddr3clk clk Input 1


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
# connection point ptr_0_sink
# 
add_interface ptr_0_sink avalon_streaming end
set_interface_property ptr_0_sink associatedClock ddr3clk_sink
set_interface_property ptr_0_sink associatedReset ddr3clk_reset_sink
set_interface_property ptr_0_sink dataBitsPerSymbol 2
set_interface_property ptr_0_sink errorDescriptor ""
set_interface_property ptr_0_sink firstSymbolInHighOrderBits true
set_interface_property ptr_0_sink maxChannel 0
set_interface_property ptr_0_sink readyLatency 0
set_interface_property ptr_0_sink ENABLED true
set_interface_property ptr_0_sink EXPORT_OF ""
set_interface_property ptr_0_sink PORT_NAME_MAP ""
set_interface_property ptr_0_sink CMSIS_SVD_VARIABLES ""
set_interface_property ptr_0_sink SVD_ADDRESS_GROUP ""

add_interface_port ptr_0_sink pointer_0_data data Input 2
add_interface_port ptr_0_sink pointer_0_valid valid Input 1


# 
# connection point ptr_1_sink
# 
add_interface ptr_1_sink avalon_streaming end
set_interface_property ptr_1_sink associatedClock ddr3clk_sink
set_interface_property ptr_1_sink associatedReset ddr3clk_reset_sink
set_interface_property ptr_1_sink dataBitsPerSymbol 2
set_interface_property ptr_1_sink errorDescriptor ""
set_interface_property ptr_1_sink firstSymbolInHighOrderBits true
set_interface_property ptr_1_sink maxChannel 0
set_interface_property ptr_1_sink readyLatency 0
set_interface_property ptr_1_sink ENABLED true
set_interface_property ptr_1_sink EXPORT_OF ""
set_interface_property ptr_1_sink PORT_NAME_MAP ""
set_interface_property ptr_1_sink CMSIS_SVD_VARIABLES ""
set_interface_property ptr_1_sink SVD_ADDRESS_GROUP ""

add_interface_port ptr_1_sink pointer_1_data data Input 2
add_interface_port ptr_1_sink pointer_1_valid valid Input 1


# 
# connection point ptr_2_sink
# 
add_interface ptr_2_sink avalon_streaming end
set_interface_property ptr_2_sink associatedClock ddr3clk_sink
set_interface_property ptr_2_sink associatedReset ddr3clk_reset_sink
set_interface_property ptr_2_sink dataBitsPerSymbol 2
set_interface_property ptr_2_sink errorDescriptor ""
set_interface_property ptr_2_sink firstSymbolInHighOrderBits true
set_interface_property ptr_2_sink maxChannel 0
set_interface_property ptr_2_sink readyLatency 0
set_interface_property ptr_2_sink ENABLED true
set_interface_property ptr_2_sink EXPORT_OF ""
set_interface_property ptr_2_sink PORT_NAME_MAP ""
set_interface_property ptr_2_sink CMSIS_SVD_VARIABLES ""
set_interface_property ptr_2_sink SVD_ADDRESS_GROUP ""

add_interface_port ptr_2_sink pointer_2_data data Input 2
add_interface_port ptr_2_sink pointer_2_valid valid Input 1


# 
# connection point ptr_3_sink
# 
add_interface ptr_3_sink avalon_streaming end
set_interface_property ptr_3_sink associatedClock ddr3clk_sink
set_interface_property ptr_3_sink associatedReset ddr3clk_reset_sink
set_interface_property ptr_3_sink dataBitsPerSymbol 2
set_interface_property ptr_3_sink errorDescriptor ""
set_interface_property ptr_3_sink firstSymbolInHighOrderBits true
set_interface_property ptr_3_sink maxChannel 0
set_interface_property ptr_3_sink readyLatency 0
set_interface_property ptr_3_sink ENABLED true
set_interface_property ptr_3_sink EXPORT_OF ""
set_interface_property ptr_3_sink PORT_NAME_MAP ""
set_interface_property ptr_3_sink CMSIS_SVD_VARIABLES ""
set_interface_property ptr_3_sink SVD_ADDRESS_GROUP ""

add_interface_port ptr_3_sink pointer_3_data data Input 2
add_interface_port ptr_3_sink pointer_3_valid valid Input 1


# 
# connection point pixel_source
# 
add_interface pixel_source avalon_streaming start
set_interface_property pixel_source associatedClock pclk_sink
set_interface_property pixel_source associatedReset pclk_reset_sink
set_interface_property pixel_source dataBitsPerSymbol 8
set_interface_property pixel_source errorDescriptor ""
set_interface_property pixel_source firstSymbolInHighOrderBits true
set_interface_property pixel_source maxChannel 0
set_interface_property pixel_source readyLatency 0
set_interface_property pixel_source ENABLED true
set_interface_property pixel_source EXPORT_OF ""
set_interface_property pixel_source PORT_NAME_MAP ""
set_interface_property pixel_source CMSIS_SVD_VARIABLES ""
set_interface_property pixel_source SVD_ADDRESS_GROUP ""

add_interface_port pixel_source pixel_valid valid Output 1
add_interface_port pixel_source pixel_data data Output 8


# 
# connection point pclk_reset_sink
# 
add_interface pclk_reset_sink reset end
set_interface_property pclk_reset_sink associatedClock pclk_sink
set_interface_property pclk_reset_sink synchronousEdges DEASSERT
set_interface_property pclk_reset_sink ENABLED true
set_interface_property pclk_reset_sink EXPORT_OF ""
set_interface_property pclk_reset_sink PORT_NAME_MAP ""
set_interface_property pclk_reset_sink CMSIS_SVD_VARIABLES ""
set_interface_property pclk_reset_sink SVD_ADDRESS_GROUP ""

add_interface_port pclk_reset_sink pclk_reset reset Input 1


# 
# connection point ddr3clk_reset_sink
# 
add_interface ddr3clk_reset_sink reset end
set_interface_property ddr3clk_reset_sink associatedClock ddr3clk_sink
set_interface_property ddr3clk_reset_sink synchronousEdges DEASSERT
set_interface_property ddr3clk_reset_sink ENABLED true
set_interface_property ddr3clk_reset_sink EXPORT_OF ""
set_interface_property ddr3clk_reset_sink PORT_NAME_MAP ""
set_interface_property ddr3clk_reset_sink CMSIS_SVD_VARIABLES ""
set_interface_property ddr3clk_reset_sink SVD_ADDRESS_GROUP ""

add_interface_port ddr3clk_reset_sink ddr3clk_reset reset Input 1


# 
# connection point start_0
# 
add_interface start_0 conduit end
set_interface_property start_0 associatedClock ddr3clk_sink
set_interface_property start_0 associatedReset ""
set_interface_property start_0 ENABLED true
set_interface_property start_0 EXPORT_OF ""
set_interface_property start_0 PORT_NAME_MAP ""
set_interface_property start_0 CMSIS_SVD_VARIABLES ""
set_interface_property start_0 SVD_ADDRESS_GROUP ""

add_interface_port start_0 start_0 address Input 27


# 
# connection point start_1
# 
add_interface start_1 conduit end
set_interface_property start_1 associatedClock ddr3clk_sink
set_interface_property start_1 associatedReset ""
set_interface_property start_1 ENABLED true
set_interface_property start_1 EXPORT_OF ""
set_interface_property start_1 PORT_NAME_MAP ""
set_interface_property start_1 CMSIS_SVD_VARIABLES ""
set_interface_property start_1 SVD_ADDRESS_GROUP ""

add_interface_port start_1 start_1 address Input 27


# 
# connection point start_2
# 
add_interface start_2 conduit end
set_interface_property start_2 associatedClock ddr3clk_sink
set_interface_property start_2 associatedReset ""
set_interface_property start_2 ENABLED true
set_interface_property start_2 EXPORT_OF ""
set_interface_property start_2 PORT_NAME_MAP ""
set_interface_property start_2 CMSIS_SVD_VARIABLES ""
set_interface_property start_2 SVD_ADDRESS_GROUP ""

add_interface_port start_2 start_2 address Input 27


# 
# connection point start_3
# 
add_interface start_3 conduit end
set_interface_property start_3 associatedClock ddr3clk_sink
set_interface_property start_3 associatedReset ""
set_interface_property start_3 ENABLED true
set_interface_property start_3 EXPORT_OF ""
set_interface_property start_3 PORT_NAME_MAP ""
set_interface_property start_3 CMSIS_SVD_VARIABLES ""
set_interface_property start_3 SVD_ADDRESS_GROUP ""

add_interface_port start_3 start_3 address Input 27


# 
# connection point wait_for_remap
# 
add_interface wait_for_remap conduit end
set_interface_property wait_for_remap associatedClock ""
set_interface_property wait_for_remap associatedReset ""
set_interface_property wait_for_remap ENABLED true
set_interface_property wait_for_remap EXPORT_OF ""
set_interface_property wait_for_remap PORT_NAME_MAP ""
set_interface_property wait_for_remap CMSIS_SVD_VARIABLES ""
set_interface_property wait_for_remap SVD_ADDRESS_GROUP ""

add_interface_port wait_for_remap wait_for_remap wait Input 1


# 
# connection point pixel_clk_source
# 
add_interface pixel_clk_source clock start
set_interface_property pixel_clk_source associatedDirectClock ""
set_interface_property pixel_clk_source clockRate 0
set_interface_property pixel_clk_source clockRateKnown false
set_interface_property pixel_clk_source ENABLED true
set_interface_property pixel_clk_source EXPORT_OF ""
set_interface_property pixel_clk_source PORT_NAME_MAP ""
set_interface_property pixel_clk_source CMSIS_SVD_VARIABLES ""
set_interface_property pixel_clk_source SVD_ADDRESS_GROUP ""

add_interface_port pixel_clk_source pixel_outclk clk Output 1
