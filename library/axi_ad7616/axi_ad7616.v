// ***************************************************************************
// ***************************************************************************
// Copyright 2013(c) Analog Devices, Inc.
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//     - Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     - Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in
//       the documentation and/or other materials provided with the
//       distribution.
//     - Neither the name of Analog Devices, Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//     - The use of this software may or may not infringe the patent rights
//       of one or more patent holders.  This license does not release you
//       from the requirement that you obtain separate licenses from these
//       patent holders to use this software.
//     - Use of the software either in source or binary form, must be run
//       on or directly connected to an Analog Devices Inc. component.
//
// THIS SOFTWARE IS PROVIDED BY ANALOG DEVICES "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
// INCLUDING, BUT NOT LIMITED TO, NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE ARE DISCLAIMED.
//
// IN NO EVENT SHALL ANALOG DEVICES BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
// EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, INTELLECTUAL PROPERTY
// RIGHTS, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
// THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// ***************************************************************************
// ***************************************************************************
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module axi_ad7616 (

  // physical data interface

  sclk,
  cs_n,
  sdo,
  sdi_0,
  sdi_1,

  db_o,
  db_i,
  rd_n,
  wr_n,

  // physical control interface

  reset_n,
  cnvst,
  busy,
  seq_en,
  hw_rngsel,
  chsel,
  crcen,
  ser1w_n,
  burst,
  os,

  // AXI Slave Memory Map

  s_axi_aclk,
  s_axi_aresetn,
  s_axi_awvalid,
  s_axi_awaddr,
  s_axi_awready,
  s_axi_wvalid,
  s_axi_wdata,
  s_axi_wstrb,
  s_axi_wready,
  s_axi_bvalid,
  s_axi_bresp,
  s_axi_bready,
  s_axi_arvalid,
  s_axi_araddr,
  s_axi_arready,
  s_axi_rvalid,
  s_axi_rresp,
  s_axi_rdata,
  s_axi_rready,

  // AXI-Stream Master

  m_axis_tdata,
  m_axis_tvalid,
  m_axis_tready

);

  // parameters

  parameter       ID = 0;
  parameter       OP_MODE = 0;
  parameter       IF_TYPE = 0;

  localparam      PCORE_VERSION = 'h0001001;
  localparam      SW = 0;
  localparam      HW = 1;
  localparam      SERIAL = 0;
  localparam      PARALLEL = 1;

  // IO definitions

  output          sclk;
  output          cs_n;
  output          sdo;
  input           sdi_0;
  input           sdi_1;

  output  [15:0]  db_o;
  input   [15:0]  db_i;
  output          rd_n;
  output          wr_n;

  output          reset_n;
  output          cnvst;
  output          busy;
  output          seq_en;
  output  [ 1:0]  hw_rngsel;
  output  [ 2:0]  chsel;
  output          crcen;
  output          ser1w_n;
  output          burst;
  output  [ 2:0]  os;


  input           s_axi_aclk;
  input           s_axi_aresetn;
  input           s_axi_awvalid;
  input   [31:0]  s_axi_awaddr;
  output          s_axi_awready;
  input           s_axi_wvalid;
  input   [31:0]  s_axi_wdata;
  input   [ 3:0]  s_axi_wstrb;
  output          s_axi_wready;
  output          s_axi_bvalid;
  output  [ 1:0]  s_axi_bresp;
  input           s_axi_bready;
  input           s_axi_arvalid;
  input   [31:0]  s_axi_araddr;
  output          s_axi_arready;
  output          s_axi_rvalid;
  output  [ 1:0]  s_axi_rresp;
  output  [31:0]  s_axi_rdata;
  input           s_axi_rready;

  output  [31:0]  m_axis_tdata;
  input           m_axis_tready;
  output          m_axis_tvalid;

  // internal registers


  // internal signals

  wire            up_rreq_s;
  wire    [13:0]  up_raddr_s;
  wire    [31:0]  up_rdata_s[0:2];
  wire            up_rack_s[0:2];
  wire            up_wack_s[0:2];
  wire            up_wreq_s;
  wire    [13:0]  up_waddr_s;
  wire    [31:0]  up_wdata_s;

  // defaults

  assign up_clk = s_axi_aclk;
  assign up_rstn = s_axi_aresetn;

  generate if (IF_TYPE == 0) begin

    wire spi_resetn_s;

    axi_spi_engine #(
      .SDI_DATA_WIDTH(),
      .NUM_OFFLOAD()
    ) i_axi_spi_engine(
      .s_axi_aclk (up_clk),
      .s_axi_aresetn (up_rstn),
      .s_axi_awvalid (s_axi_awvalid),
      .s_axi_awaddr (s_axi_awaddr),
      .s_axi_awready (s_axi_awready),
      .s_axi_wvalid (s_axi_wvalid),
      .s_axi_wdata (s_axi_wdata),
      .s_axi_wstrb (s_axi_wstrb),
      .s_axi_wready (s_axi_wready),
      .s_axi_bvalid (s_axi_bvalid),
      .s_axi_bresp (s_axi_bresp),
      .s_axi_bready (s_axi_bready),
      .s_axi_arvalid (s_axi_arvalid),
      .s_axi_araddr (s_axi_araddr),
      .s_axi_arready (s_axi_arready),
      .s_axi_rvalid (s_axi_rvalid),
      .s_axi_rready (s_axi_rready),
      .s_axi_rresp (s_axi_rresp),
      .s_axi_rdata (s_axi_rdata),
      .irq (),
      .spi_clk (up_clk),
      .spi_resetn (spi_resetn_s),
      .cmd_ready (),
      .cmd_valid (),
      .cmd_data (),
      .sdo_data_ready (),
      .sdo_data_valid (),
      .sdo_data (),
      .sdi_data_ready (),
      .sdi_data_valid (),
      .sdi_data (),
      .sync_ready (),
      .sync_valid (),
      .sync_data (),
      .offload0_cmd_wr_en (),
      .offload0_cmd_wr_data (),
      .offload0_sdo_wr_en (),
      .offload0_sdo_wr_data (),
      .offload0_mem_reset (),
      .offload0_enable (),
      .offload0_enabled());

    spi_engine_offload #(
      .SDI_DATA_WIDTH()
    ) i_spi_engine_offload(
      .ctrl_clk (),
      .ctrl_cmd_wr_en (),
      .ctrl_cmd_wr_data (),
      .ctrl_sdo_wr_en (),
      .ctrl_sdo_wr_data (),
      .ctrl_enable (),
      .ctrl_enabled (),
      .ctrl_mem_reset (),
      .spi_clk (up_clk),
      .spi_resetn (spi_resetn_s),
      .trigger (),
      .cmd_valid (),
      .cmd_ready (),
      .cmd (),
      .sdo_data_valid (),
      .sdo_data_ready (),
      .sdo_data (),
      .sdi_data_ready (),
      .sdi_data (),
      .sync_valid (),
      .sync_ready (),
      .sync_data (),
      .offload_sdi_valid (),
      .offload_sdi_ready (),
      .offload_sdi_data ());

    spi_engine_interconnect #(
      .SDI_DATA_WIDTH ()
    ) i_spi_engine_interconnect (
      .clk (up_clk),
      .resetn (spi_resetn_s),
      .m_cmd_valid (),
      .m_cmd_ready (),
      .m_cmd_data (),
      .m_sdo_valid (),
      .m_sdo_ready (),
      .m_sdo_data (),
      .m_sdi_valid (),
      .m_sdi_ready (),
      .m_sdi_data (),
      .m_sync_valid (),
      .m_sync_ready (),
      .m_sync (),
      .s0_cmd_valid (),
      .s0_cmd_ready (),
      .s0_cmd_data (),
      .s0_sdo_valid (),
      .s0_sdo_ready (),
      .s0_sdo_data (),
      .s0_sdi_valid (),
      .s0_sdi_ready (),
      .s0_sdi_data (),
      .s0_sync_valid (),
      .s0_sync_ready (),
      .s0_sync (),
      .s1_cmd_valid (),
      .s1_cmd_ready (),
      .s1_cmd_data (),
      .s1_sdo_valid (),
      .s1_sdo_ready (),
      .s1_sdo_data (),
      .s1_sdi_valid (),
      .s1_sdi_ready (),
      .s1_sdi_data (),
      .s1_sync_valid (),
      .s1_sync_ready (),
      .s1_sync ());

    spi_engine_execution #(
      .SDI_DATA_WIDTH()
    ) i_spi_engine_execution (
      .clk (up_clk),
      .resetn (spi_resetn_s),
      .active (),
      .cmd_ready (),
      .cmd_valid (),
      .cmd (),
      .sdo_data_valid (),
      .sdo_data_ready (),
      .sdo_data (),
      .sdi_data_ready (),
      .sdi_data_valid (),
      .sdi_data (),
      .sync_ready (),
      .sync_valid (),
      .sync (),
      .sclk (),
      .sdo (),
      .sdo_t (),
      .sdi (),
      .sdi_1 (),
      .sdi_2 (),
      .sdi_3 (),
      .cs (),
      .three_wire ());

  end

  // up bus interface

  up_axi i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata),
    .up_rack (up_rack));

endmodule

// ***************************************************************************
// ***************************************************************************
