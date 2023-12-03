`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.12.2023 00:33:16
// Design Name: 
// Module Name: ddr2_usr_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module ddr2_usr_top #
  (
   // Following parameters are for 72-bit RDIMM design (for ML561 Reference 
   // board design). Actual values may be different. Actual parameters values 
   // are passed from design top module MEMCtrl module. Please refer to
   // the MEMCtrl module for actual values.
   parameter BANK_WIDTH     = 2,
   parameter CS_BITS        = 0,
   parameter COL_WIDTH      = 10,
   parameter DQ_WIDTH       = 72,
   parameter DQ_PER_DQS     = 8,
   parameter APPDATA_WIDTH  = 144,
   parameter ECC_ENABLE     = 0,
   parameter DQS_WIDTH      = 9,
   parameter ROW_WIDTH      = 14
   )
  (
   input                                     clk0,
   input                                     clk90,
   input                                     rst0,
   input [DQ_WIDTH-1:0]                      rd_data_in_rise,
   input [DQ_WIDTH-1:0]                      rd_data_in_fall,
   input [DQS_WIDTH-1:0]                     phy_calib_rden,
   input [DQS_WIDTH-1:0]                     phy_calib_rden_sel,
   output                                    rd_data_valid,
   output [APPDATA_WIDTH-1:0]                rd_data_fifo_out,
   input [2:0]                               app_af_cmd,
   input [30:0]                              app_af_addr,
   input                                     app_af_wren,
   input                                     ctrl_af_rden,
   output [2:0]                              af_cmd,
   output [30:0]                             af_addr,
   output                                    af_empty,
   output                                    app_af_afull,
   output [1:0]                              rd_ecc_error,
   input                                     app_wdf_wren,
   input [APPDATA_WIDTH-1:0]                 app_wdf_data,
   input [(APPDATA_WIDTH/8)-1:0]             app_wdf_mask_data,
   input                                     wdf_rden,
   output                                    app_wdf_afull,
   output [(2*DQ_WIDTH)-1:0]                 wdf_data,
   output [((2*DQ_WIDTH)/8)-1:0]             wdf_mask_data
   );
 
  wire [(APPDATA_WIDTH/2)-1:0] i_rd_data_fifo_out_fall;
  wire [(APPDATA_WIDTH/2)-1:0] i_rd_data_fifo_out_rise;
 
  //***************************************************************************
 
  assign rd_data_fifo_out = {i_rd_data_fifo_out_fall,
                             i_rd_data_fifo_out_rise};
 
  // read data de-skew and ECC calculation
  ddr2_usr_rd #
    (
     .DQ_PER_DQS    (DQ_PER_DQS),
     .ECC_ENABLE    (ECC_ENABLE),
     .APPDATA_WIDTH (APPDATA_WIDTH),
     .DQS_WIDTH     (DQS_WIDTH)
     )
     u_usr_rd
      (
       .clk0             (clk0),
       .rst0             (rst0),
       .rd_data_in_rise  (rd_data_in_rise),
       .rd_data_in_fall  (rd_data_in_fall),
       .rd_ecc_error     (rd_ecc_error),
       .ctrl_rden        (phy_calib_rden),
       .ctrl_rden_sel    (phy_calib_rden_sel),
       .rd_data_valid    (rd_data_valid),
       .rd_data_out_rise (i_rd_data_fifo_out_rise),
       .rd_data_out_fall (i_rd_data_fifo_out_fall)
       );
 
  // Command/Addres FIFO
  ddr2_usr_addr_fifo #
    (
     .BANK_WIDTH (BANK_WIDTH),
     .COL_WIDTH  (COL_WIDTH),
     .CS_BITS    (CS_BITS),
     .ROW_WIDTH  (ROW_WIDTH)
     )
     u_usr_addr_fifo
      (
       .clk0         (clk0),
       .rst0         (rst0),
       .app_af_cmd   (app_af_cmd),
       .app_af_addr  (app_af_addr),
       .app_af_wren  (app_af_wren),
       .ctrl_af_rden (ctrl_af_rden),
       .af_cmd       (af_cmd),
       .af_addr      (af_addr),
       .af_empty     (af_empty),
       .app_af_afull (app_af_afull)
       );
 
  ddr2_usr_wr #
    (
     .BANK_WIDTH    (BANK_WIDTH),
     .COL_WIDTH     (COL_WIDTH),
     .CS_BITS       (CS_BITS),
     .DQ_WIDTH      (DQ_WIDTH),
     .APPDATA_WIDTH (APPDATA_WIDTH),
     .ECC_ENABLE    (ECC_ENABLE),
     .ROW_WIDTH     (ROW_WIDTH)
     )
    u_usr_wr
      (
       .clk0              (clk0),
       .clk90             (clk90),
       .rst0              (rst0),
       .app_wdf_wren      (app_wdf_wren),
       .app_wdf_data      (app_wdf_data),
       .app_wdf_mask_data (app_wdf_mask_data),
       .wdf_rden          (wdf_rden),
       .app_wdf_afull     (app_wdf_afull),
       .wdf_data          (wdf_data),
       .wdf_mask_data     (wdf_mask_data)
       );
 
endmodule
