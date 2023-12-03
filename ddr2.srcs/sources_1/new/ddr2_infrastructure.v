`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.12.2023 23:28:25
// Design Name: 
// Module Name: ddr2_infrastructure
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
module ddr2_infrastructure #
  (
   parameter RST_ACT_LOW  = 1
   )
  (
   input  clk0,
   input  clk90,
   input  clk200,
   input  clkdiv0,
   input  locked,
   input  sys_rst_n,
   input  idelay_ctrl_rdy,
   output rst0,
   output rst90,
   output rst200,
   output rstdiv0
   );
 
  // # of clock cycles to delay deassertion of reset. Needs to be a fairly
  // high number not so much for metastability protection, but to give time
  // for reset (i.e. stable clock cycles) to propagate through all state
  // machines and to all control signals (i.e. not all control signals have
  // resets, instead they rely on base state logic being reset, and the effect
  // of that reset propagating through the logic). Need this because we may not
  // be getting stable clock cycles while reset asserted (i.e. since reset
  // depends on DCM lock status)
  localparam RST_SYNC_NUM = 25;
 
  reg [RST_SYNC_NUM-1:0]     rst0_sync_r    /* synthesis syn_maxfan = 10 */;
  reg [RST_SYNC_NUM-1:0]     rst200_sync_r  /* synthesis syn_maxfan = 10 */;
  reg [RST_SYNC_NUM-1:0]     rst90_sync_r   /* synthesis syn_maxfan = 10 */;
  reg [(RST_SYNC_NUM/2)-1:0] rstdiv0_sync_r /* synthesis syn_maxfan = 10 */;
  wire                       rst_tmp;
  wire                       sys_clk_ibufg;
  wire                       sys_rst;
 
  assign sys_rst = RST_ACT_LOW ? ~sys_rst_n: sys_rst_n;
 
  //***************************************************************************
  // Reset synchronization
  // NOTES:
  //   1. shut down the whole operation if the DCM hasn't yet locked (and by
  //      inference, this means that external SYS_RST_IN has been asserted -
  //      DCM deasserts LOCKED as soon as SYS_RST_IN asserted)
  //   2. In the case of all resets except rst200, also assert reset if the
  //      IDELAY master controller is not yet ready
  //   3. asynchronously assert reset. This was we can assert reset even if
  //      there is no clock (needed for things like 3-stating output buffers).
  //      reset deassertion is synchronous.
  //***************************************************************************
 
  assign rst_tmp = sys_rst | ~locked | ~idelay_ctrl_rdy;
 
  // synthesis attribute max_fanout of rst0_sync_r is 10
  always @(posedge clk0 or posedge rst_tmp)
    if (rst_tmp)
      rst0_sync_r <= {RST_SYNC_NUM{1'b1}};
    else
      // logical left shift by one (pads with 0)
      rst0_sync_r <= rst0_sync_r << 1;
 
  // synthesis attribute max_fanout of rstdiv0_sync_r is 10
  always @(posedge clkdiv0 or posedge rst_tmp)
    if (rst_tmp)
      rstdiv0_sync_r <= {(RST_SYNC_NUM/2){1'b1}};
    else
      // logical left shift by one (pads with 0)
      rstdiv0_sync_r <= rstdiv0_sync_r << 1;
 
  // synthesis attribute max_fanout of rst90_sync_r is 10
  always @(posedge clk90 or posedge rst_tmp)
    if (rst_tmp)
      rst90_sync_r <= {RST_SYNC_NUM{1'b1}};
    else
      rst90_sync_r <= rst90_sync_r << 1;
 
  // make sure CLK200 doesn't depend on IDELAY_CTRL_RDY, else chicken n' egg
   // synthesis attribute max_fanout of rst200_sync_r is 10
  always @(posedge clk200 or negedge locked)
    if (!locked)
      rst200_sync_r <= {RST_SYNC_NUM{1'b1}};
    else
      rst200_sync_r <= rst200_sync_r << 1;
 
  assign rst0    = rst0_sync_r[RST_SYNC_NUM-1];
  assign rst90   = rst90_sync_r[RST_SYNC_NUM-1];
  assign rst200  = rst200_sync_r[RST_SYNC_NUM-1];
  assign rstdiv0 = rstdiv0_sync_r[(RST_SYNC_NUM/2)-1];
 
endmodule