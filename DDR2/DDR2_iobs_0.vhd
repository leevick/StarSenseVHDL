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
--  /   /        Filename           : DDR2_iobs_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates all the iobs modules. It is the
--               interface between the main logic and the memory.
-- Revision History:
--   Rev 1.1 - Changes for the logic of 3-state enable for the data I/O.
--             wr_en vector sizes changed to 2-bit vector. PK. 11/11/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_iobs_0 is
  port (
    clk               : in    std_logic;
    clk90             : in    std_logic;
    ddr_ck            : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    ddr_ck_n          : out   std_logic_vector(CLK_WIDTH-1 downto 0);
    reset0            : in    std_logic;
    dqs_rst           : in    std_logic;
    dqs_en            : in    std_logic;
    wr_en             : in    std_logic_vector(1 downto 0);
    dm_wr_en          : in    std_logic;

    data_idelay_inc   : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    data_idelay_ce    : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    data_idelay_rst   : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    delay_enable      : in    std_logic_vector(DATA_WIDTH-1 downto 0);

    wr_data_rise      : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    wr_data_fall      : in    std_logic_vector(DATA_WIDTH-1 downto 0);
    mask_data_rise    : in    std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
    mask_data_fall    : in    std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
    rd_data_rise      : out   std_logic_vector(DATA_WIDTH-1 downto 0);
    rd_data_fall      : out   std_logic_vector(DATA_WIDTH-1 downto 0);

    ddr_dq            : inout std_logic_vector(DATA_WIDTH-1 downto 0);
    ddr_dqs           : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    ddr_dqs_l         : inout std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    ddr_dm            : out   std_logic_vector(DATA_MASK_WIDTH-1 downto 0);
    ddr_address       : out   std_logic_vector(ROW_ADDRESS-1 downto 0);
    ddr_ba            : out   std_logic_vector(BANK_ADDRESS-1 downto 0);
    ddr_ras_l         : out   std_logic;
    ddr_cas_l         : out   std_logic;
    ddr_we_l          : out   std_logic;
    ddr_cs_l          : out   std_logic_vector(CS_WIDTH-1 downto 0);
    ddr_cs_l_cpy          : out   std_logic_vector(CS_WIDTH-1 downto 0);
    ddr_cke           : out   std_logic_vector(CKE_WIDTH-1 downto 0);
    ddr_odt           : out   std_logic_vector(ODT_WIDTH-1 downto 0);
    ddr_odt_cpy           : out   std_logic_vector(ODT_WIDTH-1 downto 0);
    ctrl_ddr2_ras_l   : in    std_logic;
    ctrl_ddr2_cas_l   : in    std_logic;
    ctrl_ddr2_we_l    : in    std_logic;
    ctrl_ddr2_odt     : in    std_logic_vector(ODT_WIDTH-1 downto 0);
    ctrl_ddr2_odt_cpy     : in    std_logic_vector(ODT_WIDTH-1 downto 0);
    ctrl_ddr2_cke     : in    std_logic_vector(CKE_WIDTH-1 downto 0);
    ctrl_ddr2_cs_l    : in    std_logic_vector(CS_WIDTH-1 downto 0);
    ctrl_ddr2_cs_l_cpy    : in    std_logic_vector(CS_WIDTH-1 downto 0);
    ctrl_ddr2_ba      : in    std_logic_vector(BANK_ADDRESS-1 downto 0);
    ctrl_ddr2_address : in    std_logic_vector(ROW_ADDRESS-1 downto 0)
    );

end entity;

architecture  arc_iobs of DDR2_iobs_0 is

  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of arc_iobs : architecture IS
    "mig_v3_61_ddr2_dc_v4, Coregen 12.4";

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of arc_iobs : architecture IS "ddr2_dc_v4,mig_v3_61,{component_name=DDR2_iobs_0, data_width=32, data_strobe_width=4, data_mask_width=4, clk_width=2, fifo_16=2, cs_width=1, odt_width=1, cke_width=1, row_address=14, registered=0, single_rank=1, dual_rank=0, databitsperstrobe=8, mask_enable=1, use_dm_port=1, column_address=10, bank_address=3, debug_en=0, load_mode_register=00010000110010, ext_load_mode_register=00000000000000, chip_address=1, ecc_enable=0, ecc_width=0, reset_active_low=1, tby4tapvalue=17, rfc_count_value=00100111, ras_count_value=00111, rcd_count_value=010, rp_count_value=010, trtp_count_value=001, twr_count_value=011, twtr_count_value=001, max_ref_width=11, max_ref_cnt=11000011000, language=VHDL, synthesis_tool=ISE, interface_type=DDR2_SDRAM_Direct_Clocking, no_of_controllers=1}";

  component DDR2_data_path_iobs_0
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
  end component;

  component DDR2_controller_iobs_0
    port (
      ctrl_ddr2_address : in  std_logic_vector(ROW_ADDRESS-1 downto 0);
      ctrl_ddr2_ba      : in  std_logic_vector(BANK_ADDRESS-1 downto 0);
      ctrl_ddr2_ras_l   : in  std_logic;
      ctrl_ddr2_cas_l   : in  std_logic;
      ctrl_ddr2_we_l    : in  std_logic;
      ctrl_ddr2_cs_l    : in  std_logic_vector(CS_WIDTH-1 downto 0);
      ctrl_ddr2_cs_l_cpy    : in  std_logic_vector(CS_WIDTH-1 downto 0);
      ctrl_ddr2_cke     : in  std_logic_vector(CKE_WIDTH-1 downto 0);
      ctrl_ddr2_odt     : in  std_logic_vector(ODT_WIDTH-1 downto 0);
      ctrl_ddr2_odt_cpy     : in  std_logic_vector(ODT_WIDTH-1 downto 0);

      ddr_address       : out std_logic_vector(ROW_ADDRESS-1 downto 0);
      ddr_ba            : out std_logic_vector(BANK_ADDRESS-1 downto 0);
      ddr_ras_l         : out std_logic;
      ddr_cas_l         : out std_logic;
      ddr_we_l          : out std_logic;
      ddr_odt           : out std_logic_vector(ODT_WIDTH-1 downto 0);
      ddr_odt_cpy           : out std_logic_vector(ODT_WIDTH-1 downto 0);
      ddr_cke           : out std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr_cs_l          : out std_logic_vector(CS_WIDTH-1 downto 0);
      ddr_cs_l_cpy          : out std_logic_vector(CS_WIDTH-1 downto 0)
      );
  end  component;

  component DDR2_infrastructure_iobs_0
    port (
      clk      : in std_logic;
      ddr_ck   : out std_logic_vector(CLK_WIDTH-1 downto 0);
      ddr_ck_n : out std_logic_vector(CLK_WIDTH-1 downto 0)
      );
  end  component;

begin

  --***************************************************************************

  data_path_iobs_00 : DDR2_data_path_iobs_0
    port map (
      clk             => clk,
      clk90           => clk90,
      reset0          => reset0,
      dqs_rst         => dqs_rst,
      dqs_en          => dqs_en,

      data_idelay_inc => data_idelay_inc,
      data_idelay_ce  => data_idelay_ce,
      data_idelay_rst => data_idelay_rst,
      delay_enable    => delay_enable,
      wr_data_rise    => wr_data_rise,
      wr_data_fall    => wr_data_fall,
      wr_en           => wr_en,
      dm_wr_en        => dm_wr_en,
      rd_data_rise    => rd_data_rise,
      rd_data_fall    => rd_data_fall,
      mask_data_rise  => mask_data_rise,
      mask_data_fall  => mask_data_fall,

      ddr_dq          => ddr_dq,
      ddr_dqs         => ddr_dqs,
      ddr_dqs_l       => ddr_dqs_l,
      ddr_dm          => ddr_dm
      );

  controller_iobs_00 : DDR2_controller_iobs_0
    port map (
      ddr_address       => ddr_address,
      ddr_ba            => ddr_ba,
      ddr_ras_l         => ddr_ras_l,
      ddr_cas_l         => ddr_cas_l,
      ddr_we_l          => ddr_we_l,
      ddr_cs_l          => ddr_cs_l,
      ddr_cs_l_cpy          => ddr_cs_l_cpy,
      ddr_cke           => ddr_cke,
      ddr_odt           => ddr_odt,
      ddr_odt_cpy           => ddr_odt_cpy,

      ctrl_ddr2_address => ctrl_ddr2_address,
      ctrl_ddr2_ba      => ctrl_ddr2_ba,
      ctrl_ddr2_ras_l   => ctrl_ddr2_ras_l,
      ctrl_ddr2_cas_l   => ctrl_ddr2_cas_l,
      ctrl_ddr2_we_l    => ctrl_ddr2_we_l,
      ctrl_ddr2_cs_l    => ctrl_ddr2_cs_l,
      ctrl_ddr2_cs_l_cpy    => ctrl_ddr2_cs_l_cpy,
      ctrl_ddr2_cke     => ctrl_ddr2_cke,
      ctrl_ddr2_odt     => ctrl_ddr2_odt,
      ctrl_ddr2_odt_cpy     => ctrl_ddr2_odt_cpy
      );

  infrastructure_iobs_00 : DDR2_infrastructure_iobs_0
    port map (
      clk      => clk,
      ddr_ck   => ddr_ck,
      ddr_ck_n => ddr_ck_n
      );


end arc_iobs;
