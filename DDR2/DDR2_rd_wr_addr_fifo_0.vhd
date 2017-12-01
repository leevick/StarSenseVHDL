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
--  /   /        Filename           : DDR2_rd_wr_addr_fifo_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates the block RAM based FIFO to store
--               the user address and the command information.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_rd_wr_addr_fifo_0 is
  port(
    clk0           : in  std_logic;
    clk90          : in  std_logic;
    rst            : in  std_logic;
    -- Write address fifo signals
    app_af_addr    : in  std_logic_vector(35 downto 0);
    app_af_wren    : in  std_logic;
    ctrl_af_rden   : in  std_logic;
    af_addr        : out std_logic_vector(35 downto 0);
    af_empty       : out std_logic;
    af_almost_full : out std_logic
    );
end entity;

architecture arc_rd_wr_addr_fifo of DDR2_rd_wr_addr_fifo_0 is

  signal fifo_input_write_addr  : std_logic_vector(35 downto 0);
  signal fifo_output_write_addr : std_logic_vector(35 downto 0);

  signal compare_value_r        : std_logic_vector(35 downto 0);
  signal app_af_addr_r          : std_logic_vector(35 downto 0);
  signal fifo_input_addr_r      : std_logic_vector(35 downto 0);
  signal af_en_r                : std_logic;
  signal af_en_2r               : std_logic;
  signal compare_result         : std_logic;

  signal clk270                 : std_logic;
  signal af_al_full_0           : std_logic;
  signal af_al_full_180         : std_logic;
  signal af_al_full_90          : std_logic;
  signal af_en_2r_270           : std_logic;
  signal fifo_input_270         : std_logic_vector(35 downto 0);

  signal rst_r1                 : std_logic;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of rst_r1 : signal is "no";
  attribute syn_preserve of rst_r1                : signal is true;

begin

  --***************************************************************************

  fifo_input_write_addr <= (compare_result & app_af_addr_r(34 downto 0));
  af_addr(35 downto 0)  <= fifo_output_write_addr(35 downto 0);
  compare_result <= '0' when (compare_value_r((CHIP_ADDRESS + BANK_ADDRESS + ROW_ADDRESS + COLUMN_ADDRESS- 1) downto
                                              COLUMN_ADDRESS) =
                              fifo_input_write_addr(CHIP_ADDRESS + BANK_ADDRESS + ROW_ADDRESS + COLUMN_ADDRESS- 1
                                                    downto COLUMN_ADDRESS))
                    else '1';

  clk270 <= not clk90;

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      rst_r1 <= rst;
    end if;
  end process;

  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (af_en_r = '1') then
        compare_value_r <= fifo_input_write_addr;
      end if;
      app_af_addr_r(35 downto 0)     <= app_af_addr(35 downto 0);
      fifo_input_addr_r(35 downto 0) <= fifo_input_write_addr(35 downto 0);
    end if;
  end process;

  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (rst_r1 = '1') then
        af_en_r  <= '0';
        af_en_2r <= '0';
      else
        af_en_r  <= app_af_wren;
        af_en_2r <= af_en_r;
      end if;
    end if;
  end process;

  -- A fix for FIFO16 according to answer record #22462

  process(clk270)
  begin
    if (clk270'event and clk270 = '1') then
      af_en_2r_270   <= af_en_2r;
      fifo_input_270 <= fifo_input_addr_r;
    end if;
  end process;

  -- 3 Filp-flops logic is implemented at output to avoid the timimg errors

  process(clk0)
  begin
    if (clk0'event and clk0 = '0') then
      af_al_full_180 <= af_al_full_0;
    end if;
  end process;

  process(clk90)
  begin
    if (clk90'event and clk90 = '1') then
      af_al_full_90 <= af_al_full_180;
    end if;
  end process;

  process(clk0)
  begin
    if (clk0'event and clk0 = '1') then
      af_almost_full <= af_al_full_90;
    end if;
  end process;

  -- Address FIFO
  Waf_fifo16 : FIFO16

    generic map (
      ALMOST_EMPTY_OFFSET     => X"007",
      ALMOST_FULL_OFFSET      => X"00F",
      DATA_WIDTH              => 36,
      FIRST_WORD_FALL_THROUGH => TRUE
      )
    port map(
      ALMOSTEMPTY => open,
      ALMOSTFULL  => af_al_full_0,
      DO          => fifo_output_write_addr(31 downto 0),
      DOP         => fifo_output_write_addr(35 downto 32),
      EMPTY       => af_empty,
      FULL        => open,
      RDCOUNT     => open,
      RDERR       => open,
      WRCOUNT     => open,
      WRERR       => open,
      DI          => fifo_input_270(31 downto 0),
      DIP         => fifo_input_270(35 downto 32),
      RDCLK       => clk0,
      RDEN        => ctrl_af_rden,
      RST         => rst_r1,
      WRCLK       => clk270,
      WREN        => af_en_2r_270
      );


end arc_rd_wr_addr_fifo;
