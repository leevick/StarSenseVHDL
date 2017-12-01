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
--  /   /        Filename           : DDR2_data_path_iobs_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates data, data strobe and
--               the data mask iobs.
-- Revision History:
--   Rev 1.1 - DM_IOB instance made based on USE_DM_PORT value . PK. 25/6/08
--   Rev 1.2 - Changes for the logic of 3-state enable for the data I/O.
--             wr_en vector size changed to 2-bit vector. PK. 11/11/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity DDR2_data_path_iobs_0 is
  port (
    clk             : in    std_logic;
    clk90           : in    std_logic;
    reset0          : in    std_logic;
    dqs_rst         : in    std_logic;
    dqs_en          : in    std_logic;
    data_idelay_inc : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    data_idelay_ce  : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    data_idelay_rst : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    delay_enable    : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    wr_data_rise    : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    wr_data_fall    : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    mask_data_rise  : in    std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
    mask_data_fall  : in    std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
    wr_en           : in    std_logic_vector(1 downto 0);
    dm_wr_en        : in    std_logic;

    ddr_dq          : inout std_logic_vector(DATA_WIDTH-1 downto 0);
    ddr_dqs         : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    ddr_dqs_l       : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    ddr_dm          : out   std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
    rd_data_rise    : out   std_logic_vector(DATA_WIDTH-1 downto 0);
    rd_data_fall    : out   std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture arc_data_path_iobs of DDR2_data_path_iobs_0 is

  component DDR2_v4_dqs_iob_0
    port (
      clk          : in    std_logic;
      reset        : in    std_logic;
      ctrl_dqs_rst : in    std_logic;
      ctrl_dqs_en  : in    std_logic;
      ddr_dqs_l    : inout std_logic;
      ddr_dqs      : inout std_logic
      );
  end component;

  component DDR2_v4_dq_iob
    port (
      clk             : in    std_logic;
      clk90           : in    std_logic;
      reset0          : in    std_logic;
      data_dlyinc     : in    std_logic;
      data_dlyce      : in    std_logic;
      data_dlyrst     : in    std_logic;
      write_data_rise : in    std_logic;
      write_data_fall : in    std_logic;
      ctrl_wren       : in    std_logic_vector(1 downto 0);
      delay_enable    : in    std_logic;
      rd_data_rise    : out   std_logic;
      rd_data_fall    : out   std_logic;
      ddr_dq          : inout std_logic
      );
  end component;

  component DDR2_v4_dm_iob
    port (
      clk90          : in  std_logic;
      mask_data_rise : in  std_logic;
      mask_data_fall : in  std_logic;
      dm_wr_en       : in  std_logic;
      ddr_dm         : out std_logic
      );
  end component;

begin

  --***************************************************************************

  --***************************************************************************
  -- DQS instances
  --***************************************************************************

  gen_dqs: for dqs_i in 0 to DATA_STROBE_WIDTH-1 generate
    u_iob_dqs  : DDR2_v4_dqs_iob_0
      port map (
        clk          => clk,
        reset        => reset0,
        ctrl_dqs_rst => dqs_rst,
        ctrl_dqs_en  => dqs_en,
        ddr_dqs      => ddr_dqs(dqs_i),
        ddr_dqs_l    => ddr_dqs_l(dqs_i)
        );
  end generate;


  --***************************************************************************
  -- DM instances
  --***************************************************************************

  gen_dm_inst: if (USE_DM_PORT = 1) generate
    gen_dm: for dm_i in 0 to DATA_MASK_WIDTH-1 generate
      u_iob_dm : DDR2_v4_dm_iob
        port map (
          clk90          => clk90,
          mask_data_rise => mask_data_rise(dm_i),
          mask_data_fall => mask_data_fall(dm_i),
          dm_wr_en       => dm_wr_en,
          ddr_dm         => ddr_dm(dm_i)
          );
    end generate;
  end generate;

  --***************************************************************************
  -- DQ IOB instances
  --***************************************************************************

  gen_dq: for dq_i in 0 to DATA_WIDTH-1 generate
    u_iob_dq : DDR2_v4_dq_iob
      port map (
        clk             => clk,
        clk90           => clk90,
	reset0          => reset0,
        data_dlyinc     => data_idelay_inc(dq_i),
        data_dlyce      => data_idelay_ce(dq_i),
        data_dlyrst     => data_idelay_rst(dq_i),
        write_data_rise => wr_data_rise(dq_i),
        write_data_fall => wr_data_fall(dq_i),
        ctrl_wren       => wr_en,
        delay_enable    => delay_enable(dq_i),
        ddr_dq          => ddr_dq(dq_i),
        rd_data_rise    => rd_data_rise(dq_i),
        rd_data_fall    => rd_data_fall(dq_i)
        );
  end generate;

end arc_data_path_iobs;
