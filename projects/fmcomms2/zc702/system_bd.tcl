
source $ad_hdl_dir/projects/common/zc702/zc702_system_bd.tcl
source ../common/fmcomms2_bd.tcl

set_property CONFIG.ADC_INIT_DELAY 23 [get_bd_cells axi_ad9361]

