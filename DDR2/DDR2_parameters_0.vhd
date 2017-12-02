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
--  /   /        Filename           : DDR2_parameters_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : According to the user inputs the parameters are defined here.
--               These parameters are used for the generic
--               memory interface code. Various parameters are address widths,
--               data widths, timing parameters according to the frequency
--               selected by the user and some internal parameters also.
--*****************************************************************************

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

package DDR2_parameters_0 is

  -- counter values in the controller in tCK units
  -- write latency (WL) = Read Latency (RL) - 1 = AL + CL -1
  -- Read Latency (RL ) = AL + CL

  -- The reset polarity is set to active low by default. 
  -- You can change this by editing the parameter RESET_ACTIVE_LOW.
  -- Please do not change any of the other parameters directly by editing the RTL. 
  -- All other changes should be done through the GUI.
  
constant   DATA_WIDTH                                : INTEGER   :=  32;
constant   DATA_STROBE_WIDTH                         : INTEGER   :=  4;
constant   DATA_MASK_WIDTH                           : INTEGER   :=  4;
constant   CLK_WIDTH                                 : INTEGER   :=  2;
constant   FIFO_16                                   : INTEGER   :=  2;
constant   ECC_CNTRL_BITS                            : INTEGER   :=  0;
constant   CS_WIDTH                                  : INTEGER   :=  1;
constant   ODT_WIDTH                                 : INTEGER   :=  1;
constant   CKE_WIDTH                                 : INTEGER   :=  1;
constant   ROW_ADDRESS                               : INTEGER   :=  14;
constant   MEMORY_WIDTH                              : INTEGER   :=  8;
constant   REGISTERED                                : INTEGER   :=  0;
constant   SINGLE_RANK                               : INTEGER   :=  1;
constant   DUAL_RANK                                 : INTEGER   :=  0;
constant   DATABITSPERSTROBE                         : INTEGER   :=  8;
constant   RESET_PORT                                : INTEGER   :=  0;
constant   ECC_ENABLE                                : INTEGER   :=  0;
constant   ECC_WIDTH                                 : INTEGER   :=  0;
constant   DQ_WIDTH                                  : INTEGER   :=  32;
constant   DM_WIDTH                                  : INTEGER   :=  4;
constant   DQS_WIDTH                                 : INTEGER   :=  4;
constant   MASK_ENABLE                               : INTEGER   :=  1;
constant   USE_DM_PORT                               : INTEGER   :=  1;
constant   COLUMN_ADDRESS                            : INTEGER   :=  10;
constant   BANK_ADDRESS                              : INTEGER   :=  3;
constant   DEBUG_EN                                  : INTEGER   :=  0;
constant   CLK_TYPE                                  : string    :=  "SINGLE_ENDED";
constant   DQ_BITS                                   : INTEGER   :=  5;
constant   LOAD_MODE_REGISTER                        : std_logic_vector(13 downto 0) := "00010000110010";

constant   EXT_LOAD_MODE_REGISTER                    : std_logic_vector(13 downto 0) := "00000000000000";

constant   CHIP_ADDRESS                              : INTEGER   :=  1;
constant   RESET_ACTIVE_LOW                         : std_logic := '1';
constant   TBY4TAPVALUE                             : INTEGER   :=  17;
constant   RCD_COUNT_VALUE                           : std_logic_vector(2 downto 0) := "010";
constant   RAS_COUNT_VALUE                           : std_logic_vector(4 downto 0) := "00111";
constant   MRD_COUNT_VALUE                           : std_logic := '1';
constant   RP_COUNT_VALUE                             : std_logic_vector(2 downto 0) := "010";
constant   RFC_COUNT_VALUE                            : std_logic_vector(7 downto 0) := "00100111";
constant   TRTP_COUNT_VALUE                           : std_logic_vector(2 downto 0) := "001";
constant   TWR_COUNT_VALUE                            : std_logic_vector(2 downto 0) := "011";
constant   TWTR_COUNT_VALUE                      : std_logic_vector(2 downto 0) := "001";
constant   MAX_REF_WIDTH                                   : INTEGER   :=  11;
constant   MAX_REF_CNT                     : std_logic_vector(10 downto 0) := "11000011000";
  constant PHY_MODE            : std_logic := '1';

  constant CS_H0               : std_logic_vector(3 downto 0)  := "0000";
  constant CS_H1               : std_logic_vector(3 downto 0)  := "0001";
  constant CS_H2               : std_logic_vector(3 downto 0)  := "0010";
  constant CS_H3               : std_logic_vector(3 downto 0)  := "0011";
  constant CS_H4               : std_logic_vector(3 downto 0)  := "0100";
  constant CS_H5               : std_logic_vector(3 downto 0)  := "0101";
  constant CS_H6               : std_logic_vector(3 downto 0)  := "0110";
  constant CS_H7               : std_logic_vector(3 downto 0)  := "0111";
  constant CS_H8               : std_logic_vector(3 downto 0)  := "1000";
  constant CS_HA               : std_logic_vector(3 downto 0)  := "1010";
  constant CS_HB               : std_logic_vector(3 downto 0)  := "1011";
  constant CS_HD               : std_logic_vector(3 downto 0)  := "1101";
  constant CS_HE               : std_logic_vector(3 downto 0)  := "1110";
  constant CS_HF               : std_logic_vector(3 downto 0)  := "1111";
  constant CS_D100             : std_logic_vector(7 downto 0)  := X"64";
  constant CS_D1000            : std_logic_vector(11 downto 0) := X"3E8";
  constant ADD_CONST1          : std_logic_vector(15 downto 0) := X"0100";
  constant ADD_CONST2          : std_logic_vector(15 downto 0) := X"0380";
  constant ADD_CONST3          : std_logic_vector(15 downto 0) := X"0000";
  constant ADD_CONST4          : std_logic_vector(15 downto 0) := X"FBFF";
  constant ADD_CONST5          : std_logic_vector(27 downto 0) := X"FFFFFFF";
  constant ADD_CONST6          : std_logic_vector(11 downto 0) := X"001";


end package DDR2_parameters_0 ;
