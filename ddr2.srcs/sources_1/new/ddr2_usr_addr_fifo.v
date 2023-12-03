module ddr2_usr_addr_fifo #
  (
   // Following parameters are for 72-bit RDIMM design (for ML561 Reference 
   // board design). Actual values may be different. Actual parameters values 
   // are passed from design top module MEMCtrl module. Please refer to
   // the MEMCtrl module for actual values.
   parameter BANK_WIDTH    = 2,
   parameter COL_WIDTH     = 10,
   parameter CS_BITS       = 0,
   parameter ROW_WIDTH     = 14
   )
  (
   input          clk0,
   input          rst0,
   input [2:0]    app_af_cmd,
   input [30:0]   app_af_addr,
   input          app_af_wren,
   input          ctrl_af_rden,
   output [2:0]   af_cmd,
   output [30:0]  af_addr,
   output         af_empty,
   output         app_af_afull
   );
 
  wire [35:0]     fifo_data_out;
   reg            rst_r;
 
 
  always @(posedge clk0)
     rst_r <= rst0;
 
 
  //***************************************************************************
 
  assign af_cmd      = fifo_data_out[33:31];
  assign af_addr     = fifo_data_out[30:0];
 
  //***************************************************************************
 
  FIFO36 #
    (
     .ALMOST_EMPTY_OFFSET     (13'h0007),
     .ALMOST_FULL_OFFSET      (13'h000F),
     .DATA_WIDTH              (36),
     .DO_REG                  (1),
     .EN_SYN                  ("TRUE"),
     .FIRST_WORD_FALL_THROUGH ("FALSE")
     )
    u_af
      (
       .ALMOSTEMPTY (),
       .ALMOSTFULL  (app_af_afull),
       .DO          (fifo_data_out[31:0]),
       .DOP         (fifo_data_out[35:32]),
       .EMPTY       (af_empty),
       .FULL        (),
       .RDCOUNT     (),
       .RDERR       (),
       .WRCOUNT     (),
       .WRERR       (),
       .DI          ({app_af_cmd[0],app_af_addr}),
       .DIP         ({2'b00,app_af_cmd[2:1]}),
       .RDCLK       (clk0),
       .RDEN        (ctrl_af_rden),
       .RST         (rst_r),
       .WRCLK       (clk0),
       .WREN        (app_af_wren)
       );
 
endmodule