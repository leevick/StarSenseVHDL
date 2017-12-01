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
--  /   /        Filename           : DDR2.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : It is the top most module which interfaces with the system
--               and the memory.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2 is
  port (
      cntrl0_ddr2_dq                : inout std_logic_vector(31 downto 0);
      cntrl0_ddr2_a                 : out   std_logic_vector(13 downto 0);
      cntrl0_ddr2_ba                : out   std_logic_vector(2 downto 0);
      cntrl0_ddr2_ras_n             : out   std_logic;
      cntrl0_ddr2_cas_n             : out   std_logic;
      cntrl0_ddr2_we_n              : out   std_logic;
      cntrl0_ddr2_cs_n              : out   std_logic_vector(0 downto 0);
      cntrl0_ddr2_odt               : out   std_logic_vector(0 downto 0);
      cntrl0_ddr2_odt_cpy               : out   std_logic_vector(0 downto 0);
      cntrl0_ddr2_cke               : out   std_logic_vector(0 downto 0);
      cntrl0_ddr2_dm                : out   std_logic_vector(3 downto 0);
      sys_reset_in_n                : in    std_logic;
      cntrl0_init_done              : out   std_logic;
      cntrl0_clk_tb                 : out   std_logic;
      cntrl0_reset_tb               : out   std_logic;
      cntrl0_wdf_almost_full        : out   std_logic;
      cntrl0_af_almost_full         : out   std_logic;
      cntrl0_read_data_valid        : out   std_logic;
      cntrl0_app_wdf_wren           : in    std_logic;
      cntrl0_app_af_wren            : in    std_logic;
      cntrl0_burst_length_div2      : out   std_logic_vector(2 downto 0);
      cntrl0_app_af_addr            : in    std_logic_vector(35 downto 0);
      cntrl0_read_data_fifo_out     : out   std_logic_vector(63 downto 0);
      cntrl0_app_wdf_data           : in    std_logic_vector(63 downto 0);
      cntrl0_app_mask_data          : in    std_logic_vector(7 downto 0);
      clk_0                         : in    std_logic;
      clk_90                        : in    std_logic;
      clk_200                       : in    std_logic;
      dcm_lock                      : in    std_logic;
      cntrl0_ddr2_dqs               : inout std_logic_vector(3 downto 0);
      cntrl0_ddr2_dqs_n             : inout std_logic_vector(3 downto 0);
      cntrl0_ddr2_ck                : out   std_logic_vector(1 downto 0);
      cntrl0_ddr2_ck_n              : out   std_logic_vector(1 downto 0)
    );

  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of DDR2 : ENTITY IS
    "mig_v3_61_ddr2_dc_v4, Coregen 12.4";

end entity DDR2;

architecture arc_mem_interface_top of DDR2 is

component DDR2_top_0
    port (
      ddr2_dq               : inout std_logic_vector(31 downto 0);
      ddr2_a                : out   std_logic_vector(13 downto 0);
      ddr2_ba               : out   std_logic_vector(2 downto 0);
      ddr2_ras_n            : out   std_logic;
      ddr2_cas_n            : out   std_logic;
      ddr2_we_n             : out   std_logic;
      ddr2_cs_n             : out   std_logic_vector(0 downto 0);
      ddr2_odt              : out   std_logic_vector(0 downto 0);
      ddr2_odt_cpy              : out   std_logic_vector(0 downto 0);
      ddr2_cke              : out   std_logic_vector(0 downto 0);
      ddr2_dm               : out   std_logic_vector(3 downto 0);
      init_done             : out   std_logic;
      clk_tb                : out   std_logic;
      reset_tb              : out   std_logic;
      wdf_almost_full       : out   std_logic;
      af_almost_full        : out   std_logic;
      read_data_valid       : out   std_logic;
      app_wdf_wren          : in    std_logic;
      app_af_wren           : in    std_logic;
      burst_length_div2     : out   std_logic_vector(2 downto 0);
      app_af_addr           : in    std_logic_vector(35 downto 0);
      read_data_fifo_out    : out   std_logic_vector(63 downto 0);
      app_wdf_data          : in    std_logic_vector(63 downto 0);
      app_mask_data         : in    std_logic_vector(7 downto 0);
      ddr2_dqs              : inout std_logic_vector(3 downto 0);
      ddr2_dqs_n            : inout std_logic_vector(3 downto 0);
      ddr2_ck               : out   std_logic_vector(1 downto 0);
      ddr2_ck_n             : out   std_logic_vector(1 downto 0);
      clk_0                 : in    std_logic;
      clk_90                : in    std_logic;
   
      sys_rst               : in    std_logic;   
      sys_rst90             : in    std_logic;   
      --Debug ports
      dbg_idel_up_all              : in   std_logic;
      dbg_idel_down_all            : in   std_logic;
      dbg_idel_up_dq               : in   std_logic;
      dbg_idel_down_dq             : in   std_logic;
      dbg_sel_idel_dq              : in   std_logic_vector(4 downto 0);
      dbg_sel_all_idel_dq          : in   std_logic;
      dbg_calib_dq_tap_cnt         : out   std_logic_vector(191 downto 0);
      dbg_data_tap_inc_done        : out   std_logic_vector(3 downto 0);
      dbg_sel_done                 : out   std_logic;
      dbg_first_rising             : out   std_logic_vector(3 downto 0);
      dbg_cal_first_loop           : out   std_logic_vector(3 downto 0);
      dbg_comp_done                : out   std_logic_vector(3 downto 0);
      dbg_comp_error               : out   std_logic_vector(3 downto 0);
      dbg_init_done                : out   std_logic
   );
end component;

  component DDR2_infrastructure
    port (
      sys_reset_in_n        : in    std_logic;
      clk_0                 : in    std_logic;
      clk_90                : in    std_logic;
      clk_200               : in    std_logic;
      dcm_lock              : in    std_logic;
      idelay_ctrl_rdy       : in    std_logic;
      sys_rst               : out   std_logic;
      sys_rst90             : out   std_logic;
      sys_rst200            : out   std_logic
      );
  end component;

  component DDR2_idelay_ctrl
    port (
      clk200     : in  std_logic;
      reset      : in  std_logic;
      rdy_status : out std_logic
      );
  end component;



  signal idelay_ctrl_rdy  : std_logic;
  signal sys_rst          : std_logic;
  signal sys_rst90        : std_logic;
  signal sys_rst200       : std_logic;

  signal dbg_idel_up_all              : std_logic;
  signal dbg_idel_down_all            : std_logic;
  signal dbg_idel_up_dq               : std_logic;
  signal dbg_idel_down_dq             : std_logic;
  signal dbg_sel_idel_dq              : std_logic_vector(4 downto 0);
  signal dbg_sel_all_idel_dq          : std_logic;
  signal dbg_calib_dq_tap_cnt         : std_logic_vector(191 downto 0);
  signal dbg_data_tap_inc_done        : std_logic_vector(3 downto 0);
  signal dbg_sel_done                 : std_logic;
  signal dbg_first_rising             : std_logic_vector(3 downto 0);
  signal dbg_cal_first_loop           : std_logic_vector(3 downto 0);
  signal dbg_comp_done                : std_logic_vector(3 downto 0);
  signal dbg_comp_error               : std_logic_vector(3 downto 0);
  signal dbg_init_done                : std_logic;

  --***********************************
  -- PHY Debug Port demo
  --***********************************
  signal cs_control0 : std_logic_vector(35 downto 0);
  signal cs_control1 : std_logic_vector(35 downto 0);
  signal cs_control2 : std_logic_vector(35 downto 0);
  signal vio0_in     : std_logic_vector(192 downto 0);
  signal vio1_in     : std_logic_vector(42 downto 0);
  signal vio2_out    : std_logic_vector(9 downto 0);

  attribute syn_useioff : boolean;
  attribute syn_useioff of arc_mem_interface_top : architecture is true;

begin

  --***************************************************************************

top_00 :    DDR2_top_0
    port map (
      ddr2_dq               => cntrl0_ddr2_dq,
      ddr2_a                => cntrl0_ddr2_a,
      ddr2_ba               => cntrl0_ddr2_ba,
      ddr2_ras_n            => cntrl0_ddr2_ras_n,
      ddr2_cas_n            => cntrl0_ddr2_cas_n,
      ddr2_we_n             => cntrl0_ddr2_we_n,
      ddr2_cs_n             => cntrl0_ddr2_cs_n,
      ddr2_odt              => cntrl0_ddr2_odt,
      ddr2_odt_cpy              => cntrl0_ddr2_odt_cpy,
      ddr2_cke              => cntrl0_ddr2_cke,
      ddr2_dm               => cntrl0_ddr2_dm,
      init_done             => cntrl0_init_done,
      clk_tb                => cntrl0_clk_tb,
      reset_tb              => cntrl0_reset_tb,
      wdf_almost_full       => cntrl0_wdf_almost_full,
      af_almost_full        => cntrl0_af_almost_full,
      read_data_valid       => cntrl0_read_data_valid,
      app_wdf_wren          => cntrl0_app_wdf_wren,
      app_af_wren           => cntrl0_app_af_wren,
      burst_length_div2     => cntrl0_burst_length_div2,
      app_af_addr           => cntrl0_app_af_addr,
      read_data_fifo_out    => cntrl0_read_data_fifo_out,
      app_wdf_data          => cntrl0_app_wdf_data,
      app_mask_data         => cntrl0_app_mask_data,
      ddr2_dqs              => cntrl0_ddr2_dqs,
      ddr2_dqs_n            => cntrl0_ddr2_dqs_n,
      ddr2_ck               => cntrl0_ddr2_ck,
      ddr2_ck_n             => cntrl0_ddr2_ck_n,
      clk_0                 => clk_0,
      clk_90                => clk_90,
   
      sys_rst               => sys_rst,
      sys_rst90             => sys_rst90,

      dbg_idel_up_all              => dbg_idel_up_all,
      dbg_idel_down_all            => dbg_idel_down_all,
      dbg_idel_up_dq               => dbg_idel_up_dq,
      dbg_idel_down_dq             => dbg_idel_down_dq,
      dbg_sel_idel_dq              => dbg_sel_idel_dq,
      dbg_sel_all_idel_dq          => dbg_sel_all_idel_dq,
      dbg_calib_dq_tap_cnt         => dbg_calib_dq_tap_cnt,
      dbg_data_tap_inc_done        => dbg_data_tap_inc_done,
      dbg_sel_done                 => dbg_sel_done,
      dbg_first_rising             => dbg_first_rising,
      dbg_cal_first_loop           => dbg_cal_first_loop,
      dbg_comp_done                => dbg_comp_done,
      dbg_comp_error               => dbg_comp_error,
      dbg_init_done                => dbg_init_done   );


  infrastructure0 :  DDR2_infrastructure
    port map (
      sys_reset_in_n        => sys_reset_in_n,
      clk_0                 => clk_0,
      clk_90                => clk_90,
      clk_200               => clk_200,
      dcm_lock              => dcm_lock,
      idelay_ctrl_rdy       => idelay_ctrl_rdy,
      sys_rst               => sys_rst,
      sys_rst90             => sys_rst90,
      sys_rst200            => sys_rst200
      );

  --***************************************************************************
  -- IDELAYCTRL instantiation
  --***************************************************************************

  idelay_ctrl0 : DDR2_idelay_ctrl
    port map (
      clk200 => clk_200,
      reset      => sys_rst200,
      rdy_status => idelay_ctrl_rdy
      );

  --*************************************************************************
  -- Hooks to prevent sim/syn compilation errors. When DEBUG_EN = 0, all the
  -- debug input signals are floating. To avoid this, they are connected to
  -- all zeros.
  --*************************************************************************
  dbg_idel_up_all       <= '0';
  dbg_idel_down_all     <= '0';
  dbg_idel_up_dq        <= '0';
  dbg_idel_down_dq      <= '0';
  dbg_sel_idel_dq       <= (others => '0');
  dbg_sel_all_idel_dq   <= '0';


end arc_mem_interface_top;
