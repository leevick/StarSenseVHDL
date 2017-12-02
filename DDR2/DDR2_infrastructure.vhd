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
--  /   /        Filename           : DDR2_infrastructure.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates the DCM of the FPGA device. The
--               system clock is given as the input and two clocks that
--               are phase shifted by 90 degrees are taken out. It also
--               give the reset signals in phase with the clocks.
--Revision History:
--   Rev 1.1 - Parameter CLK_TYPE added and logic for  DIFFERENTIAL and 
--             SINGLE_ENDED added. PK. 20/6/08
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_infrastructure is
  port (
    sys_reset_in_n      : in std_logic;
    idelay_ctrl_rdy     : in std_logic;
    sys_clk_p           : in std_logic;
    sys_clk_n           : in std_logic;
    sys_clk             : in std_logic;
    clk200_p            : in std_logic;
    clk200_n            : in std_logic;
    idly_clk_200        : in std_logic;

    clk_0               : out std_logic;
    clk_90              : out std_logic;
    clk_200             : out std_logic; 
    sys_rst             : out std_logic;
    sys_rst90           : out std_logic;
    sys_rst200          : out std_logic
    );
end entity;

architecture arc_infrastructure of DDR2_infrastructure is

  -- # of clock cycles to delay deassertion of reset. Needs to be a fairly
  -- high number not so much for metastability protection, but to give time
  -- for reset (i.e. stable clock cycles) to propagate through all state
  -- machines and to all control signals (i.e. not all control signals have
  -- resets, instead they rely on base state logic being reset, and the effect
  -- of that reset propagating through the logic). Need this because we may not
  -- be getting stable clock cycles while reset asserted (i.e. since reset
  -- depends on DCM lock status)
  constant RST_SYNC_NUM        : integer := 25;


  signal clk0_bufg_in          : std_logic;
  signal clk90_bufg_in         : std_logic;
  signal clk0_bufg_out         : std_logic;
  signal clk90_bufg_out        : std_logic;
  signal clk200_bufg_out       : std_logic;

  signal dcm_lock              : std_logic;
  signal ref_clk200_in         : std_logic;
  signal sys_clk_in            : std_logic;

  signal rst0_sync_r           : std_logic_vector((RST_SYNC_NUM -1) downto 0);
  signal rst200_sync_r         : std_logic_vector((RST_SYNC_NUM -1) downto 0);
  signal rst90_sync_r          : std_logic_vector((RST_SYNC_NUM -1) downto 0);
  signal rst_tmp               : std_logic;

  signal sys_reset             : std_logic;

begin

  --***************************************************************************

  sys_reset <= (not sys_reset_in_n) when (RESET_ACTIVE_LOW = '1')
               else sys_reset_in_n;

  sys_clk_in        <= sys_clk;
  clk_0             <= clk0_bufg_out;
  clk_90            <= clk90_bufg_out;
  clk_200           <= clk200_bufg_out;
  ref_clk200_in     <= idly_clk_200;

  DIFF_ENDED_CLKS_INST : if(CLK_TYPE = "DIFFERENTIAL") generate
  begin
    SYS_CLK_INST : IBUFGDS_LVPECL_25
      port map (
        I  => sys_clk_p,
        IB => sys_clk_n,
        O  => sys_clk_in
        );

    IDLY_CLK_INST : IBUFGDS_LVPECL_25
      port map (
        O  => ref_clk200_in,
        I  => clk200_p,
        IB => clk200_n
        );

  end generate;

  -- SINGLE_ENDED_CLKS_INST : if(CLK_TYPE = "SINGLE_ENDED") generate
  -- begin
  --   SYS_CLK_INST : IBUFG
  --     port map (
  --       I  => sys_clk,
  --       O  => sys_clk_in
  --       );

  --   IDLY_CLK_INST : IBUFG
  --     port map (
  --       I  => idly_clk_200,
  --       O  => ref_clk200_in
  --       );

  -- end generate;

  CLK_200_BUFG : BUFG
    port map (
      O => clk200_bufg_out,
      I => ref_clk200_in
      );

  DCM_BASE0 : DCM_BASE
    generic map(
      DLL_FREQUENCY_MODE    => "HIGH",
      DUTY_CYCLE_CORRECTION => TRUE,
      CLKDV_DIVIDE          => 16.0,
      CLKFX_MULTIPLY        => 2,
      CLKFX_DIVIDE          => 8,
      FACTORY_JF            => X"F0F0"
      )
    port map (
      CLK0     => clk0_bufg_in,
      CLK180   => open,
      CLK270   => open,
      CLK2X    => open,
      CLK2X180 => open,
      CLK90    => clk90_bufg_in,
      CLKDV    => open,
      CLKFX    => open,
      CLKFX180 => open,
      LOCKED   => dcm_lock,
      CLKFB    => clk0_bufg_out,
      CLKIN    => sys_clk_in,
      RST      => sys_reset
      );

  DCM_CLK0 : BUFG
    port map (
      O => clk0_bufg_out,
      I => clk0_bufg_in
      );

  DCM_CLK90 : BUFG
    port map (
      O => clk90_bufg_out,
      I => clk90_bufg_in
      );

  --***************************************************************************
  -- Reset synchronization
  -- NOTES:
  --   1. shut down the whole operation if the DCM hasn't yet locked (and by
  --      inference, this means that external SYS_RST_IN has been asserted -
  --      DCM deasserts DCM_LOCK as soon as SYS_RST_IN asserted)
  --   2. In the case of all resets except rst200, also assert reset if the
  --      IDELAY master controller is not yet ready
  --   3. asynchronously assert reset. This was we can assert reset even if
  --      there is no clock (needed for things like 3-stating output buffers).
  --      reset deassertion is synchronous.
  --***************************************************************************

  rst_tmp  <= (not dcm_lock) or (not idelay_ctrl_rdy) or (sys_reset);

  process(clk0_bufg_out, rst_tmp)
  begin
    if (rst_tmp = '1') then
      rst0_sync_r <= ADD_CONST5(RST_SYNC_NUM-1 downto 0);
    elsif (clk0_bufg_out'event and clk0_bufg_out = '1') then
      rst0_sync_r(RST_SYNC_NUM-1 downto 1) <= rst0_sync_r(RST_SYNC_NUM-2 downto 0);
      rst0_sync_r(0) <= '0';
    end if;
  end process;

  process(clk90_bufg_out, rst_tmp)
  begin
    if (rst_tmp = '1') then
      rst90_sync_r <= ADD_CONST5(RST_SYNC_NUM-1 downto 0);
    elsif (clk90_bufg_out'event and clk90_bufg_out = '1') then
      rst90_sync_r(RST_SYNC_NUM-1 downto 1) <= rst90_sync_r(RST_SYNC_NUM-2 downto 0);
      rst90_sync_r(0) <= '0';
    end if;
  end process;

  process(clk200_bufg_out, dcm_lock)
  begin
    if (dcm_lock = '0') then
      rst200_sync_r <= ADD_CONST5(RST_SYNC_NUM-1 downto 0);
    elsif (clk200_bufg_out'event and clk200_bufg_out = '1') then
      rst200_sync_r(RST_SYNC_NUM-1 downto 1) <= rst200_sync_r(RST_SYNC_NUM-2 downto 0);
      rst200_sync_r(0) <= '0';
    end if;
  end process;


  sys_rst    <= rst0_sync_r(RST_SYNC_NUM-1);
  sys_rst90  <= rst90_sync_r(RST_SYNC_NUM-1);
  sys_rst200 <= rst200_sync_r(RST_SYNC_NUM-1);


end arc_infrastructure;
