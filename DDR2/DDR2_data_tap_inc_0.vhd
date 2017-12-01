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
--  /   /        Filename           : DDR2_data_tap_inc.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This entity implements the tap selection for data
--               bits associated with a strobe.
-- Revision History:
--   Rev 1.1 - Changes for V4 no edge straddle calibration scheme. Added
--             PER_BIT_SKEW output and various other changes. PK. 12/22/07
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

entity DDR2_data_tap_inc_0 is
  port (
    clk                : in  std_logic;
    reset              : in  std_logic;
    calibration_dq     : in  std_logic_vector(DATABITSPERSTROBE-1 downto 0);
    ctrl_calib_start   : in  std_logic;
    dlyinc             : in  std_logic;
    dlyce              : in  std_logic;
    chan_done          : in  std_logic;
    dq_data            : out std_logic;
    data_dlyinc        : out std_logic_vector(DATABITSPERSTROBE-1 downto 0);
    data_dlyce         : out std_logic_vector(DATABITSPERSTROBE-1 downto 0);
    data_dlyrst        : out std_logic_vector(DATABITSPERSTROBE-1 downto 0);
    calib_done         : out std_logic;
    per_bit_skew       : out std_logic_vector(DATABITSPERSTROBE-1 downto 0)
    );
end entity;

architecture arc_data_tap_inc of DDR2_data_tap_inc_0 is

  signal muxout_d0d1       : std_logic;
  signal muxout_d2d3       : std_logic;
  signal muxout_d4d5       : std_logic;
  signal muxout_d6d7       : std_logic;
  signal muxout_d0_to_d3   : std_logic;
  signal muxout_d4_to_d7   : std_logic;
  signal data_dlyinc_int   : std_logic_vector(DATABITSPERSTROBE-1 downto 0);
  signal data_dlyce_int    : std_logic_vector(DATABITSPERSTROBE-1 downto 0);
  signal calib_done_int    : std_logic;
  signal calib_done_int_r1 : std_logic;
  signal calibration_dq_r  : std_logic_vector(DATABITSPERSTROBE-1 downto 0);

  signal chan_sel_int      : std_logic_vector(DATABITSPERSTROBE-1 downto 0);
  signal chan_sel          : std_logic_vector(DATABITSPERSTROBE-1 downto 0);

  signal reset_r1          : std_logic;

  attribute max_fanout : string;
  attribute syn_maxfan : integer;
  attribute max_fanout of calibration_dq_r : signal is "5";
  attribute syn_maxfan of calibration_dq_r : signal is 5;
  attribute max_fanout of chan_sel_int     : signal is "5";
  attribute syn_maxfan of chan_sel_int     : signal is 5;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of reset_r1 : signal is "no";
  attribute syn_preserve of reset_r1                : signal is true;
  attribute equivalent_register_removal of calibration_dq_r : signal is "no";
  attribute syn_preserve of calibration_dq_r                : signal is true;

begin

  --***************************************************************************

  data_dlyinc <= data_dlyinc_int;
  data_dlyce  <= data_dlyce_int;
  data_dlyrst <= (reset_r1 & reset_r1 & reset_r1 & reset_r1 & reset_r1 & reset_r1 & reset_r1 & reset_r1 );
  calib_done  <= calib_done_int;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      reset_r1 <= reset;
    end if;
  end process;

  process(clk)
  begin
    if (clk'event and clk = '1') then
      calibration_dq_r <= calibration_dq;
    end if;
  end process;

  process(clk)
  begin
    if (clk'event and clk = '1') then
      calib_done_int_r1 <= calib_done_int;
    end if;
  end process;


   -- DQ Data Select Mux
   -- Stage 1 Muxes
   muxout_d0d1 <= calibration_dq_r(1) when (chan_sel(1) = '1')
                  else calibration_dq_r(0);
   muxout_d2d3 <= calibration_dq_r(3) when (chan_sel(3) = '1')
                  else calibration_dq_r(2);
   muxout_d4d5 <= calibration_dq_r(5) when (chan_sel(5) = '1')
                  else calibration_dq_r(4);
   muxout_d6d7 <= calibration_dq_r(7) when (chan_sel(7) = '1')
                  else calibration_dq_r(6);

   -- Stage 2 Muxes
   muxout_d0_to_d3 <= muxout_d2d3 when (chan_sel(2) = '1' or chan_sel(3) = '1')
                      else muxout_d0d1;
   muxout_d4_to_d7 <= muxout_d6d7 when (chan_sel(6) = '1' or chan_sel(7) = '1')
                      else muxout_d4d5;

   -- Stage 3 Muxes
   dq_data <= muxout_d4_to_d7 when (chan_sel(4) = '1' or chan_sel(5) = '1' or
                                    chan_sel(6) = '1' or chan_sel(7) = '1')
              else muxout_d0_to_d3;



  -- RC: After calibration is complete, the Q1 output of each IDDR in the DQS
  -- group is recorded. It should either be a static 1 or 0, depending on
  -- which bit time is aligned to the rising edge of the FPGA CLK. If some
  -- of the bits are 0, and some are 1 - this indicates there is "bit-
  -- misalignment" within that DQS group. This will be handled later during
  -- pattern calibration and by enabling the delay/swap circuit to delay
  -- certain IDDR outputs by one bit time. For now, just record this "offset
  -- pattern" and provide this to the pattern calibration logic.
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (reset_r1 = '1' or (not(calib_done_int)) = '1') then
        per_bit_skew <= (others => '0');
      elsif (calib_done_int = '1' and (not(calib_done_int_r1)) = '1') then
        -- Store offset pattern immediately after per-bit calib finished
        per_bit_skew <= calibration_dq;
      end if;
    end if;
  end process;

  dlyce_dlyinc : for i in 0 to DATABITSPERSTROBE-1 generate
  begin
    data_dlyce_int(i)  <= dlyce  when(chan_sel(i) = '1') else '0';
    data_dlyinc_int(i) <= dlyinc when(chan_sel(i) = '1') else '0';
  end generate dlyce_dlyinc;

  -- Module that controls the calib_done
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (reset_r1 = '1') then
        calib_done_int <= '0';
      elsif(ctrl_calib_start = '1') then
        if (chan_sel = ADD_CONST3(DATABITSPERSTROBE-1 downto 0)) then
          calib_done_int <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Module that controls the chan_sel
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (reset_r1 = '1') then
        chan_sel_int <= ADD_CONST6((DATABITSPERSTROBE-1) downto 0);
      elsif(ctrl_calib_start = '1') then
        if (chan_done = '1') then
          chan_sel_int((DATABITSPERSTROBE-1) downto 1) <= chan_sel_int((DATABITSPERSTROBE-2) downto 0);
          chan_sel_int(0) <= '0';
        end if;
      end if;
    end if;
  end process;

  chan_sel_gen : for j in 0 to DATABITSPERSTROBE-1 generate
  begin
    chan_sel(j) <= chan_sel_int(j);
  end generate chan_sel_gen;


end arc_data_tap_inc;
