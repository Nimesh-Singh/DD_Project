module ddr2_phy_dm_iob
  (
   input  clk90,
   input  dm_ce,
   input  mask_data_rise,
   input  mask_data_fall,
   output ddr_dm
   );
 
  wire    dm_out;
  wire    dm_ce_r;
 
  FDRSE_1 u_dm_ce
    (
     .Q    (dm_ce_r),
     .C    (clk90),
     .CE   (1'b1),
     .D    (dm_ce),
     .R   (1'b0),
     .S   (1'b0)
     ) /* synthesis syn_preserve=1 */;
 
  ODDR #
    (
     .SRTYPE("SYNC"),
     .DDR_CLK_EDGE("SAME_EDGE")
     )
    u_oddr_dm
      (
       .Q  (dm_out),
       .C  (clk90),
       .CE (dm_ce_r),
       .D1 (mask_data_rise),
       .D2 (mask_data_fall),
       .R  (1'b0),
       .S  (1'b0)
       );
 
  OBUF u_obuf_dm
    (
     .I (dm_out),
     .O (ddr_dm)
     );
 
endmodule