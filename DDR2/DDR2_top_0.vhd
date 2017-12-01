--*****************************************************************************
-- DISCLAIMER OF LIABILITY
--
-- This file contains proprietary and confidential information of
-- Xilinx, Inc. ("Xilinx"), that is distributed under a license
-- from Xilinx, and may be used, copied and/or disclosed only
-- pursuant to the terms of a valid license agreement with Xilinx.
--
-- XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
-- ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
-- EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
-- LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
-- MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
-- does not warrant that functions included in the Materials will
-- meet the requirements of Licensee, or that the operation of the
-- Materials will be uninterrupted or error-free, or that defects
-- in the Materials will be corrected. Furthermore, Xilinx does
-- not warrant or make any representations regarding use, or the
-- results of the use, of the Materials in terms of correctness,
-- accuracy, reliability or otherwise.
--
-- Xilinx products are not designed or intended to be fail-safe,
-- or for use in any application requiring fail-safe performance,
-- such as life-support or safety devices or systems, Class III
-- medical devices, nuclear facilities, applications related to
-- the deployment of airbags, or any other applications that could
-- lead to death, personal injury or severe property or
-- environmental damage (individually and collectively, "critical
-- applications"). Customer assumes the sole risk and liability
-- of any use of Xilinx products in critical applications,
-- subject only to applicable laws and regulations governing
-- limitations on product liability.
--
-- Copyright 2005, 2006, 2007, 2008 Xilinx, Inc.
-- All rights reserved.
--
-- This disclaimer and copyright notice must be retained as part
-- of this file at all times.
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /   Vendor             : Xilinx
-- \   \   \/    Version            : 3.6.1
--  \   \        Application        : MIG
--  /   /        Filename           : DDR2_top_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates the main design logic of memory
--               interface and interfaces with the user.
-- Revision History:
--   Rev 1.1 - Changes for V4 no edge straddle calibration scheme. Added
--             PER_BIT_SKEW and DELAY_ENABLE port mappings.
--             Various other changes. PK. 12/4/07
--   Rev 1.2 - Changes for the logic of 3-state enable for the data I/O.
--             wr_en vector sizes changed to 2-bit vector. PK. 11/11/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_top_0 is
  port (
    clk_0              : in    std_logic;
    clk_90             : in    std_logic;
    sys_rst            : in    std_logic;
    sys_rst90          : in    std_logic;
    
    ddr2_ras_n         : out   std_logic;
    ddr2_cas_n         : out   std_logic;
    ddr2_we_n          : out   std_logic;
    ddr2_odt           : out   std_logic_vector(ODT_WIDTH-1 downto 0);
    ddr2_cke           : out   std_logic_vector(CKE_WIDTH-1 downto 0);
    ddr2_cs_n          : out   std_logic_vector(CS_WIDTH-1 downto 0);
    ddr2_dq            : inout std_logic_vector(DATA_WIDTH-1 downto 0);
    ddr2_dqs           : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    ddr2_dqs_n         : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    ddr2_dm            : out   std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
    
    ddr2_ck            : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddr2_ck_n          : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddr2_ba            : out   std_logic_vector(BANK_ADDRESS-1 downto 0);
    ddr2_a             : out   std_logic_vector(ROW_ADDRESS-1 downto 0);
    wdf_almost_full    : out   std_logic;
    af_almost_full     : out   std_logic;
    burst_length_div2  : out   std_logic_vector(2 downto 0);
    read_data_valid    : out   std_logic;
    read_data_fifo_out : out   std_logic_vector(DQ_WIDTH*2-1 downto 0);
    app_af_addr        : in    std_logic_vector(35 downto 0);
    app_af_wren        : in    std_logic;
    app_wdf_data       : in    std_logic_vector(DQ_WIDTH*2-1 downto 0);
    app_mask_data      : in    std_logic_vector(DM_WIDTH*2-1 downto 0);
    app_wdf_wren       : in    std_logic;
    clk_tb             : out   std_logic;
    reset_tb           : out   std_logic;
    init_done          : out   std_logic;

    -- Debug Signals
    dbg_idel_up_all       : in  std_logic;
    dbg_idel_down_all     : in  std_logic;
    dbg_idel_up_dq        : in  std_logic;
    dbg_idel_down_dq      : in  std_logic;
    dbg_sel_idel_dq       : in  std_logic_vector(DQ_BITS-1 downto 0);
    dbg_sel_all_idel_dq   : in  std_logic;
    dbg_calib_dq_tap_cnt  : out std_logic_vector(((6*DATA_WIDTH)-1) downto 0);
    dbg_data_tap_inc_done : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    dbg_sel_done          : out std_logic;
    dbg_first_rising      : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    dbg_cal_first_loop    : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    dbg_comp_done         : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    dbg_comp_error        : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    dbg_init_done         : out std_logic
    );

end entity;

architecture arc_top of DDR2_top_0 is

  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of arc_top : architecture IS
    "mig_v3_61_ddr2_dc_v4, Coregen 12.4";

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of arc_top : architecture IS "ddr2_dc_v4,mig_v3_61,{component_name=DDR2_top_0, data_width=32, data_strobe_width=4, data_mask_width=4, clk_width=2, fifo_16=2, cs_width=1, odt_width=1, cke_width=1, row_address=14, registered=0, single_rank=1, dual_rank=0, databitsperstrobe=8, mask_enable=1, use_dm_port=1, column_address=10, bank_address=3, debug_en=0, load_mode_register=00010000110010, ext_load_mode_register=00000000000000, chip_address=1, ecc_enable=0, ecc_width=0, reset_active_low=1, tby4tapvalue=17, rfc_count_value=00100111, ras_count_value=00111, rcd_count_value=010, rp_count_value=010, trtp_count_value=001, twr_count_value=011, twtr_count_value=001, max_ref_width=11, max_ref_cnt=11000011000, language=VHDL, synthesis_tool=ISE, interface_type=DDR2_SDRAM_Direct_Clocking, no_of_controllers=1}";

  component DDR2_data_path_0
    port (
      clk                  : in  std_logic;
      clk90                : in  std_logic;
      reset0               : in  std_logic;
      reset90              : in  std_logic;
      ctrl_dummyread_start : in  std_logic;
      wdf_data             : in  std_logic_vector(DQ_WIDTH*2-1 downto 0);
      mask_data            : in  std_logic_vector(DM_WIDTH*2-1 downto 0);
      ctrl_wren            : in  std_logic;
      ctrl_dqs_rst         : in  std_logic;
      ctrl_dqs_en          : in  std_logic;
      ctrl_dummy_wr_sel    : in  std_logic;
      calibration_dq       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      wr_data_rise         : out std_logic_vector(DATA_WIDTH-1 downto 0);
      wr_data_fall         : out std_logic_vector(DATA_WIDTH-1 downto 0);
      mask_data_rise       : out std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
      mask_data_fall       : out std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
      wr_en                : out std_logic_vector(1 downto 0);
      dm_wr_en             : out std_logic;
      dqs_rst              : out std_logic;
      dqs_en               : out std_logic;
      data_idelay_inc      : out std_logic_vector(DATA_WIDTH-1 downto 0);
      data_idelay_ce       : out std_logic_vector(DATA_WIDTH-1 downto 0);
      data_idelay_rst      : out std_logic_vector(DATA_WIDTH-1 downto 0);
      sel_done             : out std_logic;
      per_bit_skew         : out std_logic_vector(DATA_WIDTH-1 downto 0);

      -- Debug Signals
      dbg_idel_up_all       : in  std_logic;
      dbg_idel_down_all     : in  std_logic;
      dbg_idel_up_dq        : in  std_logic;
      dbg_idel_down_dq      : in  std_logic;
      dbg_sel_idel_dq       : in  std_logic_vector(DQ_BITS-1 downto 0);
      dbg_sel_all_idel_dq   : in  std_logic;
      dbg_calib_dq_tap_cnt  : out std_logic_vector(((6*DATA_WIDTH)-1) downto 0);
      dbg_data_tap_inc_done : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      dbg_sel_done          : out std_logic
      );
  end component;

  component DDR2_iobs_0
    port (
      clk               : in    std_logic;
      clk90             : in    std_logic;
      ddr_ck            : out   std_logic_vector(CLK_WIDTH-1 downto 0);
      ddr_ck_n          : out   std_logic_vector(CLK_WIDTH-1 downto 0);
      reset0            : in    std_logic;
      dqs_rst           : in    std_logic;
      dqs_en            : in    std_logic;
      wr_en             : in    std_logic_vector(1 downto 0);
      dm_wr_en          : in    std_logic;

      data_idelay_inc   : in    std_logic_vector(DATA_WIDTH-1 downto 0);
      data_idelay_ce    : in    std_logic_vector(DATA_WIDTH-1 downto 0);
      data_idelay_rst   : in    std_logic_vector(DATA_WIDTH-1 downto 0);
      delay_enable      : in    std_logic_vector(DATA_WIDTH-1 downto 0);

      wr_data_rise      : in    std_logic_vector(DATA_WIDTH-1 downto 0);
      wr_data_fall      : in    std_logic_vector(DATA_WIDTH-1 downto 0);
      mask_data_rise    : in    std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
      mask_data_fall    : in    std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
      rd_data_rise      : out   std_logic_vector(DATA_WIDTH-1 downto 0);
      rd_data_fall      : out   std_logic_vector(DATA_WIDTH-1 downto 0);

      ddr_dq            : inout std_logic_vector(DATA_WIDTH-1 downto 0);
      ddr_dqs           : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      ddr_dqs_l         : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      ddr_dm            : out   std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
      ddr_address       : out   std_logic_vector(ROW_ADDRESS-1 downto 0);
      ddr_ba            : out   std_logic_vector(BANK_ADDRESS-1 downto 0);
      ddr_ras_l         : out   std_logic;
      ddr_cas_l         : out   std_logic;
      ddr_we_l          : out   std_logic;
      ddr_cs_l          : out   std_logic_vector(CS_WIDTH-1 downto 0);
      ddr_cke           : out   std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr_odt           : out   std_logic_vector(ODT_WIDTH-1 downto 0);
      ctrl_ddr2_ras_l   : in    std_logic;
      ctrl_ddr2_cas_l   : in    std_logic;
      ctrl_ddr2_we_l    : in    std_logic;
      ctrl_ddr2_odt     : in    std_logic_vector(ODT_WIDTH-1 downto 0);
      ctrl_ddr2_cke     : in    std_logic_vector(CKE_WIDTH-1 downto 0);
      ctrl_ddr2_cs_l    : in    std_logic_vector(CS_WIDTH-1 downto 0);
      ctrl_ddr2_ba      : in    std_logic_vector(BANK_ADDRESS-1 downto 0);
      ctrl_ddr2_address : in    std_logic_vector(ROW_ADDRESS-1 downto 0)
      );
  end component;

  component  DDR2_user_interface_0
    port (
      clk                : in  std_logic;
      clk90              : in  std_logic;

      reset              : in  std_logic;
      read_data_rise     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      read_data_fall     : in  std_logic_vector(DATA_WIDTH-1 downto 0);

      init_done          : in  std_logic;
      app_af_addr        : in  std_logic_vector(35 downto 0);
      app_af_wren        : in  std_logic;
      ctrl_af_rden       : in  std_logic;
      app_wdf_data       : in  std_logic_vector(DQ_WIDTH*2-1 downto 0);
      app_mask_data      : in  std_logic_vector(DM_WIDTH*2-1 downto 0);
      app_wdf_wren       : in  std_logic;
      ctrl_wdf_rden      : in  std_logic;
      delay_enable       : out std_logic_vector(DATA_WIDTH-1 downto 0);
      ctrl_rden          : in  std_logic;
      per_bit_skew       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      
      comp_done          : out std_logic;
      read_data_fifo_out : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
      read_data_valid    : out std_logic;
      af_addr            : out std_logic_vector(35 downto 0);
      wdf_data           : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
      mask_data          : out std_logic_vector(DM_WIDTH*2-1 downto 0);
      wdf_almost_full    : out std_logic;
      af_almost_full     : out std_logic;
      af_empty           : out std_logic;
      cal_first_loop     : out std_logic;

      -- Debug Signals
      dbg_first_rising   : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      dbg_cal_first_loop : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      dbg_comp_done      : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      dbg_comp_error     : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0)
      );
  end component;

  component  DDR2_ddr2_controller_0
    port (
      clk0                 : in  std_logic; -- controller input
      rst                  : in  std_logic; -- controller input
      af_addr              : in  std_logic_vector(35 downto 0); --FIFO  signal
      af_empty             : in  std_logic;                     --FIFO  signal
      phy_dly_slct_done    : in  std_logic; --Input signal for the Dummy Reads
      cal_first_loop       : in  std_logic;
      comp_done            : in  std_logic;
      ctrl_dummy_wr_sel    : out std_logic;
      burst_length_div2    : out std_logic_vector(2 downto 0);
      ctrl_dummyread_start : out std_logic;
      ctrl_af_rden         : out std_logic; -- FIFO read enable signals
      ctrl_wdf_rden        : out std_logic; -- FIFO read enable signals
      ctrl_dqs_rst         : out std_logic; -- Rst signal for DQS logic
      ctrl_dqs_en          : out std_logic; -- Enable signal for DQS logic
      ctrl_wren            : out std_logic; -- Read and Write Enable signals to the phy interface
      ctrl_rden            : out std_logic; -- Read and Write Enable signals to the phy interface
      ctrl_ddr2_address    : out std_logic_vector((ROW_ADDRESS-1) downto 0);
      ctrl_ddr2_ba         : out std_logic_vector((BANK_ADDRESS-1) downto 0);
      ctrl_ddr2_ras_l      : out std_logic;
      ctrl_ddr2_cas_l      : out std_logic;
      ctrl_ddr2_we_l       : out std_logic;
      ctrl_ddr2_cs_l       : out std_logic_vector((CS_WIDTH-1) downto 0);
      ctrl_ddr2_cke        : out std_logic_vector((CKE_WIDTH-1) downto 0);
      ctrl_ddr2_odt        : out std_logic_vector((ODT_WIDTH-1) downto 0);
      init_done_r          : out std_logic;

      -- Debug Signals
      dbg_init_done         : out std_logic
      );
  end component;

  signal wr_df_data        : std_logic_vector(DQ_WIDTH*2-1 downto 0);
  signal mask_df_data      : std_logic_vector(DM_WIDTH*2-1 downto 0);
  signal rd_data_rise      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal rd_data_fall      : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal af_empty_w        : std_logic;

  signal dq_tap_sel_done   : std_logic;
  signal af_addr           : std_logic_vector(35 downto 0);
  signal ctrl_af_rden      : std_logic;
  signal ctrl_wr_df_rden   : std_logic;
  signal ctrl_dummy_rden   : std_logic;
  signal ctrl_dqs_enable   : std_logic;
  signal ctrl_dqs_reset    : std_logic;
  signal ctrl_wr_en        : std_logic;
  signal ctrl_rden         : std_logic ;

  signal data_idelay_inc   : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal data_idelay_ce    : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal data_idelay_rst   : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal dqs_rst           : std_logic;
  signal dqs_en            : std_logic;
  signal wr_en             : std_logic_vector(1 downto 0);
  signal dm_wr_en          : std_logic;

  signal wr_data_rise      : std_logic_vector((DATA_WIDTH-1) downto 0);
  signal wr_data_fall      : std_logic_vector((DATA_WIDTH-1) downto 0);
  signal mask_data_rise    : std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
  signal mask_data_fall    : std_logic_vector(DATA_MASK_WIDTH-1 downto 0);

  signal ctrl_ddr2_address : std_logic_vector(ROW_ADDRESS-1 downto 0);
  signal ctrl_ddr2_ba      : std_logic_vector(BANK_ADDRESS-1 downto 0);
  signal ctrl_ddr2_ras_l   : std_logic;
  signal ctrl_ddr2_cas_l   : std_logic;
  signal ctrl_ddr2_we_l    : std_logic;
  signal ctrl_ddr2_cs_l    : std_logic_vector(CS_WIDTH-1 downto 0);
  signal ctrl_ddr2_cke     : std_logic_vector(CKE_WIDTH-1 downto 0);
  signal ctrl_ddr2_odt     : std_logic_vector(ODT_WIDTH-1 downto 0);
  signal ctrl_dummy_wr_sel : std_logic;
  signal comp_done         : std_logic;
  signal init_done_i       : std_logic;
  signal per_bit_skew      : std_logic_vector((DATA_WIDTH-1) downto 0);
  signal delay_enable      : std_logic_vector((DATA_WIDTH-1) downto 0);
  signal cal_first_loop    : std_logic;

begin

  --***************************************************************************

  clk_tb    <= clk_0;
  reset_tb  <= sys_rst;
  init_done <= init_done_i;



  data_path_00 : DDR2_data_path_0
    port map (
      clk                  => clk_0,
      clk90                => clk_90,
      reset0               => sys_rst,
      reset90              => sys_rst90,
      ctrl_dummyread_start => ctrl_dummy_rden,
      wdf_data             => wr_df_data,
      mask_data            => mask_df_data,
      ctrl_wren            => ctrl_wr_en,
      ctrl_dqs_rst         => ctrl_dqs_reset,
      ctrl_dqs_en          => ctrl_dqs_enable,
      ctrl_dummy_wr_sel    => ctrl_dummy_wr_sel,
      data_idelay_inc      => data_idelay_inc,
      data_idelay_ce       => data_idelay_ce,
      data_idelay_rst      => data_idelay_rst,
      sel_done             => dq_tap_sel_done,
      dqs_rst              => dqs_rst,
      dqs_en               => dqs_en,
      wr_en                => wr_en,
      dm_wr_en             => dm_wr_en,
      wr_data_rise         => wr_data_rise,
      wr_data_fall         => wr_data_fall,
      mask_data_rise       => mask_data_rise,
      mask_data_fall       => mask_data_fall,
      calibration_dq       => rd_data_rise,
      per_bit_skew         => per_bit_skew,

      -- Debug Signals
      dbg_idel_up_all      => dbg_idel_up_all,
      dbg_idel_down_all    => dbg_idel_down_all,
      dbg_idel_up_dq       => dbg_idel_up_dq,
      dbg_idel_down_dq     => dbg_idel_down_dq,
      dbg_sel_idel_dq      => dbg_sel_idel_dq,
      dbg_sel_all_idel_dq  => dbg_sel_all_idel_dq,
      dbg_calib_dq_tap_cnt => dbg_calib_dq_tap_cnt,
      dbg_data_tap_inc_done => dbg_data_tap_inc_done,
      dbg_sel_done         => dbg_sel_done
      );

  iobs_00 : DDR2_iobs_0
    port map (
      clk               => clk_0,
      clk90             => clk_90,
      reset0            => sys_rst,
      ddr_ck            => ddr2_ck,
      ddr_ck_n          => ddr2_ck_n,

      data_idelay_inc   => data_idelay_inc,
      data_idelay_ce    => data_idelay_ce,
      data_idelay_rst   => data_idelay_rst,
      delay_enable      => delay_enable,

      dqs_rst           => dqs_rst,
      dqs_en            => dqs_en,
      wr_en             => wr_en,
      dm_wr_en          => dm_wr_en,
      wr_data_rise      => wr_data_rise,
      wr_data_fall      => wr_data_fall,
      mask_data_rise    => mask_data_rise,
      mask_data_fall    => mask_data_fall,
      rd_data_rise      => rd_data_rise,
      rd_data_fall      => rd_data_fall,
      ddr_dq            => ddr2_dq,
      ddr_dqs           => ddr2_dqs,
      ddr_dqs_l         => ddr2_dqs_n,
      ddr_dm            => ddr2_dm,
      ctrl_ddr2_address => ctrl_ddr2_address,
      ctrl_ddr2_ba      => ctrl_ddr2_ba,
      ctrl_ddr2_ras_l   => ctrl_ddr2_ras_l,
      ctrl_ddr2_cas_l   => ctrl_ddr2_cas_l,
      ctrl_ddr2_we_l    => ctrl_ddr2_we_l,
      ctrl_ddr2_cs_l    => ctrl_ddr2_cs_l,
      ctrl_ddr2_cke     => ctrl_ddr2_cke,
      ctrl_ddr2_odt     => ctrl_ddr2_odt,
      ddr_address       => ddr2_a,
      ddr_ba            => ddr2_ba,
      ddr_ras_l         => ddr2_ras_n,
      ddr_cas_l         => ddr2_cas_n,
      ddr_we_l          => ddr2_we_n,
      ddr_cke           => ddr2_cke,
      ddr_odt           => ddr2_odt,
      ddr_cs_l          => ddr2_cs_n
      );

  user_interface_00 :  DDR2_user_interface_0
    port map (
      clk                => clk_0,
      clk90              => clk_90,
      reset              => sys_rst,
      ctrl_rden          => ctrl_rden,
      per_bit_skew       => per_bit_skew,
      comp_done          => comp_done,
      read_data_rise     => rd_data_rise,
      read_data_fall     => rd_data_fall,
      init_done          => init_done_i,
      read_data_fifo_out => read_data_fifo_out,
      read_data_valid    => read_data_valid,
      af_empty           => af_empty_w,
      af_almost_full     => af_almost_full,
      app_af_addr        => app_af_addr,
      app_af_wren        => app_af_wren,
      ctrl_af_rden       => ctrl_af_rden,
      af_addr            => af_addr,
      app_wdf_data       => app_wdf_data,
      
      app_mask_data      => app_mask_data,
      app_wdf_wren       => app_wdf_wren,
      ctrl_wdf_rden      => ctrl_wr_df_rden,
      delay_enable       => delay_enable,
      wdf_data           => wr_df_data,
      mask_data          => mask_df_data,
      wdf_almost_full    => wdf_almost_full,
      cal_first_loop     => cal_first_loop,

      -- Debug Signals
      dbg_first_rising   => dbg_first_rising,
      dbg_cal_first_loop => dbg_cal_first_loop,
      dbg_comp_done      => dbg_comp_done,
      dbg_comp_error     => dbg_comp_error
      );

  ddr2_controller_00 :  DDR2_ddr2_controller_0
    port map (
      clk0                 => clk_0,
      rst                  => sys_rst,
      burst_length_div2    => burst_length_div2,
      af_addr              => af_addr,
      af_empty             => af_empty_w,
      phy_dly_slct_done    => dq_tap_sel_done,
      cal_first_loop       => cal_first_loop,
      ctrl_dummyread_start => ctrl_dummy_rden,
      ctrl_af_rden         => ctrl_af_rden,
      ctrl_wdf_rden        => ctrl_wr_df_rden,
      ctrl_dqs_rst         => ctrl_dqs_reset,
      ctrl_dqs_en          => ctrl_dqs_enable,
      ctrl_wren            => ctrl_wr_en,
      ctrl_rden            => ctrl_rden,
      ctrl_ddr2_address    => ctrl_ddr2_address,
      ctrl_ddr2_ba         => ctrl_ddr2_ba,
      ctrl_ddr2_ras_l      => ctrl_ddr2_ras_l,
      ctrl_ddr2_cas_l      => ctrl_ddr2_cas_l,
      ctrl_ddr2_we_l       => ctrl_ddr2_we_l,
      ctrl_ddr2_cs_l       => ctrl_ddr2_cs_l,
      ctrl_ddr2_cke        => ctrl_ddr2_cke,
      ctrl_ddr2_odt        => ctrl_ddr2_odt,
      ctrl_dummy_wr_sel    => ctrl_dummy_wr_sel,
      comp_done            => comp_done,
      init_done_r          => init_done_i,

      -- Debug Signals
      dbg_init_done        => dbg_init_done
      );


end arc_top;
