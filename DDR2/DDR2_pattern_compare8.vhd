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
--  /   /        Filename           : DDR2_pattern_compare8.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : Compares the IOB output 8 bit data of one bank
--               that is read data during the initialization to get
--               the delay for the data with respect to the command issued.
-- Revision History:
--   Rev 1.1 - Changes for V4 no edge straddle calibration scheme. Added
--             PER_BIT_SKEW input, COMP_ERROR, DELAY_ENABLE outputs.
--             Use single calibration state machine to handle both falling
--             and rising edge data pattern cal. Use shift
--             register for enable delay chain. Various other changes. RC.
--             12/23/07
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity DDR2_pattern_compare8 is
  port(
    clk            : in  std_logic;
    rst            : in  std_logic;
    ctrl_rden      : in  std_logic;
    calib_done     : in  std_logic;
    rd_data_rise   : in  std_logic_vector(7 downto 0);
    rd_data_fall   : in  std_logic_vector(7 downto 0);
    -- indicates possible capture skew over DQ's
    per_bit_skew   : in  std_logic_vector(7 downto 0);
    comp_done      : out std_logic;
    -- asserted if unable to find correct pattern
    comp_error     : out std_logic;
    first_rising   : out std_logic;
    rd_en_rise     : out std_logic;
    rd_en_fall     : out std_logic;
    cal_first_loop : out std_logic;
    -- control delay/swap MUX for each DQ
    delay_enable   : out std_logic_vector(7 downto 0)
    );
end entity;

architecture arc_pattern_compare of DDR2_pattern_compare8 is

  type CAL2_STATE_TYPE is (CAL_IDLE,
                           CAL_CHECK_DATA,
                           CAL_INV_DELAY_ENABLE,
                           CAL_DONE,
                           CAL_ERROR);

  signal cal_first_loop_i          : std_logic;
  signal cal_next_state            : CAL2_STATE_TYPE;
  signal cal_state                 : CAL2_STATE_TYPE;
  signal clk_count                 : std_logic_vector(3 downto 0);
  signal cntrl_rden_r              : std_logic;
  signal comp_done_r               : std_logic;
  signal comp_error_r              : std_logic;
  signal data_match_first_clk_fall : std_logic;
  signal data_match_first_clk_rise : std_logic;
  signal first_rising_i            : std_logic;
  signal found_first_clk_rise      : std_logic;
  signal found_first_clk_rise_r    : std_logic;
  signal lock_first_rising         : std_logic;
  signal rd_data_fall_r            : std_logic_vector(7 downto 0);
  signal rd_data_fall_r2           : std_logic_vector(7 downto 0);
  signal rd_data_rise_r            : std_logic_vector(7 downto 0);
  signal rd_data_rise_r2           : std_logic_vector(7 downto 0);
  signal rd_data_rise_r3           : std_logic_vector(7 downto 0);
  signal rd_en_out                 : std_logic;
  signal rd_en_out_r               : std_logic;
  signal rd_en_r1                  : std_logic;
  signal rd_en_r2                  : std_logic;
  signal rd_en_r3                  : std_logic;
  signal rd_en_r4                  : std_logic;
  signal rd_en_r5                  : std_logic;
  signal rd_en_r6                  : std_logic;
  signal rd_en_r7                  : std_logic;
  signal rd_en_r8                  : std_logic;
  signal rd_en_r9                  : std_logic;
  signal rd_en_r10                 : std_logic;
  signal rd_en_r11                 : std_logic;
  signal rst_r1                    : std_logic;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of rd_en_r1 : signal is "no";
  attribute syn_preserve of rd_en_r1                : signal is true;
  attribute equivalent_register_removal of rst_r1   : signal is "no";
  attribute syn_preserve of rst_r1                  : signal is true;

begin

  --***************************************************************************

  comp_done  <= comp_done_r;
  comp_error <= comp_error_r;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      rst_r1 <= rst;
    end if;
  end process;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        rd_en_r1  <= '0';
        rd_en_r2  <= '0';
        rd_en_r3  <= '0';
        rd_en_r4  <= '0';
        rd_en_r5  <= '0';
        rd_en_r6  <= '0';
        rd_en_r7  <= '0';
        rd_en_r8  <= '0';
        rd_en_r9  <= '0';
        rd_en_r10 <= '0';
        rd_en_r11 <= '0';
      else
        rd_en_r1  <= ctrl_rden;
        rd_en_r2  <= rd_en_r1;
        rd_en_r3  <= rd_en_r2;
        rd_en_r4  <= rd_en_r3;
        rd_en_r5  <= rd_en_r4;
        rd_en_r6  <= rd_en_r5;
        rd_en_r7  <= rd_en_r6;
        rd_en_r8  <= rd_en_r7;
        rd_en_r9  <= rd_en_r8;
        rd_en_r10 <= rd_en_r9;
        rd_en_r11 <= rd_en_r10;
      end if;
    end if;
  end process;

  --*******************************************************************
  -- Indicates when received data is equal to the expected data pattern
  -- There are two possible scenarios: (1) rise and fall data are arrive
  -- at the same clock cycle (FIRST_RISING = 0), (2) rise and fall data
  -- arrive "staggered" w/r to each other (FIRST_RISING = 1). Which
  -- sequence occurs depends on the results of the per-bit calibration
  -- (and whether first data from memory is captured using rising or
  -- falling edge data). Expected data pattern = [rise/fall] = 0110 for
  -- even bits, and 1001 for odd bits = "A55A"
  -- For FIRST_CLK_RISE = 0 (non-staggered case):
  --   - IDDR.Q1 = fall data, IDDR.Q2 = rise data, and rise and fall
  --     read data FIFO enables are asserted at same time
  -- For FIRST_CLK_FALL = 1 (staggered case):
  --   - IDDR.Q1 = rise data, IDDR.Q2 = fall data, and rise and fall
  --     read data FIFO enables must be offset by 1 clk (rise enable
  --     leads fall enable)
  --*******************************************************************

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      rd_data_rise_r  <= rd_data_rise;
      rd_data_fall_r  <= rd_data_fall;
      rd_data_rise_r2 <= rd_data_rise_r;
      rd_data_fall_r2 <= rd_data_fall_r;
      rd_data_rise_r3 <= rd_data_rise_r2;
    end if;
  end process;

  data_match_first_clk_fall <= '1' when ((rd_data_fall_r2 = X"AA") and
                                         (rd_data_rise_r2 = X"55") and
                                         (rd_data_fall_r  = X"55") and
                                         (rd_data_rise_r  = X"AA"))
                               else '0';

  data_match_first_clk_rise <= '1' when ((rd_data_rise_r3 = X"AA") and
                                         (rd_data_fall_r2 = X"55") and
                                         (rd_data_rise_r2 = X"55") and
                                         (rd_data_fall_r  = X"AA"))
                               else '0';

  --*******************************************************************
  -- State machine to determine:
  --  1. What round trip delay is for read data (i.e. from when
  --     CTRL_RDEN is asserted until when synchronized data is
  --     available at input to read data FIFO
  --  2. Whether data is arriving staggered or simulataneous (depends
  --     on whether first data from memory is latched in on rising or
  --     falling edge
  --  3. Whether there is bit-alignment from the per-bit calibration
  --     step - i.e. whether the same FPGA clock edge is being used to
  --     clock in bits from two different bit times on different DQ's
  --     in this DQS group
  --*******************************************************************
  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        cal_state <= CAL_IDLE;
      else
        cal_state <= cal_next_state;
      end if;
    end if;
  end process;

  process(cal_state, cntrl_rden_r, clk_count, cal_first_loop_i,
          data_match_first_clk_rise, data_match_first_clk_fall)
  begin
    -- default values, this value only gets pulsed when we find a
    -- FIRST_RISING data pattern
    found_first_clk_rise  <= '0';
    cal_next_state <= cal_state;
    case (cal_state) is

      when CAL_IDLE =>
        -- Don't start pattern calibration until controller issues read
        if(cntrl_rden_r = '1') then
          cal_next_state <= CAL_CHECK_DATA;
        end if;

      when CAL_CHECK_DATA =>
        -- Stay in this state until we've waited maximum number of clock
        -- cycles for a valid pattern to appear on the bus
        if (clk_count = "1111") then
          if (cal_first_loop_i = '1') then
            cal_next_state <= CAL_INV_DELAY_ENABLE;
          else
            -- Otherwise, we haven't found the right pattern
            cal_next_state <= CAL_ERROR;
          end if;
        else
          if (data_match_first_clk_rise = '1' or
              data_match_first_clk_fall = '1') then
            cal_next_state <= CAL_DONE;
            -- Indicate to logic which data pattern was found
            found_first_clk_rise <= data_match_first_clk_rise;
          end if;
        end if;

      -- Inverting the control pattern for the delay/swap circuit for the
      -- DQ's in this DQS group - we would have to do this if we got the
      -- directionality incorrect on the first go-around. Note that we have
      -- to wait several clock cycles to: (1) reflect new CLK_COUNT value,
      -- (2) allow rd_data_rise/fall pipe chain to clear
      when CAL_INV_DELAY_ENABLE =>
        cal_next_state <= CAL_IDLE;

      -- Found a first rising or first falling pattern. We're done here.
      when CAL_DONE =>
        cal_next_state <= CAL_DONE;

      -- Error - we incremented CLK_COUNT to the highest possible value
      -- and still didn't find a valid pattern - could be an issue with
      -- per-bit calibration, or a board-level (e.g. stuck at bit) issue
      when CAL_ERROR =>
        cal_next_state <= CAL_ERROR;

    end case;
  end process;

  --*******************************************************************

  -- Asserted when controller is issuing a read
  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        cntrl_rden_r <= '0';
      else
        cntrl_rden_r <= ctrl_rden;
      end if;
    end if;
  end process;

  -- Asserted when pattern calibration complete
  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        comp_done_r <= '0';
      elsif (cal_state = CAL_DONE) then
        comp_done_r <= '1';
      end if;
    end if;
  end process;

  -- Asserted when pattern calibration hangs due to error
  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        comp_error_r <= '0';
      elsif (cal_state = CAL_ERROR) then
        comp_error_r <= '1';
      end if;
    end if;
  end process;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      found_first_clk_rise_r <= found_first_clk_rise;
    end if;
  end process;

  first_rising <= first_rising_i;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        first_rising_i    <= '0';
        lock_first_rising <= '0';
      elsif (cal_state = CAL_DONE) then
        -- If we enter CAL_DONE and found_first_clk_rise_r is pulsed (meaning
        -- we found a FIRST_RISING=1 pattern), then set FIRST_RISING=0
        -- This will be used statically to control MUXes to determine which
        -- output (Q1 or Q2) of the IDDR is "rising" and which is "falling" data
        -- NOTE: Once first rising is set, it stays set
        -- NOTE: FIRST_RISING as it is used in the rest of the design does not
        -- mean the same thing as FOUND_FIRST_CLK_RISE in this design!! It
        -- is actually named for something else (=1 means rising data forms
        -- the LSB of the full data word). Hence the inversion here.
        if ((not(lock_first_rising)) = '1') then
          lock_first_rising <= '1';
          first_rising_i    <= not (found_first_clk_rise_r);
        end if;
      end if;
    end if;
  end process;

  --*******************************************************************

  -- Count # of clock cycles from when read is issued, until when
  -- correct data is detected
  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (cal_state = CAL_IDLE) then
        clk_count <= "0000";
      elsif (cal_state = CAL_CHECK_DATA) then
        clk_count <= clk_count + "0001";
      end if;
    end if;
  end process;

  -- NOTE: Probably don't need all these cases! Need to check on this!
  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        rd_en_out <= '0';
      else
        case clk_count is
          when "0101" => rd_en_out <= rd_en_r1;
          when "0110" => rd_en_out <= rd_en_r2;
          when "0111" => rd_en_out <= rd_en_r3;
          when "1000" => rd_en_out <= rd_en_r4;
          when "1001" => rd_en_out <= rd_en_r5;
          when "1010" => rd_en_out <= rd_en_r6;
          when "1011" => rd_en_out <= rd_en_r7;
          when "1100" => rd_en_out <= rd_en_r8;
          when "1101" => rd_en_out <= rd_en_r9;
          when "1110" => rd_en_out <= rd_en_r10;
          when "1111" => rd_en_out <= rd_en_r11;
          when others => rd_en_out <= '0';
        end case;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        rd_en_out_r <= '0';
      else
        rd_en_out_r <= rd_en_out;
      end if;
    end if;
  end process;

  -- Generate read enables for Rising and Falling read data FIFOs
  -- The timing of these will be dependent on whether a first rising or
  -- first falling pattern was detected.
  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        rd_en_rise <= '0';
        rd_en_fall <= '0';
      else
        if ((not(calib_done)) = '1') then
          rd_en_rise <= '0';
          rd_en_fall <= '0';
        elsif ((not(first_rising_i)) = '1') then
          rd_en_rise <= rd_en_out;
          rd_en_fall <= rd_en_out_r;
        else
          rd_en_rise <= rd_en_out_r;
          rd_en_fall <= rd_en_out_r;
        end if;
      end if;
    end if;
  end process;

  --*******************************************************************

  -- Keep track of which iteration of calibration loop we're in
  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        cal_first_loop_i <= '1';
      elsif (cal_state = CAL_INV_DELAY_ENABLE) then
        cal_first_loop_i <= '0';
      end if;
    end if;
  end process;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      cal_first_loop <= cal_first_loop_i;
    end if;
  end process;

  -- MUX control for delay/swap circuit for each DQ (used to compensate
  -- for possible bit-misalignment from per-bit calibration)
  process(clk)
  begin
    if (clk = '1' and clk'event) then
      if (rst_r1 = '1') then
        delay_enable <= (others => '0');
      else
        if(cal_first_loop_i = '1') then
          -- Special case if per_bit_skew = 0xFF. Set delay_enable = 0x00
          -- to bypass the delay/swap circuit (we should be able to find
          -- a match with either delay_enable = 0xFF or 0x00, but finding
          -- a match w/ = 0x00 saves one cycle of latency)
          if (per_bit_skew = "11111111") then
            delay_enable <= (others => '0');
          else
            delay_enable <= per_bit_skew;
          end if;
        else
          delay_enable <= (not(per_bit_skew));
        end if;
      end if;
    end if;
  end process;

end arc_pattern_compare;
