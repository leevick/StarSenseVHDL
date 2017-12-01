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
--  /   /        Filename           : DDR2_v4_dm_iob.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module places the data mask signals into the IOBs.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity DDR2_v4_dm_iob is
  port (
    clk90          : in  std_logic;
    mask_data_rise : in  std_logic;
    mask_data_fall : in  std_logic;
    dm_wr_en       : in  std_logic;
    ddr_dm         : out std_logic
    );

end entity;

architecture arc_v4_dm_iob of DDR2_v4_dm_iob is

  signal dm_out        : std_logic;
  signal write_en_l    : std_logic;
  signal write_en_l_r1 : std_logic;
  signal vcc           : std_logic;
  signal gnd           : std_logic;
  signal clk270        : std_logic;

  attribute syn_preserve : boolean;
  attribute syn_preserve of dm_oddr_ce : label is true;

begin

  --***************************************************************************

  vcc        <= '1';
  gnd        <= '0';
  write_en_l <= dm_wr_en;
  clk270     <= not clk90;

  dm_oddr_ce : FDRSE
    port map(
      Q  => write_en_l_r1,
      C  => clk270,
      CE => vcc,
      D  => write_en_l,
      R  => gnd,
      S  => gnd
      );

  oddr_dm : ODDR
    generic map(
      DDR_CLK_EDGE => "SAME_EDGE",
      SRTYPE       => "SYNC"
      )
    port map (
      Q  => dm_out,
      C  => clk90,
      CE => write_en_l_r1,
      D1 => mask_data_rise,
      D2 => mask_data_fall,
      R  => gnd,
      S  => gnd
      );

  obuf_dm : OBUF
    port map (
      I => dm_out,
      O => ddr_dm
      );


end arc_v4_dm_iob;
