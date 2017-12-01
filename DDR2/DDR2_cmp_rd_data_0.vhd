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
--  /   /        Filename           : DDR2_cmp_rd_data_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module generates the error signal in case of bit errors.
--               It compares the read data with expected data value.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

entity DDR2_cmp_rd_data_0 is
  port (
    clk                : in  std_logic;
    reset              : in  std_logic;
    read_data_valid    : in  std_logic;
    app_compare_data   : in  std_logic_vector(DQ_WIDTH*2-1 downto 0);
    read_data_fifo_out : in  std_logic_vector(DQ_WIDTH*2-1 downto 0);
    error              : out std_logic
    );
end entity;

architecture arc_cmp_rd_data of DDR2_cmp_rd_data_0 is

  signal valid                : std_logic;
  signal byte_err_rising      : std_logic_vector(DM_WIDTH-1 downto 0);
  signal byte_err_falling     : std_logic_vector(DM_WIDTH-1 downto 0);
  signal valid_1              : std_logic;
  signal read_data_r          : std_logic_vector(DQ_WIDTH*2-1 downto 0);
  signal read_data_r2         : std_logic_vector(DQ_WIDTH*2-1 downto 0);
  signal write_data_r2        : std_logic_vector(DQ_WIDTH*2-1 downto 0);
  signal data_pattern_falling : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal data_pattern_rising  : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal data_falling         : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal data_rising          : std_logic_vector(DQ_WIDTH-1 downto 0);
  signal falling_error        : std_logic;
  signal rising_error         : std_logic;
  signal byte_err_falling_w   : std_logic_vector(DM_WIDTH-1 downto 0);
  signal byte_err_rising_w    : std_logic_vector(DM_WIDTH-1 downto 0);
  signal byte_err_rising_a    : std_logic;
  signal byte_err_falling_a   : std_logic;

  signal error_r1             : std_logic;
  signal error_r2             : std_logic;

  signal reset_r1             : std_logic;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of reset_r1 : signal is "no";
  attribute syn_preserve of reset_r1                : signal is true;

begin

  --***************************************************************************

  data_falling <= read_data_r2(DQ_WIDTH-1 downto 0);
  data_rising  <= read_data_r2(DQ_WIDTH*2-1 downto DQ_WIDTH);

  data_pattern_falling <= write_data_r2(DQ_WIDTH-1 downto 0);
  data_pattern_rising  <= write_data_r2(DQ_WIDTH*2-1 downto DQ_WIDTH);

byte_err_falling_w(0) <= '1' when ((valid_1 = '1') and (data_falling(7 downto 0) /= data_pattern_falling(7 downto 0)))
                                  else '0';
byte_err_falling_w(1) <= '1' when ((valid_1 = '1') and (data_falling(15 downto 8) /= data_pattern_falling(15 downto 8)))
                                  else '0';
byte_err_falling_w(2) <= '1' when ((valid_1 = '1') and (data_falling(23 downto 16) /= data_pattern_falling(23 downto 16)))
                                  else '0';
byte_err_falling_w(3) <= '1' when ((valid_1 = '1') and (data_falling(31 downto 24) /= data_pattern_falling(31 downto 24)))
                                  else '0';
byte_err_rising_w(0) <= '1' when ((valid_1 = '1') and (data_rising(7 downto 0) /= data_pattern_rising(7 downto 0)))
                                 else '0';
byte_err_rising_w(1) <= '1' when ((valid_1 = '1') and (data_rising(15 downto 8) /= data_pattern_rising(15 downto 8)))
                                 else '0';
byte_err_rising_w(2) <= '1' when ((valid_1 = '1') and (data_rising(23 downto 16) /= data_pattern_rising(23 downto 16)))
                                 else '0';
byte_err_rising_w(3) <= '1' when ((valid_1 = '1') and (data_rising(31 downto 24) /= data_pattern_rising(31 downto 24)))
                                 else '0';

  byte_err_rising_a  <=  byte_err_rising(0) or byte_err_rising(1) or byte_err_rising(2) or byte_err_rising(3) ;

  byte_err_falling_a <=  byte_err_falling(0) or byte_err_falling(1) or byte_err_falling(2) or byte_err_falling(3) ;

  error <= error_r2;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      reset_r1 <= reset;
    end if;
  end process;

  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1') then
        valid   <= '0';
        valid_1 <= '0';
      else
        valid   <= read_data_valid;
        valid_1 <= valid;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if clk'event and clk = '1' then
      read_data_r <= read_data_fifo_out;
    end if;
  end process;

  process(clk)
  begin
    if clk'event and clk = '1' then
      read_data_r2  <= read_data_r;
      write_data_r2 <= app_compare_data;
    end if;
  end process;

  process (clk)
  begin
    if clk'event and clk = '1' then
      byte_err_rising  <= byte_err_falling_w;
      byte_err_falling <= byte_err_rising_w;
    end if;
  end process;

  process(clk)
  begin
    if clk'event and clk = '1' then
      rising_error  <= byte_err_rising_a;
      falling_error <= byte_err_falling_a;
      error_r1      <= (rising_error or falling_error);
    end if;
  end process;

  --synthesis translate_off
  process(clk)
  begin
    if clk'event and clk = '1' then
      if reset_r1 = '0' then
        assert (rising_error = '0' and falling_error = '0')
          report " DATA ERROR at time " & time'image(now);
      end if;
    end if;
  end process;
  --synthesis translate_on

  process (clk)
  begin
    if(clk'event and clk = '1') then
      if(reset_r1 = '1') then
        error_r2 <= '0';
      elsif(error_r2 = '0')then
        error_r2 <= error_r1;
      else
        error_r2 <= error_r2;
      end if;
    end if;
  end process;


end arc_cmp_rd_data;
