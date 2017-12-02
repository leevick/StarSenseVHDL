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
--  /   /        Filename           : DDR2_main_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : The main design logic is instantiated here which includes
--               the test bench and the user interface also. It takes the
--               memory signals and the calibrated clocks and the reset
--               signals from the DCM.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_main_0 is
  port (
    clk_0           : in std_logic;
    clk_90          : in std_logic;
    sys_rst         : in std_logic;
    sys_rst90       : in std_logic;
    
    ddr2_ras_n      : out std_logic;
    ddr2_cas_n      : out std_logic;
    ddr2_we_n       : out std_logic;
    ddr2_odt        : out std_logic_vector(ODT_WIDTH-1 downto 0);
    ddr2_odt_cpy        : out std_logic_vector(ODT_WIDTH-1 downto 0);
    ddr2_cke        : out std_logic_vector(CKE_WIDTH-1 downto 0);
    ddr2_cs_n       : out std_logic_vector(CS_WIDTH-1 downto 0);
    ddr2_cs_n_cpy       : out std_logic_vector(CS_WIDTH-1 downto 0);
    ddr2_dq         : inout std_logic_vector(DATA_WIDTH-1 downto 0);
    ddr2_dqs        : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    ddr2_dqs_n      : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    ddr2_dm         : out std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
    
    ddr2_ck         : out std_logic_vector(CLK_WIDTH-1 downto 0);
    ddr2_ck_n       : out std_logic_vector(CLK_WIDTH-1 downto 0);
    ddr2_ba         : out std_logic_vector(BANK_ADDRESS-1 downto 0);
    ddr2_a          : out std_logic_vector(ROW_ADDRESS-1 downto 0);
    error           : out std_logic;
    init_done       : out std_logic;

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

architecture arc_main of DDR2_main_0 is
  component DDR2_top_0
    port (
      clk_0              : in std_logic;
      clk_90             : in std_logic;
      sys_rst            : in std_logic;
      sys_rst90          : in std_logic;
      
      ddr2_ras_n         : out std_logic;
      ddr2_cas_n         : out std_logic;
      ddr2_we_n          : out std_logic;
      ddr2_odt           : out std_logic_vector(ODT_WIDTH-1 downto 0);
      ddr2_odt_cpy           : out std_logic_vector(ODT_WIDTH-1 downto 0);
      ddr2_cke           : out std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr2_cs_n          : out std_logic_vector(CS_WIDTH-1 downto 0);
      ddr2_cs_n_cpy          : out std_logic_vector(CS_WIDTH-1 downto 0);
      ddr2_dq            : inout std_logic_vector(DATA_WIDTH-1 downto 0);
      ddr2_dqs           : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      ddr2_dqs_n         : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      ddr2_dm            : out std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
      
      ddr2_ck            : out std_logic_vector(CLK_WIDTH-1 downto 0);
      ddr2_ck_n          : out std_logic_vector(CLK_WIDTH-1 downto 0);
      ddr2_ba            : out std_logic_vector(BANK_ADDRESS-1 downto 0);
      ddr2_a             : out std_logic_vector(ROW_ADDRESS-1 downto 0);

      wdf_almost_full    : out std_logic;
      af_almost_full     : out std_logic;
      burst_length_div2  : out std_logic_vector(2 downto 0);
      read_data_valid    : out std_logic;
      read_data_fifo_out : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
      app_af_addr        : in std_logic_vector(35 downto 0);
      app_af_wren        : in std_logic;
      app_wdf_data       : in std_logic_vector(DQ_WIDTH*2-1 downto 0);
      app_mask_data      : in std_logic_vector(DM_WIDTH*2-1 downto 0);
      app_wdf_wren       : in std_logic;
      clk_tb             : out std_logic;
      reset_tb           : out std_logic;
      init_done          : out std_logic;

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
  end component;

  component DDR2_test_bench_0
    port (
      clk                : in  std_logic;
      reset              : in  std_logic;
      wdf_almost_full    : in  std_logic;
      af_almost_full     : in  std_logic;
      burst_length_div2  : in  std_logic_vector(2 downto 0);
      read_data_valid    : in  std_logic;
      read_data_fifo_out : in  std_logic_vector(DQ_WIDTH*2-1 downto 0);
      init_done          : in  std_logic;
      app_af_addr        : out std_logic_vector(35 downto 0);
      app_af_wren        : out std_logic;
      app_wdf_data       : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
      app_mask_data      : out std_logic_vector(DM_WIDTH*2-1 downto 0);
      app_wdf_wren       : out std_logic;
      error              : out std_logic
      );
  end component;

  signal app_af_addr       : std_logic_vector(35 downto 0);
  signal app_af_wren       : std_logic;
  signal app_wr_df_data    : std_logic_vector(DQ_WIDTH*2-1 downto 0);
  signal app_mask_df_data  : std_logic_vector(DM_WIDTH*2-1 downto 0);
  signal app_wr_df_wren    : std_logic;
  signal wr_df_almost_full : std_logic;
  signal clk_tb            : std_logic;
  signal reset_tb          : std_logic;

  signal af_almost_full    : std_logic;
  signal rd_data_valid     : std_logic;
  signal rd_data_fifo_out  : std_logic_vector(DQ_WIDTH*2-1 downto 0);
  signal burst_length_div2 : std_logic_vector(2 downto 0);
  signal init_done_r       : std_logic;

begin

  --***************************************************************************

  init_done <= init_done_r;

  top_00 : DDR2_top_0
    port map (
      clk_0              => clk_0,
      clk_90             => clk_90,
      sys_rst            => sys_rst,
      sys_rst90          => sys_rst90,
      
      ddr2_ras_n         => ddr2_ras_n,
      ddr2_cas_n         => ddr2_cas_n,
      ddr2_we_n          => ddr2_we_n,
      ddr2_odt           => ddr2_odt,
      ddr2_odt_cpy           => ddr2_odt_cpy,
      ddr2_cke           => ddr2_cke,
      ddr2_cs_n          => ddr2_cs_n,
      ddr2_cs_n_cpy          => ddr2_cs_n_cpy,
      ddr2_dq            => ddr2_dq,
      ddr2_dqs           => ddr2_dqs,
      ddr2_dqs_n         => ddr2_dqs_n,
      ddr2_dm            =>     ddr2_dm,
      
      ddr2_ck            => ddr2_ck,
      ddr2_ck_n          => ddr2_ck_n,
      ddr2_ba            => ddr2_ba,
      ddr2_a             => ddr2_a,
      clk_tb             => clk_tb,
      reset_tb           => reset_tb,
      -- TEST BENCH SIGNALS
      wdf_almost_full    => wr_df_almost_full,
      af_almost_full     => af_almost_full,
      burst_length_div2  => burst_length_div2,
      read_data_valid    => rd_data_valid,
      read_data_fifo_out => rd_data_fifo_out,
      app_af_addr        => app_af_addr,
      app_af_wren        => app_af_wren,
      app_wdf_data       => app_wr_df_data,
      app_mask_data      => app_mask_df_data,
      app_wdf_wren       => app_wr_df_wren,
      init_done          => init_done_r,

      -- Debug Signals
      dbg_idel_up_all      => dbg_idel_up_all,
      dbg_idel_down_all    => dbg_idel_down_all,
      dbg_idel_up_dq       => dbg_idel_up_dq,
      dbg_idel_down_dq     => dbg_idel_down_dq,
      dbg_sel_idel_dq      => dbg_sel_idel_dq,
      dbg_sel_all_idel_dq  => dbg_sel_all_idel_dq,
      dbg_calib_dq_tap_cnt => dbg_calib_dq_tap_cnt,
      dbg_data_tap_inc_done => dbg_data_tap_inc_done,
      dbg_sel_done         => dbg_sel_done,
      dbg_first_rising     => dbg_first_rising,
      dbg_cal_first_loop   => dbg_cal_first_loop,
      dbg_comp_done        => dbg_comp_done,
      dbg_comp_error       => dbg_comp_error,
      dbg_init_done        => dbg_init_done
      );

  test_bench_00 : DDR2_test_bench_0
    port map (
      clk                => clk_tb,
      reset              => reset_tb,
      wdf_almost_full    => wr_df_almost_full,
      af_almost_full     => af_almost_full,
      burst_length_div2  => burst_length_div2,
      read_data_valid    => rd_data_valid,
      read_data_fifo_out => rd_data_fifo_out,
      app_af_addr        => app_af_addr,
      app_af_wren        => app_af_wren,
      app_wdf_data       => app_wr_df_data,
      app_mask_data      => app_mask_df_data,
      app_wdf_wren       => app_wr_df_wren,
      error              => error,
      init_done          => init_done_r
      );


end arc_main;
