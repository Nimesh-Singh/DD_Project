`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.12.2023 23:31:02
// Design Name: 
// Module Name: ddr2_chipscope
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

module icon4 
  (
      control0,
      control1,
      control2,
      control3
  )
  /* synthesis syn_black_box syn_noprune = 1 */;
  output [35:0] control0;
  output [35:0] control1;
  output [35:0] control2;
  output [35:0] control3;
endmodule
 
module vio_async_in192
  (
    control,
    async_in
  )
  /* synthesis syn_black_box syn_noprune = 1 */;
  input  [35:0] control;
  input  [191:0] async_in;
endmodule
 
module vio_async_in96
  (
    control,
    async_in
  )
  /* synthesis syn_black_box syn_noprune = 1 */;
  input  [35:0] control;
  input  [95:0] async_in;
endmodule
 
module vio_async_in100
  (
    control,
    async_in
  )
  /* synthesis syn_black_box syn_noprune = 1 */;
  input  [35:0] control;
  input  [99:0] async_in;
endmodule
 
module vio_sync_out32
  (
    control,
    clk,
    sync_out
  )
  /* synthesis syn_black_box syn_noprune = 1 */;
  input  [35:0] control;
  input  clk;
  output [31:0] sync_out;
endmodule
