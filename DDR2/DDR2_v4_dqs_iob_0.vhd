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
--  /   /        Filename           : DDR2_v4_dqs_iob_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module places the data strobes in the IOBs.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_v4_dqs_iob_0 is
  port (
    clk          : in    std_logic;
    reset        : in    std_logic;
    ctrl_dqs_rst : in    std_logic;
    ctrl_dqs_en  : in    std_logic;
    ddr_dqs_l    : inout std_logic;
    ddr_dqs      : inout std_logic
    );
end entity;

architecture arc_v4_dqs_iob of DDR2_v4_dqs_iob_0 is

  signal dqs_in         : std_logic;
  signal dqs_out        : std_logic;
  signal ctrl_dqs_en_r1 : std_logic;
  signal vcc            : std_logic;
  signal gnd            : std_logic;
  signal clk180         : std_logic;
  signal data1          : std_logic;
  signal reset_r1       : std_logic;

  attribute IOB : string;
  attribute IOB of tri_state_dqs : label is "FORCE";
  attribute syn_useioff : boolean;
  attribute syn_useioff of tri_state_dqs : label is true;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of reset_r1 : signal is "no";
  attribute syn_preserve of reset_r1                : signal is true;

begin

  --***************************************************************************

  vcc    <= '1';
  gnd    <= '0';
  clk180 <= not clk;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      reset_r1 <= reset;
    end if;
  end process;

  process(clk180)
  begin
    if clk180'event and clk180 = '1' then
      if (ctrl_dqs_rst = '1') then
        data1 <= '0';
      else
        data1 <= '1';
      end if;
    end if;
  end process;

  oddr_dqs : ODDR
    generic map(
      DDR_CLK_EDGE => "OPPOSITE_EDGE",
      SRTYPE       => "SYNC"
      )
    port map (
      Q  => dqs_out,
      C  => clk180,
      CE => vcc,
      D1 => data1,
      D2 => gnd,
      R  => gnd,
      S  => gnd
      );

  tri_state_dqs : FDP
    port map (
      Q   => ctrl_dqs_en_r1,
      C   => clk180,
      D   => ctrl_dqs_en,
      PRE => gnd
      );


  iobuf_dqs : IOBUFDS
    port map (
      O   => dqs_in,
      IO  => ddr_dqs,
      IOB => ddr_dqs_l,
      I   => dqs_out,
      T   => ctrl_dqs_en_r1
      );



end arc_v4_dqs_iob;
