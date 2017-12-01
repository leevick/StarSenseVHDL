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
--  /   /        Filename           : DDR2_tap_logic_0.vhd
-- /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:52 $
-- \   \  /  \   Date Created       : Mon May 2 2005
--  \___\/\___\
--
-- Device      : Virtex-4
-- Design Name : DDR2 Direct Clocking
-- Purpose     : This module instantiates the tap_ctrl and the data_tap_inc
--               modules. Used for calibration of the memory data with
--               the FPGA clock.
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.DDR2_parameters_0.all;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity DDR2_tap_logic_0 is
  port (
    clk                  : in  std_logic;
    reset0               : in  std_logic;
    ctrl_dummyread_start : in  std_logic;
    calibration_dq       : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    sel_done             : out std_logic;
    data_idelay_inc      : out std_logic_vector(DATA_WIDTH-1 downto 0);
    data_idelay_ce       : out std_logic_vector(DATA_WIDTH-1 downto 0);
    data_idelay_rst      : out std_logic_vector(DATA_WIDTH-1 downto 0);
    per_bit_skew         : out std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Debug Signals
    dbg_idel_up_all       : in  std_logic;
    dbg_idel_down_all     : in  std_logic;
    dbg_idel_up_dq        : in  std_logic;
    dbg_idel_down_dq      : in  std_logic;
    dbg_sel_idel_dq       : in  std_logic_vector(DQ_BITS-1 downto 0);
    dbg_sel_all_idel_dq   : in  std_logic;
    dbg_calib_dq_tap_cnt  : out std_logic_vector(((6*DATA_WIDTH)-1) downto 0);
    dbg_data_tap_inc_done : out std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
    dbg_sel_done          : out std_logic
    );

end entity;

architecture arc_tap_logic of DDR2_tap_logic_0 is

  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of arc_tap_logic : architecture IS
    "mig_v3_61_ddr2_dc_v4, Coregen 12.4";

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of arc_tap_logic : architecture IS "ddr2_dc_v4,mig_v3_61,{component_name=DDR2_tap_logic_0, data_width=32, data_strobe_width=4, data_mask_width=4, clk_width=2, fifo_16=2, cs_width=1, odt_width=1, cke_width=1, row_address=14, registered=0, single_rank=1, dual_rank=0, databitsperstrobe=8, mask_enable=1, use_dm_port=1, column_address=10, bank_address=3, debug_en=0, load_mode_register=00010000110010, ext_load_mode_register=00000000000000, chip_address=1, ecc_enable=0, ecc_width=0, reset_active_low=1, tby4tapvalue=17, rfc_count_value=00100111, ras_count_value=00111, rcd_count_value=010, rp_count_value=010, trtp_count_value=001, twr_count_value=011, twtr_count_value=001, max_ref_width=11, max_ref_cnt=11000011000, language=VHDL, synthesis_tool=ISE, interface_type=DDR2_SDRAM_Direct_Clocking, no_of_controllers=1}";

  component DDR2_tap_ctrl_0
    port (
      clk                  : in  std_logic;
      reset                : in  std_logic;
      dq_data              : in  std_logic;
      ctrl_dummyread_start : in  std_logic;
      dlyinc               : out std_logic;
      dlyce                : out std_logic;
      chan_done            : out std_logic
      );
  end component;

  component DDR2_data_tap_inc_0
    port (
      clk                : in  std_logic;
      reset              : in  std_logic;
      calibration_dq     : in  std_logic_vector(DATABITSPERSTROBE-1 downto 0);
      ctrl_calib_start   : in  std_logic;
      dlyinc             : in  std_logic;
      dlyce              : in  std_logic;
      chan_done          : in  std_logic;
      dq_data            : out std_logic;
      data_dlyinc        : out std_logic_vector(DATABITSPERSTROBE-1 downto 0);
      data_dlyce         : out std_logic_vector(DATABITSPERSTROBE-1 downto 0);
      data_dlyrst        : out std_logic_vector(DATABITSPERSTROBE-1 downto 0);
      calib_done         : out std_logic;
      per_bit_skew       : out std_logic_vector(DATABITSPERSTROBE-1 downto 0)
      );
  end component;

  signal data_dlyinc           : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal data_dlyce            : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal data_dlyinc_r         : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal data_dlyce_r          : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal data_idelay_inc_i     : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal data_idelay_ce_i      : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal dlyinc_dqs            : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal dlyce_dqs             : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal chan_done_dqs         : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal dq_data_dqs           : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal calib_done_dqs        : std_logic_vector(DATA_STROBE_WIDTH-1 downto 0);
  signal data_tap_inc_done     : std_logic;
  signal tap_sel_done          : std_logic;
  signal reset0_r1             : std_logic;

  -- Debug
  type TYPE_DBG_DQ_ARRAY is array (DATA_WIDTH-1 downto 0) of
    unsigned(5 downto 0);
  signal dbg_dq_tap_cnt        : TYPE_DBG_DQ_ARRAY;

  attribute equivalent_register_removal : string;
  attribute syn_preserve                : boolean;
  attribute equivalent_register_removal of reset0_r1 : signal is "no";
  attribute syn_preserve of reset0_r1                : signal is true;

begin

  --***************************************************************************

  -- For controller to stop dummy reads

  sel_done       <= tap_sel_done;

  process(clk)
  begin
    if (clk = '1' and clk'event) then
      reset0_r1 <= reset0;
    end if;
  end process;

  process(clk)
  begin
    if clk'event and clk = '1' then
      if (reset0_r1 = '1') then
        data_tap_inc_done <= '0';
        tap_sel_done      <= '0';
      else
        data_tap_inc_done <= ( calib_done_dqs(0) and calib_done_dqs(1) and calib_done_dqs(2) and calib_done_dqs(3) );
        tap_sel_done      <= data_tap_inc_done;
      end if;
    end if;
  end process;

  --***************************************************************************
  -- Debug output ("dbg_*")
  -- NOTES:
  --  1. All debug outputs coming out of TAP_LOGIC are clocked off CLK0,
  --     although they are also static after calibration is complete. This
  --     means the user can either connect them to a Chipscope ILA, or to
  --     either a sync/async VIO input block. Using an async VIO has the
  --     advantage of not requiring these paths to meet cycle-to-cycle timing.
  --  2. The widths of most of these debug buses are dependent on the # of
  --     DQS/DQ bits (e.g. dq_tap_cnt width = 6 * (# of DQ bits)
  -- SIGNAL DESCRIPTION:
  --  1. tap_sel_done:      1 bit - asserted as per bit calibration 
  --                        (first stage) is completed.
  --  2. data_tap_inc_done: # of DQS bits - each one asserted when 
  --                        per bit calibration is completed for 
  --                        corresponding byte.
  --  3. calib_dq_tap_cnt:  final IDELAY tap counts for all DQ IDELAYs
  --***************************************************************************

  dbg_sel_done <= tap_sel_done;
  dbg_data_tap_inc_done <= calib_done_dqs;

  data_idelay_inc_i <= data_dlyinc_r when (DEBUG_EN = 1) else data_dlyinc;
  data_idelay_ce_i <= data_dlyce_r when (DEBUG_EN = 1) else data_dlyce;

  data_idelay_inc <= data_idelay_inc_i;
  data_idelay_ce  <= data_idelay_ce_i;

  process (clk)
  begin
     if (rising_edge (clk)) then
       if (reset0_r1 = '1') then
         data_dlyce_r  <= (others => '0');
         data_dlyinc_r <= (others => '0');
       else
         data_dlyce_r  <= (others => '0');
         data_dlyinc_r <= (others => '0');

         if (not(data_tap_inc_done) = '1') then
           data_dlyce_r  <= data_dlyce;
           data_dlyinc_r <= data_dlyinc;
         -- DEBUG: allow user to vary IDELAY tap settings
         -- For DQ IDELAY taps
         elsif (DEBUG_EN = 1) then
           if (dbg_idel_up_all = '1' or dbg_idel_down_all = '1' or
               dbg_sel_all_idel_dq = '1') then
             loop_dly_inc_dq: for x in 0 to DATA_WIDTH-1 loop
               data_dlyce_r(x)  <= dbg_idel_up_all or dbg_idel_down_all or
                                     dbg_idel_up_dq  or dbg_idel_down_dq;
               data_dlyinc_r(x) <= dbg_idel_up_all or dbg_idel_up_dq;
             end loop;
           else
             data_dlyce_r <= (others => '0');
             data_dlyce_r(to_integer(unsigned(dbg_sel_idel_dq)))
               <= dbg_idel_up_dq or dbg_idel_down_dq;
             data_dlyinc_r(to_integer(unsigned(dbg_sel_idel_dq)))
               <= dbg_idel_up_dq;
           end if;
         end if;
       end if;
     end if;
  end process;

  --*****************************************************************
  -- Record IDELAY tap values by "snooping" IDELAY control signals
  --*****************************************************************

  -- record DQ IDELAY tap values
  gen_dbg_dq_tap_cnt: for dbg_dq_tc_i in 0 to DATA_WIDTH-1 generate
    dbg_calib_dq_tap_cnt(((6*dbg_dq_tc_i)+5) downto (6*dbg_dq_tc_i))
      <= std_logic_vector(dbg_dq_tap_cnt(dbg_dq_tc_i));
    process (clk)
    begin
      if (rising_edge (clk)) then
        if (reset0_r1 = '1') then
          dbg_dq_tap_cnt(dbg_dq_tc_i) <= TO_UNSIGNED(0,6);
        else
          if (data_idelay_ce_i(dbg_dq_tc_i) = '1') then
            if (data_idelay_inc_i(dbg_dq_tc_i) = '1') then
              dbg_dq_tap_cnt(dbg_dq_tc_i)
                <= dbg_dq_tap_cnt(dbg_dq_tc_i) + 1;
            else
              dbg_dq_tap_cnt(dbg_dq_tc_i)
                <= dbg_dq_tap_cnt(dbg_dq_tc_i) - 1;
            end if;
          end if;
        end if;
      end if;
    end process;
  end generate;

  --***************************************************************************
  -- tap_ctrl instances
  --***************************************************************************
  gen_tap_ctrl: for dqs_i in 0 to DATA_STROBE_WIDTH-1 generate
    u_tap_ctrl_dqs : DDR2_tap_ctrl_0
      port map (
        clk                  => clk,
        reset                => reset0,
        dq_data              => dq_data_dqs(dqs_i),
        ctrl_dummyread_start => ctrl_dummyread_start,
        dlyinc               => dlyinc_dqs(dqs_i),
        dlyce                => dlyce_dqs(dqs_i),
        chan_done            => chan_done_dqs(dqs_i)
        );
  end generate;

  --***************************************************************************
  -- data_tap_inc instances
  --***************************************************************************
  gen_data_tap_inc: for dqs_ii in 0 to DATA_STROBE_WIDTH-1 generate
    u_data_tap_inc : DDR2_data_tap_inc_0
      port map (
        clk                => clk,
        reset              => reset0,
        calibration_dq     => calibration_dq((DATABITSPERSTROBE*(dqs_ii+1))-1
                                             downto DATABITSPERSTROBE*dqs_ii),
        ctrl_calib_start   => ctrl_dummyread_start,
        dlyinc             => dlyinc_dqs(dqs_ii),
        dlyce              => dlyce_dqs(dqs_ii),
        chan_done          => chan_done_dqs(dqs_ii),
        dq_data            => dq_data_dqs(dqs_ii),
        data_dlyinc        => data_dlyinc((DATABITSPERSTROBE*(dqs_ii+1))-1
                                           downto DATABITSPERSTROBE*dqs_ii),
        data_dlyce         => data_dlyce((DATABITSPERSTROBE*(dqs_ii+1))-1
                                          downto DATABITSPERSTROBE*dqs_ii),
        data_dlyrst        => data_idelay_rst((DATABITSPERSTROBE*(dqs_ii+1))-1
                                              downto DATABITSPERSTROBE*dqs_ii),
        calib_done         => calib_done_dqs(dqs_ii),
        per_bit_skew       => per_bit_skew((DATABITSPERSTROBE*(dqs_ii+1))-1
                                            downto DATABITSPERSTROBE*dqs_ii)
        );
  end generate;

end arc_tap_logic;
