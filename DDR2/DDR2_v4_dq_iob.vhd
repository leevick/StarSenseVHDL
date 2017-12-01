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
--  /   /        Filename           : DDR2_v4_dq_iob.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module places the data in the IOBs.
-- Revision History:
--   Rev 1.1 - Changes for V4 no edge straddle calibration scheme.
--             Optional circuit to delay the bit by one bit time.
--             Various other changes. PK. 12/22/07
--   Rev 1.2 - Modified the logic of 3-state enable for the I/O to enable
--             write data output one-half clock cycle before
--             the first data word, and disable the write data
--             one-half clock cycle after the last data word. PK. 11/11/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_v4_dq_iob is
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

end entity;

architecture arc_v4_dq_iob of DDR2_v4_dq_iob is

  signal dq_delayed    : std_logic;
  signal dq_in         : std_logic;
  signal dq_out        : std_logic;
  signal dq_q1         : std_logic;
  signal dq_q1_r       : std_logic;
  signal dq_q2         : std_logic;
  signal write_en_l    : std_logic_vector(1 downto 0);
  signal write_en_l_r1 : std_logic;
  signal vcc           : std_logic;
  signal gnd           : std_logic;
  signal reset0_r1     : std_logic;

  attribute IOB : string;
  attribute IOB of tri_state_dq : label is "FORCE";
  attribute syn_useioff : boolean;
  attribute syn_useioff of tri_state_dq : label is true;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of reset0_r1 : signal is "no";
  attribute syn_preserve of reset0_r1                : signal is true;

begin

  --***************************************************************************

  vcc        <= '1';
  gnd        <= '0';
  write_en_l <= not ctrl_wren;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      reset0_r1 <= reset0;
    end if;
  end process;

  oddr_dq : ODDR
    generic map (
      DDR_CLK_EDGE => "SAME_EDGE",
      SRTYPE       => "SYNC"
      )
    port map (
      Q  => dq_out,
      C  => clk90,
      CE => vcc,
      D1 => write_data_rise,
      D2 => write_data_fall,
      R  => gnd,
      S  => gnd
      );

  -- 3-state enable for the data I/O generated such that to enable
  -- write data output one-half clock cycle before
  -- the first data word, and disable the write data
  -- one-half clock cycle after the last data word
  tri_state_dq : ODDR
    generic map (
      DDR_CLK_EDGE => "SAME_EDGE",
      SRTYPE       => "SYNC"
      )
    port map (
      Q  => write_en_l_r1,
      C  => clk90,
      CE => vcc,
      D1 => write_en_l(0),
      D2 => write_en_l(1),
      R  => gnd,
      S  => gnd
      );

  iobuf_dq : IOBUF
    port map (
      I  => dq_out,
      T  => write_en_l_r1,
      IO => ddr_dq,
      O  => dq_in
      );

  idelay_dq : IDELAY
    generic map (
      IOBDELAY_TYPE  => "VARIABLE",
      IOBDELAY_VALUE => 0
      )
    port map (
      O   => dq_delayed,
      I   => dq_in,
      C   => clk,
      CE  => data_dlyce,
      INC => data_dlyinc,
      RST => data_dlyrst
      );

  iddr_dq : IDDR
    generic map(
      DDR_CLK_EDGE => "SAME_EDGE",
      SRTYPE       => "SYNC"
      )
    port map (
      Q1 => dq_q1,
      Q2 => dq_q2,
      C  => clk,
      CE => vcc,
      D  => dq_delayed,
      R  => gnd,
      S  => gnd
      );

   --*******************************************************************
   -- RC: Optional circuit to delay the bit by one bit time - may be
   -- necessary if there is bit-misalignment (e.g. rising edge of FPGA
   -- clock may be capturing bit[n] for DQ[0] but bit[n+1] for DQ[1])
   -- within a DQS group. The operation for delaying by one bit time
   -- involves delaying the Q1 (rise) output of the IDDR, and "flipping"
   -- the Q bits
   --*******************************************************************

   u_fd_dly_q1 : FDRSE
    port map (
      Q  => dq_q1_r,
      C  => clk,
      CE => vcc,
      D  => dq_q1,
      R  => gnd,
      S  => gnd
      );

  rd_data_rise <= dq_q2 when (delay_enable = '1') else dq_q1;
  rd_data_fall <= dq_q1_r when (delay_enable = '1') else dq_q2  ;


end arc_v4_dq_iob;
