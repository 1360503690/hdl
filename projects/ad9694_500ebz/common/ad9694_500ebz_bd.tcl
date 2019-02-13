
source $ad_hdl_dir/library/jesd204/scripts/jesd204.tcl

# interfaces and IO ports

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 iic_dac
create_bd_port -dir I spi_vco_csn_i
create_bd_port -dir O spi_vco_csn_o
create_bd_port -dir I spi_vco_clk_i
create_bd_port -dir O spi_vco_clk_o
create_bd_port -dir I spi_vco_sdo_i
create_bd_port -dir O spi_vco_sdo_o
create_bd_port -dir I spi_vco_sdi_i
create_bd_port -dir I spi_afe_adc_csn_i
create_bd_port -dir O spi_afe_adc_csn_o
create_bd_port -dir I spi_afe_adc_clk_i
create_bd_port -dir O spi_afe_adc_clk_o
create_bd_port -dir I spi_afe_adc_sdo_i
create_bd_port -dir O spi_afe_adc_sdo_o
create_bd_port -dir I spi_afe_adc_sdi_i

# adc peripherals - controlled by PS7/SPI0

ad_ip_instance axi_adxcvr axi_ad9694_xcvr [list \
  NUM_OF_LANES $NUM_OF_LANES \
  QPLL_ENABLE 1 \
  TX_OR_RX_N 0 \
]

adi_axi_jesd204_rx_create ad9694_jesd $NUM_OF_LANES
adi_tpl_jesd204_rx_create ad9694_tpl_core $NUM_OF_LANES $NUM_OF_CHANNELS $SAMPLES_PER_FRAME $SAMPLE_WIDTH

ad_ip_instance util_cpack2 util_ad9694_cpack [list \
  NUM_OF_CHANNELS $NUM_OF_CHANNELS \
  SAMPLES_PER_CHANNEL [expr $CHANNEL_DATA_WIDTH / $SAMPLE_WIDTH] \
  SAMPLE_DATA_WIDTH $SAMPLE_WIDTH \
]

ad_ip_instance axi_dmac ad9694_dma [list \
  DMA_TYPE_SRC 1 \
  DMA_TYPE_DEST 0 \
  DMA_DATA_WIDTH_SRC $DMA_DATA_WIDTH \
  DMA_DATA_WIDTH_DEST 64 \
]

# 3-wire SPI for clock synthesizer & VCO - 12.5MHz SCLK rate

ad_ip_instance axi_quad_spi axi_spi_vco
ad_ip_parameter axi_spi_vco CONFIG.C_USE_STARTUP 0
ad_ip_parameter axi_spi_vco CONFIG.C_NUM_SS_BITS 1
ad_ip_parameter axi_spi_vco CONFIG.C_SCK_RATIO 8

# I2C for AFE board's DAC

ad_ip_parameter sys_ps7 CONFIG.PCW_QSPI_GRP_IO1_ENABLE 1
ad_ip_parameter sys_ps7 CONFIG.PCW_I2C1_PERIPHERAL_ENABLE 1

# 3-wire SPI for AFE board's ADC - 12.5MHz SCLK rate

ad_ip_instance axi_quad_spi axi_spi_afe_adc
ad_ip_parameter axi_spi_afe_adc CONFIG.C_USE_STARTUP 0
ad_ip_parameter axi_spi_afe_adc CONFIG.C_NUM_SS_BITS 1
ad_ip_parameter axi_spi_afe_adc CONFIG.C_SCK_RATIO 8

# shared transceiver core

ad_ip_instance util_adxcvr util_ad9694_xcvr [list \
  RX_NUM_OF_LANES $NUM_OF_LANES \
  TX_NUM_OF_LANES 0 \
]

ad_connect sys_cpu_resetn util_ad9694_xcvr/up_rstn
ad_connect sys_cpu_clk util_ad9694_xcvr/up_clk

# instantiate the axi_adcfifo

set adc_fifo_name axi_ad9694_fifo
ad_adcfifo_create $adc_fifo_name $ADC_DATA_WIDTH $DMA_DATA_WIDTH

# reference clocks & resets

create_bd_port -dir I -type clk rx_ref_clk
create_bd_port -dir I -type clk rx_device_clk

ad_xcvrpll  rx_ref_clk util_ad9694_xcvr/qpll_ref_clk_*
ad_xcvrpll  rx_ref_clk util_ad9694_xcvr/cpll_ref_clk_*
ad_xcvrpll  axi_ad9694_xcvr/up_pll_rst util_ad9694_xcvr/up_qpll_rst_*
ad_xcvrpll  axi_ad9694_xcvr/up_pll_rst util_ad9694_xcvr/up_cpll_rst_*

# connections (adc)

ad_xcvrcon util_ad9694_xcvr axi_ad9694_xcvr ad9694_jesd {2 3 0 1} rx_device_clk
ad_connect rx_device_clk ad9694_tpl_core/link_clk
ad_connect ad9694_jesd/rx_sof ad9694_tpl_core/link_sof
ad_connect ad9694_jesd/rx_data_tvalid ad9694_tpl_core/link_valid
ad_connect ad9694_jesd/rx_data_tdata ad9694_tpl_core/link_data

ad_connect rx_device_clk util_ad9694_cpack/clk
ad_connect rx_device_clk_rstgen/peripheral_reset util_ad9694_cpack/reset

for {set i 0} {$i < $NUM_OF_CHANNELS} {incr i} {
  ad_connect ad9694_tpl_core/adc_enable_$i util_ad9694_cpack/enable_$i
  ad_connect ad9694_tpl_core/adc_data_$i util_ad9694_cpack/fifo_wr_data_$i
}
ad_connect ad9694_tpl_core/adc_valid_0 util_ad9694_cpack/fifo_wr_en

ad_connect rx_device_clk axi_ad9694_fifo/adc_clk
ad_connect rx_device_clk_rstgen/peripheral_reset axi_ad9694_fifo/adc_rst
ad_connect util_ad9694_cpack/packed_fifo_wr_en axi_ad9694_fifo/adc_wr
ad_connect util_ad9694_cpack/packed_fifo_wr_data axi_ad9694_fifo/adc_wdata
ad_connect sys_cpu_clk axi_ad9694_fifo/dma_clk
ad_connect sys_cpu_clk ad9694_dma/s_axis_aclk
ad_connect sys_cpu_resetn ad9694_dma/m_dest_axi_aresetn
ad_connect axi_ad9694_fifo/dma_wr ad9694_dma/s_axis_valid
ad_connect axi_ad9694_fifo/dma_wdata ad9694_dma/s_axis_data
ad_connect axi_ad9694_fifo/dma_wready ad9694_dma/s_axis_ready
ad_connect axi_ad9694_fifo/dma_xfer_req ad9694_dma/s_axis_xfer_req
ad_connect ad9694_tpl_core/adc_dovf axi_ad9694_fifo/adc_wovf

ad_connect sys_cpu_clk  axi_spi_vco/ext_spi_clk
ad_connect spi_vco axi_spi_vco/SPI_0
ad_connect spi_vco_csn_i axi_spi_vco/ss_i
ad_connect spi_vco_csn_o axi_spi_vco/ss_o
ad_connect spi_vco_clk_i axi_spi_vco/sck_i
ad_connect spi_vco_clk_o axi_spi_vco/sck_o
ad_connect spi_vco_sdo_i axi_spi_vco/io0_i
ad_connect spi_vco_sdo_o axi_spi_vco/io0_o
ad_connect spi_vco_sdi_i axi_spi_vco/io1_i

ad_connect iic_dac sys_ps7/IIC_1

ad_connect sys_cpu_clk  axi_spi_afe_adc/ext_spi_clk
ad_connect spi_afe_adc axi_spi_afe_adc/SPI_0
ad_connect spi_afe_adc_csn_i axi_spi_afe_adc/ss_i
ad_connect spi_afe_adc_csn_o axi_spi_afe_adc/ss_o
ad_connect spi_afe_adc_clk_i axi_spi_afe_adc/sck_i
ad_connect spi_afe_adc_clk_o axi_spi_afe_adc/sck_o
ad_connect spi_afe_adc_sdo_i axi_spi_afe_adc/io0_i
ad_connect spi_afe_adc_sdo_o axi_spi_afe_adc/io0_o
ad_connect spi_afe_adc_sdi_i axi_spi_afe_adc/io1_i

# interconnect (cpu)

ad_cpu_interconnect 0x44A50000 axi_ad9694_xcvr
ad_cpu_interconnect 0x44A10000 ad9694_tpl_core
ad_cpu_interconnect 0x44AA0000 ad9694_jesd
ad_cpu_interconnect 0x7c400000 ad9694_dma
ad_cpu_interconnect 0x7c500000 axi_spi_vco
ad_cpu_interconnect 0x7c600000 axi_spi_afe_adc

# gt uses hp3, and 100MHz clock for both DRP and AXI4

ad_mem_hp3_interconnect sys_cpu_clk sys_ps7/S_AXI_HP3
ad_mem_hp3_interconnect sys_cpu_clk axi_ad9694_xcvr/m_axi

# interconnect (mem/dac)

ad_mem_hp2_interconnect sys_cpu_clk sys_ps7/S_AXI_HP2
ad_mem_hp2_interconnect sys_cpu_clk ad9694_dma/m_dest_axi

# interrupts

ad_cpu_interrupt ps-11 mb-14 ad9694_jesd/irq
ad_cpu_interrupt ps-13 mb-12 ad9694_dma/irq
ad_cpu_interrupt ps-10 mb-15 axi_spi_vco/ip2intc_irpt
ad_cpu_interrupt ps-9 mb-8  axi_spi_afe_adc/ip2intc_irpt

