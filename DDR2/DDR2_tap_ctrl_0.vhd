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
--  /   /        Filename           : DDR2_tap_ctrl.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module performs the selection of number of taps in IDELAY
--               for each DQ seperately, in order to center the FPGA clock in
--               the data valid window.
-- Revision History:
--   Rev 1.1 - Changes for V4 no edge straddle calibration scheme.
--             State machine modified to detect an edge. Various other changes.
--             PK. 12/22/07
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.vcomponents.ALL;

entity DDR2_tap_ctrl_0 is
  port(
    clk                  : in  std_logic;
    reset                : in  std_logic;
    dq_data              : in  std_logic;
    ctrl_dummyread_start : in  std_logic;
    dlyinc               : out std_logic;
    dlyce                : out std_logic;
    chan_done            : out std_logic
    );
end DDR2_tap_ctrl_0;

architecture arch of DDR2_tap_ctrl_0 is

  function CALC_MAX_TAP_COUNT return integer is
  begin
    if (TBY4TAPVALUE < 32) then
      return TBY4TAPVALUE;
    else
      return 32;
    end if;
  end function CALC_MAX_TAP_COUNT;

  -- IDEL_SET_VAL = (# of cycles - 1) to wait after changing IDELAY value
  -- we only have to wait enough for input with new IDELAY value to
  -- propagate through pipeline stages
  constant IDEL_SET_VAL : unsigned(2 downto 0) := "111";

  -- Number of taps to be incremented or decremented after finding an edge.
  -- i.e., min(32, T/4)
  constant MAX_TAP_COUNT : integer := CALC_MAX_TAP_COUNT;

  type CAL1_STATE_TYPE is (IDLE,
                           BIT_CALIBRATION,
                           INC,
                           IDEL_WAIT,
                           EDGE,
                           EDGE_WAIT,
                           DEC,
                           INC_TAPS,
                           DONE,
                           PIPE_WAIT);

  signal cal_detect_edge    : std_logic;
  signal calib_start        : std_logic;
  signal curr_tap_cnt       : unsigned(5 downto 0);
  signal current_state      : CAL1_STATE_TYPE;
  signal dec_tap_count      : unsigned(5 downto 0);
  signal dlyce_int          : std_logic;
  signal dlyinc_int         : std_logic;
  signal done_int           : std_logic;
  signal inc_tap_count      : unsigned(5 downto 0);
  signal idel_set_cnt       : unsigned(2 downto 0);
  signal idel_set_wait      : std_logic;
  signal next_state         : CAL1_STATE_TYPE;
  signal prev_dq            : std_logic;
  signal reset_r1           : std_logic;
  signal tap_count_flag     : std_logic;
  signal tap_count_rst      : std_logic;
  signal tap_max_count_flag : std_logic;

  attribute max_fanout : string;
  attribute syn_maxfan : integer;
  attribute max_fanout of current_state : signal is "5";
  attribute syn_maxfan of current_state : signal is 5;
  attribute max_fanout of next_state    : signal is "5";
  attribute syn_maxfan of next_state    : signal is 5;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of reset_r1 : signal is "no";
  attribute syn_preserve of reset_r1                : signal is true;

begin

  --*******************************************************************

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      reset_r1 <= reset;
    end if;
  end process;

  dlyce              <= dlyce_int;
  dlyinc             <= dlyinc_int;

  -- Asserted when per bit calibration complete
  chan_done          <= done_int;

  -- Asserted when controller is issuing a dummy read
  process(clk)
  begin
    if clk'event and clk = '1' then
      if reset_r1 = '1' then
        calib_start <= '0';
      else
        calib_start <= ctrl_dummyread_start;
      end if;
    end if;
  end process;

  --*******************************************************************
  -- Per Bit calibration: DQ-FPGA Clock
  -- Definitions:
  --  edge: detected when varying IDELAY, and current capture data != prev
  --    capture data
  -- Algorithm Description:
  --  1. Starts at IDELAY tap 0 for each bit
  --  2. Increment DQ IDELAY until we find an edge.
  --  3. Once it finds an edge, decide whether it’s more accurate to
  --     increment or decrement by min(32, T/4).
  --  4. If no edge is found by tap 63, decrement to tap MAX_TAP_COUNT.
  --  5. Repeat for each DQ in current DQS set.
  --*******************************************************************

  -- Current State Logic
  process(clk)
  begin
    if clk'event and clk = '1' then
      if ((reset_r1 = '1') or ((not(ctrl_dummyread_start)) = '1')) then
        current_state <= IDLE;
      else
        current_state <= next_state;
      end if;
    end if;
  end process;

  --*******************************************************************
  -- signal to tell calibration state machines to wait and give IDELAY time to
  -- settle after it's value is changed (both time for IDELAY chain to settle,
  -- and for settled output to propagate through IDDR). For general use: use
  -- for any calibration state machines that modify any IDELAY.
  -- Should give at least enough time for IDELAY output to settle for new data
  -- to propagate through IDDR.
  -- For now, give very "generous" delay - doesn't really matter since only
  -- needed during calibration
  --*******************************************************************

  idel_set_wait <= '1' when (idel_set_cnt /= IDEL_SET_VAL) else '0';

  process(clk)
  begin
    if clk'event and clk = '1' then
      if reset_r1 = '1' then
        idel_set_cnt <= (others => '0');
      elsif (dlyce_int = '1') then
        idel_set_cnt <= (others => '0');
      elsif (idel_set_cnt /= IDEL_SET_VAL) then
       idel_set_cnt <= idel_set_cnt + "001";
      end if;
    end if;
  end process;

  -- Everytime the IDELAY is incremented when searching for edge of
  -- data valid window, wait for some time for IDELAY output to settle
  -- (IDELAY output can glitch), then sample the output. Then:
  --   1. Compare current value of DQ to PREV_DQ, if they are different
  --      then an edge has been found
  --   2. Set PREV_DQ = current value of DQ
  process(clk)
  begin
    if clk'event and clk = '1' then
      -- When first calibrating each individual bit, store the initial value
      -- of data as PREV_DQ (i.e. initialize PREV_DQ - since it's possible to
      -- find an edge immediately after the first incrementation of IDELAY)
      -- NOTE: Make sure that during state BIT_CALIBRATION, that DQ_DATA
      --  reflects the current DQ being calibrated (i.e. does not reflect the
      --  previous DQ bit)
      if (current_state = BIT_CALIBRATION) then
        prev_dq <= dq_data;
        cal_detect_edge <= '0';
      elsif ((not(idel_set_wait) = '1') and (current_state = IDEL_WAIT)) then
        -- Only update PREV_DQ once each time after IDELAY inc'ed - update
        -- as we're done waiting for IDELAY to settle
        prev_dq <= dq_data;
        if (dq_data /= prev_dq) then
          cal_detect_edge <= '1';
        else
          cal_detect_edge <= '0';
        end if;
      end if;
    end if;
  end process;

  --*****************************************************************
  -- keep track of edge tap counts found, and whether we've
  -- incremented to the maximum number of taps allowed
  -- curr_tap_cnt is reset for each bit
  --*****************************************************************

  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1' or tap_count_rst = '1') then
        curr_tap_cnt <= (others => '0');
      elsif((dlyce_int = '1') and (dlyinc_int = '1')) then
        curr_tap_cnt <= curr_tap_cnt + "000001";
      end if;
    end if;
  end process;

  --*******************************************************************
  -- Keeps track of tap counts to increment or decrement
  -- by min(32, T/4) once it finds an edge.
  --*******************************************************************

  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1' or tap_count_rst = '1') then
        dec_tap_count <= TO_UNSIGNED(MAX_TAP_COUNT, 6);
      elsif ((dlyce_int = '1') and (dlyinc_int = '0')) then
        dec_tap_count <= dec_tap_count - "000001";
      end if;
    end if;
  end process;

  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1' or tap_count_rst = '1') then
        inc_tap_count <= TO_UNSIGNED(MAX_TAP_COUNT, 6);
      elsif ((dlyce_int = '1') and (dlyinc_int = '1')) then
        inc_tap_count <= inc_tap_count - "000001";
      end if;
    end if;
  end process;

  -- Flag to decide whether it’s more accurate
  -- to increment or decrement by min(32, T/4) after finding an edge.
  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1') then
        tap_count_flag <= '0';
      elsif (curr_tap_cnt > TO_UNSIGNED(MAX_TAP_COUNT, 6)) then
        tap_count_flag <= '1';
      else
        tap_count_flag <= '0';
      end if;
    end if;
  end process;

  -- Flag asserted, if edge not found and tap count reached maximum value
  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset_r1 = '1') then
        tap_max_count_flag <= '0';
      elsif (curr_tap_cnt = TO_UNSIGNED(63, 6)) then
        tap_max_count_flag <= '1';
      else
        tap_max_count_flag <= '0';
      end if;
    end if;
  end process;

  --*******************************************************************
  -- Flags for taps to increment or decrement.
  -- Flags for counters deassertion.
  --*******************************************************************

  process(current_state, dlyce_int, dlyinc_int,
          tap_count_rst, done_int)
  begin
    -- default values, all these flags gets pulsed in different states
    dlyce_int              <= '0';
    dlyinc_int             <= '0';
    done_int               <= '0';
    tap_count_rst          <= '0';

    case current_state is

      when BIT_CALIBRATION =>
        -- Reset all tap counters before per bit calibration of each bit
        tap_count_rst <= '1';

      when INC =>
        -- Increment taps by one tap
        dlyce_int  <= '1';
        dlyinc_int <= '1';

      when EDGE_WAIT =>
        -- Reset all tap counters before per bit calibration of each bit
        tap_count_rst <= '1';

      when DEC =>
        -- Decrement taps by one tap
        dlyce_int  <= '1';
        dlyinc_int <= '0';

      when INC_TAPS =>
        -- Increment taps by one tap
        dlyce_int  <= '1';
        dlyinc_int <= '1';

      when DONE =>
        done_int <= '1';

      when others =>
        dlyce_int     <= '0';
        dlyinc_int    <= '0';
        done_int      <= '0';
        tap_count_rst <= '0';

    end case;
  end process;

  --*******************************************************************
  -- Next State Logic
  --*******************************************************************

  process(current_state, calib_start, idel_set_wait, cal_detect_edge,
          tap_max_count_flag, tap_count_flag, dec_tap_count, inc_tap_count)
  begin
    case current_state is

      -- Start per bit calibration after controller issues dummy read
      when IDLE =>
        if (calib_start = '1') then
          next_state <= BIT_CALIBRATION;
        else
          next_state <= IDLE;
        end if;

      -- starts per bit calibration for each bit
      when BIT_CALIBRATION =>
        next_state <= INC;

      -- increment by one tap value
      when INC =>
        next_state <= IDEL_WAIT;

      when IDEL_WAIT =>
         if ((not(idel_set_wait)) = '1') then
           -- wait few clock cycles for IDELAY output to settle and
           -- IDDR pipe to clear
           next_state <= EDGE;
         else
           next_state <= IDEL_WAIT;
         end if;

      when EDGE =>
        if (cal_detect_edge = '1') then
          -- if edge found, increment or decrement by MAX_TAP_COUNT
          next_state <= EDGE_WAIT;
        elsif (tap_max_count_flag = '1') then
          -- if edge not found, decrement by MAX_TAP_COUNT taps
          next_state <= DEC;
        else
          next_state <= INC;
        end if;

      when EDGE_WAIT =>
        if (tap_count_flag = '1') then
          -- if edge found and taps incremented (curr_tap_cnt) to find
          -- an edge are more than MAX_TAP_COUNT, decrement by MAX_TAP_COUNT.
          next_state <= DEC;
        else
          -- if edge found and taps incremented (curr_tap_cnt) to find
          -- an edge are less than MAX_TAP_COUNT, increment by MAX_TAP_COUNT.
          next_state <= INC_TAPS;
        end if;

      -- Decrement by MAX_TAP_COUNT i.e., T/4 or 32
      when DEC =>
        if (dec_tap_count = TO_UNSIGNED(1, 6)) then
          next_state <= DONE;
        else
          next_state <= DEC;
        end if;

      -- Decrement by MAX_TAP_COUNT i.e., T/4 or 32
      when INC_TAPS =>
        if (inc_tap_count = TO_UNSIGNED(1, 6)) then
          next_state <= DONE;
        else
          next_state <= INC_TAPS;
        end if;

      -- per bit calibration completed for one bit and continue for other bits
      when DONE =>
        next_state <= PIPE_WAIT;

      -- wait extra clock cycle to allow MUX selector for which bit to
      -- calibrate to take effect. Not needed in current design because all
      -- MUX logic is combination, but include just in case later need to
      -- add register stage for MUX logic for timing purposes
      when PIPE_WAIT =>
        next_state <= BIT_CALIBRATION;

    end case;
  end process;


end arch;
