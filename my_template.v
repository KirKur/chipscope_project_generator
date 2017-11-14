output [                 1:0] bui_mem_wr
output [                 1:0] bui_long_wr
output [                 1:0] bui_cmpl_wr
output [                 1:0] bui_raw_wr
output                        bui_raw_hdr_wr
output [RDBW            -1:0] bui_data
output [ADDRW*2         -1:0] bui_addr
output [NUMVFSW         -1:0] bui_fn_num
input [NUMVFSW          -1:0] pcie_numvfs
input  [TAGW            -1:0] core_tag_o
input  [RGDBW           -1:0] core_io_data
input                         core_io_ack
output [NUMVFSW         -1:0] bui_io_fn_num
output                        bui_io_wr
output                        bui_io_rd
output [RGDBW           -1:0] bui_io_data
output [IO_ADDRW        -1:0] bui_io_addr
output [SUBB_CS_WIDTH   -1:0] bui_bcs
output                        bui_io_ack
input                                     rst_n_2buip
input                                     rst_n_2bui
input                                     rst_n_pipe
output [RDBW                        -1:0] trn_td
output [REMW                        -1:0] trn_trem
output                                    trn_tsof
output                                    trn_teof
output                                    trn_tsrc_rdy
input                                     trn_tdst_rdy
input                                     trn_tdst_dsc
output                                    trn_tsrc_dsc
input                                     trn_tnp_ok
input                                     trn_rsrc_rdy
input                                     trn_rsrc_dsc
input                                     trn_rerr_fwd
input                                     trn_recrc_err
input                                     trn_rsof
input                                     trn_reof
input [REMW                         -1:0] trn_rrem
input [RDBW                         -1:0] trn_rd
input [BARW                         -1:0] trn_rbar_hit
output                                    trn_rdst_rdy

      chipscope_icon chipscope_icon(
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
