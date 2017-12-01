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
--  /   /        Filename           : DDR2_data_write_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module splits the user data into the rise data
--               and the fall data.
-- Revision History:
--   Rev 1.1 - Modified the logic of 3-state enable for the data I/O to enable
--             write data output one-half clock cycle before
--             the first data word, and disable the write data
--             one-half clock cycle after the last data word. PK. 11/11/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity DDR2_data_write_0 is
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
    dm_wr_en          : out std_logic;
    dqs_rst           : out std_logic;
    dqs_en            : out std_logic
    );

end entity;

architecture arc_data_write of DDR2_data_write_0 is

  signal dqs_rst_r1            : std_logic;
  signal dqs_rst_r2            : std_logic;
  signal dqs_en_r1             : std_logic;
  signal dqs_en_r2             : std_logic;
  signal dqs_en_r3             : std_logic;

  signal wr_en_clk270_r1       : std_logic;
  signal wr_en_clk270_r2       : std_logic;
  signal wr_en_clk90_r2        : std_logic;
  signal wr_en_clk90_r3        : std_logic;
  signal wr_en_clk90_r4        : std_logic;

  signal reset90_r1            : std_logic;


  attribute syn_preserve                   : boolean;
  attribute syn_preserve of arc_data_write : architecture is true;

  attribute max_fanout : string;
  attribute syn_maxfan : integer;
  attribute max_fanout of dqs_en_r3       : signal is "5";
  attribute syn_maxfan of dqs_en_r3       : signal is 5;

begin

  --***************************************************************************

  dqs_rst    <= dqs_rst_r2;
  dqs_en     <= dqs_en_r3;

  -- 3-state enable for the data I/O generated such that to enable
  -- write data output one-half clock cycle before
  -- the first data word, and disable the write data
  -- one-half clock cycle after the last data word
  wr_en(0)   <= wr_en_clk90_r3 or wr_en_clk90_r4;
  wr_en(1)   <= wr_en_clk90_r2 or wr_en_clk90_r3;
  dm_wr_en   <= wr_en_clk270_r2;

  process(clk90)
  begin
    if (clk90 = '1' and clk90'event) then
      reset90_r1 <= reset90;
    end if;
  end process;

  process(clk90)
  begin
    if (clk90'event and clk90 = '0') then
      wr_en_clk270_r1 <= ctrl_wren;
      wr_en_clk270_r2 <= wr_en_clk270_r1;
      dqs_rst_r1      <= ctrl_dqs_rst;
      dqs_en_r1       <= not ctrl_dqs_en;
    end if;
  end process;

  process (clk)
  begin
    if (clk'event and clk = '0') then
      dqs_rst_r2 <= dqs_rst_r1;
      dqs_en_r2  <= dqs_en_r1;
      dqs_en_r3  <= dqs_en_r2;
    end if;
  end process;

  process(clk90)
  begin
    if (clk90'event and clk90 = '1') then
      wr_en_clk90_r2 <= wr_en_clk270_r1;
      wr_en_clk90_r3 <= wr_en_clk90_r2;
      wr_en_clk90_r4 <= wr_en_clk90_r3;
    end if;
  end process;

  --***************************************************************************
  -- Format write data/mask: Data is in format: {rise, fall}
  --***************************************************************************

  wr_data_rise <= wdf_data((DQ_WIDTH*2)-1 downto DQ_WIDTH);
  wr_data_fall <= wdf_data((DQ_WIDTH-1) downto 0);




  mask_data_rise <= mask_data((DM_WIDTH*2)-1 downto DM_WIDTH);
  mask_data_fall <= mask_data((dm_width-1) downto 0);


end arc_data_write;
