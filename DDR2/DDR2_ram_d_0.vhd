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
--  /   /        Filename           : DDR2_ram_d_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : Contains the distributed RAM which stores IOB output data
--               that is read from the memory.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_ram_d_0 is
  port (
    dpo   : out std_logic_vector(MEMORY_WIDTH-1 downto 0);
    a0    : in  std_logic;
    a1    : in  std_logic;
    a2    : in  std_logic;
    a3    : in  std_logic;
    d     : in  std_logic_vector(MEMORY_WIDTH-1 downto 0);
    dpra0 : in  std_logic;
    dpra1 : in  std_logic;
    dpra2 : in  std_logic;
    dpra3 : in  std_logic;
    wclk  : in  std_logic;
    we    : in  std_logic
    );
end entity;

architecture arc_RAM of DDR2_ram_d_0 is

begin

  --***************************************************************************

  gen_ram16: for ram16_i in 0 to MEMORY_WIDTH-1 generate
    u_ram16x1d : RAM16X1D
      port map (
        D     => d(ram16_i),
        WE    => we,
        WCLK  => wclk,
        A0    => a0,
        A1    => a1,
        A2    => a2,
        A3    => a3,
        DPRA0 => dpra0,
        DPRA1 => dpra1,
        DPRA2 => dpra2,
        DPRA3 => dpra3,
        SPO   => open,
        DPO   => dpo(ram16_i)
        );
  end generate;

end arc_RAM;
