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
--  /   /        Filename           : DDR2_infrastructure_iobs_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : The DDR2 memory clocks are generated here using the
--               differential buffers and the ODDR elements in the IOBs.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_infrastructure_iobs_0 is
  port (
    clk      : in  std_logic;
    ddr_ck   : out std_logic_vector(CLK_WIDTH-1 downto 0);
    ddr_ck_n : out std_logic_vector(CLK_WIDTH-1 downto 0)
    );
end entity;

architecture arc_infrastructure_iobs of DDR2_infrastructure_iobs_0 is

  signal ddr_ck_q : std_logic_vector((CLK_WIDTH-1) downto 0);

begin

  --***************************************************************************

  --***************************************************************************
  -- Memory clock generation
  --***************************************************************************

  gen_ck: for ck_i in 0 to CLK_WIDTH-1 generate
    u_oddr_ck_i : ODDR
      generic map (
        SRTYPE       => "SYNC",
        DDR_CLK_EDGE => "OPPOSITE_EDGE"
        )
      port map (
        Q            => ddr_ck_q(ck_i),
        C            => clk,
        CE           => '1',
        D1           => '0',
        D2           => '1',
        R            => '0',
        S            => '0'
        );

    u_obuf_ck_i : OBUFDS
      port map (
        I  => ddr_ck_q(ck_i),
        O  => ddr_ck(ck_i),
        OB => ddr_ck_n(ck_i)
      );
  end generate;

end arc_infrastructure_iobs;
