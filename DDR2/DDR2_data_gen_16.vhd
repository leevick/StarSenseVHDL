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
--  /   /        Filename           : DDR2_data_gen_16.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module contains the data generation logic
--               for a 16 bit data.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity DDR2_data_gen_16 is
  port (
    clk0                : in  std_logic;
    rst                 : in  std_logic;
    -- enables signals from state machine
    bkend_data_en       : in  std_logic;
    bkend_rd_data_valid : in  std_logic;
    -- Write data fifo signals
    app_wdf_data        : out std_logic_vector(31 downto 0);
    app_mask_data       : out std_logic_vector(3 downto 0);
    -- data for the backend compare logic
    app_compare_data    : out std_logic_vector(31 downto 0);
    app_wdf_wren        : out std_logic
    );
end entity;

architecture arc_data_gen_16 of DDR2_data_gen_16 is

  type   wr_sm is (wr_idle_first_data, wr_second_data,
                   wr_third_data, wr_fourth_data);
  signal wr_state              : wr_sm;

  type   rd_sm is (rd_idle_first_data, rd_second_data,
                   rd_third_data, rd_fourth_data);
  signal rd_state              : rd_sm;

  signal wr_data_pattern       : std_logic_vector(15 downto 0);
  signal rd_data_pattern       : std_logic_vector(15 downto 0);
  signal app_wdf_wren_r        : std_logic;
  signal app_wdf_wren_2r       : std_logic;
  signal app_wdf_wren_3r       : std_logic;
  signal bkend_rd_data_valid_r : std_logic;

  signal app_wdf_data_r        : std_logic_vector(31 downto 0);
  signal app_wdf_data_1r       : std_logic_vector(31 downto 0);
  signal app_wdf_data_2r       : std_logic_vector(31 downto 0);
  signal rd_rising_edge_data   : std_logic_vector(15 downto 0);
  signal rd_falling_edge_data  : std_logic_vector(15 downto 0);

  signal wr_data_mask_rise     : std_logic_vector(1 downto 0);
  signal wr_data_mask_fall     : std_logic_vector(1 downto 0);
  signal app_mask_data_r       : std_logic_vector(3 downto 0);
  signal app_mask_data_1r      : std_logic_vector(3 downto 0);
  signal app_mask_data_2r      : std_logic_vector(3 downto 0);

  signal rst_r1 : std_logic;

  attribute equivalent_register_removal : string;
  attribute syn_preserve : boolean;
  attribute equivalent_register_removal of rst_r1 : signal is "no";
  attribute syn_preserve of rst_r1                : signal is true;
  attribute syn_preserve of arc_data_gen_16 : architecture is true;

begin

  --***************************************************************************

  wr_data_mask_rise <= "00";
  wr_data_mask_fall <= "00";

  process(clk0)
  begin
    if (clk0 = '1' and clk0'event) then
      rst_r1 <= rst;
    end if;
  end process;

  -- DATA generation for WRITE DATA FIFOs & for READ DATA COMPARE

  -- write data generation
  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (rst_r1 = '1') then
        wr_data_pattern(15 downto 0) <= X"0000";
        wr_state                     <= wr_idle_first_data;
      else
        case (wr_state) is

          when wr_idle_first_data =>
            if (bkend_data_en = '1') then
              wr_data_pattern(15 downto 0) <= X"FFFF";
              wr_state                     <= wr_second_data;
            else
              wr_state <= wr_idle_first_data;
            end if;

          when wr_second_data =>
            if (bkend_data_en = '1') then
              wr_data_pattern(15 downto 0) <= X"AAAA";
              wr_state                     <= wr_third_data;
            else
              wr_state <= wr_second_data;
            end if;

          when wr_third_data =>
            if (bkend_data_en = '1') then
              wr_data_pattern(15 downto 0) <= X"5555";
              wr_state                     <= wr_fourth_data;
            else
              wr_state <= wr_third_data;
            end if;

          when wr_fourth_data =>
            if (bkend_data_en = '1') then
              wr_data_pattern(15 downto 0) <= X"9999";
              wr_state                     <= wr_idle_first_data;
            else
              wr_state <= wr_fourth_data;
            end if;

        end case;
      end if;
    end if;
  end process;

  app_wdf_data_r(31 downto 0) <= (wr_data_pattern(15 downto 0) &
                                  not(wr_data_pattern(15 downto 0)))
                                 when (app_wdf_wren_r = '1') else x"00000000";

  app_mask_data_r(3 downto 0) <= (wr_data_mask_rise(1 downto 0) &
                                  wr_data_mask_fall(1 downto 0))
                                 when (app_wdf_wren_r = '1') else "0000";

  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      app_Wdf_data_1r <= app_Wdf_data_r;
      app_Wdf_data_2r <= app_Wdf_data_1r;
      app_Wdf_data    <= app_Wdf_data_2r;
    end if;
  end process;

  process (clk0)
  begin
    if clk0'event and clk0 = '1' then
      app_mask_data_1r <= app_mask_data_r;
      app_mask_data_2r <= app_mask_data_1r;
      app_mask_data    <= app_mask_data_2r;
    end if;
  end process;

  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (rst_r1 = '1') then
        app_wdf_wren_r  <= '0';
        app_wdf_wren_2r <= '0';
        app_wdf_wren_3r <= '0';
        app_wdf_wren    <= '0';
      else
        app_wdf_wren_r  <= bkend_data_en;
        app_wdf_wren_2r <= app_wdf_wren_r;
        app_wdf_wren_3r <= app_wdf_wren_2r;
        app_wdf_wren    <= app_wdf_wren_3r;
      end if;
    end if;
  end process;

  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (rst_r1 = '1') then
        bkend_rd_data_valid_r <= '0';
      else
        bkend_rd_data_valid_r <= bkend_rd_data_valid;
      end if;
    end if;
  end process;

  -- read comparison data generation
  process(clk0)
  begin
    if clk0'event and clk0 = '1' then
      if (rst_r1 = '1') then
        rd_data_pattern(15 downto 0) <= X"0000";
        rd_state                     <= rd_idle_first_data;
      else
        case (rd_state) is

          when rd_idle_first_data =>
            if (bkend_rd_data_valid = '1') then
              rd_data_pattern(15 downto 0) <= X"FFFF";
              rd_state                     <= rd_second_data;
            else
              rd_state <= rd_idle_first_data;
            end if;

          when rd_second_data =>
            rd_data_pattern(15 downto 0) <= X"AAAA";
            rd_state                     <= rd_third_data;

          when rd_third_data =>
            if (bkend_rd_data_valid = '1') then
              rd_data_pattern(15 downto 0) <= X"5555";
              rd_state                     <= rd_fourth_data;
            else
              rd_state <= rd_third_data;
            end if;

          when rd_fourth_data =>
            rd_data_pattern(15 downto 0) <= X"9999";
            rd_state                     <= rd_idle_first_data;

        end case;
      end if;
    end if;
  end process;

  rd_rising_edge_data(15 downto 0)  <= rd_data_pattern(15 downto 0);
  rd_falling_edge_data(15 downto 0) <= not (rd_data_pattern(15 downto 0));

  -- data to the compare circuit during read
  app_compare_data(31 downto 0) <= (rd_rising_edge_data(15 downto 0) &
                                    rd_falling_edge_data(15 downto 0))
                                   when (bkend_rd_data_valid_r = '1') else X"00000000";


end arc_data_gen_16;
