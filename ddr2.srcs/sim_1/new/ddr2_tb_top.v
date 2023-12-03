`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.12.2023 01:02:44
// Design Name: 
// Module Name: ddr2_tb_top
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
module ddr2_tb_top #
  (
   // Following parameters are for 72-bit RDIMM design (for ML561 Reference 
   // board design). Actual values may be different. Actual parameters values 
   // are passed from design top module MEMCtrl module. Please refer to
   // the MEMCtrl module for actual values.
   parameter BANK_WIDTH    = 2,
   parameter COL_WIDTH     = 10,
   parameter DM_WIDTH      = 9,
   parameter DQ_WIDTH      = 72,
   parameter ROW_WIDTH     = 14,
   parameter APPDATA_WIDTH = 144,
   parameter ECC_ENABLE    = 0,
   parameter BURST_LEN     = 4
   )
  (
   input                                  clk0,
   input                                  rst0,
   input                                  app_af_afull,
   input                                  app_wdf_afull,
   input                                  rd_data_valid,
   input [APPDATA_WIDTH-1:0]              rd_data_fifo_out,
   input                                  phy_init_done,
   output                                 app_af_wren,
   output [2:0]                           app_af_cmd,
   output [30:0]                          app_af_addr,
   output                                 app_wdf_wren,
   output [APPDATA_WIDTH-1:0]             app_wdf_data,
   output [(APPDATA_WIDTH/8)-1:0]         app_wdf_mask_data,
   output                                 error,
   output                                 error_cmp
   );
 
  localparam BURST_LEN_DIV2 = BURST_LEN/2;
 
  localparam TB_IDLE  = 3'b000;
  localparam TB_WRITE = 3'b001;
  localparam TB_READ  = 3'b010;
 
  wire                     app_af_afull_r  ;
  wire                     app_af_afull_r1 ;
  wire                     app_af_afull_r2;
  reg                      app_af_not_afull_r;
  wire [APPDATA_WIDTH-1:0] app_cmp_data;
  wire                     app_wdf_afull_r;
  wire                     app_wdf_afull_r1 ;
  wire                     app_wdf_afull_r2;
  reg                      app_wdf_not_afull_r ;
  reg [2:0]                burst_cnt;
  reg                      phy_init_done_tb_r;
  wire                     phy_init_done_r;
  reg                      rst_r
                           /* synthesis syn_preserve = 1 */;
  reg                      rst_r1
                           /* synthesis syn_maxfan = 10 */;
  reg [2:0]                state;
  reg [3:0]                state_cnt;
  reg                      wr_addr_en ;
  reg                      wr_data_en ;
 
  // XST attributes for local reset "tree"
  // synthesis attribute shreg_extract of rst_r is "no";
  // synthesis attribute shreg_extract of rst_r1 is "no";
  // synthesis attribute equivalent_register_removal of rst_r is "no"
 
  //*****************************************************************
 
  // local reset "tree" for controller logic only. Create this to ease timing
  // on reset path. Prohibit equivalent register removal on RST_R to prevent
  // "sharing" with other local reset trees (caution: make sure global fanout
  // limit is set to larger than fanout on RST_R, otherwise SLICES will be
  // used for fanout control on RST_R.
  always @(posedge clk0) begin
    rst_r  <= rst0;
    rst_r1 <= rst_r;
  end
 
  // Instantiate flops for timing.
  FDRSE ff_af_afull_r
    (
     .Q   (app_af_afull_r),
     .C   (clk0),
     .CE  (1'b1),
     .D   (app_af_afull),
     .R   (1'b0),
     .S   (1'b0)
     );
 
  FDRSE ff_af_afull_r1
    (
     .Q   (app_af_afull_r1),
     .C   (clk0),
     .CE  (1'b1),
     .D   (app_af_afull_r),
     .R   (1'b0),
     .S   (1'b0)
     );
 
   FDRSE ff_af_afull_r2
    (
     .Q   (app_af_afull_r2),
     .C   (clk0),
     .CE  (1'b1),
     .D   (app_af_afull_r1),
     .R   (1'b0),
     .S   (1'b0)
     );
 
 
  FDRSE ff_wdf_afull_r
    (
     .Q   (app_wdf_afull_r),
     .C   (clk0),
     .CE  (1'b1),
     .D   (app_wdf_afull),
     .R   (1'b0),
     .S   (1'b0)
     );
 
  FDRSE ff_wdf_afull_r1
    (
     .Q   (app_wdf_afull_r1),
     .C   (clk0),
     .CE  (1'b1),
     .D   (app_wdf_afull_r),
     .R   (1'b0),
     .S   (1'b0)
     );
 
   FDRSE ff_wdf_afull_r2
    (
     .Q   (app_wdf_afull_r2),
     .C   (clk0),
     .CE  (1'b1),
     .D   (app_wdf_afull_r1),
     .R   (1'b0),
     .S   (1'b0)
     );
 
    FDRSE ff_phy_init_done
    (
     .Q   (phy_init_done_r),
     .C   (clk0),
     .CE  (1'b1),
     .D   (phy_init_done),
     .R   (1'b0),
     .S   (1'b0)
     );
 
  //***************************************************************************
  // State Machine for writing to WRITE DATA & ADDRESS FIFOs
  // state machine changed for low FIFO threshold values
  //***************************************************************************
 
  always @(posedge clk0) begin
    if (rst_r1) begin
      wr_data_en          <= 1'bx;
      wr_addr_en          <= 1'bx;
      state[2:0]          <= TB_IDLE;
      state_cnt           <= 4'bxxxx;
      app_af_not_afull_r  <= 1'bx;
      app_wdf_not_afull_r <= 1'bx;
      burst_cnt           <= 3'bxxx;
      phy_init_done_tb_r  <= 1'bx;
    end else begin
      wr_data_en          <= 1'b0;
      wr_addr_en          <= 1'b0;
      app_af_not_afull_r  <= ~app_af_afull_r2;
      app_wdf_not_afull_r <= ~app_wdf_afull_r2;
      phy_init_done_tb_r  <= phy_init_done_r;
 
      case (state)
        TB_IDLE: begin
          state_cnt  <= 4'd0;
          burst_cnt  <= BURST_LEN_DIV2 - 1;
          // only start writing when initialization done
          if (app_wdf_not_afull_r && app_af_not_afull_r && phy_init_done_tb_r)
            state <= TB_WRITE;
        end
 
        TB_WRITE:
          if (app_wdf_not_afull_r && app_af_not_afull_r) begin
            wr_data_en <= 1'b1;
            // When we're done with the current burst...
            if (burst_cnt == 3'd0) begin
              burst_cnt <= BURST_LEN_DIV2 - 1;
              wr_addr_en <= 1'b1;
              // Writes occurs in groups of 8 consecutive bursts. Once 8 writes
              // have been issued, now issue the corresponding read back bursts
              if (state_cnt == 4'd7) begin
                state      <= TB_READ;
                state_cnt  <= 4'd0;
              end else
                state_cnt  <= state_cnt + 1;
            end else
              burst_cnt <= burst_cnt - 1;
          end
 
        TB_READ: begin
          burst_cnt <= BURST_LEN_DIV2 - 1;
          if (app_af_not_afull_r) begin
            wr_addr_en <= 1'b1;
            // if finished with all 8 reads, proceed to next 8 writes
            if (state_cnt == 4'd7) begin
              state     <= TB_WRITE;
              state_cnt <= 4'd0;
            end else
              state_cnt <= state_cnt + 1;
          end
        end
      endcase
    end
  end
 
  // Read data comparision
  ddr2_tb_test_cmp #
    (
     .DQ_WIDTH      (DQ_WIDTH),
     .APPDATA_WIDTH (APPDATA_WIDTH),
     .ECC_ENABLE    (ECC_ENABLE)
     )
    u_tb_test_cmp
      (
       .clk              (clk0),
       .rst              (rst0),
       .phy_init_done    (phy_init_done_tb_r),
       .rd_data_valid    (rd_data_valid),
       .app_cmp_data     (app_cmp_data),
       .rd_data_fifo_in  (rd_data_fifo_out),
       .error            (error),
       .error_cmp        (error_cmp)
       );
 
  // Command/Address and Write Data generation
  ddr2_tb_test_gen #
    (
     .BANK_WIDTH    (BANK_WIDTH),
     .COL_WIDTH     (COL_WIDTH),
     .DM_WIDTH      (DM_WIDTH),
     .DQ_WIDTH      (DQ_WIDTH),
     .APPDATA_WIDTH (APPDATA_WIDTH),
     .ECC_ENABLE    (ECC_ENABLE),
     .ROW_WIDTH     (ROW_WIDTH)
     )
    u_tb_test_gen
      (
       .clk               (clk0),
       .rst               (rst0),
       .wr_addr_en        (wr_addr_en),
       .wr_data_en        (wr_data_en),
       .rd_data_valid     (rd_data_valid),
       .app_af_wren       (app_af_wren),
       .app_af_cmd        (app_af_cmd),
       .app_af_addr       (app_af_addr),
       .app_wdf_wren      (app_wdf_wren),
       .app_wdf_data      (app_wdf_data),
       .app_wdf_mask_data (app_wdf_mask_data),
       .app_cmp_data      (app_cmp_data)
       );
 
endmodule
