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
--  /   /        Filename           : DDR2_backend_rom_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates the addr_gen and the data_gen modules.
--               It takes the user data stored in internal FIFOs and gives the
--               data that is to be compared with the read data.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_backend_rom_0 is
  port (
    clk0                : in  std_logic;
    rst                 : in  std_logic;
    -- enables signals from state machine
    bkend_data_en       : in  std_logic;
    bkend_wraddr_en     : in  std_logic;
    bkend_rd_data_valid : in  std_logic;

    -- Write address fifo signals
    app_af_addr         : out std_logic_vector(35 downto 0);
    app_af_wren         : out std_logic;
    -- Write data fifo signals
    app_wdf_data        : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
    app_mask_data       : out std_logic_vector(DM_WIDTH*2-1 downto 0);
    -- data for the backend compare logic
    app_compare_data    : out std_logic_vector(DQ_WIDTH*2-1 downto 0);
    app_wdf_wren        : out std_logic
    );
end entity;

architecture arc_backend_rom of DDR2_backend_rom_0 is

  component DDR2_data_gen_16
    port (
      clk0                : in  std_logic;
      rst                 : in  std_logic;
      bkend_data_en       : in  std_logic;
      bkend_rd_data_valid : in  std_logic;
      app_wdf_data        : out std_logic_vector(31 downto 0);
      app_mask_data       : out std_logic_vector(3 downto 0);
      app_compare_data    : out std_logic_vector(31 downto 0);
      app_wdf_wren        : out std_logic
      );
  end component;

  component DDR2_data_gen_8
    port (
      clk0                : in  std_logic;
      rst                 : in  std_logic;
      bkend_data_en       : in  std_logic;
      bkend_rd_data_valid : in  std_logic;
      app_wdf_data        : out std_logic_vector(15 downto 0);
      app_mask_data       : out std_logic_vector(1 downto 0);
      app_compare_data    : out std_logic_vector(15 downto 0);
      app_wdf_wren        : out std_logic
      );
  end component;

  component DDR2_addr_gen_0
    port (
      clk0            : in  std_logic;
      rst             : in  std_logic;
      bkend_wraddr_en : in  std_logic;
      app_af_addr     : out std_logic_vector(35 downto 0);
      app_af_wren     : out std_logic
      );
  end component;

  signal app_wdf_data0     : std_logic_vector(31 downto 0);
  signal app_wdf_data1     : std_logic_vector(31 downto 0);


  signal app_mask_data0    : std_logic_vector(3 downto 0);
  signal app_mask_data1    : std_logic_vector(3 downto 0);


  signal app_compare_data0 : std_logic_vector(31 downto 0);
  signal app_compare_data1 : std_logic_vector(31 downto 0);


  signal app_wdf_wren_w    : std_logic_vector((FIFO_16-1) downto 0);

  attribute syn_preserve : boolean;
  attribute syn_preserve of data_gen_0 :label is true;
  attribute syn_preserve of data_gen_1 :label is true;

begin

  --***************************************************************************

  app_wdf_data     <= (  app_wdf_data1(31 downto 16)& app_wdf_data0(31 downto 16) &
                         app_wdf_data1(15 downto 0) & app_wdf_data0(15 downto 0) );

  app_mask_data    <= (  app_mask_data1(3 downto 2) & app_mask_data0(3 downto 2)  &
                         app_mask_data1(1 downto 0)& app_mask_data0(1 downto 0));

  app_compare_data <= (  app_compare_data1(31 downto 16)& app_compare_data0(31 downto 16) &
                         app_compare_data1(15 downto 0)& app_compare_data0(15 downto 0));

  app_wdf_wren     <= app_wdf_wren_w(FIFO_16-1);

  addr_gen_00 : DDR2_addr_gen_0
    port map (
      clk0            => clk0,
      rst             => rst,
      bkend_wraddr_en => bkend_wraddr_en,
      app_af_addr     => app_af_addr,
      app_af_wren     => app_af_wren
      );

  data_gen_0  : DDR2_data_gen_16
    port map (
      clk0                => clk0,
      rst                 => rst,
      bkend_data_en       => bkend_data_en,
      bkend_rd_data_valid => bkend_rd_data_valid,
      app_wdf_data        => app_wdf_data0(31 downto 0),
      app_mask_data       => app_mask_data0(3 downto 0),
      app_compare_data    => app_compare_data0(31 downto 0),
      app_wdf_wren        => app_wdf_wren_w(0)
      );


  data_gen_1  : DDR2_data_gen_16
    port map (
      clk0                => clk0,
      rst                 => rst,
      bkend_data_en       => bkend_data_en,
      bkend_rd_data_valid => bkend_rd_data_valid,
      app_wdf_data        => app_wdf_data1(31 downto 0),
      app_mask_data       => app_mask_data1(3 downto 0),
      app_compare_data    => app_compare_data1(31 downto 0),
      app_wdf_wren        => app_wdf_wren_w(1)
      );



end arc_backend_rom;
