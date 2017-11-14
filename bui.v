`ifndef _BUI_
`define _BUI_

//==================================================================
//
// (c) Copyright 2011 NICEVT. All rights reserved.
//
// Science and Research Centre of Computer Technology "NICEVT"
// Varshavskoe Shosse 125, 117587, Moscow, Russian Federation.
// http://www.nicevt.ru
//
//
// Author(s)    :  Kirill Kurochkin (kurochkin@nicevt.ru)
//
// Create Date  :  28.03.2014
// Design Name  :  Router EC8430.
// File Name    :  bui.v
// Description  :
//
//==================================================================

//`define FLASH_MODEL_ON
//`define ARM_SRAM   // for netlist only
//`define PCIE_BLACK_BOX

//`define SC_ENABLE  // for netlist only

`timescale 1ns/1ps

module bui #(
// bui_pcie Parameters:




   parameter PCIE_NUM        = 0,
   parameter RGDBW           = `RGDBW,
   parameter RDBW            = `RDBW,               //  BUI Data Bus Width(TRN/PE IF): 128
   parameter REMW            =  2,                  //  need to change name of this parameter
   parameter BARW            =   7,                 // PCI_EXP_BAR_HIT_WIDTH
   parameter CORE_CS_WTH     =  96,                 //  ChipSelect Group Bus Width
   parameter TAGW            =  5,                  //  Real TAG Field Width
   parameter VF_MAX_NUM      = `ROUTER_FN_MAX_NUM,  //  Maximum functions, supported by router
   parameter VF_MAX_NUM_W    = `LOG2(VF_MAX_NUM),
   parameter NUMVFSW         =  8,
   parameter EXCQ            = `EXC_EVENT_WTH_BUI,  //  Exceptional Event Quantity
   parameter ERGQ            = 6,//`EXTREG_SEL_WTH_BUI, //  Extention Register Quantity
   parameter ROUTER_VERSION  = `ROUTER_VERSION,     //  Router Version
   parameter PARCHK          =  `ifdef ARM_SRAM 1,
                                 `else           0,
                                 `endif
   // PCI_Express Parameters:
   parameter PCIE_BARHW      =  7,                  //  PCI_EXP_BAR_HIT_WIDTH
   parameter PCIE_CBSNW      =  8,                  //  PCI_EXP_CFG_BUSNUM_WIDTH
   parameter PCIE_CDVNW      =  5,                  //  PCI_EXP_CFG_DEVNUM_WIDTH
   parameter PCIE_CFNNW      =  3,                  //  PCI_EXP_CFG_FUNNUM_WIDTH

   parameter EXC_VEC_PTR_W   =  5,
   //ELB Parameters:
   parameter ELB_AW          = `ELB_ADR_WIDTH,
   parameter ELB_DW          = `ELB_DATA_WIDTH,
   parameter ELB_MS          = `ELB_MODE_SIZE,
   parameter SPL_AW          = `SPL_ADR_WIDTH,
   parameter SPL_DW          = `SPL_DATA_WIDTH,

   //Flash ctrl./router_ip_ config parameters:
   parameter FI_ADR_WIDTH    =  8,
   parameter PCIE_CFGINT_WTH =  2,
   parameter AUR_CFGINT_WTH  =  1,
   parameter MC_CFGINT_WTH   =  9,
   parameter DIM             = `RDIM,

   //Common parameters:
   //
   parameter PCIEQ             = `PCIEQ,
   parameter PEPQ              = `PIPEQ,                // "PE PipeLine Quantity" for one PCIE
   parameter BASQ              = 4, // BaseAddress Quantity
   parameter SUM_PEPQ          =  PEPQ * PCIEQ,
   parameter PPQW              = `PIPE_NUM_WIDTH,       // "PE PipeLine Quantity" Field Width
   parameter FSAW              = `PIPE_FRESP_WIDTH,
   parameter PIPE_ALLOC_WIDTH  = `PIPE_ALLOC_WIDTH,     // Memory size allocated per each pipeline.
   parameter SUBB_NUM_WIDTH    = `SUBB_NUM_WIDTH,       // IO subblock number field width
   parameter SUBB_IOADDR_WIDTH = `SUBB_IOADDR_WIDTH,    // IO subblock address field width
   parameter IO_PCIENUM_WIDTH  = `IO_PCIENUM_DEC_WIDTH,
   parameter PKT_PCIENUM_WIDTH = `PKT_PCIENUM_DEC_WIDTH,
   parameter FLIT_PRECISION    = (RDBW == 64)? 3 : 4,
   parameter ADDRW             = PKT_PCIENUM_WIDTH + PPQW + PIPE_ALLOC_WIDTH,
   parameter IO_ADDRW          = IO_PCIENUM_WIDTH + SUBB_NUM_WIDTH + SUBB_IOADDR_WIDTH,
   parameter SUBB_CS_WIDTH     = `SUBBQR,
   parameter RAW_CREDIT_WTH    = 8,
   parameter CORE_INPUT_REG    = 1,
   parameter CORE_IO_INPUT_REG = 0,
   parameter MSIX_TABLE_OFFSET = 0,
   parameter MSIX_PBA_OFFSET   = 'H10000000
 )


 (

  //---Sys interface
   input                                     core_clk,          // 
   input                                     rst_n_2buip,       //  reset 2 buip
   input                                     rst_n_2bui,        //  reset 2 bui
   input                                     rst_n_pipe,

   input [REMW                         -1:0] trn_rrem,
   input                                     trn_rsrc_rdy,
   input                                     trn_rsrc_dsc,
   input                                     trn_rerr_fwd,
   input                                     trn_recrc_err,
   input                                     trn_rsof,
   input                                     trn_reof,
   input [RDBW                         -1:0] trn_rd,
   input [BARW                         -1:0] trn_rbar_hit,
   input [NUMVFSW                      -1:0] trn_rfunc_num,
   output                                    trn_rdst_rdy,

      // Transmit

   output [RDBW                        -1:0] trn_td,
   output [REMW                        -1:0] trn_trem,
   output                                    trn_tsof,
   output                                    trn_teof,
   output                                    trn_tsrc_rdy,
   input                                     trn_tdst_rdy,
   input                                     trn_tdst_dsc,
   output                                    trn_tsrc_dsc,
   input                                     trn_tnp_ok,

//////////////////////////


  input  [PCIE_CBSNW      -1:0] cfg_bus_number,
  input  [PCIE_CDVNW      -1:0] cfg_device_number,
  input  [PCIE_CFNNW      -1:0] cfg_function_number,

  input [NUMVFSW          -1:0] pcie_numvfs,          // Field from SR-IOV Cap.
  input [NUMVFSW          -1:0] pcie_vf_offset,

  output [64              -1:0] cfg_dsn,

//==== MSI interface:
  input  [63               :0] int_msi_addr,
  input  [15               :0] int_msi_data,
  input                        int_msi_enable,
  input  [31               :0] int_msi_mask,
  input  [2                :0] int_msi_mm,
  output [31               :0] int_msi_pba,
  output                       int_msi_update_pba,

//=== MSI-X interface:
  input                        int_msix_enable,
  input                        int_msix_mask,
  input [VF_MAX_NUM-1-1:0]     int_msix_vf_enable,
  input [VF_MAX_NUM-1-1:0]     int_msix_vf_mask,



// // CFG EXT Interface:
//input                         cfg_ext_rd,
//input                         cfg_ext_wr,
//input  [9:0]                  cfg_ext_reg_num,
//// output  [7:0]              cfg_ext_func_num,       // we have only one function in our device
//input  [31:0]                 cfg_ext_wr_data,
//input  [3:0]                  cfg_ext_wr_be,    // only for write
//
//output   [31:0]               cfg_ext_rd_data,
//output                        cfg_ext_rd_data_val,

/////// ELB bus from ELB ADAPTER
  input  [SPL_AW          -1:0] elba_addr_2spl,    // address of ppc soft accessible regs
  input                         elba_rd_2spl,      // converted to pci_clk read request
  input                         elba_wr_2spl,      // Bus to IP write enable
  input  [SPL_DW          -1:0] elba_data_2spl,    // Bus to IP data bus
  input                         elba_enabled_2spl, // elb on/off switch


  output [SPL_DW          -1:0] spl_data_2elba,    // IP to Bus data bus
  output                        spl_ack_2elba,     // IP to Bus read transfer acknowledgement
  output                        spl_irq_2elba,     // IP to Bus interrupt event strob

////// ELB BUS from internal service processor

  input  [SPL_AW          -1:0] elbi_addr_2spl,    // address of ppc soft accessible regs
  input                         elbi_rd_2spl,      // converted to pci_clk read request
  input                         elbi_wr_2spl,      // Bus to IP write enable
  input  [SPL_DW          -1:0] elbi_data_2spl,    // Bus to IP data bus
  input                         elbi_enabled_2spl, // elb on/off switch

  output [SPL_DW          -1:0] spl_data_2elbi,    // IP to Bus data bus
  output                        spl_ack_2elbi,     // IP to Bus read transfer acknowledgement
  output                        spl_irq_2elbi,     // IP to Bus interrupt event strob

//////////////////////////////////////////////////




//-----JTAG DEBUG interface
   input                        jtag_rd_2buij,
   input                        jtag_wr_2buij,
   input  [RDBW           -1:0] jtag_data_2buij,
   input  [RGDBW          -1:0] jtag_addr_2buij,

   output [RDBW           -1:0] buij_data_2jtag,
   output                       buij_ack_2jtag,

  //---router_core interface
  // RX ---
  // Commands:
   output                        bui_io_wr,         //IO Write
   output                        bui_io_rd,         //IO Read
   output [RGDBW           -1:0] bui_io_data,
   output [IO_ADDRW        -1:0] bui_io_addr,
   output [SUBB_CS_WIDTH   -1:0] bui_bcs,           // Chip select for each block
   output                        bui_io_ack,   // notify wrapper about ending of current io request

   output [                 1:0] bui_mem_wr,        //Memory Write
   output [                 1:0] bui_long_wr,       //Memory Long Write
   output [                 1:0] bui_cmpl_wr,       //Completion Write
   output [                 1:0] bui_raw_wr,
   output                        bui_raw_hdr_wr,

   output [RDBW            -1:0] bui_data,          //Data
   output [ADDRW*2         -1:0] bui_addr,
   output [NUMVFSW         -1:0] bui_fn_num,        // Virtual Function number.
   output [NUMVFSW         -1:0] bui_io_fn_num,
   output [TAGW            -1:0] bui_tag,

   output                        bui_tag_wr,        //TAG Write

   output [                 1:0] bui_sop,           //Start of Package
   output [                 1:0] bui_eop,           //End of Package

                                                    //(CheapSelects)
   // TX ---
   output                       bui_rdy,           //BUI Ready

   output                       bui_nposted_skip,  // note NI that request was deleted due to max offset violation
   output [TAGW           -1:0] bui_nposted_val,   //
                                                   //=1 when FreeSpace in TX FIFO>TMIN
   input                         core_wr,           //NI Write
   input                         core_wr_sop,       //NI Write SOP
   input                         core_wr_eop,       //NI Write EOP
   input  [RDBW            -1:0] core_data,         //NI Data
   input                         core_raw_rdy,      // CORE rdy for RAW packets

   input  [FSAW*SUM_PEPQ   -1:0] pe_fresp_ptr,      //Free_space Pointer
   input  [PCIEQ           -1:0] bui_rsp_mask,      // injection pipelines responsibility mask

   input  [TAGW            -1:0] core_tag_o,        //TAG
   input  [RGDBW           -1:0] core_io_data,       //IORD Data
   input                         core_io_ack,

   input                         ihdl_64k_tick,     //core_clk:64k
   input                         ihdl_interrupt,    //Interrupt_proc Request
   input [EXC_VEC_PTR_W    -1:0] ihdl_except_num,
   input                         ihdl_pfcnt_sclr,   //PerfCnt SyncReset
   input                         ihdl_pfcnt_en,     //PerfCnt Enable

   output reg [EXCQ        -1:0] bui_except_event,  //Exceptional Events
   output                        bui_int,           //BUI Interrupt(to PCIe)
   input                         pcie_int_ack,      //Interrupt Acknowledge

   input                         glb_sram_we,       //Global SRAMWriteEnable
   input                         glb_sram_re        //Global SRAMReadEnable




);

   localparam TRN_CLK_HPER      = 4;
   localparam TCK_UP_LEN        = 1020;
   localparam TCK_LO_LEN        = 510;

   localparam JTAG_CMD_RG_WHT   = 5;
   localparam JTAG_DATA_RG_WHT  = 32;
   localparam SLOW_INT_NUM      = 2;          // jtag + BIST

   //eeprom command definition
   localparam CMD_WREN        = 8'b0000_0110;
   localparam CMD_WRDI        = 8'b0000_0100;
   localparam CMD_RDSR        = 8'b0000_0101;
   localparam CMD_WRSR        = 8'b0000_0001;
   localparam CMD_READ        = 8'b0000_0011;
   localparam CMD_WRITE       = 8'b0000_0010;

   localparam WR_WIDTH        = 2;

   localparam OP_TYPE_HI      = 127;
   localparam OP_TYPE_LO      = 122;
   localparam TO_PCIE         = 32'd0;
   localparam SOURCE_NUM      = 4;
   localparam DEST_NUM        = 4;  // don't count IO direction
   localparam DIR_REG_WDT     = DEST_NUM;
//////////////////////////////////
   localparam XBAR_DATA_WIDTH   = NUMVFSW + RDBW + ADDRW*WR_WIDTH + TAGW + WR_WIDTH + WR_WIDTH + WR_WIDTH + 1 + WR_WIDTH + 1 + 1;
//////////////////////////////////

//////////////////////////////////
   localparam XBAR_IODATA_WIDTH = NUMVFSW + RGDBW + IO_ADDRW + 1 + 1;
//////////////////////////////////
   localparam BUIP_ADDRW       = `PIPE_NUM_WIDTH +
                                 `PIPE_PTR_WIDTH +
                                  FLIT_PRECISION;

   wire [RDBW -1:0] core_data_s;
   wire             core_wr_s;
   wire             core_wr_sop_s;
   wire             core_wr_eop_s;
   wire             core_raw_rdy_s;

   wire [RDBW -1:0] core_data_2arb;
   wire             core_wr_2arb;
   wire             core_wr_sop_2arb;
   wire             core_wr_eop_2arb;
   wire [TAGW -1:0] core_tag_s;
   reg  [TAGW -1:0] core_tag_r;

   wire             bui_csCBGRA;
   wire             bui_csCBGRD;

   wire  [RGDBW         -1:0] debug_rg_o;
   wire  [RGDBW         -1:0] jtag_idata;

   wire  [SPL_AW        -1:0] elb_mux_addr_2spl;    // address of ppc soft accessible regs
   wire                       elb_mux_rd_2spl;      // converted to pci_clk read request
   wire                       elb_mux_wr_2spl;      // Bus to IP write enable
   wire  [SPL_DW        -1:0] elb_mux_data_2spl;    // Bus to IP data bus
   wire                       elb_mux_enabled_2spl; // elb on/off switch

   wire  [SPL_DW        -1:0] spl_data_2elb_mux;
   wire                       spl_ack_2elb_mux;

   wire                       spl_rdy;
   wire                       spl_io_wr;
   wire                       spl_io_rd;
   wire [IO_ADDRW       -1:0] spl_io_addr;
   wire [RGDBW          -1:0] spl_io_data;

   wire                       spl_hdr_wr;
   wire [WR_WIDTH       -1:0] spl_mem_wr;
   wire [WR_WIDTH       -1:0] spl_raw_wr;
   wire [WR_WIDTH       -1:0] spl_long_wr;
   wire [WR_WIDTH       -1:0] spl_cmpl_wr;
   wire [WR_WIDTH       -1:0] spl_spl_wr;    // loopback strobe
   wire [WR_WIDTH       -1:0] spl_sum_strobe;

   wire [ADDRW*WR_WIDTH -1:0] spl_addr;
   wire [RDBW           -1:0] spl_data;
   wire                       spl_tag_wr;
   wire [TAGW           -1:0] spl_tag_i;

   wire [WR_WIDTH       -1:0] spl_sop;
   wire [WR_WIDTH       -1:0] spl_eop;
   wire [RGDBW          -1:0] spl_hbuf_ctrl_rg;

   wire [WR_WIDTH       -1:0] hub2spl_sop;
   wire [WR_WIDTH       -1:0] hub2spl_eop;
   wire                       hub2spl_rdy;

   wire [NUMVFSW        -1:0] hub_2spl_fn_num;
   wire [RDBW           -1:0] hub2spl_data;
   wire [ADDRW*WR_WIDTH -1:0] hub2spl_addr;
   wire [TAGW           -1:0] hub2spl_tag;
   wire [RDBW           -1:0] hub2spl_dummy;
   wire                       hub2spl_host_wr_fl;
   wire [WR_WIDTH       -1:0] hub2spl_host_wr;
   wire [WR_WIDTH       -1:0] hub2spl_core_wr;

   wire [RGDBW          -1:0] hub2spl_iodata;
   wire                       hub2spl_iodata_val;
   wire                       hub2spl_io_rdy;

   wire [1                :0] spl_except_event;

   wire                       buij_rdy;
   wire                       buij_io_wr;
   wire                       buij_io_rd;
   wire [IO_ADDRW       -1:0] buij_io_addr;
   wire [RGDBW          -1:0] buij_io_data;

   wire                       buij_hdr_wr;
   wire [WR_WIDTH       -1:0] buij_mem_wr;
   wire [WR_WIDTH       -1:0] buij_raw_wr;
   wire [WR_WIDTH       -1:0] buij_long_wr;
   wire [WR_WIDTH       -1:0] buij_cmpl_wr;
   wire [WR_WIDTH       -1:0] buij_buij_wr;     //loopback strobe

   wire [ADDRW*WR_WIDTH -1:0] buij_addr;
   wire [RDBW           -1:0] buij_data;
   wire                       buij_tag_wr;
   wire [TAGW           -1:0] buij_tag_i;

   wire [WR_WIDTH       -1:0] buij_sop;
   wire [WR_WIDTH       -1:0] buij_eop;
   wire [RGDBW          -1:0] buij_hbuf_ctrl_rg;

   wire [WR_WIDTH       -1:0] hub2buij_sop;
   wire [WR_WIDTH       -1:0] hub2buij_eop;
   wire                       hub2buij_rdy;
   wire [RDBW           -1:0] hub2buij_data;
   wire [ADDRW*WR_WIDTH -1:0] hub2buij_addr;
   wire [TAGW           -1:0] hub2buij_tag;
   wire [RDBW           -1:0] hub2buij_dummy;
   wire                       hub_2buij_host_wr_fl;
   wire [WR_WIDTH       -1:0] hub2buij_host_wr;
   wire [WR_WIDTH       -1:0] hub2buij_core_wr;

   wire [RGDBW          -1:0] hub2buij_iodata;
   wire                       hub2buij_iodata_val;
   wire                       hub2buij_io_rdy;

   wire [1                :0] buij_except_event;

   wire                       buir_fixed_error, buir_fatal_error;
   wire                       core_fifo_fixed_error, core_fifo_fatal_error;

   wire                       cbg_mem_wr;
   wire                       cbg_sop;
   wire                       cbg_eop;
   wire [RDBW           -1:0] cbg_data;
   wire [TAGW           -1:0] cbg_tag;
   wire [ADDRW          -1:0] cbg_adr;
   wire                       cbg_rdy;
   wire                       cbg_core_dir;

   wire [DIR_REG_WDT      :0] core_route_rg;    // msb  - Use Router Rg. flag
   wire [DIR_REG_WDT      :0] pcie_route_rg;
   wire [DIR_REG_WDT      :0] lf_route_rg;
   wire [DIR_REG_WDT      :0] spl_route_rg;

   wire [DEST_NUM       -1:0] buip_dir_s;
   wire [DEST_NUM       -1:0] core_dir_s;
   wire [DEST_NUM       -1:0] lfmux_dir_s;
   wire [DEST_NUM       -1:0] spl_dir_s;

   wire [TAGW           -1:0] switch_tag;

   wire [RGDBW          -1:0] switch_io_data_wr;
   wire [RGDBW          -1:0] switch_io_data_rd;

   wire [WR_WIDTH       -1:0] buip_sop;
   wire [WR_WIDTH       -1:0] buip_eop;
   wire [WR_WIDTH       -1:0] buip_mem_wr;
   wire [WR_WIDTH       -1:0] buip_long_wr;
   wire [WR_WIDTH       -1:0] buip_cmpl_wr;
   wire [WR_WIDTH       -1:0] buip_raw_wr;
   wire                       buip_raw_hdr_wr;

   wire                       buip_io_wr;
   wire [TAGW           -1:0] buip_tag_i;
   wire                       buip_io_rd;
   wire                       buip_tag_wr;
   wire [ADDRW*WR_WIDTH -1:0] buip_addr;
   wire [NUMVFSW        -1:0] buip_fn_num;
   wire [RDBW           -1:0] buip_data;
   wire                       buip_rdy;
   wire [RGDBW          -1:0] buip_iodata;
   wire [IO_ADDRW       -1:0] buip_ioaddr;
   wire [NUMVFSW        -1:0] buip_io_fn_num;

   wire                       buip_fetch_rg;
   wire [1                :0] buip_fetch_rg_num;
   wire [VF_MAX_NUM_W   -1:0] buip_fetch_fn_num;
   wire                       buip_fetch_rdy;

   wire [45             -1:0] base_dma_addr;
   wire [29             -1:0] max_offset;

   wire [63               :0] buip_raw_addr_msk;
   wire [1                :0] max_tlp_size;
   wire                       host_amo;

   wire                       bui_data_granul_64;
   wire [15               :0] buip_cmpl_receive_tout;
   wire [31               :0] buip_pfcnt_adr_err_cnt;
   wire [47               :0] buip_pfcnt_dmareadlatency_cnt;
   
   wire  [VF_MAX_NUM    -1:0] credit_en;
   wire  [1               :0] credit_delta;
   wire  [5               :0] credit_gran;

   wire  [EXCQ          -1:0] buip_except_event;
   wire  [RGDBW         -1:0] buip_ext_reg;


   wire                       hub2pcie_sop;
   wire                       hub2pcie_eop;
   wire                       hub2pcie_rdy;

   wire [NUMVFSW        -1:0] hub2pcie_fn_num;
   wire [RDBW           -1:0] hub2pcie_data;
   wire [RDBW           -1:0] hub2pcie_dummy;
   wire [TAGW           -1:0] hub2pcie_tag;

   wire                       hub2pcie_wr;

   wire [RGDBW          -1:0] hub2pcie_iodata;
   wire                       hub2pcie_iodata_val;
   wire                       hub2pcie_io_rdy;

   wire [1                :0] hub_trn_ckf;

   wire [RGDBW          -1:0] cfg_data_2bui;
   wire [WR_WIDTH       -1:0] buip_wr_2spl;

   wire [31               :0] int_msix_data;
   wire [63               :0] int_msix_address;
   wire                       int_msix_int;
   wire                       int_msix_sent;


   wire [RGDBW          -1:0] buir_iodata, cbg_iodata, msix_iodata;
   wire                       buir_io_ack, cbg_io_ack, msix_io_ack;

   wire                       ignore_raw_pack;

 // assign  trn_reset_n_mdf         = trn_reset_n         |  debug_rg_o[1];  // temp !!!


   wire [WR_WIDTH*SOURCE_NUM             -1:0] indr_sop;             // begining transaction from BUI
   wire [WR_WIDTH*SOURCE_NUM             -1:0] indr_eop;             // indication of the end transaction from BUI
   wire [WR_WIDTH*SOURCE_NUM             -1:0] indr_req;
   wire [DEST_NUM*SOURCE_NUM             -1:0] indr_dir;
   wire [XBAR_DATA_WIDTH*SOURCE_NUM      -1:0] indr_data_pack;



   wire [DEST_NUM                        -1:0] indr_rdy;

   wire [SOURCE_NUM                      -1:0] indr_io_req;

   wire [SOURCE_NUM*ADDRW                -1:0] indr_io_addr;
   wire [XBAR_IODATA_WIDTH*SOURCE_NUM    -1:0] indr_iodata_pack;

   wire [RGDBW                           -1:0] hub_io_rdata;
   wire [SOURCE_NUM                      -1:0] hub_io_rdata_val;

   wire [SOURCE_NUM                      -1:0] arb_rdy;
   wire [SOURCE_NUM                      -1:0] hub_io_rdy;          // do we need this signal?
   wire [SOURCE_NUM                      -1:0] iodata_rdy_2hub;
   wire [DEST_NUM*WR_WIDTH               -1:0] arb_req;
   wire [WR_WIDTH*(DEST_NUM)             -1:0] arb_sop;             // begining transaction from BUI
   wire [WR_WIDTH*(DEST_NUM)             -1:0] arb_eop;             // indication of the end transaction from BUI
   wire [XBAR_DATA_WIDTH *DEST_NUM       -1:0] arb_data_pack;

   wire [RGDBW                           -1:0] hub_io_data;
   wire [IO_ADDRW                        -1:0] hub_io_addr;
   wire [NUMVFSW                         -1:0] hub_io_fn_num;
   wire [SUBB_CS_WIDTH                   -1:0] hub_io_bcs;
   wire                                        hub_io_wr;
   wire                                        hub_io_rd;

   wire [WR_WIDTH                        -1:0] hub2lfmux_sop;
   wire [WR_WIDTH                        -1:0] hub2lfmux_eop;
   wire                                        hub2lfmux_rdy;

   wire [NUMVFSW                         -1:0] hub2lfmux_fn_num;
   wire [RDBW                            -1:0] hub2lfmux_data;
   wire [ADDRW*WR_WIDTH                  -1:0] hub2lfmux_addr;
   wire [TAGW                            -1:0] hub2lfmux_tag;
   wire                                        hub2lfmux_tag_wr;
   wire                                        hub2lfmux_host_wr_fl;
   wire [9:                                 0] hub2lfmux_dummy;

   wire [WR_WIDTH                        -1:0] hub2lfmux_host_wr;
   wire [WR_WIDTH                        -1:0] hub2lfmux_core_wr;


   wire [RDBW                            -1:0] hub2lfmux_iodata;
   wire                                        hub2lfmux_iodata_val;
   wire                                        hub2lfmux_io_rdy;

   wire [WR_WIDTH                        -1:0] lfmux_sum_strobe;
   wire [WR_WIDTH                        -1:0] lfmux2hub_mem_wr;
   wire [WR_WIDTH                        -1:0] lfmux2hub_long_wr;
   wire [WR_WIDTH                        -1:0] lfmux2hub_raw_wr;
   wire                                        lfmux2hub_hdr_wr;
   wire [WR_WIDTH                        -1:0] lfmux2hub_cmpl_wr;
   wire                                        lfmux2hub_tag_wr;
   wire                                        lfmux2hub_loop_wr;
   wire [WR_WIDTH                        -1:0] lfmux2hub_sop;
   wire [WR_WIDTH                        -1:0] lfmux2hub_eop;
   wire [TAGW                            -1:0] lfmux2hub_tag;
   wire [RDBW                            -1:0] lfmux2hub_data;
   wire [ADDRW * WR_WIDTH                -1:0] lfmux2hub_addr;
   wire                                        lfmux2hub_rdy;

   wire                                        lfmux2hub_io_wr;
   wire                                        lfmux2hub_io_rd;
   wire [IO_ADDRW                        -1:0] lfmux2hub_ioaddr;
   wire [RGDBW                           -1:0] lfmux2hub_iodata;


   wire [WR_WIDTH*SLOW_INT_NUM           -1:0] lfint2lfmux_mem_wr;
   wire [WR_WIDTH*SLOW_INT_NUM           -1:0] lfint2lfmux_long_wr;
   wire [WR_WIDTH*SLOW_INT_NUM           -1:0] lfint2lfmux_raw_wr;
   wire [SLOW_INT_NUM                    -1:0] lfint2lfmux_hdr_wr;
   wire [WR_WIDTH*SLOW_INT_NUM           -1:0] lfint2lfmux_cmpl_wr;
   wire [SLOW_INT_NUM                    -1:0] lfint2lfmux_tag_wr;
   wire [SLOW_INT_NUM                    -1:0] lfint2lfmux_loop_wr;
   wire [WR_WIDTH*SLOW_INT_NUM           -1:0] lfint2lfmux_sop;             // begining transaction from BUI
   wire [WR_WIDTH*SLOW_INT_NUM           -1:0] lfint2lfmux_eop;             // indication of the end transaction from BUI
   wire [SLOW_INT_NUM*WR_WIDTH*ADDRW     -1:0] lfint2lfmux_addr;
   wire [SLOW_INT_NUM*RDBW               -1:0] lfint2lfmux_data;
   wire [SLOW_INT_NUM*TAGW               -1:0] lfint2lfmux_tag;
   wire [SLOW_INT_NUM                    -1:0] lfint2lfmux_rdy;
   wire [SLOW_INT_NUM                    -1:0] lfint2lfmux_io_wr;
   wire [SLOW_INT_NUM                    -1:0] lfint2lfmux_io_rd;
   wire [SLOW_INT_NUM*IO_ADDRW           -1:0] lfint2lfmux_ioaddr;
   wire [SLOW_INT_NUM*RGDBW              -1:0] lfint2lfmux_iodata;

   wire [SLOW_INT_NUM*WR_WIDTH           -1:0] lfmux2lfint_sop;
   wire [SLOW_INT_NUM*WR_WIDTH           -1:0] lfmux2lfint_eop;
   wire [SLOW_INT_NUM                    -1:0] lfmux2lfint_rdy;
   wire [SLOW_INT_NUM*WR_WIDTH           -1:0] lfmux2lfint_core_wr;
   wire [SLOW_INT_NUM*WR_WIDTH           -1:0] lfmux2lfint_host_wr;
   wire [SLOW_INT_NUM                    -1:0] lfmux2lfint_tag_wr;
   wire [RDBW*SLOW_INT_NUM               -1:0] lfmux2lfint_data;
   wire [ADDRW*WR_WIDTH*SLOW_INT_NUM     -1:0] lfmux2lfint_addr;
   wire [TAGW*SLOW_INT_NUM               -1:0] lfmux2lfint_tag;
   wire [RGDBW*SLOW_INT_NUM              -1:0] lfmux2lfint_iodata;
   wire [SLOW_INT_NUM                    -1:0] lfmux2lfint_iodata_val;
   wire [SLOW_INT_NUM                    -1:0] lfmux2lfint_io_rdy;
   wire [SLOW_INT_NUM                    -1:0] lf_dir_rg;
   wire [SLOW_INT_NUM                    -1:0] lf_io_dir_rg;

   wire  [1                                :0] spl_dir_rg;

   wire                                        bui_dummy;


/// Summary exceptions from BUI
   always @ (posedge core_clk or negedge rst_n_2bui) begin
      if (!rst_n_2bui) bui_except_event <= {{1'b0}};
      else             bui_except_event <= buip_except_event | {spl_except_event | buij_except_event | {buir_fixed_error, buir_fatal_error} | {core_fifo_fixed_error, core_fifo_fatal_error}, 2'b00};

   end


// PCIE

   wire [WR_WIDTH -1:0] buip_sum_strobe;

   wire                 pcie_use_rg_flag;

   assign pcie_use_rg_flag = pcie_route_rg[DIR_REG_WDT];

   assign buip_sum_strobe  = buip_mem_wr | buip_long_wr | buip_cmpl_wr | {WR_WIDTH{buip_tag_wr}} | buip_raw_wr | {WR_WIDTH{buip_raw_hdr_wr}};

   assign buip_dir_s       = pcie_route_rg[DIR_REG_WDT-1:0]; // use_route.RG flag hardriven to "1"

// CORE

   reg  core_use_dir_reg;
   wire core_use_dir_reg_s;
   wire core_use_rg_flag;

   always @(posedge core_clk or negedge rst_n_2bui) begin
      if(!rst_n_2bui) core_use_dir_reg <= 1'b0;
      else if (core_wr_sop_2arb)  begin
         core_use_dir_reg <= core_data_2arb[`HF_USE_ROUTE_RG_LB];
      end
      else if (core_wr_eop_2arb) begin
         core_use_dir_reg <= 1'b0;
      end
   end

   assign core_use_dir_reg_s = (core_wr_sop_2arb) ? core_data_2arb [`HF_USE_ROUTE_RG_LB] : core_use_dir_reg;

   assign core_use_rg_flag = core_route_rg [DIR_REG_WDT];

   assign core_dir_s = (core_use_dir_reg_s || core_use_rg_flag) ? core_route_rg[DIR_REG_WDT-1:0] : 4'b0001;


// SPL

   reg  spl_use_dir_reg;
   wire spl_use_dir_reg_s;

   always @(posedge core_clk or negedge rst_n_2bui) begin
      if(!rst_n_2bui) spl_use_dir_reg <= 1'b0;
      else if (spl_sop)  begin
         spl_use_dir_reg <= spl_data[`HF_USE_ROUTE_RG_LB];
      end
      else if (spl_eop) begin
         spl_use_dir_reg <= 1'b0;
      end
   end

   assign spl_use_dir_reg_s = (spl_sop) ? spl_data [`HF_USE_ROUTE_RG_LB] : spl_use_dir_reg;

   wire   spl_use_rg_flag = spl_route_rg[DIR_REG_WDT];

   assign spl_sum_strobe  = spl_mem_wr | spl_long_wr | spl_cmpl_wr | {WR_WIDTH{spl_tag_wr && !spl_dir_s [0]}} | spl_raw_wr | {WR_WIDTH{spl_hdr_wr}};

   assign spl_dir_s       = (spl_spl_wr) ? 4'b0100 : (spl_use_dir_reg_s || spl_use_rg_flag) ? spl_route_rg[DIR_REG_WDT-1:0] : 4'b0001;



// BUI Low Frequency

   reg  lfmux_use_dir_reg;
   wire lfmux_use_dir_reg_s;

   always @(posedge core_clk or negedge rst_n_2bui) begin
      if(!rst_n_2bui) lfmux_use_dir_reg <= 1'b0;
      else if (lfmux2hub_sop)  begin
         lfmux_use_dir_reg <= lfmux2hub_data[`HF_USE_ROUTE_RG_LB];
      end
      else if (lfmux2hub_eop) begin
         lfmux_use_dir_reg <= 1'b0;
      end
   end

   assign lfmux_use_dir_reg_s = (lfmux2hub_sop) ? lfmux2hub_data [`HF_USE_ROUTE_RG_LB] : lfmux_use_dir_reg;

   wire   lfmux_use_rg_flag = lf_route_rg[DIR_REG_WDT];

   assign lfmux_sum_strobe  = lfmux2hub_mem_wr | lfmux2hub_long_wr | lfmux2hub_cmpl_wr | {WR_WIDTH{lfmux2hub_tag_wr && !lfmux_dir_s[0]}} | lfmux2hub_raw_wr | {WR_WIDTH{lfmux2hub_hdr_wr}} | {WR_WIDTH{lfmux2hub_loop_wr}};

   assign lfmux_dir_s       = (lfmux2hub_loop_wr) ? 4'b1000 : (lfmux_use_dir_reg_s || lfmux_use_rg_flag) ? lf_route_rg[DIR_REG_WDT-1:0] : 4'b0001;

   assign cbg_core_dir = lfmux_use_rg_flag && lf_route_rg[1];




   ////////////////// BUI-PCIE gather signals:

   assign indr_rdy  [0]                                         = buip_rdy;
   assign indr_sop  [WR_WIDTH*0 +: WR_WIDTH]                    = buip_sop;
   assign indr_eop  [WR_WIDTH*0 +: WR_WIDTH]                    = buip_eop;
   assign indr_req  [WR_WIDTH*0 +: WR_WIDTH]                    = buip_sum_strobe;
   assign indr_dir  [DEST_NUM*0 +: DEST_NUM]                    = buip_dir_s;

   genvar i;

   assign indr_data_pack [XBAR_DATA_WIDTH*0 +: XBAR_DATA_WIDTH] = {buip_fn_num,
                                                                   buip_data,
                                                                   buip_addr,
                                                                   buip_tag_i,
                                                                   buip_mem_wr,
                                                                   buip_long_wr,
                                                                   buip_cmpl_wr,
                                                                   buip_tag_wr,
                                                                   buip_raw_wr,
                                                                   buip_raw_hdr_wr,
                                                                   1'b1};            // host_write

// To IO/arbiter:
   assign indr_io_req      [0]                                        = buip_io_rd || buip_io_wr;

   assign indr_iodata_pack [XBAR_IODATA_WIDTH*0 +: XBAR_IODATA_WIDTH] = {buip_io_fn_num,
                                                                         buip_iodata,
                                                                         buip_io_wr,
                                                                         buip_io_rd,
                                                                         buip_ioaddr};
   assign iodata_rdy_2hub [0]                                          = 1'b1;

//////////////////////////////////////////////////////////////////////////////////////////////////////////


 // ROUTER CORE gather signals

   generate
      if (CORE_INPUT_REG == 1) begin: core_with_rg     // input register for data from core
         reg [RDBW -1:0] core_data_r;
         reg             core_wr_r;
         reg             core_wr_sop_r;
         reg             core_wr_eop_r;
         reg             core_raw_rdy_r;

         always @ (posedge core_clk or negedge rst_n_2bui) begin
            if (!rst_n_2bui) begin
               core_data_r    <= {RDBW{1'b0}};
               core_wr_r      <= 1'b0;
               core_wr_sop_r  <= 1'b0;
               core_wr_eop_r  <= 1'b0;
               core_raw_rdy_r <= 1'b0;
            end
            else begin
               core_data_r    <= core_data;
               core_wr_r      <= core_wr;
               core_wr_sop_r  <= core_wr_sop;
               core_wr_eop_r  <= core_wr_eop;
               core_raw_rdy_r <= core_raw_rdy;
            end
         end

         assign core_data_s    = core_data_r;
         assign core_wr_s      = core_wr_r;
         assign core_wr_sop_s  = core_wr_sop_r;
         assign core_wr_eop_s  = core_wr_eop_r;
         assign core_raw_rdy_s = core_raw_rdy_r;
      end

      else begin : core_without_rg                    // without input register
         assign core_data_s    = core_data;
         assign core_wr_s      = core_wr;
         assign core_wr_sop_s  = core_wr_sop;
         assign core_wr_eop_s  = core_wr_eop;
         assign core_raw_rdy_s = core_raw_rdy;
      end
   endgenerate



// input fifo for core packets:
   bui_hs_fifo2 # (
      .PTR_W              (7  ),
      .ALMOST_FULL_BORDER (45 )
    )
    core_input_fifo (
      //--- System interface
      //
      .clk               ( core_clk    ),
      .rst_n             ( rst_n_2bui  ),
      .glb_sram_we       ( glb_sram_we ),
      .glb_sram_re       ( glb_sram_re ),

      //--- Input interface
      //
      .wr_sop_2hsf       ( core_wr_sop_s ),
      .wr_eop_2hsf       ( core_wr_eop_s ),
      .wr_2hsf           ( core_wr_s     ),
      .data_2hsf         ( core_data_s   ),
      .hsf_rdy           (               ),
      .hsf_almost_rdy    ( bui_rdy       ),

      //--- Output Interface
      //
      .hsf_wr_2recvr     ( core_wr_2arb     ),
      .hsf_wr_sop_2recvr ( core_wr_sop_2arb ),
      .hsf_wr_eop_2recvr ( core_wr_eop_2arb ),
      .hsf_data_2recvr   ( core_data_2arb   ),
      .recvr_rdy_2hsf    ( arb_rdy[1]       ),     // arb_rdy 2 core

      //--- error detecting
      //
      .fixed_error       ( core_fifo_fixed_error ),
      .fatal_error       ( core_fifo_fatal_error )
    );



   always @ (posedge core_clk or negedge rst_n_2bui) begin
      if (!rst_n_2bui)                           core_tag_r <= {TAGW{1'b0}};
      else if (core_wr_2arb && core_wr_sop_2arb) core_tag_r <= core_data_2arb[`HF_TSEQ_LB +:TAGW];
   end

   assign core_tag_s = (core_wr_2arb && core_wr_sop_2arb) ? core_data_2arb[`HF_TSEQ_LB +:TAGW] : core_tag_r;

   assign indr_rdy  [1]                                         = core_raw_rdy_s;
   assign indr_sop  [WR_WIDTH*1 +: WR_WIDTH]                    = {WR_WIDTH{core_wr_sop_2arb}};
   assign indr_eop  [WR_WIDTH*1 +: WR_WIDTH]                    = {WR_WIDTH{core_wr_eop_2arb}};
   assign indr_req  [WR_WIDTH*1 +: WR_WIDTH]                    = {WR_WIDTH{core_wr_2arb}};
   assign indr_dir  [DEST_NUM*1 +: DEST_NUM]                    = core_dir_s;

   assign indr_data_pack [XBAR_DATA_WIDTH*1 +: XBAR_DATA_WIDTH] = {core_data_2arb,
                                                                  {ADDRW*WR_WIDTH{1'b0}},
                                                                   core_tag_s,
                                                                   2'b0,  //mem_wr
                                                                   2'b0,  //long_wr
                                                                   2'b0,  //cmpl_wr
                                                                   1'b0,  //tag_wr
                                                                   2'b0,  //raw_wr
                                                                   1'b0,  //raw_hdr_wr
                                                                   1'b0   //host_wr
                                                                       };
// To IO/arbiter:
   assign indr_io_req      [1]                                        = 1'b0;

   assign indr_iodata_pack [XBAR_IODATA_WIDTH*1 +: XBAR_IODATA_WIDTH] = {XBAR_IODATA_WIDTH{1'b0}};

   assign iodata_rdy_2hub [1]                                         = 1'b1;


//////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////SPL - Service processor link gather signals

   assign indr_rdy  [2]                                         = spl_rdy;     // TEMP!
   assign indr_sop  [WR_WIDTH*2 +: WR_WIDTH]                    = spl_sop;
   assign indr_eop  [WR_WIDTH*2 +: WR_WIDTH]                    = spl_eop;
   assign indr_req  [WR_WIDTH*2 +: WR_WIDTH]                    = spl_sum_strobe;
   assign indr_dir  [DEST_NUM*2 +: DEST_NUM]                    = spl_dir_s;

   assign indr_data_pack [XBAR_DATA_WIDTH*2 +: XBAR_DATA_WIDTH] = {spl_data,
                                                                   spl_addr,
                                                                   spl_tag_i,
                                                                   spl_mem_wr,
                                                                   spl_long_wr,
                                                                   spl_cmpl_wr,
                                                                   spl_tag_wr,
                                                                   spl_raw_wr,
                                                                   spl_hdr_wr,
                                                                   1'b0};
// To IO/arbiter
   assign indr_io_req      [2]                                        = spl_io_wr || spl_io_rd;

   assign indr_iodata_pack [XBAR_IODATA_WIDTH*2 +: XBAR_IODATA_WIDTH] = {{NUMVFSW{1'b0}},
                                                                         spl_io_data,
                                                                         spl_io_wr,
                                                                         spl_io_rd,
                                                                         spl_io_addr};

   assign iodata_rdy_2hub [2]                                        = 1'b1;
//////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////////LOW FREQUENCY INTERFACE

   assign indr_rdy  [3]                                         = lfmux2hub_rdy;     // TEMP!
   assign indr_sop  [WR_WIDTH*3 +: WR_WIDTH]                    = lfmux2hub_sop;
   assign indr_eop  [WR_WIDTH*3 +: WR_WIDTH]                    = lfmux2hub_eop;
   assign indr_req  [WR_WIDTH*3 +: WR_WIDTH]                    = lfmux_sum_strobe;
   assign indr_dir  [DEST_NUM*3 +: DEST_NUM]                    = lfmux_dir_s;

   assign indr_data_pack [XBAR_DATA_WIDTH*3 +: XBAR_DATA_WIDTH] = {lfmux2hub_data,
                                                                   lfmux2hub_addr,
                                                                   lfmux2hub_tag,
                                                                   lfmux2hub_mem_wr,
                                                                   lfmux2hub_long_wr,
                                                                   lfmux2hub_cmpl_wr,
                                                                   lfmux2hub_tag_wr,
                                                                   lfmux2hub_raw_wr,
                                                                   lfmux2hub_hdr_wr,
                                                                   1'b0};
// To IO/arbiter
   assign indr_io_req      [3]                                        = lfmux2hub_io_wr || lfmux2hub_io_rd;

   assign indr_iodata_pack [XBAR_IODATA_WIDTH*3 +: XBAR_IODATA_WIDTH] = {{NUMVFSW{1'b0}},
                                                                         lfmux2hub_iodata,
                                                                         lfmux2hub_io_wr,
                                                                         lfmux2hub_io_rd,
                                                                         lfmux2hub_ioaddr};

   assign iodata_rdy_2hub [3]                                        = 1'b1;


///////////////////////////////////////////////////////////////////////////////////////////////////////////

// XBAR instantination:


   bui_packet_hub #(
      .WR_WIDTH            (WR_WIDTH),
      .SOURCE_NUM          (SOURCE_NUM),
      .DEST_NUM            (DEST_NUM),
      .XBAR_DATA_WIDTH     (XBAR_DATA_WIDTH),
      .XBAR_IODATA_WIDTH   (XBAR_IODATA_WIDTH)
   )

   bui_packet_hub (
      //--- Sys. Interface
      .clk                ( core_clk ),
      .rst_n              ( rst_n_2bui),

// HUB inputs

      .indr_rdy           (indr_rdy),
      .indr_req           (indr_req),

      .indr_dir           (indr_dir),

      .indr_sop           (indr_sop),
      .indr_eop           (indr_eop),

      .indr_data          (indr_data_pack),
      
      .ignore_raw_pack    (ignore_raw_pack),

// HUB outputs:

      .arb_rdy           (arb_rdy),
      .arb_req           (arb_req),

      .arb_sop           (arb_sop),
      .arb_eop           (arb_eop),
      .arb_data          (arb_data_pack)
);


// XBAR instantination:


   bui_io_hub #(
      .SOURCE_NUM        (SOURCE_NUM),
      .XBAR_IODATA_WIDTH (XBAR_IODATA_WIDTH),
      .CORE_IO_INPUT_REG (CORE_IO_INPUT_REG),
      .SUBB_NUM_WIDTH    (SUBB_NUM_WIDTH),
      .SUBB_IOADDR_WIDTH (SUBB_IOADDR_WIDTH),
      .SUBB_CS_WIDTH     (SUBB_CS_WIDTH),
      .IO_ADDRW          (IO_ADDRW)
   )

   bui_io_hub (
      //--- Sys. Interface
      .clk                (core_clk),
      .rst_n              (rst_n_2bui),

      .indr_io_req        (indr_io_req),
      .indr_io_rdy        (iodata_rdy_2hub),
      .indr_iodata        (indr_iodata_pack),

      .hub_io_rdy         (hub_io_rdy),

      .hub_io_bcs         (hub_io_bcs),
      .hub_io_data        (hub_io_data),
      .hub_io_wr          (hub_io_wr),
      .hub_io_rd          (hub_io_rd),
      .hub_io_addr        (hub_io_addr),
      .hub_io_fn_num      (hub_io_fn_num),

      .buir_iodata        (buir_iodata),
      .buir_io_ack        (buir_io_ack),

      .cbg_iodata         (cbg_iodata),
      .cbg_io_ack         (cbg_io_ack),

      .core_iodata        (core_io_data),
      .core_io_ack        (core_io_ack),

      .msix_iodata        (msix_iodata),
      .msix_io_ack        (msix_io_ack),

      .bui_sum_io_ack     (bui_io_ack),

      .hub_io_rdata       (hub_io_rdata),
      .hub_io_rdata_val   (hub_io_rdata_val)
   );

///////////////////////////////////////////////////////////

   //XBAR Outputs assign

//  HUB to BUI_PCIE internal signals assign  :

   assign hub2pcie_sop  = |arb_sop [WR_WIDTH*0 +: WR_WIDTH];
   assign hub2pcie_eop  = |arb_eop [WR_WIDTH*0 +: WR_WIDTH];
   assign hub2pcie_rdy  =  arb_rdy [0];

   assign {hub2pcie_fn_num,
           hub2pcie_data,
           hub2pcie_dummy[ADDRW*WR_WIDTH -1:0],
           hub2pcie_tag,
           hub2pcie_dummy[ADDRW*WR_WIDTH +: 11 ]} = arb_data_pack [XBAR_DATA_WIDTH*0 +: XBAR_DATA_WIDTH];

   assign hub2pcie_wr  = |arb_req [WR_WIDTH*0 +: WR_WIDTH];

  // IO - interface:

   assign hub2pcie_iodata     = hub_io_rdata;
   assign hub2pcie_iodata_val = hub_io_rdata_val [0];
   assign hub2pcie_io_rdy     = hub_io_rdy       [0];

/////////////////////////////////////////////////////////////////////

// HUB to ROUTER_CORE output signals assign

   assign bui_sop           = arb_sop [WR_WIDTH*1 +: WR_WIDTH];
   assign bui_eop           = arb_eop [WR_WIDTH*1 +: WR_WIDTH];

   assign { bui_fn_num,
            bui_data,
            bui_addr,
            bui_tag,
            bui_mem_wr,
            bui_long_wr,
            bui_cmpl_wr,
            bui_tag_wr,
            bui_raw_wr,
            bui_raw_hdr_wr,
            bui_dummy }     = arb_data_pack [XBAR_DATA_WIDTH*1 +: XBAR_DATA_WIDTH];

   assign bui_io_data       = hub_io_data;
   assign bui_io_addr       = hub_io_addr;
   assign bui_io_fn_num     = hub_io_fn_num;
   assign bui_bcs           = hub_io_bcs;
   assign bui_io_wr         = hub_io_wr;
   assign bui_io_rd         = hub_io_rd;

///////////////////////////////////////////////////////////////////
//  HUB to SPL internal signals assign  :

   assign hub2spl_sop   = arb_sop [WR_WIDTH*2 +: WR_WIDTH];
   assign hub2spl_eop   = arb_eop [WR_WIDTH*2 +: WR_WIDTH];
   assign hub2spl_rdy   = arb_rdy [2];

   assign {hub_2spl_fn_num,      // dummy bus!
           hub2spl_data,
           hub2spl_addr,
           hub2spl_tag,
           hub2spl_dummy[9:0],
           hub2spl_host_wr_fl} = arb_data_pack [XBAR_DATA_WIDTH*2 +: XBAR_DATA_WIDTH];

   assign hub2spl_host_wr  = arb_req [WR_WIDTH*2 +: WR_WIDTH] & {WR_WIDTH{ hub2spl_host_wr_fl}};
   assign hub2spl_core_wr  = arb_req [WR_WIDTH*2 +: WR_WIDTH] & {WR_WIDTH{!hub2spl_host_wr_fl}};

  // IO - interface:

   assign hub2spl_iodata     = hub_io_rdata;
   assign hub2spl_iodata_val = hub_io_rdata_val [2];
   assign hub2spl_io_rdy     = hub_io_rdy       [2];

////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////
//  HUB to SLCM internal signals assign  :

   assign hub2lfmux_sop   = arb_sop [WR_WIDTH*3 +: WR_WIDTH];
   assign hub2lfmux_eop   = arb_eop [WR_WIDTH*3 +: WR_WIDTH];
   assign hub2lfmux_rdy   = arb_rdy [3];
   
   assign {hub2lfmux_fn_num,     //dummy_bus!
           hub2lfmux_data,
           hub2lfmux_addr,
           hub2lfmux_tag,
           hub2lfmux_dummy[5:0],
           hub2lfmux_tag_wr,
           hub2lfmux_dummy [9:7],
           hub2lfmux_host_wr_fl} = arb_data_pack [XBAR_DATA_WIDTH*3 +: XBAR_DATA_WIDTH];

   assign hub2lfmux_host_wr  = arb_req [WR_WIDTH*3 +: WR_WIDTH] & {WR_WIDTH{ hub2lfmux_host_wr_fl}};
   assign hub2lfmux_core_wr  = arb_req [WR_WIDTH*3 +: WR_WIDTH] & {WR_WIDTH{!hub2lfmux_host_wr_fl}};

  // IO - interface:

   assign hub2lfmux_iodata     = hub_io_rdata;
   assign hub2lfmux_iodata_val = hub_io_rdata_val [3];
   assign hub2lfmux_io_rdy     = hub_io_rdy       [3];

////////////////////////////////////////////////////////////////////

   bui_pcie # (
      .ADDRW               (ADDRW        ),
      .IO_ADDRW            (IO_ADDRW     ),
      .SYNMEM              (0            ),

      .FSAW                (FSAW         ),
      .PCIEQ               (PCIEQ        ),
      .PEPQ                (PEPQ         ),
      .SUM_PEPQ            (SUM_PEPQ     ),
      .VF_MAX_NUM          (VF_MAX_NUM   ),
      .BDBW                (RDBW         ),            // BUI Data Bus Width(TRN/PE IF):64,128

      .REMW                (REMW         ),
      .PARCHK              (PARCHK       ),
      .EXCQ                (EXCQ         ),
      .ERGQ                (ERGQ         ),

      .PCIE_BARHW          (PCIE_BARHW   ),            // PCI_EXP_BAR_HIT_WIDTH
      .PCIE_CBSNW          (PCIE_CBSNW   ),            // PCI_EXP_CFG_BUSNUM_WIDTH
      .PCIE_CDVNW          (PCIE_CDVNW   ),            // PCI_EXP_CFG_DEVNUM_WIDTH
      .PCIE_CFNNW          (PCIE_CFNNW   ),            // PCI_EXP_CFG_FUNNUM_WIDTH

      .MXTM                (65536),

      .BAR_MWR             (0            ),            // BAR Number for pi_mem_wr cmd
      .BAR_IOC             (1            ),            // BAR Number for pi_io_wr,pi_io_rd cmd
      .BAR_RAW             (2            ),            // BAR Number for pi_hd_wr cmd
      .BAR_LWR             (4            ),            // BAR Number for pi_mem_wr_long cmd
      .BAR_SPL             (5            )             // BAR Number for pi_wr_2spl cmd


   )

   bui_pcie ( // Ports:

  // TRN Interface: ----------------------------------------


      .core_clk            (core_clk),
      .trn_rst_n           (rst_n_2buip),

  // Tx Interface
      .trn_td              (trn_td),
      .trn_trem            (trn_trem),
      .trn_tsof            (trn_tsof),
      .trn_teof            (trn_teof),
      .trn_tsrc_rdy        (trn_tsrc_rdy),
      .trn_tdst_rdy        (trn_tdst_rdy),
      .trn_tdst_dsc        (trn_tdst_dsc),
      .trn_tsrc_dsc        (trn_tsrc_dsc),
      .trn_tnp_ok          (trn_tnp_ok),

  // Rx Interface
      .trn_rd              (trn_rd),
      .trn_rrem            (trn_rrem),
      .trn_rsof            (trn_rsof),
      .trn_reof            (trn_reof),
      .trn_rsrc_rdy        (trn_rsrc_rdy),
      .trn_rsrc_dsc        (trn_rsrc_dsc),
      .trn_rdst_rdy        (trn_rdst_rdy),

      .trn_rbar_hit        (trn_rbar_hit),
      .trn_rfunc_num       (trn_rfunc_num),

      .trn_rerr_fwd        (trn_rerr_fwd),

      .trn_recrc_err       (trn_recrc_err),

      .cfg_bus_number      (cfg_bus_number),
      .cfg_device_number   (cfg_device_number),
      .cfg_function_number (cfg_function_number),

      .pcie_numvfs         (pcie_numvfs),          // current number of virtual functions
      .vf_offset           (pcie_vf_offset),

      .cfg_dsn             (cfg_dsn),
      .host_amo            (host_amo),

    //      // CFG EXT Interface:
    //.cfg_ext_rd          (cfg_ext_rd),
    //.cfg_ext_wr          (cfg_ext_wr),
    //.cfg_ext_reg_num     (cfg_ext_reg_num),
    //.cfg_ext_wr_data     (cfg_ext_wr_data),
    //.cfg_ext_wr_be       (cfg_ext_wr_be),
    //
    //.cfg_ext_rd_data     (cfg_ext_rd_data),
    //.cfg_ext_rd_data_val (cfg_ext_rd_data_val),

// Router Core Interface: PE/NI

      // RX part ---


     //.For (For) each 64-Data Chan:
      .buip_mem_wr         (buip_mem_wr),      //Memory Write
      .buip_long_wr        (buip_long_wr),     //Memory Long Write
      .buip_spl_wr         (buip_wr_2spl),     //Write to PPC         // ????
      .buip_cmpl_wr        (buip_cmpl_wr),     //Completion Write
      .buip_raw_wr         (buip_raw_wr),
      .buip_hdr_wr         (buip_raw_hdr_wr),  //

      .buip_addr           (buip_addr),         //Address*2 (per channel)
      .buip_fn_num         (buip_fn_num),
      .buip_data           (buip_data),        //Data*2 (per channel)

      .buip_tag_wr         (buip_tag_wr),      //TAG Write
      .buip_tag            (buip_tag_i),       //TAG Value

      .buip_io_wr          (buip_io_wr),       //IO Write
      .buip_io_rd          (buip_io_rd),       //IO Read
      .buip_ioadr          (buip_ioaddr),
      .buip_io_fn_num      (buip_io_fn_num),
      .buip_iodata         (buip_iodata),


      .buip_sop            (buip_sop /*indr_sop[0]*/),         //Start of Package
      .buip_eop            (buip_eop),         //End Of Package(per ch)                                        //Commands:
      .buip_rdy            (buip_rdy),                         //BUI Ready (currently unused).

      .buip_nposted_skip   (bui_nposted_skip),  // note NI that request was deleted due to max offset violation
      .buip_nposted_val    (bui_nposted_val),

  // TX ---
  //
      .hub_iodata          (hub2pcie_iodata ),            //Hub IORD Data/pe_do_reg
      .hub_iodata_rdy      (hub2pcie_iodata_val),         //Hub IORD Data is valid
      .hub_rdy             (hub2pcie_rdy),
      .hub_iordy           (hub2pcie_io_rdy),
      .hub_wr              (hub2pcie_wr),          //Hub Write /core_wr
      .hub_sof             (hub2pcie_sop),
      .hub_eof             (hub2pcie_eop),
      .hub_data            (hub2pcie_data),              //Hub Data /core_data
      .hub_tag             (hub2pcie_tag),             //Hub TAG /core_tag_o

      .rst_n_pipe          (rst_n_pipe),               //Program Reset
      .pe_fresp_ptr        (pe_fresp_ptr),             //Free_space Pointer
      .bui_rsp_mask        (bui_rsp_mask),


      .ihdl_64k_tick       (ihdl_64k_tick),            //core_clk:64k
      .ihdl_interrupt      (ihdl_interrupt),           //Interrupt_proc Request
      .ihdl_pfcnt_sclr     (ihdl_pfcnt_sclr),          //PerfCnt SyncReset
      .ihdl_pfcnt_en       (ihdl_pfcnt_en),            //PerfCnt Enable

      .buip_except_event   (buip_except_event),        //Exceptional Events
   //   .buip_ext_reg        (buip_ext_reg),             //Extention Register
      .buip_int            (bui_int),                  //BUI Interrupt(to PCIe)
      .pcie_int_ack        (pcie_int_ack),             //Interrupt Acknowledge


   //fetching DMA registers interface:
      .buip_fetch_rg       (buip_fetch_rg),
      .buip_fetch_rg_num   (buip_fetch_rg_num),
      .buip_fetch_fn_num   (buip_fetch_fn_num),
      .buip_fetch_rdy      (buip_fetch_rdy),
   //
   // MSIX interrupts:
      .int_msix_data       (int_msix_data),
      .int_msix_address    (int_msix_address),
      .int_msix_int        (int_msix_int),
      .int_msix_sent       (int_msix_sent),

 // Info from internal registers: -----------------------------
      .base_dma_addr       (base_dma_addr),             //DMA Address
      .max_offset          (max_offset),                // Max DMA offset
      .raw_addr_msk        (buip_raw_addr_msk),              // apperture for raw addr
//
      .bui_data_granul_64            (bui_data_granul_64),
      .buip_cmpl_receive_tout        (buip_cmpl_receive_tout),
      .buip_pfcnt_adr_err_cnt        (buip_pfcnt_adr_err_cnt),
      .buip_pfcnt_dmareadlatency_cnt (buip_pfcnt_dmareadlatency_cnt),
  //.base_credit_adr     (64'b0/*base_credit_adr*/),          //Credit Address
                                                        // For Credit Control:
      .credit_en           (credit_en),                //CCR enable
      .credit_delta        (credit_delta),             //0=64,1=128,2=256,3=448
      .credit_gran         (credit_gran),
                                                      // For TLP division (PCIE_TX):
      .max_tlp_size        (max_tlp_size),             //0=64,1=128,2=256,3=512

      .glb_sram_we         (glb_sram_we),              //Global SRAMWriteEnable
      .glb_sram_re         (glb_sram_re)               //Global SRAMReadEnable

   );


   bui_regs #(
      .SLOW_INT_NUM (SLOW_INT_NUM),
      .NUMVFSW      (NUMVFSW),
      .VF_MAX_NUM   (VF_MAX_NUM)
   )
   bui_regs (

      //---Sys. Interface
      .clk                  (core_clk),
      .rst_n                (rst_n_2buip),

      //---Bui interface
      .hub_io_wr            (hub_io_wr),
      .hub_io_rd            (hub_io_rd),
      .hub_io_data          (hub_io_data),
      .hub_bui_bcs          (hub_io_bcs [`BUI_SUBB_NUM]),
      .hub_io_addr          (hub_io_addr[SUBB_IOADDR_WIDTH-1:0]),
      .hub_io_fn_num        (hub_io_fn_num),

      .bui_csCBGRA          (bui_csCBGRA),
      .bui_csCBGRD          (bui_csCBGRD),

      .buir_iodata          (buir_iodata),
      .buir_io_ack          (buir_io_ack),

   //fetching registers interface:
      .buip_fetch_rg        (buip_fetch_rg),
      .buip_fetch_rg_num    (buip_fetch_rg_num),
      .buip_fetch_fn_num    (buip_fetch_fn_num),
      .buip_fetch_rdy       (buip_fetch_rdy),

      //---bui_pcie settings
      .buip_base_dma_addr   (base_dma_addr),       //DMA Address0
      .buip_max_offset      (max_offset),     //Maximum_offset_0

      .buip_raw_addr_msk    (buip_raw_addr_msk),

      .host_amo             (host_amo),

      .bui_data_granul_64            (bui_data_granul_64),
      .buip_cmpl_receive_tout        (buip_cmpl_receive_tout),
      .buip_pfcnt_adr_err_cnt        (buip_pfcnt_adr_err_cnt),
      .buip_pfcnt_dmareadlatency_cnt (buip_pfcnt_dmareadlatency_cnt),

      .bui_memerr                    (9'b0),       /// temporary!!!
/////// Direction registers

      .core_route_rg  (core_route_rg),
      .pcie_route_rg  (pcie_route_rg),
      .lf_route_rg    (lf_route_rg),
      .spl_route_rg   (spl_route_rg),
      .lf_dir_rg      (lf_dir_rg),
      .lf_io_dir_rg   (lf_io_dir_rg),

/////// ELB mux selector (MUX beetwen internal and external spl links)
      .spl_dir_rg     (spl_dir_rg),

      .core_raw_rdy    (core_raw_rdy_s),
      .ignore_raw_pack (ignore_raw_pack),    // o
      .ihdl_64k_tick   (ihdl_64k_tick),

//////////////////////////////////////////////

      // For Credit Control:
      .buip_credit_en      (credit_en ),
      .buip_credit_delta   (credit_delta),
      .buip_credit_gran    (credit_gran),

      .buip_max_tlp_size    (max_tlp_size),

      .buij_hbuf_ctrl_rg    (buij_hbuf_ctrl_rg),
      .spl_hbuf_ctrl_rg     (spl_hbuf_ctrl_rg),
/// To bui_pcie clock frequency ratio
      .buip_clk_sel         (hub_trn_ckf),
      .fixed_error          (buir_fixed_error),
      .fatal_error          (buir_fatal_error)

//---------------------------------------------
  //    .switch_lwca_wr             ( ),                   //output     [            1:0]
  //    .switch_rdreq_maxval_wr     ( ),                   //output
  //    .switch_srareg_wr           ( ),                   //output
  //    .switch_srdreg_wr           ( ),                   //output


//-----------------------------------------------
    );

//  LOW FREQUENCY INTERFACES MUX


   bui_lf_mux #(
      .ADDRW        (ADDRW),
      .IO_ADDRW     (IO_ADDRW),
      .SLOW_INT_NUM (SLOW_INT_NUM)
   )

   bui_lf_mux (

      .lf_dir_rg             (lf_dir_rg),
      .lf_io_dir_rg          (lf_io_dir_rg),

//////////// hub to LF MUX:
      .hub2lfmux_sop         (hub2lfmux_sop),
      .hub2lfmux_eop         (hub2lfmux_eop),
      .hub2lfmux_rdy         (hub2lfmux_rdy),
      .hub2lfmux_data        (hub2lfmux_data),
      .hub2lfmux_addr        (hub2lfmux_addr),
      .hub2lfmux_tag         (hub2lfmux_tag),
      .hub2lfmux_tag_wr      (hub2lfmux_tag_wr),

      .hub2lfmux_host_wr     (hub2lfmux_host_wr),
      .hub2lfmux_core_wr     (hub2lfmux_core_wr),


      .hub2lfmux_iodata      (hub2lfmux_iodata),
      .hub2lfmux_iodata_val  (hub2lfmux_iodata_val),
      .hub2lfmux_io_rdy      (hub2lfmux_io_rdy),

//////////  Low frequency interfaces to LF MUX:
      .lfint2lfmux_mem_wr    (lfint2lfmux_mem_wr),
      .lfint2lfmux_long_wr   (lfint2lfmux_long_wr),
      .lfint2lfmux_raw_wr    (lfint2lfmux_raw_wr),
      .lfint2lfmux_hdr_wr    (lfint2lfmux_hdr_wr),
      .lfint2lfmux_cmpl_wr   (lfint2lfmux_cmpl_wr),
      .lfint2lfmux_tag_wr    (lfint2lfmux_tag_wr),
      .lfint2lfmux_loop_wr   (lfint2lfmux_loop_wr),
      .lfint2lfmux_sop       (lfint2lfmux_sop),
      .lfint2lfmux_eop       (lfint2lfmux_eop),
      .lfint2lfmux_tag       (lfint2lfmux_tag),
      .lfint2lfmux_data      (lfint2lfmux_data),
      .lfint2lfmux_addr      (lfint2lfmux_addr),
      .lfint2lfmux_rdy       (lfint2lfmux_rdy),
      .lfint2lfmux_io_wr     (lfint2lfmux_io_wr),
      .lfint2lfmux_io_rd     (lfint2lfmux_io_rd),
      .lfint2lfmux_ioaddr    (lfint2lfmux_ioaddr),
      .lfint2lfmux_iodata    (lfint2lfmux_iodata),

/////////// MUX to HUB:

      .lfmux2hub_mem_wr        (lfmux2hub_mem_wr),
      .lfmux2hub_long_wr       (lfmux2hub_long_wr),
      .lfmux2hub_raw_wr        (lfmux2hub_raw_wr),
      .lfmux2hub_hdr_wr        (lfmux2hub_hdr_wr),
      .lfmux2hub_cmpl_wr       (lfmux2hub_cmpl_wr),
      .lfmux2hub_tag_wr        (lfmux2hub_tag_wr),
      .lfmux2hub_loop_wr       (lfmux2hub_loop_wr),
      .lfmux2hub_sop           (lfmux2hub_sop),
      .lfmux2hub_eop           (lfmux2hub_eop),
      .lfmux2hub_data          (lfmux2hub_data),
      .lfmux2hub_addr          (lfmux2hub_addr),
      .lfmux2hub_tag           (lfmux2hub_tag),
      .lfmux2hub_rdy           (lfmux2hub_rdy),
      .lfmux2hub_io_wr         (lfmux2hub_io_wr),
      .lfmux2hub_io_rd         (lfmux2hub_io_rd),
      .lfmux2hub_ioaddr        (lfmux2hub_ioaddr),
      .lfmux2hub_iodata        (lfmux2hub_iodata),
////////// MUX to Low frequency interfaces:

      .lfmux2lfint_sop         (lfmux2lfint_sop),
      .lfmux2lfint_eop         (lfmux2lfint_eop),
      .lfmux2lfint_rdy         (lfmux2lfint_rdy),
      .lfmux2lfint_data        (lfmux2lfint_data),
      .lfmux2lfint_addr        (lfmux2lfint_addr),
      .lfmux2lfint_tag         (lfmux2lfint_tag),
      .lfmux2lfint_tag_wr      (lfmux2lfint_tag_wr),
      .lfmux2lfint_host_wr     (lfmux2lfint_host_wr),
      .lfmux2lfint_core_wr     (lfmux2lfint_core_wr),


      .lfmux2lfint_iodata      (lfmux2lfint_iodata),
      .lfmux2lfint_iodata_val  (lfmux2lfint_iodata_val),
      .lfmux2lfint_io_rdy      (lfmux2lfint_io_rdy)

   );


   assign lfint2lfmux_mem_wr  = { {WR_WIDTH{cbg_mem_wr}}, buij_mem_wr};
   assign lfint2lfmux_long_wr = {       {WR_WIDTH{1'b0}}, buij_long_wr};
   assign lfint2lfmux_raw_wr  = {       {WR_WIDTH{1'b0}}, buij_raw_wr};
   assign lfint2lfmux_hdr_wr  = {                   1'b0, buij_hdr_wr};
   assign lfint2lfmux_cmpl_wr = {       {WR_WIDTH{1'b0}}, buij_cmpl_wr};
   assign lfint2lfmux_tag_wr  = {                   1'b0, buij_tag_wr};
   assign lfint2lfmux_loop_wr = {       {WR_WIDTH{1'b0}}, buij_buij_wr};
   assign lfint2lfmux_sop     = {    {WR_WIDTH{cbg_sop}}, buij_sop};
   assign lfint2lfmux_eop     = {    {WR_WIDTH{cbg_eop}}, buij_eop};
   assign lfint2lfmux_data    = {               cbg_data, buij_data};
   assign lfint2lfmux_tag     = {                cbg_tag, buij_tag_i};
   assign lfint2lfmux_addr    = {    {WR_WIDTH{cbg_adr}}, buij_addr};
   assign lfint2lfmux_rdy     = {        1'b1/*cbg_rdy*/, buij_rdy};
   assign lfint2lfmux_io_wr   = {                   1'b0, buij_io_wr};
   assign lfint2lfmux_io_rd   = {                   1'b0, buij_io_rd};
   assign lfint2lfmux_ioaddr  = {       {IO_ADDRW{1'b0}}, buij_io_addr};
   assign lfint2lfmux_iodata  = {          {RGDBW{1'b0}}, buij_io_data};


   wire [WR_WIDTH -1:0] lfmux2buij_host_wr    = lfmux2lfint_host_wr    [WR_WIDTH*0 +: WR_WIDTH];
   wire [WR_WIDTH -1:0] lfmux2buij_core_wr    = lfmux2lfint_core_wr    [WR_WIDTH*0 +: WR_WIDTH];
   wire [RDBW     -1:0] lfmux2buij_data       = lfmux2lfint_data       [RDBW*0  +: RDBW];
   wire                 lfmux2buij_rdy        = lfmux2lfint_rdy        [0];
   wire [RGDBW    -1:0] lfmux2buij_iodata     = lfmux2lfint_iodata     [RGDBW*0 +: RGDBW];
   wire                 lfmux2buij_iodata_val = lfmux2lfint_iodata_val [0];
   wire                 lfmux2buij_io_rdy     = lfmux2lfint_io_rdy     [0];



   bui_uexb #(
      .BUI_ADDR_WTH (ADDRW),
      .IO_ADDR_WTH  (IO_ADDRW),
      .JTAG_EN      (1)
   )
      bui_jtag  (
         .clk                (core_clk),
         .rst_n              (rst_n_2bui),
         .glb_sram_we        (glb_sram_we),     //global sram enable write
         .glb_sram_re        (glb_sram_re),     //global sram enable read signal

      //--- JTAG ADAPTER INTERFACE, Interface
      //
         .sint_enabled_2uexb ( 1'b1),      // elb on/off switch
         .sint_addr_2uexb    (jtag_addr_2buij),         // address of service processor accessible regs
         .sint_rd_2uexb      (jtag_rd_2buij),           // converted to pci_clk read request
         .sint_wr_2uexb      (jtag_wr_2buij),           // Bus to IP write enable
         .sint_data_2uexb    (jtag_data_2buij),         // Bus to IP data bus

         .uexb_data_2sint    (buij_data_2jtag),         // IP to Bus data bus
         .uexb_ack_2sint     (buij_ack_2jtag),          // IP to Bus read transfer acknowledgement

    //--- .Input (Input),(elect) interface
    //
         .host_wr            (lfmux2buij_host_wr),
         .core_wr            (lfmux2buij_core_wr),
         //.core_tag_o         (hub2buij_tag),             // Request ID for read operations.
         .hub_data           (lfmux2buij_data),
         .uexb_rdy           (buij_rdy),
         .hub_io_data        (lfmux2buij_iodata),
         .hub_io_data_valid  (lfmux2buij_iodata_val),

    //--- .Host (Host), buf control register
    //
         .hbuf_control_rg    (buij_hbuf_ctrl_rg),


    //--- .Output (Output),(inject) interface with Hub
    //--- .IO (IO), Hub
         .uexb_io_wr         (buij_io_wr),       //IO Write      /BAR 1
         .uexb_io_rd         (buij_io_rd),       //IO Read       /BAR 1
         .uexb_io_addr       (buij_io_addr),     //IO Address (7 bits)
         .uexb_io_data       (buij_io_data),     //IO Data (32 bits)
         .hub_io_rdy         (lfmux2buij_io_rdy),

         .uexb_hdr_wr        (buij_hdr_wr),      //Head Write    /BAR 2,3
         .uexb_mem_wr        (buij_mem_wr),      //Mem Write     /BAR 0
         .uexb_raw_wr        (buij_raw_wr),         //RAW           /BAR 2,3
         .uexb_long_wr       (buij_long_wr),     //MemLong Write /BAR 4
         .uexb_cmpl_wr       (buij_cmpl_wr),     //Completion Write
         .uexb_uexb_wr       (buij_buij_wr),

         .uexb_addr          (buij_addr),        //Address*2 (per channel)
         .uexb_data          (buij_data),        //Data*2 (per channel)
         .uexb_tag_wr        (buij_tag_wr),      //TAG Write
         .uexb_tag_i         (buij_tag_i),       //TAG Value

         .uexb_sop           (buij_sop),         //Start of Package
         .uexb_eop           (buij_eop),         //End Of Package(per ch)
         .hub_rdy            (lfmux2buij_rdy),         //Packet Hub Ready

    //---.Exeptions (Exeptions),
         .uexb_except_event  (buij_except_event)
   );


   wire            lfmux2cbg_rdy     =  lfmux2lfint_rdy     [1];
   wire            lfmux2cbg_core_wr = |lfmux2lfint_core_wr [WR_WIDTH*1 +: WR_WIDTH];
   wire            lfmux2cbg_sop     = |lfmux2lfint_sop     [WR_WIDTH*1 +: WR_WIDTH];
   wire            lfmux2cbg_eop     = |lfmux2lfint_eop     [WR_WIDTH*1 +: WR_WIDTH];
   wire [RDBW-1:0] lfmux2cbg_data    =  lfmux2lfint_data    [RDBW*1     +: RDBW];

   router_core_bist #(
      .ADDR_W   (ADDRW),
      .TAGW     (TAGW),
      .PCIE_NUM (PCIE_NUM)
   )

   router_core_bist
   (
    //--- System interface
    //
      .clk            (core_clk),
      .rst_n          (rst_n_2bui),


   //--- Bui interface
   //
      .bui_io_wr      (hub_io_wr),
      .bui_io_rd      (hub_io_rd),
      .bui_io_data    (hub_io_data),
      .bui_csCBGRA    (bui_csCBGRA),
      .bui_csCBGRD    (bui_csCBGRD),
      .cbg_io_data    (cbg_iodata),
      .cbg_io_data_wr (cbg_io_ack),

   //--- Core interface
   //---
   //--- Inject interface
      .cbg_mem_wr     (cbg_mem_wr),
      .cbg_sop        (cbg_sop),
      .cbg_eop        (cbg_eop),
      .cbg_data       (cbg_data),
      .cbg_tag        (cbg_tag),
      .cbg_adr        (cbg_adr),
      .core_rdy       (lfmux2cbg_rdy),
      .free_space_cnt (pe_fresp_ptr [FSAW*PEPQ*PCIE_NUM +: FSAW*((PEPQ > 4) ? 4 : PEPQ)]),
      .core_dir       (cbg_core_dir),// == 1 if core BIST traffic is routed to core
   //--- Eject interface
      .core_wr        (lfmux2cbg_core_wr),
      .core_wr_sop    (lfmux2cbg_sop),
      .core_wr_eop    (lfmux2cbg_eop),
      .core_data      (lfmux2cbg_data),
      .cbg_rdy        (cbg_rdy)

  );



////////////// ELB MUX! /////////////

   assign elb_mux_enabled_2spl = spl_dir_rg[0] ? elbi_enabled_2spl : elba_enabled_2spl;
   assign elb_mux_addr_2spl    = spl_dir_rg[0] ? elbi_addr_2spl    : elba_addr_2spl;
   assign elb_mux_rd_2spl      = spl_dir_rg[0] ? elbi_rd_2spl      : elba_rd_2spl;
   assign elb_mux_wr_2spl      = spl_dir_rg[0] ? elbi_wr_2spl      : elba_wr_2spl;
   assign elb_mux_data_2spl    = spl_dir_rg[0] ? elbi_data_2spl    : elba_data_2spl;

   assign spl_data_2elba       = spl_dir_rg[0] ? {SPL_DW{1'b0}}    : spl_data_2elb_mux;
   assign spl_ack_2elba        = spl_dir_rg[0] ? 1'b0              : spl_ack_2elb_mux;
   assign spl_data_2elbi       = spl_dir_rg[0] ? spl_data_2elb_mux : {SPL_DW{1'b0}};
   assign spl_ack_2elbi        = spl_dir_rg[0] ? spl_ack_2elb_mux  : 1'b0;



   bui_uexb # (
      .BUI_ADDR_WTH (ADDRW),
      .IO_ADDR_WTH  (IO_ADDRW),
      .JTAG_EN      (0)
   )

   bui_spl (

      //--- System Interface
      //
      .clk                (core_clk),
      .rst_n              (rst_n_2bui),
      .glb_sram_we        (glb_sram_we),     //global sram enable write
      .glb_sram_re        (glb_sram_re),     //global sram enable read signal


      //--- .ELB (ELB), Interface
      //
      .sint_enabled_2uexb (elb_mux_enabled_2spl),      // elb on/off switch
      .sint_addr_2uexb    (elb_mux_addr_2spl),         // address of service processor accessible regs
      .sint_rd_2uexb      (elb_mux_rd_2spl),           // converted to pci_clk read request
      .sint_wr_2uexb      (elb_mux_wr_2spl),           // Bus to IP write enable
      .sint_data_2uexb    (elb_mux_data_2spl),         // Bus to IP data bus

      .uexb_data_2sint    (spl_data_2elb_mux),         // IP to Bus data bus
      .uexb_ack_2sint     (spl_ack_2elb_mux),          // IP to Bus read transfer acknowledgement
   //.spl_irq_2elba (spl_irq_2elba),          // IP to Bus interrupt event strob

    //--- .Input (Input),(elect) interface
    //
      .host_wr            (hub2spl_host_wr),
      .core_wr            (hub2spl_core_wr),
     // .core_tag_o         (hub2spl_tag),             // Request ID for read operations.
      .hub_data           (hub2spl_data),
      .uexb_rdy           (spl_rdy),
      .hub_io_data        (hub2spl_iodata),
      .hub_io_data_valid  (hub2spl_iodata_val),

    //--- .Host (Host), buf control register
    //
      .hbuf_control_rg    (spl_hbuf_ctrl_rg),


    //--- .Output (Output),(inject) interface with Hub
    //--- .IO (IO), Hub
      .uexb_io_wr         (spl_io_wr),       //IO Write      /BAR 1
      .uexb_io_rd         (spl_io_rd),       //IO Read       /BAR 1
      .uexb_io_addr       (spl_io_addr),     //IO Address (7 bits)
      .uexb_io_data       (spl_io_data),     //IO Data (32 bits)
      .hub_io_rdy         (hub2spl_io_rdy),

      .uexb_hdr_wr        (spl_hdr_wr),      //Head Write    /BAR 2,3
      .uexb_mem_wr        (spl_mem_wr),      //Mem Write     /BAR 0
      .uexb_raw_wr        (spl_raw_wr),         //RAW           /BAR 2,3
      .uexb_long_wr       (spl_long_wr),     //MemLong Write /BAR 4
      .uexb_cmpl_wr       (spl_cmpl_wr),     //Completion Write
      .uexb_uexb_wr       (spl_spl_wr),      //loopback

      .uexb_addr          (spl_addr),        //Address*2 (per channel)
      .uexb_data          (spl_data),        //Data*2 (per channel)
      .uexb_tag_wr        (spl_tag_wr),      //TAG Write
      .uexb_tag_i         (spl_tag_i),       //TAG Value

      .uexb_sop           (spl_sop),         //Start of Package
      .uexb_eop           (spl_eop),         //End Of Package(per ch)
      .hub_rdy            (hub2spl_rdy),         //Packet Hub Ready

    //---.Exeptions (Exeptions),
      .uexb_except_event  (spl_except_event)
   );

   assign spl_irq_2elba = 1'b0;        // temp!!!

bui_msix_table #(
   .NUMVFSW       (NUMVFSW),
   .RGDBW         (RGDBW),
   .IO_ADDRW      (IO_ADDRW),
   .EXC_VEC_PTR_W (EXC_VEC_PTR_W),
   .VF_MAX_NUM    (VF_MAX_NUM-1)
)

buip_msix_table (
   
   .clk                  (core_clk),
   .rst_n                (rst_n_2bui),
   
   .hub_io_wr            (hub_io_wr),
   .hub_io_rd            (hub_io_rd),
   .hub_io_data          (hub_io_data),

   .hub_io_addr          (hub_io_addr),
   .hub_io_fn_num        (hub_io_fn_num),

   .msix_iodata          (msix_iodata), ////
   .msix_io_ack          (msix_io_ack),
   .ihdl_interrupt       (ihdl_interrupt),
   .ihdl_except_num      (ihdl_except_num),

//==== MSI interface:
   .int_msi_addr               (0),
   .int_msi_data               (0),
   .int_msi_enable             (0),
   .int_msi_mask               (0),
   .int_msi_mm                 (0),
   .int_msi_pba                (),
   .int_msi_update_pba         (),

//====MSIX interface:
   .int_msix_enable            (int_msix_enable),
   .int_msix_mask              (int_msix_mask),
   .int_msix_vf_enable         (int_msix_vf_enable),
   .int_msix_vf_mask           (int_msix_vf_mask),

//=== issue interrupts interface:
   .issue_int_address          (int_msix_address),
   .issue_int_data             (int_msix_data),
   .issue_int_val              (int_msix_int),
   .issue_int_ack              (int_msix_sent),
   .int_msix_fail              (1'b0)
);




// Chipscope insertion for debug
`ifdef BUI_CHIPSCOPE_ENABLE

   generate if (PCIE_NUM == 0) begin : insert_chipscope

      wire [35:0] CONTROL;

      wire [1023:0] data;

      chipscope_icon chipscope_icon(
         .CONTROL0 (CONTROL)
      );

      assign data = {
                   bui_mem_wr,     //--- 709:708  Memory Write
                   bui_long_wr,    //--- 707:706  Memory Long Write
                   bui_cmpl_wr,    //--- 705:704  Completion Write
                   bui_raw_wr,     //--- 703:702
                   bui_raw_hdr_wr, //--- 701
                   bui_data,       //--- 700:573  Data
                   bui_addr,       //--- 572:531
                   bui_fn_num,     //--- 530:523  Virtual Function number.
                   pcie_numvfs,    //--- 522:515
                   core_tag_o,     //--- 514:510  TAG
                   core_io_data,   //--- 509:478  IORD Data
                   core_io_ack,    //--- 477
                   bui_io_fn_num,  //--- 476:469
                   bui_io_wr,      //--- 468      IO Write
                   bui_io_rd,      //--- 467      IO Read
                   bui_io_data,    //--- 466:435
                   bui_io_addr,    //--- 434:413
                   bui_bcs,        //--- 412:285  Chip select for each block
                   bui_io_ack,     //--- 284      notify wrapper about ending of current io request
//-----------------------------------------------------------------------------------------
                   rst_n_2buip,    //--- 283
                   rst_n_2bui,     //--- 282
                   rst_n_pipe,     //--- 281
//-----------------------------------------------------------------------------------------
                   trn_td,         //--- 280:153
                   trn_trem,       //--- 152:151
                   trn_tsof,       //--- 150
                   trn_teof,       //--- 149
                   trn_tsrc_rdy,   //--- 148
                   trn_tdst_rdy,   //--- 147
                   trn_tdst_dsc,   //--- 146
                   trn_tsrc_dsc,   //--- 145
                   trn_tnp_ok,     //--- 144
//-----------------------------------------------------------------------------------------
                   trn_rsrc_rdy,   //--- 143
                   trn_rsrc_dsc,   //--- 142
                   trn_rerr_fwd,   //--- 141
                   trn_recrc_err,  //--- 140
                   trn_rsof,       //--- 139
                   trn_reof,       //--- 138
                   trn_rrem,       //--- 137:136
                   trn_rd,         //--- 135:8
                   trn_rbar_hit,   //--- 7:1
                   trn_rdst_rdy};  //--- 0
//----------------------------------------------------------------------------------------

   chipscope_ila chipscope_ila(
      .CONTROL (CONTROL),
      .CLK     (core_clk),
      .DATA    (data),
      .TRIG0   ( (trn_rsrc_rdy && trn_rsof) ),
      .TRIG1   ( (trn_tsrc_rdy && trn_tsof) ),
      .TRIG2   ( trn_rbar_hit[1]),
      .TRIG3   ( rst_n_2buip || rst_n_2bui || rst_n_pipe)
   );

   end endgenerate

`endif

endmodule

`endif

