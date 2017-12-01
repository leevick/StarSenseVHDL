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
--  /   /        Filename           : DDR2_rd_data_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : The delay between the read data with respect to the command
--               issued is calculated in terms of no. of clocks. This data is
--               then stored into the FIFOs and then read back and given as
--               the ouput for comparison.
-- Revision History:
--   Rev 1.1 - Changes for V4 no edge straddle calibration scheme. Added
--             PER_BIT_SKEW input, DELAY_ENABLE output and
--             CAL_FIRST_LOOP output. Various other changes. PK. 12/24/07
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;



entity DDR2_rd_data_0 is
  port (
    clk                 : in  std_logic;
    reset               : in  std_logic;
    ctrl_rden           : in  std_logic;
    read_data_rise      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    read_data_fall      : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    per_bit_skew        : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    delay_enable        : out std_logic_vector(DATA_WIDTH-1 downto 0);
    comp_done           : out std_logic;
    read_data_valid     : out std_logic;
    read_data_fifo_rise : out std_logic_vector(DATA_WIDTH-1 downto 0);
    read_data_fifo_fall : out std_logic_vector(DATA_WIDTH-1 downto 0);
    cal_first_loop      : out std_logic;

    -- Debug Signals
    dbg_first_rising    : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    dbg_cal_first_loop  : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    dbg_comp_done       : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    dbg_comp_error      : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0)
    );
end entity;

architecture arc_rd_data of DDR2_rd_data_0 is

  constant ONES  : std_logic_vector(DATA_STROBE_WIDTH downto 0) := (others => '1');
  constant ZEROS : std_logic_vector(DATA_STROBE_WIDTH downto 0) := (others => '0');

  component DDR2_rd_data_fifo_0
    port (
      clk                  : in  std_logic;
      reset                : in  std_logic;
      fifo_rd_en           : in  std_logic;
      read_en_delayed_rise : in  std_logic;
      read_en_delayed_fall : in  std_logic;
      first_rising         : in  std_logic;
      read_data_rise       : in  std_logic_vector(MEMORY_WIDTH-1 downto 0);
      read_data_fall       : in  std_logic_vector(MEMORY_WIDTH-1 downto 0);
      read_data_fifo_rise  : out std_logic_vector(MEMORY_WIDTH-1 downto 0);
      read_data_fifo_fall  : out std_logic_vector(MEMORY_WIDTH-1 downto 0);
      read_data_valid      : out std_logic
      );
  end component;

  component DDR2_pattern_compare4
    port(
      clk            : in  std_logic;
      rst            : in  std_logic;
      ctrl_rden      : in  std_logic;
      calib_done     : in  std_logic;
      rd_data_rise   : in  std_logic_vector(3 downto 0);
      rd_data_fall   : in  std_logic_vector(3 downto 0);
      per_bit_skew   : in  std_logic_vector(3 downto 0);
      comp_done      : out std_logic;
      comp_error     : out std_logic;
      first_rising   : out std_logic;
      rd_en_rise     : out std_logic;
      rd_en_fall     : out std_logic;
      cal_first_loop : out std_logic;
      delay_enable   : out std_logic_vector(3 downto 0)
      );
  end component;

  component DDR2_pattern_compare8
    port(
      clk            : in  std_logic;
      rst            : in  std_logic;
      ctrl_rden      : in  std_logic;
      calib_done     : in  std_logic;
      rd_data_rise   : in  std_logic_vector(7 downto 0);
      rd_data_fall   : in  std_logic_vector(7 downto 0);
      per_bit_skew   : in  std_logic_vector(7 downto 0);
      comp_done      : out std_logic;
      comp_error     : out std_logic;
      first_rising   : out std_logic;
      rd_en_rise     : out std_logic;
      rd_en_fall     : out std_logic;
      cal_first_loop : out std_logic;
      delay_enable   : out std_logic_vector(7 downto 0)
      );
  end component;


  signal cal_first_loop_i     : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal cal_first_loop_r2    : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal calib_done           : std_logic;
  signal comp_done_i          : std_logic;
  signal comp_error           : std_logic;
  signal comp_error_i         : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal comp_done_int        : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal fifo_read_enable_r   : std_logic;
  signal fifo_read_enable_2r  : std_logic;
  signal first_rising_int     : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal gen_cal_loop         : std_logic;
  signal gen_comp_err         : std_logic;
  signal read_data_valid_i    : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal read_en_delayed_rise : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal read_en_delayed_fall : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal reset_r1             : std_logic;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of reset_r1 : signal is "no";
  attribute syn_preserve of reset_r1                : signal is true;

begin

  --***************************************************************************

  --***************************************************************************
  -- Debug output ("dbg_*")
  -- NOTES:
  --  1. All debug outputs coming out of RD_DATA are clocked off CLK0,
  --     although they are also static after calibration is complete. This
  --     means the user can either connect them to a Chipscope ILA, or to
  --     either a sync/async VIO input block. Using an async VIO has the
  --     advantage of not requiring these paths to meet cycle-to-cycle timing.
  --  2. The widths of most of these debug buses are dependent on the # of
  --     DQS/DQ bits (e.g. first_rising = (# of DQS bits)
  -- SIGNAL DESCRIPTION:
  --  1. first_rising:   # of DQS bits - asserted for each byte if rise and 
  --                     fall data arrive "staggered" w/r to each other.
  --  2. cal_first_loop: # of DQS bits - deasserted ('0') for corresponding byte 
  --                     if pattern calibration is not completed on 
  --                     first pattern read command.
  --  3. comp_done:      #of DQS bits - each one asserted as pattern calibration 
  --                     (second stage) is completed for corresponding byte.
  --  4. comp_error:     # of DQS bits - each one asserted when a calibration 
  --                     error encountered in pattern calibrtation stage for 
  --                     corresponding byte. 
  --***************************************************************************

  dbg_first_rising   <= first_rising_int;
  dbg_cal_first_loop <= cal_first_loop_r2;
  dbg_comp_done      <= comp_done_int;
  dbg_comp_error     <= comp_error_i;

  read_data_valid <= read_data_valid_i(0);

  comp_done_i <=  comp_done_int(0)  and  comp_done_int(1)  and  comp_done_int(2)  and  comp_done_int(3) ;
  comp_done <= comp_done_i;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      reset_r1 <= reset;
    end if;
  end process;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      calib_done <= comp_done_i;
    end if;
  end process;

  --***************************************************************************
  -- cal_first_loop: Flag for controller to issue a second pattern calibration
  -- read if the first one does not result in a successful calibration.
  -- Second pattern calibration command is issued to all DQS sets by NANDing
  -- of CAL_FIRST_LOOP from all PATTERN_COMPARE modules. The set calibrated on
  -- first pattern calibration command ignores the second calibration command,
  -- since it will in CAL_DONE state (in PATTERN_COMPARE module) for the ones
  -- calibrated. The set that is not calibrated on first pattern calibration
  -- command, is calibrated on second calibration command.
  --***************************************************************************

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      cal_first_loop_r2 <= cal_first_loop_i;
    end if;
  end process;

  gen_cal_loop <= '1' when (cal_first_loop_i = ONES) else '0';

  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (reset_r1 = '1') then
        cal_first_loop <= '1';
      elsif ((cal_first_loop_r2 /= cal_first_loop_i) and ((not (gen_cal_loop)) = '1')) then
        cal_first_loop <= '0';
      else
        cal_first_loop <= '1';
      end if;
    end if;
  end process;

  gen_comp_err <= '1' when (comp_error_i /= ZEROS) else '0';

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      comp_error <= gen_comp_err;
    end if;
  end process;

  process(clk)
  begin
    if (clk'event and clk = '1') then
      if (reset_r1 = '1') then
        fifo_read_enable_r  <= '0';
        fifo_read_enable_2r <= '0';
      else
        fifo_read_enable_r  <= read_en_delayed_rise(0);
        fifo_read_enable_2r <= fifo_read_enable_r;
      end if;
    end if;
  end process;




  pattern_0 : DDR2_pattern_compare8
    port map (
      clk            => clk,
      rst            => reset,
      ctrl_rden      => ctrl_rden,
      calib_done     => calib_done,
      rd_data_rise   => read_data_rise(7 downto 0),
      rd_data_fall   => read_data_fall(7 downto 0),
      per_bit_skew   => per_bit_skew(7 downto 0),
      comp_done      => comp_done_int(0),
      comp_error     => comp_error_i(0),
      first_rising   => first_rising_int(0),
      rd_en_rise     => read_en_delayed_rise(0),
      rd_en_fall     => read_en_delayed_fall(0),
      cal_first_loop => cal_first_loop_i(0),
      delay_enable   => delay_enable(7 downto 0)
      );


  pattern_1 : DDR2_pattern_compare8
    port map (
      clk            => clk,
      rst            => reset,
      ctrl_rden      => ctrl_rden,
      calib_done     => calib_done,
      rd_data_rise   => read_data_rise(15 downto 8),
      rd_data_fall   => read_data_fall(15 downto 8),
      per_bit_skew   => per_bit_skew(15 downto 8),
      comp_done      => comp_done_int(1),
      comp_error     => comp_error_i(1),
      first_rising   => first_rising_int(1),
      rd_en_rise     => read_en_delayed_rise(1),
      rd_en_fall     => read_en_delayed_fall(1),
      cal_first_loop => cal_first_loop_i(1),
      delay_enable   => delay_enable(15 downto 8)
      );


  pattern_2 : DDR2_pattern_compare8
    port map (
      clk            => clk,
      rst            => reset,
      ctrl_rden      => ctrl_rden,
      calib_done     => calib_done,
      rd_data_rise   => read_data_rise(23 downto 16),
      rd_data_fall   => read_data_fall(23 downto 16),
      per_bit_skew   => per_bit_skew(23 downto 16),
      comp_done      => comp_done_int(2),
      comp_error     => comp_error_i(2),
      first_rising   => first_rising_int(2),
      rd_en_rise     => read_en_delayed_rise(2),
      rd_en_fall     => read_en_delayed_fall(2),
      cal_first_loop => cal_first_loop_i(2),
      delay_enable   => delay_enable(23 downto 16)
      );


  pattern_3 : DDR2_pattern_compare8
    port map (
      clk            => clk,
      rst            => reset,
      ctrl_rden      => ctrl_rden,
      calib_done     => calib_done,
      rd_data_rise   => read_data_rise(31 downto 24),
      rd_data_fall   => read_data_fall(31 downto 24),
      per_bit_skew   => per_bit_skew(31 downto 24),
      comp_done      => comp_done_int(3),
      comp_error     => comp_error_i(3),
      first_rising   => first_rising_int(3),
      rd_en_rise     => read_en_delayed_rise(3),
      rd_en_fall     => read_en_delayed_fall(3),
      cal_first_loop => cal_first_loop_i(3),
      delay_enable   => delay_enable(31 downto 24)
      );


  --***************************************************************************
  -- rd_data_fifo instances
  --***************************************************************************
  gen_fifo: for fifo_i in 0 to DATA_STROBE_WIDTH-1 generate
    u_rd_fifo : DDR2_rd_data_fifo_0
      port map (
        clk                  => clk,
        reset                => reset,
        fifo_rd_en           => fifo_read_enable_2r,
        read_en_delayed_rise => read_en_delayed_rise(fifo_i),
        read_en_delayed_fall => read_en_delayed_fall(fifo_i),
        first_rising         => first_rising_int(fifo_i),
        read_data_rise       => read_data_rise((MEMORY_WIDTH*(fifo_i+1))-1
                                               downto MEMORY_WIDTH*fifo_i),
        read_data_fall       => read_data_fall((MEMORY_WIDTH*(fifo_i+1))-1
                                               downto MEMORY_WIDTH*fifo_i),
        read_data_fifo_rise  => read_data_fifo_rise((MEMORY_WIDTH*(fifo_i+1))-1
                                                    downto MEMORY_WIDTH*fifo_i),
        read_data_fifo_fall  => read_data_fifo_fall((MEMORY_WIDTH*(fifo_i+1))-1
                                                    downto MEMORY_WIDTH*fifo_i),
        read_data_valid      => read_data_valid_i(fifo_i)
        );
  end generate;


end arc_rd_data;
