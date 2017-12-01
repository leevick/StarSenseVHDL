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
--  /   /        Filename           : DDR2_controller_iobs_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module puts the memory control signals like address,
--               bank address, row address strobe, column address strobe,
--               write enable and clock enable in the IOBs.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_controller_iobs_0 is
  port (
    ctrl_ddr2_address : in  std_logic_vector(ROW_ADDRESS-1 downto 0);
    ctrl_ddr2_ba      : in  std_logic_vector(BANK_ADDRESS-1 downto 0);
    ctrl_ddr2_ras_l   : in  std_logic;
    ctrl_ddr2_cas_l   : in  std_logic;
    ctrl_ddr2_we_l    : in  std_logic;
    ctrl_ddr2_cs_l    : in  std_logic_vector(CS_WIDTH-1 downto 0);
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
    ddr_cs_l          : out std_logic_vector(CS_WIDTH-1 downto 0)
    );
end entity;

architecture arc_controller_iobs of DDR2_controller_iobs_0 is

begin

  --***************************************************************************

  -- RAS: = 1 at reset
  obuf_ras : OBUF
    port map(
      I => ctrl_ddr2_ras_l,
      O => ddr_ras_l
      );

  -- CAS: = 1 at reset
  obuf_cas : OBUF
    port map(
      I => ctrl_ddr2_cas_l,
      O => ddr_cas_l
      );

  -- WE: = 1 at reset
  obuf_we : OBUF
    port map(
      I => ctrl_ddr2_we_l,
      O => ddr_we_l
      );

  -- chip select: = 1 at reset
  gen_cs_n: for cs_i in 0 to CS_WIDTH-1 generate
  begin
    u_obuf_cs_n : OBUF
      port map (
        I => ctrl_ddr2_cs_l(cs_i),
        O => ddr_cs_l(cs_i)
        );
  end generate;

  -- CKE: = 0 at reset
  gen_cke: for cke_i in 0 to CKE_WIDTH-1 generate
  begin
    u_obuf_cke : OBUF
      port map (
        I => ctrl_ddr2_cke(cke_i),
        O => ddr_cke(cke_i)
        );
  end generate;

  -- ODT control = 0 at reset
  gen_odt: for odt_i in 0 to ODT_WIDTH-1 generate
  begin
    u_obuf_odt : OBUF
      port map (
        I => ctrl_ddr2_odt(odt_i),
        O => ddr_odt(odt_i)
        );
  end generate;

  -- ODT control = 0 at reset
  gen_odt_cpy: for odt_i in 0 to ODT_WIDTH-1 generate
  begin
    u_obuf_odt_cpy : OBUF
      port map (
        I => ctrl_ddr2_odt_cpy(odt_i),
        O => ddr_odt_cpy(odt_i)
        );
  end generate;

  -- address: = 0 at reset
  gen_addr: for addr_i in 0 to ROW_ADDRESS-1 generate
  begin
    u_obuf_addr : OBUF
      port map (
        I => ctrl_ddr2_address(addr_i),
        O => ddr_address(addr_i)
        );
  end generate;

  -- bank address = 0 at reset
  gen_ba: for ba_i in 0 to BANK_ADDRESS-1 generate
  begin
    u_obuf_ba : OBUF
      port map (
        I => ctrl_ddr2_ba(ba_i),
        O => ddr_ba(ba_i)
        );
  end generate;

end arc_controller_iobs;
