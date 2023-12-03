module ddr2_tb_test_gen #
  (
   // Following parameters are for 72-bit RDIMM design (for ML561 Reference 
   // board design). Actual values may be different. Actual parameters values 
   // are passed from design top module MEMCtrl module. Please refer to
   // the MEMCtrl module for actual values.
   parameter BANK_WIDTH    = 2,
   parameter COL_WIDTH     = 10,
   parameter DM_WIDTH      = 9,
   parameter DQ_WIDTH      = 72,
   parameter APPDATA_WIDTH = 144,
   parameter ECC_ENABLE    = 0,
   parameter ROW_WIDTH     = 14
   )
  (
   input                                  clk,
   input                                  rst,
   input                                  wr_addr_en,
   input                                  wr_data_en,
   input                                  rd_data_valid,
   output                                 app_af_wren,
   output [2:0]                           app_af_cmd,
   output [30:0]                          app_af_addr,
   output                                 app_wdf_wren,
   output [APPDATA_WIDTH-1:0]             app_wdf_data,
   output [(APPDATA_WIDTH/8)-1:0]         app_wdf_mask_data,
   output [APPDATA_WIDTH-1:0]             app_cmp_data
   );
 
  //***************************************************************************
 
  ddr2_tb_test_addr_gen #
    (
     .BANK_WIDTH (BANK_WIDTH),
     .COL_WIDTH  (COL_WIDTH),
     .ROW_WIDTH  (ROW_WIDTH)
     )
    u_addr_gen
      (
       .clk         (clk),
       .rst         (rst),
       .wr_addr_en  (wr_addr_en),
       .app_af_cmd  (app_af_cmd),
       .app_af_addr (app_af_addr),
       .app_af_wren (app_af_wren)
       );
 
  ddr2_tb_test_data_gen #
    (
     .DM_WIDTH      (DM_WIDTH),
     .DQ_WIDTH      (DQ_WIDTH),
     .APPDATA_WIDTH (APPDATA_WIDTH),
     .ECC_ENABLE    (ECC_ENABLE)
     )
    u_data_gen
      (
       .clk               (clk),
       .rst               (rst),
       .wr_data_en        (wr_data_en),
       .rd_data_valid     (rd_data_valid),
       .app_wdf_wren      (app_wdf_wren),
       .app_wdf_data      (app_wdf_data),
       .app_wdf_mask_data (app_wdf_mask_data),
       .app_cmp_data      (app_cmp_data)
       );
 
endmodule