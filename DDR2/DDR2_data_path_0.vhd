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
--  /   /        Filename           : DDR2_data_path_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates the tap logic and the data write
--               modules. Gives the rise and the fall data and the calibration
--               information for the IDELAY elements.
-- Revision History:
--   Rev 1.1 - Changes for V4 no edge straddle calibration scheme. Added
--             PER_BIT_SKEW output. Various other changes. PK. 12/4/07
--   Rev 1.2 - Changes for the logic of 3-state enable for the data I/O.
--             wr_en vector sizes changed to 2-bit vector. PK. 11/11/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity DDR2_data_path_0 is
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
end entity;

architecture arc_data_path of DDR2_data_path_0 is

  component DDR2_data_write_0
    port (
      clk               : in  std_logic;
      clk90             : in  std_logic;
      reset90           : in  std_logic;
      wdf_data          : in  std_logic_vector(DQ_WIDTH*2-1 downto 0);
      mask_data         : in  std_logic_vector(DM_WIDTH*2-1 downto 0);
      ctrl_wren         : in  std_logic;
      ctrl_dqs_rst      : in  std_logic;
      ctrl_dqs_en       : in  std_logic;
      wr_data_fall      : out std_logic_vector(DQ_WIDTH-1 downto 0);
      wr_data_rise      : out std_logic_vector(DQ_WIDTH-1 downto 0);
      mask_data_fall    : out std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
      mask_data_rise    : out std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
      wr_en             : out std_logic_vector(1 downto 0);
      dm_wr_en             : out std_logic;
      dqs_rst           : out std_logic;
      dqs_en            : out std_logic
      );
  end component;

  component DDR2_tap_logic_0
    port (
      clk                  : in std_logic;
      reset0               : in std_logic;
      ctrl_dummyread_start : in std_logic;
      calibration_dq       : in std_logic_vector(DATA_WIDTH-1 downto 0);
      sel_done             : out std_logic;
      data_idelay_inc      : out std_logic_vector(DATA_WIDTH-1 downto 0);
      data_idelay_ce       : out std_logic_vector(DATA_WIDTH-1 downto 0);
      data_idelay_rst      : out std_logic_vector(DATA_WIDTH-1 downto 0);
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




begin

  --***************************************************************************


  data_write_0 : DDR2_data_write_0
    port map (
      clk                   => clk,
      clk90                 => clk90,
      reset90               => reset90,
      wdf_data              => wdf_data,
      mask_data             => mask_data,
      ctrl_wren             => ctrl_wren,
      ctrl_dqs_rst          => ctrl_dqs_rst,
      ctrl_dqs_en           => ctrl_dqs_en,
      dqs_rst               => dqs_rst,
      dqs_en                => dqs_en,
      wr_en                 => wr_en,
      dm_wr_en              => dm_wr_en,
      wr_data_rise          => wr_data_rise,
      wr_data_fall          => wr_data_fall,
      mask_data_rise        => mask_data_rise,
      mask_data_fall        => mask_data_fall
      );





  tap_logic_00 : DDR2_tap_logic_0
    port map (
      clk                    => clk,
      reset0                 => reset0,
      ctrl_dummyread_start   => ctrl_dummyread_start,
      calibration_dq         => calibration_dq,
      data_idelay_inc        => data_idelay_inc,
      data_idelay_ce         => data_idelay_ce,
      data_idelay_rst        => data_idelay_rst,
      sel_done               => sel_done,
      per_bit_skew           => per_bit_skew,

      -- Debug Signals
      dbg_idel_up_all        => dbg_idel_up_all,
      dbg_idel_down_all      => dbg_idel_down_all,
      dbg_idel_up_dq         => dbg_idel_up_dq,
      dbg_idel_down_dq       => dbg_idel_down_dq,
      dbg_sel_idel_dq        => dbg_sel_idel_dq,
      dbg_sel_all_idel_dq    => dbg_sel_all_idel_dq,
      dbg_calib_dq_tap_cnt   => dbg_calib_dq_tap_cnt,
      dbg_data_tap_inc_done  => dbg_data_tap_inc_done,
      dbg_sel_done           => dbg_sel_done
      );


end arc_data_path;
