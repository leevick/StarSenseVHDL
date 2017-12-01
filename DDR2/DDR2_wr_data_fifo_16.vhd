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
--  /   /        Filename           : DDR2_wr_data_fifo_16.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates the block RAM based FIFO to store
--               the user interface data into it and read after a specified
--               amount in already written. The reading starts when the
--               almost full signal is generated whose offset is programmable.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity DDR2_wr_data_fifo_16 is
  port(
    clk0              : in  std_logic;
    clk90             : in  std_logic;
    rst               : in  std_logic;
    -- Write data fifo signals
    app_wdf_data      : in  std_logic_vector(31 downto 0);
    app_mask_data     : in  std_logic_vector(3 downto 0);
    app_wdf_wren      : in  std_logic;
    ctrl_wdf_rden     : in  std_logic;
    wdf_data          : out std_logic_vector(31 downto 0);
    mask_data         : out std_logic_vector(3 downto 0);
    wr_df_almost_full : out std_logic
    );
end entity;

architecture arc_wr_data_fifo_16 of DDR2_wr_data_fifo_16 is

  signal ctrl_wdf_rden_270 : std_logic;
  signal ctrl_wdf_rden_90  : std_logic;

  signal rst_r1            : std_logic;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of rst_r1        : signal is "no";
  attribute syn_preserve of rst_r1                       : signal is true;

begin

  --***************************************************************************

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      rst_r1 <= rst;
    end if;
  end process;

  process(clk90)
  begin
    if clk90'event and clk90 = '0' then
      ctrl_wdf_rden_270 <= ctrl_wdf_rden;
    end if;
  end process;

  process(clk90)
  begin
    if clk90'event and clk90 = '1' then
      ctrl_wdf_rden_90 <= ctrl_wdf_rden_270;
    end if;
  end process;

  Wdf_1 : FIFO16
    generic map(
      ALMOST_FULL_OFFSET      => X"00F",
      ALMOST_EMPTY_OFFSET     => X"007",
      DATA_WIDTH              => 36,
      FIRST_WORD_FALL_THROUGH => FALSE
      )
    port map (
      ALMOSTEMPTY => open,
      ALMOSTFULL  => wr_df_almost_full,
      DO          => wdf_data(31 downto 0),
      DOP         => mask_data(3 downto 0),
      EMPTY       => open,
      FULL        => open,
      RDCOUNT     => open,
      RDERR       => open,
      WRCOUNT     => open,
      WRERR       => open,
      DI          => app_wdf_data(31 downto 0),
      DIP         => app_mask_data(3 downto 0),
      RDCLK       => clk90,
      RDEN        => ctrl_wdf_rden_90,
      RST         => rst_r1,
      WRCLK       => clk0,
      WREN        => app_wdf_wren
      );


end arc_wr_data_fifo_16;
