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
-- Copyright 2005, 2006, 2007 Xilinx, Inc.
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
--  /   /        Filename           : DDR2_user_interface_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module interfaces with the user. The user should
--               provide the data and various commands.
-- Revision History:
--   Rev 1.1 - Changes for V4 no edge straddle calibration scheme. Added
--             PER_BIT_SKEW input, DELAY_ENABLE outputs.
--             Various other changes. PK. 12/22/07
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

entity DDR2_user_interface_0 is
  port (
    CLK                : in  std_logic;
    clk90              : in  std_logic;
    reset              : in  std_logic;
    read_data_rise     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    read_data_fall     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    ctrl_rden          : in  std_logic;
    per_bit_skew       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    init_done          : in  std_logic;
    app_af_addr        : in  std_logic_vector(35 downto 0);
    app_af_wren        : in  std_logic;
    ctrl_af_rden       : in  std_logic;
    app_wdf_data       : in  std_logic_vector(DQ_WIDTH*2-1 downto 0);
    app_mask_data      : in  std_logic_vector(DM_WIDTH*2-1 downto 0);
    app_wdf_wren       : in  std_logic;
    ctrl_wdf_rden      : in  std_logic;
    delay_enable       : out std_logic_vector(DATA_WIDTH-1 downto 0);
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
end entity;

architecture arc_user_interface of DDR2_user_interface_0 is


  component DDR2_rd_data_0
    port (
      clk                 : in std_logic;
      reset               : in std_logic;
      read_data_rise      : in std_logic_vector(data_width-1 downto 0);
      read_data_fall      : in std_logic_vector(data_width-1 downto 0);
      ctrl_rden           : in std_logic;
      per_bit_skew        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      comp_done           : out std_logic;
      delay_enable        : out std_logic_vector(DATA_WIDTH-1 downto 0);
      read_data_fifo_rise : out std_logic_vector(data_width-1 downto 0);
      read_data_fifo_fall : out std_logic_vector(data_width-1 downto 0);
      read_data_valid     : out std_logic;
      cal_first_loop      : out std_logic;

      -- Debug Signals
      dbg_first_rising   : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      dbg_cal_first_loop : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      dbg_comp_done      : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
      dbg_comp_error     : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0)
      );
  end component;

  component DDR2_backend_fifos_0
    port (
      clk0            : in  std_logic;
      clk90           : in  std_logic;
      rst             : in  std_logic;
      init_done       : in  std_logic;
      -- Write address fifo signals
      app_af_addr     : in  std_logic_vector(35 downto 0);
      app_af_wren     : in  std_logic;
      ctrl_af_rden    : in  std_logic;
      af_addr         : out std_logic_vector(35 downto 0);
      af_empty        : out std_logic ;
      af_almost_full  : out std_logic;
      -- Write data fifo signals
      app_wdf_data    : in  std_logic_vector(DQ_WIDTH*2-1 downto 0);
      app_mask_data   : in  std_logic_vector(DM_WIDTH*2-1 downto 0);
      app_wdf_wren    : in  std_logic;
      ctrl_wdf_rden   : in  std_logic;
      wdf_data        : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
      mask_data       : out std_logic_vector(DM_WIDTH*2-1 downto 0);
      wdf_almost_full : out std_logic
      );
  end component;

  signal read_data_fifo_rise_i : std_logic_vector(DQ_WIDTH-1 downto  0);
  signal read_data_fifo_fall_i : std_logic_vector(DQ_WIDTH-1 downto  0);


begin

  --***************************************************************************




  read_data_fifo_out  <= (read_data_fifo_rise_i & read_data_fifo_fall_i);

  rd_data_00 :  DDR2_rd_data_0
    port map (
      clk                 => clk,
      reset               => reset,
      ctrl_rden           => ctrl_rden,
      per_bit_skew        => per_bit_skew,
      comp_done           => comp_done,
      delay_enable        => delay_enable,
      read_data_rise      => read_data_rise,
      read_data_fall      => read_data_fall,
      read_data_fifo_rise => read_data_fifo_rise_i,
      read_data_fifo_fall => read_data_fifo_fall_i,
      read_data_valid     => read_data_valid,
      cal_first_loop      => cal_first_loop,

      -- Debug Signals
      dbg_first_rising   => dbg_first_rising,
      dbg_cal_first_loop => dbg_cal_first_loop,
      dbg_comp_done      => dbg_comp_done,
      dbg_comp_error     => dbg_comp_error
      );

  backend_fifos_00 : DDR2_backend_fifos_0
    port map (
      clk0            => clk,
      clk90           => clk90,
      rst             => reset,
      init_done       => init_done,
      app_af_addr     => app_af_addr,
      app_af_wren     => app_af_wren,
      ctrl_af_rden    => ctrl_af_rden,
      af_addr         => af_addr,
      af_empty        => af_empty,
      af_almost_full  => af_almost_full,
      app_wdf_data    => app_wdf_data,
      app_mask_data   => app_mask_data,
      app_wdf_wren    => app_wdf_wren,
      ctrl_wdf_rden   => ctrl_wdf_rden,
      wdf_data        => wdf_data,
      mask_data       => mask_data,
      wdf_almost_full => wdf_almost_full
      );


end arc_user_interface;
