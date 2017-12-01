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
--  /   /        Filename           : DDR2_idelay_ctrl.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates the IDELAYCTRL primitive of the
--               Virtex4 device which continuously calibrates the IDELAY
--               elements in the region in case of varying operating
--               conditions. It takes a 200MHz clock as an input.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity DDR2_idelay_ctrl is
  port (
    clk200     : in  std_logic;
    reset      : in  std_logic;
    rdy_status : out std_logic
    );
end entity;

architecture arc_idelay_ctrl of DDR2_idelay_ctrl is

-- The following parameter "IDELAYCTRL_NUM" indicates the number of IDELAYCTRLs 
-- that are LOCed for the design. The IDELAYCTRL LOCs are provided in the UCF 
-- file of par folder. MIG provides the parameter value and the LOCs in the UCF
-- file based on the selected data banks for the design. You must not alter 
-- this value unless it is needed. If you modify this value, you should make
-- sure that the value of "IDELAYCTRL_NUM" and IDELAYCTRL LOCs in UCF file are
-- same and are relavent to the data banks used.

  constant IDELAYCTRL_NUM : integer := 2;
  constant ONES : std_logic_vector(IDELAYCTRL_NUM-1 downto 0) := (others => '1');

  signal rdy_status_i : std_logic_vector(IDELAYCTRL_NUM-1 downto 0);

begin

  --***************************************************************************

IDELAYCTRL_INST : for bnk_i in 0 to IDELAYCTRL_NUM-1 generate
  u_idelayctrl : IDELAYCTRL
    port map (
      RDY    => rdy_status_i(bnk_i),
      REFCLK => clk200,
      RST    => reset
      );
end generate IDELAYCTRL_INST;

rdy_status <= '1' when (rdy_status_i = ONES) else
              '0';

end arc_idelay_ctrl;
